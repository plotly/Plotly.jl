module Plotly
using HTTPClient
using JSON

type PlotlyAccount 
  username::String
  api_key::String
end

default_options = ["filename"=>"plot from api",
                   "world_readable"=>true,
                   "fileopt"=>"overwrite",
                   "layout"=>["title"=>"experimental data"]]

## Taken from https://github.com/johnmyleswhite/Vega.jl/blob/master/src/Vega.jl#L51
# Open a URL in a browser
function openurl(url::String)
    @osx_only run(`open $url`)
    @windows_only run(`start $url`)
    @linux_only run(`xdg-open $url`)
end

function plot(p::PlotlyAccount,data::Array,options=Dict())
  opt = merge(default_options,options)
  r = HTTPClient.HTTPC.post("https://plot.ly/clientresp", 
      [("un",p.username),
       ("key",p.api_key),
       ("origin","plot"),
       ("platform","julia"),
       ("version","0.1"),
       ("args",json(data)),
       ("kwargs",json(opt))])
  if r.http_code == 200
    b = JSON.parse(r.body)
    b["error"] == "" ? b["url"] : error(b["error"]) 
  else
    error(r.http_code)
  end
end

plot(p::PlotlyAccount,data::Dict,options=Dict()) = plot(p,push!(Dict[],data),options)

end
