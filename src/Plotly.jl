module Plotly
using HTTPClient.HTTPC
using JSON

include("plot.jl")
include("utils.jl")

type CurrentPlot
    filename::ASCIIString
    fileopt::ASCIIString
    url::ASCIIString
end

api_version = "v2"

default_options = Dict("filename"=>"Plot from Julia API",
  "world_readable"=> true,
  "layout"=>Dict(""=>""))

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::ASCIIString)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

default_opts = Dict(
  "origin" => "plot",
  "platform" => "Julia",
  "version" => "0.2")

function get_plot_endpoint()
    config = get_config()
    plot_endpoint = "clientresp"
    return "$(config.plotly_domain)/$plot_endpoint"
end

function get_content_endpoint(file_id::ASCIIString, owner::ASCIIString)
    config = get_config()
    api_endpoint = "$(config.plotly_api_domain)/$api_version/files"
    detail = "$owner:$file_id"
    custom_action = "content"
    content_endpoint = "$api_endpoint/$detail/$custom_action"
    return content_endpoint
end

function plot(data::Array,options=Dict())
    creds = get_credentials()
    endpoint = get_plot_endpoint()
    opt = merge(default_options,options)
    r = post(endpoint,
             merge(default_opts,
                   Dict(
                    "un" => creds.username,
                    "key" => creds.api_key,
                    "args" => json(data),
                    "kwargs" => json(opt)
                    ))
             )
    body=JSON.parse(bytestring(r.body))

    if r.http_code != 200
        error(["r.http_code"])
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
    merge(default_opts,
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
    merge(default_opts,
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

  options = RequestOptions(headers=[
                                    ("Authorization", auth),
                                    ("Plotly-Client-Platform", lib_version)
                                    ])

  r = get(endpoint, options)
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
    body=JSON.parse(bytestring(r.body))
    if r.http_code != 200
        error(["r.http_code"])
    elseif haskey(body, "error") && body["error"] != ""
        error(body["error"])
    elseif haskey(body, "detail") && body["detail"] != ""
        error(body["detail"])
    else
        body
    end
end

function get_template(format_type::ASCIIString)
    if format_type == "layout"
        return Dict(
                "title"=>"Click to enter Plot title",
                "xaxis"=>Dict(
                        "range"=>[-1,6],
                        "type"=>"-",
                        "mirror"=>true,
                        "linecolor"=>"#000",
                        "linewidth"=>1,
                        "tick0"=>0,
                        "dtick"=>2,
                        "ticks"=>"outside",
                        "ticklen"=>5,
                        "tickwidth"=>1,
                        "tickcolor"=>"#000",
                        "nticks"=>0,
                        "showticklabels"=>true,
                        "tickangle"=>"auto",
                        "exponentformat"=>"e",
                        "showexponent"=>"all",
                        "showgrid"=>true,
                        "gridcolor"=>"#ddd",
                        "gridwidth"=>1,
                        "autorange"=>true,
                        "autotick"=>true,
                        "zeroline"=>true,
                        "zerolinecolor"=>"#000",
                        "zerolinewidth"=>1,
                        "title"=>"Click to enter X axis title",
                        "unit"=>"",
                        "titlefont"=>Dict("family"=>"","size"=>0,"color"=>""),
                        "tickfont"=>Dict("family"=>"","size"=>0,"color"=>"")),
                "yaxis"=>Dict(
                        "range"=>[-1,4],
                        "type"=>"-",
                        "mirror"=>true,
                        "linecolor"=>"#000",
                        "linewidth"=>1,
                        "tick0"=>0,
                        "dtick"=>1,
                        "ticks"=>"outside",
                        "ticklen"=>5,
                        "tickwidth"=>1,
                        "tickcolor"=>"#000",
                        "nticks"=>0,
                        "showticklabels"=>true,
                        "tickangle"=>"auto",
                        "exponentformat"=>"e",
                        "showexponent"=>"all",
                        "showgrid"=>true,
                        "gridcolor"=>"#ddd",
                        "gridwidth"=>1,
                        "autorange"=>true,
                        "autotick"=>true,
                        "zeroline"=>true,
                        "zerolinecolor"=>"#000",
                        "zerolinewidth"=>1,
                        "title"=>"Click to enter Y axis title",
                        "unit"=>"",
                        "titlefont"=>Dict("family"=>"","size"=>0,"color"=>""),
                        "tickfont"=>Dict("family"=>"","size"=>0,"color"=>"")),
                "legend"=>Dict(
                        "bgcolor"=>"#fff",
                        "bordercolor"=>"#000",
                        "borderwidth"=>1,
                        "font"=>Dict("family"=>"","size"=>0,"color"=>""),
                        "traceorder"=>"normal"),
                "width"=>700,
                "height"=>450,
                "autosize"=>"initial",
                "margin"=>Dict("l"=>80,"r"=>80,"t"=>80,"b"=>80,"pad"=>2),
                "paper_bgcolor"=>"#fff",
                "plot_bgcolor"=>"#fff",
                "barmode"=>"stack",
                "bargap"=>0.2,
                "bargroupgap"=>0.0,
                "boxmode"=>"overlay",
                "boxgap"=>0.3,
                "boxgroupgap"=>0.3,
                "font"=>Dict("family"=>"Arial, sans-serif;","size"=>12,"color"=>"#000"),
                "titlefont"=>Dict("family"=>"","size"=>0,"color"=>""),
                "dragmode"=>"zoom",
                "hovermode"=>"x")
    end
end

function help()
    println("Please enter the name of the funtion you'd like help with")
    println("Options include:")
    println("\t Plotly.help(\"plot\") OR Plotly.help(:plot)")
    println("\t Plotly.help(\"layout\") OR Plotly.help(:layout)")
    println("\t Plotly.help(\"style\") OR Plotly.help(:style)")
end

end
