# __precompile__(true)

module Plotly
using Compat
using Compat: String
using Requests
using JSON
using Reexport: @reexport
import Requests: URI, post

@reexport using PlotlyJS
export post
export set_credentials_file, RemotePlot, download_plot

include("utils.jl")

const api_version = "v2"

const default_kwargs = Dict{Symbol,Any}(:filename=>"Plot from Julia API",
                                        :world_readable=> true)

const default_opts = Dict{Symbol,Any}(:origin => "plot",
                                      :platform => "Julia",
                                      :version => "0.2")

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::ASCIIString)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

openurl(url::URI) = openurl(string(url))

get_plot_endpoint() = "$(get_config().plotly_domain)/clientresp"

"""
Proxy for a plot stored on the Plotly cloud.
"""
immutable RemotePlot
    url::URI
end
RemotePlot(url) = RemotePlot(URI(url))

"""
Display a plot stored in the Plotly cloud in a browser window.
"""
Base.open(p::RemotePlot) = openurl(p.url)

"""
Post a local Plotly plot to the Plotly cloud.

Must be signed in first.
"""
function post(p::Plot; kwargs...)
    creds = get_credentials()
    endpoint = get_plot_endpoint()
    opt = merge(default_kwargs, Dict(:layout => p.layout.fields),
    Dict(kwargs))

    data = merge(default_opts,
    Dict("un" => creds.username,
    "key" => creds.api_key,
    "args" => json(p.data),
    "kwargs" => json(opt)))

    r = post(endpoint, data=data)
    body = parse_response(r)
    return RemotePlot(URI(body["url"]))
end

function Requests.post(l::AbstractLayout, meta_opts=Dict(); meta_kwargs...)
    creds = get_credentials()
    endpoint = get_plot_endpoint()

    meta = merge(meta_opts,
    get_required_params(["filename", "fileopt"], meta_opts),
    Dict(meta_kwargs))
    data = merge(default_opts,
    Dict("un" => creds.username,
         "key" => creds.api_key,
         "args" => json(l),
         "origin" => "layout",
         "kwargs" => json(meta)))

    parse_response(post(endpoint, data=data))
end

post(p::PlotlyJS.SyncPlot) = post(p.plot)

function style(style_opts, meta_opts=Dict(); meta_kwargs...)
    creds = get_credentials()
    endpoint = get_plot_endpoint()

    meta = merge(meta_opts,
    get_required_params(["filename", "fileopt"], meta_opts),
    Dict(meta_kwargs))
    data = merge(default_opts,
    Dict("un" => creds.username,
    "key" => creds.api_key,
    "args" => json([style_opts]),
    "origin" => "style",
    "kwargs" => json(meta_opts)))

    parse_response(post(endpoint, data=data))
end

"""
Transport a plot from the Plotly cloud to a local `Plot` object.

Must be signed in first if the plot is not public.
"""
function Base.download(plot::RemotePlot)
    creds = get_credentials()
    username = creds.username
    api_key = creds.api_key
    lib_version = string(default_opts[:platform], " ", default_opts[:version])
    auth = string("Basic ", base64encode("$username:$api_key"))
    options = Dict("Authorization"=>auth, "Plotly-Client-Platform"=>lib_version)
    original_path = plot.url.path
    if original_path[end] == '/'
        path = original_path[1:end-1]
    else
        path = original_path
    end
    endpoint = URI(plot.url, path="$path.json")
    response = get(endpoint, headers=options)
    local_plot = JSON.parse(Plot, bytestring(response))
    return PlotlyJS.SyncPlot(local_plot)
end

download_plot(url) = download(RemotePlot(url))
download_plot(plot::RemotePlot) = download(plot)

immutable PlotlyError <: Exception
    msg::String
end

function Base.show(io::IO, err::PlotlyError)
    print(io, "Plotly error: $(err.msg)")
end

function parse_response(r)
    body = Requests.json(r)
    if statuscode(r) ≠ 200
        throw(PlotlyError("Non-sucessful status code: $(statuscode(r))"))
    elseif "error" ∈ keys(body) && body["error"] ≠ ""
        throw(PlotlyError(body["error"]))
    elseif "detail" ∈ keys(body) && body["detail"] ≠ ""
        throw(PlotlyError(body["detail"]))
    else
        body
    end
end

end
