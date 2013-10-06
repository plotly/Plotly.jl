#A Julia interface to the plot.ly API

Forked from [astrieanna/Plotly.jl](https://github.com/astrieanna/Plotly.jl)

README quickly to get started. Alternately, checkout out the pretty Julia docs at http://plot.ly/api

## Installation

Given that you have Julia v0.2,

    Pkg2.clone("https://github.com/shirlenator/Plotly.jl")

## Usage

    julia> using Plotly

You'll need to create a plot.ly account and find out your API key before you'll be able to use this package.
## New user signup
    julia> Plotly.signup("username","email")
    Success! Check your email to activate account.
    
## Signin 
    julia> Plotly.signin("username","your api key")
    PlotlyAccount("username","your api key")

## Plot && Open in browser
    julia> Plotly.openurl(Plotly.plot(["z"=>rand(6,6)],["style"=>["type"=>"heatmap"]]))
    START /bin/firefox "https://plot.ly/~astrieanna/0"
    
That last line is what the REPL prints out,
as a Firefox tab opens with the plot.
You can also just call `plot` by itself, and you'll get a String that's the url of your chart.

## Style and Layout
    julia> Plotly.style(["line"=>["color"=>"rgb(255,0,0)","width"=>10]])
    
    julia> Plotly.layout(["layout"=>["title"=>"Time Wasted"]])
    




