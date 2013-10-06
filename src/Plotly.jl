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

function style(style_opts,meta_opts=Dict())
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
           "args" => json(["style" =>style_opts]),
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

end
