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

