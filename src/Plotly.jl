module Plotly
using HTTPClient
using JSON

type PlotlyAccount 
    username::String
    api_key::String
end

type CurrentPlot
    filename::String
    fileopt::String
    url::String
end

default_options = {"filename"=>"Plot from Julia API",
"world_readable"=> true,
"layout"=>{""=>""}}

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::String)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

default_opts = {
"origin" => "plot",
"platform" => "Julia",
"version" => "0.2"}

function signup(username::String, email::String)
    r = HTTPClient.HTTPC.post("http://plot.ly/apimkacct", 
    merge(default_opts, 
    {"un" => username, 
    "email" => email}))
    if r.http_code == 200
        results = JSON.parse(bytestring(r.body)) 
        for flag in ["error","warning","message"]
            if haskey(results, flag) && results[flag] != ""
                println(results[flag])
            end
        end
        if haskey(results,"tmp_pw")
            println("Success! Check your email to activate your account.")
            results
        end
    end
end

function signin(username::String, api_key::String)
    global plotlyaccount 
    plotlyaccount = PlotlyAccount(username,api_key)
end

function plot(data::Array,options=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end
    opt = merge(default_options,options)
    r = HTTPClient.HTTPC.post("http://plot.ly/clientresp", 
    merge(default_opts,
    {"un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json(data),
    "kwargs" => json(opt)}))
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

include("plot.jl")

function layout(layout_opts::Dict,meta_opts=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = HTTPClient.HTTPC.post("http://plot.ly/clientresp",
    merge(default_opts,
    {"un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json(layout_opts),
    "origin" => "layout",
    "kwargs" => json(meta_opts)}))
    __parseresponse(r)
end

function style(style_opts,meta_opts=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = HTTPClient.HTTPC.post("http://plot.ly/clientresp",
    merge(default_opts,
    {"un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json([style_opts]),
    "origin" => "style",
    "kwargs" => json(meta_opts)}))
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
    elseif body["error"] != ""
        error(body["error"])
    else
        body
    end
end

function get_template(format_type::String)
    if format_type == "layout" 
        return {
                "title"=>"Click to enter Plot title",
                "xaxis"=>{
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
                        "titlefont"=>{"family"=>"","size"=>0,"color"=>""}, 
                        "tickfont"=>{"family"=>"","size"=>0,"color"=>""}}, 
                "yaxis"=>{
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
                        "titlefont"=>{"family"=>"","size"=>0,"color"=>""}, 
                        "tickfont"=>{"family"=>"","size"=>0,"color"=>""}}, 
                "legend"=>{
                        "bgcolor"=>"#fff", 
                        "bordercolor"=>"#000", 
                        "borderwidth"=>1, 
                        "font"=>{"family"=>"","size"=>0,"color"=>""}, 
                        "traceorder"=>"normal"},
                "width"=>700,
                "height"=>450,
                "autosize"=>"initial", 
                "margin"=>{"l"=>80,"r"=>80,"t"=>80,"b"=>80,"pad"=>2},
                "paper_bgcolor"=>"#fff",
                "plot_bgcolor"=>"#fff",
                "barmode"=>"stack",
                "bargap"=>0.2,
                "bargroupgap"=>0.0,
                "boxmode"=>"overlay",
                "boxgap"=>0.3,
                "boxgroupgap"=>0.3,
                "font"=>{"family"=>"Arial, sans-serif;","size"=>12,"color"=>"#000"},
                "titlefont"=>{"family"=>"","size"=>0,"color"=>""},
                "dragmode"=>"zoom",
                "hovermode"=>"x"}
    end
end

function help(func_name::String)
    print("hihi")
end
function help()
    println("Please enter the name of the funtion you'd like help with")
    println("Options include:")
    println("\t Plotly.help(\"plot\") OR Plotly.help(:plot)")
    println("\t Plotly.help(\"layout\") OR Plotly.help(:layout)")
    println("\t Plotly.help(\"style\") OR Plotly.help(:style)")
end
function help(func_name::Symbol)
    print("hihi")
end


end
