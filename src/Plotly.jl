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

type Font
    family::String
    size::Number
    color::String
end

type Margin
    left::Number #Key is "l" for REST API, not "left"
    right::Number # "r"
    top::Number # "t"
    bottom::Number # "b"
    pad::Number
end

type Axis
    range::Array{Int64,1}
    _type::ASCIIString
    mirror::Bool
    linecolor::ASCIIString
    linewidth::Int64
    tick0::Int64
    dtick::Int64
    ticks::ASCIIString
    ticklen::Int64
    tickwidth::Int64
    tickcolor::ASCIIString
    nticks::Int64
    showticklabels::Bool
    tickangle::ASCIIString
    exponentformat::ASCIIString
    showexponent::ASCIIString
    showgrid::Bool
    gridcolor::ASCIIString
    gridwidth::Int64
    autorange::Bool
    autotick::Bool
    zeroline::Bool
    zerolinecolor::ASCIIString
    zerolinewidth::Int64
    title::ASCIIString
    unit::ASCIIString
    titlefont::Font
    tickfont::Font
end

type Legend
    bgcolor::String
    bordercolor::String
    borderwidth::Number
    font::Font
    traceorder::String
end

type Layout
    title::ASCIIString
    xaxis::Axis
    yaxis::Axis
    legend::Legend
    width::Int64
    height::Int64
    autosize::ASCIIString
    margin::Margin
    paper_bgcolor::ASCIIString
    plot_bgcolor::ASCIIString
    barmode::ASCIIString
    bargap::Number
    bargroupgap::Number
    boxmode::ASCIIString
    boxgap::Number
    boxgroupgap::Number
    font::Font
    titlefont::Font
    dragmode::ASCIIString
    hovermode::ASCIIString
end

default_options = ["filename"=>"Plot from Julia API",
"world_readable"=> true,
"layout"=>["title"=>"Plot from Julia API"]]

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::String)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

default_opts = [ 
"origin" => "plot",
"platform" => "Julia",
"version" => "0.1"]

function signup(username::String, email::String)
    r = HTTPClient.HTTPC.post("http://plot.ly/apimkacct", 
    merge(default_opts, 
    ["un" => username, 
    "email" => email]))
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
    ["un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json(data),
    "kwargs" => json(opt)]))
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
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = HTTPClient.HTTPC.post("http://plot.ly/clientresp",
    merge(default_opts,
    ["un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json(layout_opts),
    "origin" => "layout",
    "kwargs" => json(meta_opts)]))
    __parseresponse(r)
end

function style(style_opts::Dict,meta_opts=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = HTTPClient.HTTPC.post("http://plot.ly/clientresp",
    merge(default_opts,
    ["un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json([style_opts]),
    "origin" => "style",
    "kwargs" => json(meta_opts)]))
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

function get_layout_template()
    return Layout(
        "Click to enter Plot title", #title
            Axis( #xaxis
                [-1,6], #range
                "-", #_type
                true, #mirror
                "#000", #linecolor
                1, #linewidth
                0, #tick0
                2, #dtick y1
                "outside", #ticks
                5, #ticklen
                1, #tickwidth
                "#000", #tickcolor
                0, #nticks
                true, #showticklabels
                "auto", #tickangle
                "e", #exponentformat
                "all", #showexponent
                true, #showgrid
                "#ddd", #showgrid
                1, #gridwidth
                true, #autorange
                true, #autotick
                true, #zeroline
                "#000", #zerolinecolor
                1, #zerolinewidth
                "Click to enter X axis title", #title Y
                "",  #unit
                Font( #titlefont
                    "", #family
                    0, #size
                    ""), #color
                Font( #tickfont
                    "", #family
                    0, #size
                    "")), #color
            Axis( #yaxis
                [-1,6], #range
                "-", #_type
                true, #mirror
                "#000", #linecolor
                1, #linewidth
                0, #tick0
                1, #dtick 
                "outside", #ticks
                5, #ticklen
                1, #tickwidth
                "#000", #tickcolor
                0, #nticks
                true, #showticklabels
                "auto", #tickangle
                "e", #exponentformat
                "all", #showexponent
                true, #showgrid
                "#ddd", #showgrid
                1, #gridwidth
                true, #autorange
                true, #autotick
                true, #zeroline
                "#000", #zerolinecolor
                1, #zerolinewidth
                "Click to enter Y axis title", 
                "",  #unit
                Font( #titlefont
                    "", #family
                    0, #size
                    ""), #color
                Font( #tickfont
                    "", #family
                    0, #size
                    "")), #color
            Legend( #legend
                "#fff", #bgcolor
                "#000", #bordercolor
                1, #borderwidth
                Font( #font
                    "", #family
                    0, #size
                    ""), #color
                "normal"), #traceorder
            700, #width
            450, #height
            "initial", #autosize
            Margin( #margin
                80, #l
                80, #r
                80, #t
                80, #b
                2), #pad
            "#fff", #paper_bgcolor
            "#fff", #plot_bgcolor
            "stack", #barmode
            0.2, #bargap
            0.0, #bargroupgap
            "overlay", #boxmode
            0.3, #boxgap
            0.3, #boxgroupgap
            Font( #font
                "Arial, sans-serif;", #family
                12, #size
                "#000"), #color
            Font( #titlefont
                "", #family
                0, #size
                ""), #color
            "zoom", #dragmode
            "x") #hovermode
end

end
