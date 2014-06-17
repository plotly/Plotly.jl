using Plotly
using JSON
using Base.Test

# just check that http://plot.ly/clientresp behaves as expected -- nothing to see here

Plotly.signin("unittest","tfzz811f5n")

(x0,y0) = [1,2,3], [4,5,6]
(x1,y1) = [1,2,3], [2,10,12]

response = Plotly.plot([[x0 y0] [x1 y1]])
@test response["error"] == ""

datastyle = ["line"=>["color"=> "rgb(84, 39, 143)", "width"=> 4]]
style_res = Plotly.style(datastyle)
@test style_res["error"] == ""

layout_res = Plotly.layout(["title"=>"Hello World"])
@test layout_res["error"] == ""

# just check that these won't raise an error
trace1 = Plotly.line(sin, ["left"=>0, "right"=>10, "step"=>1])
trace2 = Plotly.histogram(cos, ["left"=>0, "right"=>10, "step"=>1])
trace3 = Plotly.box(abs, ["left"=>0, "right"=>10, "step"=>1])
trace4 = Plotly.scatter(log, ["left"=>0, "right"=>10, "step"=>1])
response = Plotly.plot([trace1, trace2, trace3, trace4])
@test response["error"] == ""

# and one last check
response = Plotly.plot([sin, cos, abs, log], ["left"=>eps(), "right"=>10, "step"=>1])
@test response["error"] == ""