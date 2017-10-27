module PlotlyV2

# ------------- #
# Imports/Setup #
# ------------- #

using Plotly, JSON, Requests

const API_ROOT = "https://api.plot.ly/v2/"
const VERSION = string(Pkg.installed("Plotly"))

const METHOD_MAP = Dict(
    :get => Requests.get,
    :post => Requests.post,
    :put => Requests.put,
    :delete => Requests.delete,
    :patch => Requests.patch,
)

# import HTTP
# const METHOD_MAP = Dict(
#     :get => HTTP.get,
#     :post => HTTP.post,
#     :put => HTTP.put,
#     :delete => HTTP.delete,
#     :patch => HTTP.patch,
# )
# function validate_response(res::HTTP.Response)
#     if res.status > 204
#         uri = get(res.request).uri
#         throw(PlotlyAPIError("Request $uri failed with code $(res.status)", res))
#     end
# end
# get_json_data(res::HTTP.Response) = JSON.parse(deepcopy(res.body))

# --------------- #
# Tools/Utilities #
# --------------- #

function get_method(method::Symbol)
    if haskey(METHOD_MAP, method)
        return METHOD_MAP[method]
    else
        error("Unkown method type $method requested")
    end
end
get_method(s::String) = get_method(Symbol(s))

struct PlotlyAPIError <: Exception
    msg
    res
end

function validate_response(res::Requests.Response)
    code = Requests.statuscode(res)
    if code > 204
        uri = Requests.requestfor(res).uri
        # TODO: provide meaningful error message based on request url + status
        throw(PlotlyAPIError("Request $uri failed with code $code", res))
    end
end

get_json_data(res::Requests.Response) = Requests.json(res)

function basic_auth(username, password)
    # ref https://github.com/plotly/plotly.py/blob/master/plotly/api/utils.py
    return string("Basic ", base64encode(string(username, ":", password)))
end

function get_headers(method::Symbol=:get)
    creds = Plotly.get_credentials()
    return Dict{Any,Any}(
        "Plotly-Client-Platform" => "Julia $(VERSION)",
        "Content-Type" => "application/json",
        "content-type" => "application/json",
        "Accept" =>  "application/json",  # TODO: for some reason I had to do this to get it to work???
        "authorization" => basic_auth(creds.username, creds.api_key),
    )
end
get_headers(s::String) = get_headers(Symbol(s))

function get_json(;kwargs...)
    out = Dict()
    for (k, v) in kwargs
        if v !=nothing
            out[k] = v
        end
    end
    out
end

function _get_uid(uids)
    length(uids) == 0 && error("Must supply at least one uid")
    uid = join(map(string, uids), ",")
end

function api_url(endpoint; fid=nothing, route=nothing)
    extra = []
    fid !== nothing && push!(extra, fid)
    route !== nothing && push!(extra, route)
    out = string(API_ROOT, endpoint)
    if length(extra) > 0
        return out *  "/" * join(extra, "/")
    else
        return out
    end
end

function request(method, endpoint; fid=nothing, route=nothing, json=nothing, kwargs...)
    url = api_url(endpoint; fid=fid, route=route)
    method_func = get_method(method)
    query_params = Dict()
    for (k, v) in kwargs
        if v !== nothing
            query_params[k] = v
        end
    end
    if Symbol(method) in (:post, :patch, :put) && json !== nothing
        # here I am!
        res = method_func(url, headers=get_headers(method), query=query_params, json=json)
    else
        res = method_func(url, headers=get_headers(method), query=query_params)
    end
    validate_response(res)
    res
end

function request_data(method, endpoint; kwargs...)
    res = request(method, endpoint; kwargs...)
    content_type = get(Requests.headers(res), "Content-Type", "application/json")
    if startswith(content_type, "application/json")
        return get_json_data(res)
    else
        return res
    end
end

# ---------------- #
# # API wrappers # #
# ---------------- #

struct ApiCall
    funname::Symbol
    method::Symbol
    endpoint::Symbol
    fid::Bool
    route::Union{Void,Symbol}
    required::Vector{Symbol}
    optional::Vector{Symbol}
    json::Vector{Symbol}
    required_json::Vector{Symbol}
    uids::Bool
    data_out::Bool
end

function ApiCall(
        funname::Symbol, method::Symbol, endpoint::Symbol, fid::Bool=false,
        route=nothing; required=Symbol[], optional=Symbol[], json=Symbol[],
        required_json=Symbol[], uids::Bool=false, data_out::Bool=true
    )
    ApiCall(
        funname, method, endpoint, fid, route, required, optional, json,
        required_json, uids, data_out
    )
end

function make_method(api::ApiCall)
    request_fun = api.data_out ? :request_data : :request
    request_kwargs = []

    all_kw = vcat(api.json, api.optional)
    sig = Expr(:call,
        api.funname,
        Expr(:parameters, [Expr(:kw, name, nothing) for name in all_kw]...),
    )
    if api.fid
        push!(sig.args, :_fid)
        push!(request_kwargs, Expr(:kw, :fid, :_fid))
    end

    # add rest of required
    append!(sig.args, api.required)
    append!(sig.args, api.required_json)
    if api.uids
        push!(sig.args, Expr(:(...), :uids))
        push!(request_kwargs, Expr(:kw, :uid, :(_get_uid(uids))))
    end

    if api.route != nothing
        push!(request_kwargs, Expr(:kw, :route, string(api.route)))
    end

    all_json = vcat(api.json, api.required_json)
    if length(all_json) > 0
        call_get_json = Expr(:call, :get_json, [Expr(:kw, name, name) for name in all_json]...)
        push!(request_kwargs, Expr(:kw, :json, call_get_json))
    elseif api.method in (:put, :post, :patch, :delete)
        # need to add empty json argument on put these request methods when
        # no json data is needed.
        push!(request_kwargs, Expr(:kw, :json, :(Dict())))
    end

    # add rest of kwargs
    append!(request_kwargs, [Expr(:kw, name, name) for name in api.optional])
    append!(request_kwargs, [Expr(:kw, name, name) for name in api.required])

    body = Expr(:block,
        Expr(:call,
            request_fun,
            string(api.method),
            string(api.endpoint),
            request_kwargs...,
        )
    )

    if api.data_out
        raw_sig = deepcopy(sig)
        raw_sig.args[1] = Symbol(api.funname, "_", "raw")

        raw_body = deepcopy(body)
        raw_body.args[1].args[1] = :request
        return Expr(:block, Expr(:function, sig, body), Expr(:function, raw_sig, raw_body))

    else
        return Expr(:function, sig, body)
    end
end

file_writeable_metadata = [
    :parent_path, :filename, :parent, :share_key_enabled, :world_readable
]
grid_writable_metadata = vcat(file_writeable_metadata, [:])
for _api in [
        # search
        ApiCall(:search_list, :get, :search, false, required=[:q])

        # files
        ApiCall(:file_retrieve, :get, :files, true)
        ApiCall(:file_content, :get, :files, true, :content)  # failing
        ApiCall(:file_update, :put, :files, true, json=file_writeable_metadata)
        ApiCall(:file_partial_update, :patch, :files, true, json=file_writeable_metadata)
        ApiCall(:file_image, :get, :files, true, :image)
        ApiCall(:file_copy, :get, :files, true, :copy, optional=[:deep_copy])  # failing
        ApiCall(:file_path, :get, :files, true, :path)
        ApiCall(:file_drop_reference, :post, :files, true, :drop_reference, json=[:fid])
        ApiCall(:file_trash, :post, :files, true, :trash)
        ApiCall(:file_restore, :post, :files, true, :restore)
        ApiCall(:file_permanent_delete, :post, :files, true, :permanent_delete, data_out=false)
        ApiCall(:file_lookup, :get, :files, false, :lookup, required=[:path], optional=[:parent, :user, :exists])
        ApiCall(:file_star, :post, :files, true, :star)
        ApiCall(:file_remove_star, :delete, :files, true, :star, data_out=false)
        ApiCall(:file_sources, :get, :files, true, :sources)

        # grids
        ApiCall(:grid_create, :post, :grids, false, required_json=[:data], json=file_writeable_metadata)
        # ApiCall(:grid_upload)  # failing
        ApiCall(:grid_row, :post, :grids, true, :row, required_json=[:rows], data_out=false)
        ApiCall(:grid_get_col, :get, :grids, true, :col, uids=true)
        ApiCall(:grid_put_col, :put, :grids, true, :col, uids=true, required_json=[:cols])  # failing
        ApiCall(:grid_post_col, :post, :grids, true, :col, required_json=[:cols])  # failing
        ApiCall(:grid_retrieve, :get, :grids, true)
        ApiCall(:grid_content, :get, :grids, true, :content)
        ApiCall(:grid_destroy, :delete, :grids, true, data_out=false)
        ApiCall(:grid_partial_update, :patch, :grids, true, json=file_writeable_metadata)
        ApiCall(:grid_update, :put, :grids, true, json=file_writeable_metadata)
        ApiCall(:grid_drop_reference, :post, :grids, true, :drop_reference, json=[:fid])
        ApiCall(:grid_trash, :post, :grids, true, :trash)
        ApiCall(:grid_restore, :post, :grids, true, :restore)
        ApiCall(:grid_permanent_delete, :post, :grids, true, :permanent_delete, data_out=false)
        ApiCall(:grid_lookup, :get, :grids, false, :lookup, required=[:path], optional=[:parent, :user, :exists])

        # plots
        ApiCall(:plot_list, :get, :plots, false, optional=[:order_by, :min_quality, :max_quality])
        ApiCall(:plot_feed, :get, :plots, false, :feed)
        ApiCall(:plot_create, :post, :plots, false; required_json=[:figure], json=file_writeable_metadata)
        ApiCall(:plot_detail, :get, :plots, true)
        ApiCall(:plot_content, :get, :plots, true, :content, optional=[:inline_data, :map_data])
        ApiCall(:plot_update, :put, :plots, true, json=file_writeable_metadata)
        ApiCall(:plot_partial_update, :patch, :plots, true, json=file_writeable_metadata)

        # extras
        ApiCall(:extra_create, :post, :extras, false, required_json=[:referencers], json=[:filename, :content])
        ApiCall(:extra_content, :post, :extras, true, :content)
        ApiCall(:extra_partial_update, :patch, :extras, true, json=[:filename, :content])
        ApiCall(:extra_delete, :delete, :extras, true, data_out=false)
        ApiCall(:extra_detail, :get, :extras, true)

        # folders
        ApiCall(:folder_create, :post, :folders, false, required_json=[:path], json=[:parent])
        ApiCall(:folder_detail, :get, :folders, true)
        ApiCall(:folder_home, :get, :folders, false, :home, optional=[:user])
        ApiCall(:folder_shared, :get, :folders, false, :shared)
        ApiCall(:folder_starred, :get, :folders, false, :starred)
        ApiCall(:folder_trashed, :get, :folders, false, :trashed)
        ApiCall(:folder_all, :get, :folders, false, :all, optional=[:user, :filetype, :order_by])
        ApiCall(:folder_trash, :post, :folders, true, :trash)
        ApiCall(:folder_restore, :post, :folders, true, :restore)
        ApiCall(:folder_permanent_delete, :post, :folders, true, :permanent_delete)

        # images
        ApiCall(:image_generate, :post, :images, false, required_json=[:figure], json=[:width, :height, :format, :scale, :encoded])

        # comments
        ApiCall(:comment_create, :post, :comments, false, required_json=[:fid, :comment])
        ApiCall(:comment_delete, :delete, :comments, true)

        # plot-schema
        ApiCall(:plot_schema_get, :get, Symbol("plot-schema"), required=[:sha1])
    ]
    eval(current_module(), make_method(_api))
end

# --------------------- #
# Convenience functions #
# --------------------- #

end  # module
