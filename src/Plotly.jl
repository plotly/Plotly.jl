module Plotly
using HTTPClient.HTTPC
using JSON
using Debug


type CurrentPlot
    filename::String
    fileopt::String
    url::String
end

default_options = {"filename"=>"Plot from Julia API",
"world_readable"=> true,
"layout"=>{""=>""}}

type PlotlyCredentials
    username::String
    api_key::String
end

type PlotlyConfig
    plotly_domain::String
    plotly_api_domain::String
end

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

default_endpoints = {
"base" => "https://plot.ly",
"api" => "https://api.plot.ly/v2"}

function signin(username::String, api_key::String, endpoints=None)
    if endpoints != None
        base_domain = get(endpoints, "plotly_domain", default_endpoints["base"])
        api_domain = get(endpoints, "plotly_api_domain", default_endpoints["api"])
        global plotlyconfig = PlotlyConfig(base_domain, api_domain)
    end
    global plotlycredentials = PlotlyCredentials(username, api_key)
end

function get_credentials()
    if !isdefined(Plotly,:plotlycredentials)
        creds = get_credentials_file()
        try
            username = creds["username"]
            api_key = creds["api_key"]
            global plotlycredentials = PlotlyCredentials(username, api_key)
        catch
            error("Please 'signin(username, api_key)' before proceeding. See
            http://plot.ly/API for help!")
        end
    end

    # will persist for the remainder of the session
    return plotlycredentials
end

function get_config()
    if !isdefined(Plotly,:plotlyconfig)
        config = get_config_file()
        base_domain = get(config, "plotly_domain", default_endpoints["base"])
        api_domain = get(config, "plotly_api_domain", default_endpoints["api"])
        global plotlyconfig = PlotlyConfig(base_domain, api_domain)
    end

    # will persist for the remainder of the session
    return plotlyconfig
end

function set_credentials_file(input_creds::Dict)
# Save Plotly endpoint configuration as JSON key-value pairs in
# userhome/.plotly/.credentials. This includes username and api_key.

    prev_creds = get_credentials_file()

    # plotly credentials file
    userhome = get(ENV, "HOME", "")
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    #check to see if dir/file exists --> if not create it
    try
        mkdir(plotly_credential_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    #merge input creds with prev creds
    creds = merge(prev_creds, input_creds)

    #write the json strings to the cred file
    creds_file = open(plotly_credentials_file, "w")
    write(creds_file, JSON.json(creds))
    close(creds_file)
end

function set_config_file(input_config::Dict)
# Save Plotly endpoint configuration as JSON key-value pairs in
# userhome/.plotly/.config. This includes the plotly_domain, and plotly_api_domain.

    prev_config = get_config_file()

    # plotly configuration file
    userhome = get(ENV, "HOME", "")
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    #check to see if dir/file exists --> if not create it
    try
        mkdir(plotly_config_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    #merge input config with prev config
    config = merge(prev_config, input_config)

    #write the json strings to the config file
    config_file = open(plotly_config_file, "w")
    write(config_file, JSON.json(config))
    close(config_file)
end

function get_credentials_file()
# Load user credentials as a Dict

    # plotly credentials file
    userhome = get(ENV, "HOME", "")
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    if !isfile(plotly_credentials_file)
        error(" No credentials file found. Please Set up your credentials
        file by running set_credentials_file({\"username\": \"your_plotly_username\", ...
        \"api_key\": \"your_plotly_api_key\"})")
    end

    creds_file = open(plotly_credentials_file)
    creds = JSON.parse(creds_file)
    return creds
end

function get_config_file()
# Load endpoint configuration as a Dict

    # plotly configuration file
    userhome = get(ENV, "HOME", "")
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    if !isfile(plotly_config_file)
        error(" No configuration file found. Please Set up your configuration
        file by running set_config_file({\"plotly_domain\": \"your_plotly_domain\", ...
        \"plotly_api_domain\": \"your_plotly_api_domain\"})")
    end

    config_file = open(plotly_config_file)
    config = JSON.parse(config_file)
    return config
end

function plot(data::Array,options=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end
    opt = merge(default_options,options)
    r = post("http://plot.ly/clientresp",
             merge(default_opts,
                   {
                    "un" => plotlyaccount.username,
                    "key" => plotlyaccount.api_key,
                    "args" => json(data),
                    "kwargs" => json(opt)
                    })
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

include("plot.jl")

function layout(layout_opts::Dict,meta_opts=Dict())
    global plotlyaccount
    if !isdefined(Plotly,:plotlyaccount)
        println("Please 'signin(username, api_key)' before proceeding. See http://plot.ly/API for help!")
        return
    end

    merge!(meta_opts,get_required_params(["filename","fileopt"],meta_opts))

    r = post("http://plot.ly/clientresp",
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

    r = post("http://plot.ly/clientresp",
    merge(default_opts,
    {"un" => plotlyaccount.username,
    "key" => plotlyaccount.api_key,
    "args" => json([style_opts]),
    "origin" => "style",
    "kwargs" => json(meta_opts)}))
    __parseresponse(r)
end


function getFile(file_id::String, file_owner=None)
  global plotlyaccount

  user = plotlyaccount.username
  apikey = plotlyaccount.api_key

  if (file_owner == None)
    file_owner = user
  end

  url = "https://api.plot.ly/v2/files/$file_owner:$file_id/content"
  lib_version = string(default_opts["platform"], " ", default_opts["version"])

  auth = string("Basic ", base64("$user:$apikey"))

  options = RequestOptions(headers=[
                                    ("Authorization", auth),
                                    ("Plotly-Client-Platform", lib_version)
                                    ])

  r = get(url, options)

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

function help()
    println("Please enter the name of the funtion you'd like help with")
    println("Options include:")
    println("\t Plotly.help(\"plot\") OR Plotly.help(:plot)")
    println("\t Plotly.help(\"layout\") OR Plotly.help(:layout)")
    println("\t Plotly.help(\"style\") OR Plotly.help(:style)")
end

end
