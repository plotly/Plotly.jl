#A Julia interface to the plot.ly API

Forked from [astrieanna/Plotly.jl](https://github.com/astrieanna/Plotly.jl)

README quickly to get started. Alternately, checkout out the pretty Julia docs at http://plot.ly/api

## Installation

Given that you have Julia v0.2.1,

    Pkg.clone("https://github.com/plotly/Plotly.jl")

## Usage

    julia> using Plotly
    INFO: Cloning Plotly from https://github.com/plotly/Plotly.jl
    INFO: Computing changes...
    INFO: No packages to install, update or remove.


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

## Plot Functions and Polynomials
    julia> Plotly.plot(abs)
    julia> Plotly.plot([sqrt, log], ["left"=>10, "right"=>20, "step"=>0.1])

You can now plot functions directly.
The first line shows how to plot the absolute value function, and the second line plots
the square root and logarithm functions, both from 10 to 20 at increments of 0.1.

    julia> using Polynomial
    julia> x = Poly([1,0])
    julia> Plotly.plot(3x^3 + 2x^2 - x + 1)

If you have the Polynomial package installed, you can plot them directly the same way as math functions.
    
## Plot TimeSeries
    julia> using TimeSeries
    julia> d = [date(2012,5,29):date(2013,5,29)]
    julia> t = TimeArray(d, rand(length(d),2), ["foo","bar"])
    julia> Plotly.plot(t)

If you have the TimeSeries package installed, you can plot them directly by passing a TimeArray argument.