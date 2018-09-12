# ------------- #
# Imports/Setup #
# ------------- #

const API_ROOT = "https://api.plot.ly/v2/"
const _VERSION = string(Pkg.installed()["Plotly"])
import JSON: json
import HTTP, JSON
import HTTP: post
function validate_response(res::HTTP.Response)
    if res.status > 204
        url = res.request.headers["Host"] * "/" * res.request.target
        throw(PlotlyAPIError("Request $uri failed with code $(res.status)", res))
    end
end
get_json_data(res::HTTP.Response) = JSON.parse(String(res.body))
get_headers(res::HTTP.Response) = res.headers

# --------------- #
# Tools/Utilities #
# --------------- #
struct PlotlyAPIError <: Exception
    msg
    res
end


function basic_auth(username, password)
    # ref https://github.com/plotly/plotly.py/blob/master/plotly/api/utils.py
    return string("Basic ", base64encode(string(username, ":", password)))
end

function get_req_headers()
    creds = get_credentials()
    return Dict{Any,Any}(
        "Plotly-Client-Platform" => "Julia $(_VERSION)",
        "Content-Type" => "application/json",
        "content-type" => "application/json",
        "Accept" =>  "application/json",  # TODO: for some reason I had to do this to get it to work???
        "authorization" => basic_auth(creds.username, creds.api_key),
    )
end

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
    query_params = Dict()
    for (k, v) in kwargs
        if v !== nothing
            query_params[string(k)] = v
        end
    end
    # build kwargs for HTTP.request
    kw = Any[:query => query_params, :headers => get_req_headers()]
    json !== nothing && push!(kw, :body => JSON.json(json))

    res = HTTP.request(method, url; kw...)
    validate_response(res)
    res
end

function request_data(method, endpoint; kwargs...)
    res = request(method, endpoint; kwargs...)
    content_type = get(Dict(get_headers(res)), "Content-Type", "application/json")
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
    route::Union{Nothing,Symbol}
    required::Vector{Symbol}
    optional::Vector{Symbol}
    json::Vector{Symbol}
    pre_json::Vector{Symbol}
    required_json::Vector{Symbol}
    required_pre_json::Vector{Symbol}
    uids::Bool
    data_out::Bool
end

function ApiCall(
        funname::Symbol, method::Symbol, endpoint::Symbol, fid::Bool=false,
        route=nothing; required=Symbol[], optional=Symbol[], json=Symbol[],
        pre_json=Symbol[], required_json=Symbol[], required_pre_json=Symbol[],
        uids::Bool=false, data_out::Bool=true
    )
    ApiCall(
        funname, method, endpoint, fid, route, required, optional, json,
        pre_json, required_json, required_pre_json, uids, data_out
    )
end

function make_method(api::ApiCall)
    request_fun = api.data_out ? :request_data : :request
    request_kwargs = []

    all_kw = vcat(api.json, api.optional, api.pre_json)
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
    append!(sig.args, api.required_pre_json)
    if api.uids
        push!(sig.args, Expr(:(...), :uids))
        push!(request_kwargs, Expr(:kw, :uid, :(_get_uid(uids))))
    end

    if api.route != nothing
        push!(request_kwargs, Expr(:kw, :route, string(api.route)))
    end

    call_get_json = Expr(:call, :get_json)
    for name in vcat(api.pre_json, api.required_pre_json)
        push!(call_get_json.args, Expr(:kw, name, Expr(:call, :json, name)))
    end
    for name in vcat(api.json, api.required_json)
        push!(call_get_json.args, Expr(:kw, name, name))
    end

    if length(call_get_json.args) > 1  # we had some json args
        push!(request_kwargs, Expr(:kw, :json, call_get_json))
    elseif api.method in (:PUT, :POST, :PATCH, :delete)
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
dashboard_writeable_metadata = [
    :content, :filename, :parent, :parent_path, :world_readable
]
for _api in [
        # search
        ApiCall(:search_list, :GET, :search, false, required=[:q])

        # files
        ApiCall(:file_retrieve, :GET, :files, true)
        ApiCall(:file_content, :GET, :files, true, :content)  # failing
        ApiCall(:file_update, :PUT, :files, true, json=file_writeable_metadata)
        ApiCall(:file_partial_update, :PATCH, :files, true, json=file_writeable_metadata)
        ApiCall(:file_image, :GET, :files, true, :image)
        ApiCall(:file_copy, :GET, :files, true, :copy, optional=[:deep_copy])  # failing
        ApiCall(:file_path, :GET, :files, true, :path)
        ApiCall(:file_drop_reference, :POST, :files, true, :drop_reference, json=[:fid])
        ApiCall(:file_trash, :POST, :files, true, :trash)
        ApiCall(:file_restore, :POST, :files, true, :restore)
        ApiCall(:file_permanent_delete, :POST, :files, true, :permanent_delete, data_out=false)
        ApiCall(:file_lookup, :GET, :files, false, :lookup, required=[:path], optional=[:parent, :user, :exists])
        ApiCall(:file_star, :POST, :files, true, :star)
        ApiCall(:file_remove_star, :DELETE, :files, true, :star, data_out=false)
        ApiCall(:file_sources, :GET, :files, true, :sources)

        # grids
        ApiCall(:grid_create, :POST, :grids, false, required_json=[:data], json=file_writeable_metadata)
        # ApiCall(:grid_upload)  # failing
        ApiCall(:grid_row, :POST, :grids, true, :row, required_json=[:rows], data_out=false)
        ApiCall(:grid_get_col, :GET, :grids, true, :col, uids=true)
        ApiCall(:grid_put_col, :PUT, :grids, true, :col, uids=true, required_pre_json=[:cols])
        ApiCall(:grid_post_col, :POST, :grids, true, :col, required_pre_json=[:cols])
        ApiCall(:grid_retrieve, :GET, :grids, true)
        ApiCall(:grid_content, :GET, :grids, true, :content)
        ApiCall(:grid_destroy, :DELETE, :grids, true, data_out=false)
        ApiCall(:grid_partial_update, :PATCH, :grids, true, json=file_writeable_metadata)
        ApiCall(:grid_update, :PUT, :grids, true, json=file_writeable_metadata)
        ApiCall(:grid_drop_reference, :POST, :grids, true, :drop_reference, json=[:fid])
        ApiCall(:grid_trash, :POST, :grids, true, :trash)
        ApiCall(:grid_restore, :POST, :grids, true, :restore)
        ApiCall(:grid_permanent_delete, :POST, :grids, true, :permanent_delete, data_out=false)
        ApiCall(:grid_lookup, :GET, :grids, false, :lookup, required=[:path], optional=[:parent, :user, :exists])

        # plots
        ApiCall(:plot_list, :GET, :plots, false, optional=[:order_by, :min_quality, :max_quality])
        ApiCall(:plot_feed, :GET, :plots, false, :feed)
        ApiCall(:plot_create, :POST, :plots, false; required_json=[:figure], json=file_writeable_metadata)
        ApiCall(:plot_detail, :GET, :plots, true)
        ApiCall(:plot_content, :GET, :plots, true, :content, optional=[:inline_data, :map_data])
        ApiCall(:plot_update, :PUT, :plots, true, json=vcat(file_writeable_metadata, :figure))
        ApiCall(:plot_partial_update, :PATCH, :plots, true, json=file_writeable_metadata)

        # extras
        ApiCall(:extra_create, :POST, :extras, false, required_json=[:referencers], json=[:filename, :content])
        ApiCall(:extra_content, :POST, :extras, true, :content)
        ApiCall(:extra_partial_update, :PATCH, :extras, true, json=[:filename, :content])
        ApiCall(:extra_delete, :DELETE, :extras, true, data_out=false)
        ApiCall(:extra_detail, :GET, :extras, true)

        # folders
        ApiCall(:folder_create, :POST, :folders, false, required_json=[:path], json=[:parent])
        ApiCall(:folder_detail, :GET, :folders, true)
        ApiCall(:folder_home, :GET, :folders, false, :home, optional=[:user])
        ApiCall(:folder_shared, :GET, :folders, false, :shared)
        ApiCall(:folder_starred, :GET, :folders, false, :starred)
        ApiCall(:folder_trashed, :GET, :folders, false, :trashed)
        ApiCall(:folder_all, :GET, :folders, false, :all, optional=[:user, :filetype, :order_by])
        ApiCall(:folder_trash, :POST, :folders, true, :trash)
        ApiCall(:folder_restore, :POST, :folders, true, :restore)
        ApiCall(:folder_permanent_delete, :POST, :folders, true, :permanent_delete)

        # images
        ApiCall(:image_generate, :POST, :images, false, required_json=[:figure], json=[:width, :height, :format, :scale, :encoded])

        # comments
        ApiCall(:comment_create, :POST, :comments, false, required_json=[:fid, :comment])
        ApiCall(:comment_delete, :DELETE, :comments, true)

        # dashboards
        ApiCall(:dashboard_create, :POST, :dashboards, false, required_json=[:content])
        ApiCall(:dashboard_list, :GET, :dashboards, false)
        ApiCall(:dashboard_retrieve, :GET, :dashboards, true)
        ApiCall(:dashboard_update, :PUT, :dashboards, true, json=dashboard_writeable_metadata)
        ApiCall(:dashboard_partial_update, :PATCH, :dashboards, true, json=dashboard_writeable_metadata)
        ApiCall(:dashboard_trash, :POST, :dashboards, true, :trash)
        ApiCall(:dashboard_permanent_delete, :DELETE, :dashboards, true, :permanent_delete, data_out=false)
        ApiCall(:dashboard_schema, :GET, :dashboards, false, :schema)

        # plot-schema
        ApiCall(:plot_schema_get, :GET, Symbol("plot-schema"), required=[:sha1])
    ]
    eval(make_method(_api))
end

# --------------------- #
# Convenience functions #
# --------------------- #

function try_me(func, args...; kwargs...)
    try
        func(args...; kwargs...)
    catch
        return nothing
    end
end


try_lookup(path; kwargs...) = try_me(file_lookup, path; kwargs...)

function grid_overwrite!(cols::AbstractDict; fid::String="", path::String="")
    !isempty(fid) && !isempty(path) && error("Can't pass both fid and path")
    if !isempty(fid)
        grid_info = try_me(grid_retrieve, fid)
    elseif !isempty(path)
        grid_info = try_me(grid_lookup, path)
    else
        error("must pass one of fid or path")
    end

    grid_info == nothing && error("can't overwrite a grid that doesn't exit")
    grid_overwrite!(grid_info, cols)
end

function grid_overwrite!(grid_info::AbstractDict, cols::AbstractDict)
    col_name_uid = Dict()
    for col in grid_info["cols"]
        col_name_uid[col["name"]] = col["uid"]
    end

    uids_to_replace = []
    data_to_replace = []
    to_create = []
    out = Dict()
    for (name, data) in cols
        pop!(data, "temp", nothing)
        if haskey(col_name_uid, name)
            # prep this column for replacement
            push!(uids_to_replace, col_name_uid[name])
            push!(data_to_replace, data)
            out[name] = col_name_uid[name]
        else
            # will be adding this column
            push!(to_create, Dict("name" => name, "data" => data["data"]))
        end
    end

    if length(to_create) > 0
        # need to create some columns
        res_post = grid_post_col(grid_info["fid"], to_create)
        for res_col in res_post["cols"]
            out[res_col["name"]] = res_col["uid"]
        end
    end

    if length(data_to_replace) > 0
        res_put = grid_put_col(grid_info["fid"], data_to_replace, uids_to_replace...)
        # we've already added these uids to the output...
    end

    out
end


"""
    grid_overwrite(cols::AbstractDict; fid::String="", path::String="")

Replace the data in the grid assocaited with fid `fid` or at the path `path`
with data in `cols`. `cols` should be an AbstractDict mapping from column names
to column data. The output of this function is an AbstractDict mapping from
column names to column uids in the updated grid.

There are three possible scenarios for the data:

1. The column appears both in the grid and in `cols`. In this case the data in
   that column of the grid will be updated to match the data in `cols`
2. The column appears only in `cols`. In this case a new column will be created
   in the grid
3. The column appears only in the grid. Nothing happens...

NOTE: only one of `fid` and `path` can be passed

"""
grid_overwrite!
