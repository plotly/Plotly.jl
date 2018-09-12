module Plotly

using HTTP
using Reexport
using JSON
@reexport using PlotlyJS
using DelimitedFiles, Pkg, Base64  # stdlib

export set_credentials_file, RemotePlot, download_plot, savefig_remote, post

const _SRC_ATTRS = let
    _src_attr_path = joinpath(PlotlyJS._pkg_root, "deps", "src_attrs.csv")
    raw_src_attrs = vec(readdlm(_src_attr_path))
    src_attrs = map(x -> x[1:end-3], raw_src_attrs)  # remove the `src` suffix
    Set(map(Symbol, src_attrs))
end::Set{Symbol}

include("utils.jl")
include("v2.jl")

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::String)
    if is_apple()
        run(`open $url`)
    elseif is_windows()
        run(`start $url`)
    elseif is_unix()
        run(`xdg-open $url`)
    end
end

openurl(url::HTTP.URI) = openurl(string(url))

"""
Proxy for a plot stored on the Plotly cloud.
"""
struct RemotePlot
    url::HTTP.URI
end
RemotePlot(url::String) = RemotePlot(HTTP.URI(url))

"""
    fid(rp::RemotePlot)

Return the unique plotly `fid` for `rp`. Throws an error if the url inside
`rp` is not correctly formed.
"""
function fid(rp::RemotePlot)
    parts = match(r"^/~([^/]+)/(\d+)/?", rp.url.path)
    if parts === nothing
        error("Malformed RemotePlot url")
    end
    "$(parts[1]):$(parts[2])"
end

"""
Display a plot stored in the Plotly cloud in a browser window.
"""
Base.open(p::RemotePlot) = openurl(p.url)

"""
Post a local Plotly plot to the Plotly cloud using V2 api.

Must be signed in first. See `Plotly.signin` for details on how to do that
"""
function post_v2(p::Plot; fileopt=get_config().fileopt, filename=nothing, kwargs...)
    JSON.lower(p)
    fileopt = Symbol(fileopt)
    grid_fn = string(filename, "_", "Grid")
    clean_p = srcify(p; fileopt=fileopt, grid_fn=grid_fn, kwargs...)
    if fileopt == :overwrite
        file_data = try_lookup(filename)  ## Api call 1
        if file_data == nothing
            fileopt = :create
        else
            res = plot_update(file_data["fid"], figure=clean_p)  ## Api call 2
            return RemotePlot(res["web_url"])
        end
    end
    if fileopt == :create || fileopt == :new
        if filename == nothing
            res = plot_create(clean_p; kwargs...)  ## Api call 2 (or 1)
        else
            parent_path = dirname(filename)
            if !isempty(parent_path)
                res = plot_create(
                    clean_p; parent_path=parent_path,
                    filename=basename(filename), kwargs...
                ) ## Api call 2 (or 1)
            else
                res = plot_create(clean_p; filename=filename, kwargs...) ## Api call 2 (or 1)
            end
        end

        return RemotePlot(res["file"]["web_url"])
    else
        error("fileopt must be one of `overwrite` and `create`")
    end
end

function post(p::Plot; kwargs...)
    # call JSON.lower to apply themes
    JSON.lower(p)
    config = get_config()
    default_kwargs = Dict{Symbol,Any}(:filename=>"Plot from Julia API",
                                       :world_readable=> config.world_readable)
    default_opts = Dict{Symbol,Any}(:origin => "plot",
                                     :platform => "Julia",
                                     :version => "0.2")
    creds = get_credentials()
    endpoint = "$(get_config().plotly_domain)/clientresp"
    opt = merge(
        default_kwargs,
        Dict(:layout => p.layout.fields),
        Dict(kwargs)
    )

    data = merge(
        default_opts,
        Dict(
            :un => creds.username,
            :key => creds.api_key,
            :args => JSON.json(p.data),
            :kwargs => JSON.json(opt)
        )
    )

    res = HTTP.request("POST", endpoint,
                       ["Content-Type" => "application/x-www-form-urlencoded"],
                       HTTP.URIs.escapeuri(data))
    body = JSON.parse(String(deepcopy(res.body)))
    if res.status ≠ 200
        throw(PlotlyError("Non-sucessful status code: $(statuscode(r))"))
    elseif "error" ∈ keys(body) && body["error"] ≠ ""
        throw(PlotlyError(body["error"]))
    elseif "detail" ∈ keys(body) && body["detail"] ≠ ""
        throw(PlotlyError(body["detail"]))
    end
    return RemotePlot(HTTP.URI(body["url"]))
end

post(p::PlotlyJS.SyncPlot; kwargs...) = post(p.plot; kwargs...)
post_v2(p::PlotlyJS.SyncPlot; kwargs...) = post_v2(p.plot; kwargs...)

"""
    srcify!(p::Plot; fileopt::Symbol=:overwrite, grid_fn=nothing, kwargs...)

Look through each trace and the Layout for attributes that have a value of type
Union{AbstractArray,Tuple} and are able to be set via `(attributename)(src)` in
the plotly.js api. For each of these, do the following:

1. Extract the value so it can become a column in a Grid
2. Remove that key/value pair from the trace/Layout

This happens in place, so the `src`ified fields will be removed within the
input to this function.
"""
function extract_grid_data!(p::Plot)
    data_for_grid = Dict()
    function add_to_grid!(k::Vector, v::Union{AbstractArray,Tuple})
        if !(k[end] in Plotly._SRC_ATTRS)
            return
            # only do what follows if k is one of the src attrs
        end
        # all the magic happens here
        the_key = join(map(string, k), "_")
        setindex!(data_for_grid, Dict{Any,Any}("data" => v, "temp" => k), the_key)  # step 1

        # now remove this from the plot
        if k[1] == "trace"
            ind = k[2]
            attr = join(map(String, k[3:end]), "_")
            pop!(p.data[ind], attr)
        elseif k[1] == "layout"
            attr = join(map(String, k[2:end]), "_")
            pop!(p.layout, attr)
        else
            error("bad key...")
        end
    end
    function add_to_grid!(k1::Vector, v::AbstractDict)
        for (k2, v2) in v
            add_to_grid!(vcat(k1, k2), v2)
        end
    end
    add_to_grid!(k::Vector, v) = nothing  # otherwise don't do anything...

    for (i, t) in enumerate(p.data)
        k = ["trace", i]
        for (field, val) in t
            add_to_grid!(vcat(k, field), val)
        end
    end

    k = ["layout"]
    for (field, val) in p.layout
        add_to_grid!(vcat(k, field), val)
    end
    data_for_grid
end

extract_grid_data(p::Plot) = extract_grid_data!(deepcopy(p))

"""
    srcify!(p::Plot; fileopt::Symbol=get_config().fileopt, grid_fn=nothing, kwargs...)

This function does three things:

1. Calls `extract_grid_data!(p)` (see docs) to remove attributes that can be
   set via `(attributename)(src)` in the plotly.js api.
2. Creates a grid on the plotly server containing the extract data
3. Maps the `(attributename)(src)` attribute to the grid column

If fileopt is `:create` and `grid_fn` exists under the User's plotly account,
then the changes described above will happen in-place on the grid.

If either of those conditions are not met, then a new grid will be created.
"""
function srcify!(p::Plot; fileopt::Symbol=get_config().fileopt, grid_fn=nothing, kwargs...)
    data_for_grid = extract_grid_data!(p)
    temp_map = Dict()
    for (k, v) in data_for_grid
        temp_map[k] = pop!(v, "temp")
    end

    if fileopt == :overwrite
        grid_info = try_me(grid_lookup, grid_fn)
        if grid_info == nothing
            fileopt = :create
        else
            fid = grid_info["fid"]
            uid_map = grid_overwrite!(grid_info, data_for_grid)
            @goto add_src_attrs
        end
    end

    if fileopt == :create || fileopt == :new
        # add order to each grid
        for (i, (k, v)) in enumerate(data_for_grid)
            v["order"] = i-1
        end
        parent_path = dirname(grid_fn)
        if !isempty(parent_path)
            root_name = basename(grid_fn)
            res = grid_create(
                Dict("cols" => data_for_grid);
                parent_path=parent_path, filename=root_name, kwargs...
            )
        else
            res = grid_create(Dict("cols" => data_for_grid); filename=grid_fn, kwargs...)
        end

        fid = res["file"]["fid"]

        uid_map = Dict()
        for col in res["file"]["cols"]
            uid_map[col["name"]] = col["uid"]
        end
    else
        error("Can only create or overwrite")
    end

    @label add_src_attrs
    # Add (attributename)(src) = uid fields to plot
    for k in keys(data_for_grid)
        key = temp_map[k]
        uid = uid_map[k]
        if key[1] == "trace"
            trace_ind = key[2]
            the_key = join(vcat(key[3:end-1], string(key[end], "src")), "_")
            col_uid = string(fid, ":", uid)
            p.data[trace_ind][the_key] = col_uid
        elseif key[1] == "layout"
            the_key = join(vcat(key[2:end-1], string(key[end], "src")), "_")
            col_uid = string(fid, ":", uid)
            p.layout[the_key] = col_uid
        else
            error("bad key...")
        end
    end
    p
end

"""
    srcify(p::Plot)

Allocating version of `srcify!` the plot will be deepcopied before passing
to `srcify!`, so the argument passed to this function will not be modified.
"""
srcify(p::Plot; kwargs...) = srcify!(deepcopy(p); kwargs...)

"""
Transport a plot from the Plotly cloud to a local `Plot` object.

Must be signed in first if the plot is not public.
"""
function Base.download(p::RemotePlot)
    res = plot_content(fid(p), inline_data=true)
    data = GenericTrace[GenericTrace(tr) for tr in res["data"]]
    layout = Layout(res["layout"])
    plot(data, layout)
end

download_plot(url) = download(RemotePlot(url))
download_plot(plot::RemotePlot) = download(plot)

function savefig_remote(p::Plot, fn::String; width::Int=8, height::Int=6)
    suf = split(fn, ".")[end]

    # if html we don't need a plot window
    if suf == "html"
        open(fn, "w") do f
            show(f, MIME"text/html"(), p, js)
        end
        return p
    end

    # same for json
    if suf == "json"
        open(fn, "w") do f
            print(f, json(p))
        end
        return p
    end

    if suf in ["png", "jpeg", "svg", "pdf", "eps", "webp"]
        res = image_generate(p, format=suf, width=width*96, height=height*96)
        open(fn, "w") do f
            print(f, String(res))
        end
    else
        error("Only html, json, png, jpeg, svg, pdf, eps, and webp output supported")
    end
    fn
end

function savefig_remote(p::PlotlyJS.SyncPlot, args...;kwargs...)
    savefig_remote(p.plot, args...; kwargs...)
end

end  # module
