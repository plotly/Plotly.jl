# __precompile__(true)

module Plotly
using Requests
using JSON
using Reexport: @reexport

@reexport using PlotlyJS

include("utils.jl")

#export default_options, default_opts, get_config, get_plot_endpoint, get_credentials,get_content_endpoint,get_template

type CurrentPlot
    filename::ASCIIString
    fileopt::ASCIIString
    url::ASCIIString
end

const api_version = "v2"

const default_options = Dict("filename"=>"Plot from Julia API",
                             "world_readable"=> true,
                             "layout"=>Dict())

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::ASCIIString)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

const default_opts = Dict("origin" => "plot",
                          "platform" => "Julia",
                          "version" => "0.2")

get_plot_endpoint() = "$(get_config().plotly_domain)/clientresp"

function get_content_endpoint(file_id::ASCIIString, owner::ASCIIString)
    config = get_config()
    api_endpoint = "$(config.plotly_api_domain)/$api_version/files"
    detail = "$owner:$file_id"
    "$api_endpoint/$detail/content"
end

function plot(data::Array,options=Dict())
    creds = get_credentials()
    endpoint = get_plot_endpoint()
    opt = merge(default_options,options)

    r = post(endpoint,
             data = merge(default_opts,
                   Dict(
                    "un" => creds.username,
                    "key" => creds.api_key,
                    "args" => json(data),
                    "kwargs" => json(opt)
                    ))
             )
    body=Requests.json(r)

    if statuscode(r) != 200
        error(["r.status"])
    elseif body["error"] != ""
        error(body["error"])
    else
        global currentplot
        currentplot=CurrentPlot(body["filename"],"new",body["url"])
        body
    end
end

function layout(layout_opts::Dict,meta_opts=Dict())
    creds = get_credentials()
    endpoint = get_plot_endpoint()

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = post(endpoint,
    data = merge(default_opts,
    Dict("un" => creds.username,
    "key" => creds.api_key,
    "args" => json(layout_opts),
    "origin" => "layout",
    "kwargs" => json(meta_opts))))
    __parseresponse(r)
end

function style(style_opts,meta_opts=Dict())
    creds = get_credentials()
    endpoint = get_plot_endpoint()

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = post(endpoint,
    data = merge(default_opts,
    Dict("un" => creds.username,
    "key" => creds.api_key,
    "args" => json([style_opts]),
    "origin" => "style",
    "kwargs" => json(meta_opts))))
    __parseresponse(r)
end


function getFile(file_id::ASCIIString, owner=None)
  creds = get_credentials()
  username = creds.username
  api_key = creds.api_key

  if (owner == None)
    owner = username
  end

  endpoint = get_content_endpoint(file_id, owner)
  lib_version = string(default_opts["platform"], " ", default_opts["version"])

  auth = string("Basic ", base64("$username:$api_key"))

  options = Dict("Authorization"=> auth,"Plotly-Client-Platform"=> lib_version)

  r = get(endpoint, headers=options)
  print(r)

  __parseresponse(r)

end


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
            error("Missing required param ",p, ". Make sure to create a plot first. Please refer to http://plot.ly/api, or ask chris@plot.ly")
        end
    end
    result
end

function __parseresponse(r)
    body=Requests.json(r)
    if statuscode(r) != 200
        error(["r.status"])
    elseif haskey(body, "error") && body["error"] != ""
        error(body["error"])
    elseif haskey(body, "detail") && body["detail"] != ""
        error(body["detail"])
    else
        body
    end
end

end
