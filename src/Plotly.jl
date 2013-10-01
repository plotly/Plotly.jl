module Plotly
using HTTPClient
using JSON

type PlotlyAccount 
  username::String
  api_key::String
end

signedin = false

default_options = ["filename"=>"Plot from API",
                   "world_readable"=> true,
                   "layout"=>["title"=>"Add Title in plotly"]]

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::String)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

default_opts = [ 
       "origin" => "plot",
       "platform" => "julia",
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
    if !haskey(results,"error") && haskey(results,"tmp_pw")
      println("Success! Check your email to activate your account.")
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
  if r.http_code == 200
    b=JSON.parse(bytestring(r.body))
    b["error"] == "" ? b["url"] : error(b["error"]) 
  else
    error(r.http_code)
  end
end

plot(data::Dict,options=Dict()) = plot(push!(Dict[],data),options)

end
