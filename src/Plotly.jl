# __precompile__(true)

module Plotly
using Compat
using Requests
using JSON
using Reexport: @reexport
import Requests: URI, post

@reexport using PlotlyJS
export post

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


immutable RemotePlot
    url::URI
end
RemotePlot(url) = RemotePlot(URI(url))

Base.open(p::RemotePlot) = openurl(p.url)

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
    # body=Requests.json(r)
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
    return JSON.parse(Plot, bytestring(response))
end

download_plot(url) = download(RemotePlot(url))

function get_required_params(required,opts)
    # Priority given to user-inputted opts, then currentplot
    result=Dict()
    for p in required
        global currentplot
        if haskey(opts,p)
            result[p] = opts[p]
        elseif isdefined(Plotly,:currentplot)
            result[p] = getfield(currentplot,symbol(p))
        else
            msg = string("Missing required param $(p). ",
            "Make sure to create a plot first. ",
            " Please refer to http://plot.ly/api")
            error(msg)
        end
    end
    result
end

immutable PlotlyError <: Exception
    msg::UTF8String
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
