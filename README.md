#A Julia interface to the plot.ly API

[![Build Status](https://travis-ci.org/snotskie/Plotly.jl.png)](https://travis-ci.org/snotskie/Plotly.jl)

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
    julia> Plotly.plot() do x
           savings = 3000
           income = x*1000
           expenses = x*800
           return savings+income-expenses
           end

You can now plot functions directly.
The first line shows how to plot the absolute value function, and the second line plots
the square root and logarithm functions, both from 10 to 20 at increments of 0.1.
The last line shows how to use Julia's `do` syntax to plot complicated anonymous functions.

    julia> using Polynomial
    julia> x = Poly([1,0])
    julia> Plotly.plot(3x^3 + 2x^2 - x + 1)
    julia> Plotly.plot([x, 2x, 3x^2-x])

Using the Polynomial package, you can plot polynomials directly the same way as math functions.
    
## Plot DataFrames and TimeSeries
    julia> using DataFrames
    julia> df = readtable("height_vs_weight.csv")
    julia> Plotly.plot(df, ["xs"=>:height, "ys"=>:weight])

Using the DataFrames package, you can read CSV data and plot it directly by passing the data frame and setting the xs and/or ys options. These are symbols or arrays of symbols refering to columns names in the CSV file.

    julia> using TimeSeries
    julia> d = [date(2012,5,29):date(2013,5,29)]
    julia> t = TimeArray(d, rand(length(d),2), ["foo","bar"])
    julia> Plotly.plot(t)

Using the TimeSeries package, you can plot them directly by passing a TimeArray argument.

## Plot WAV Files
    julia> using WAV
    julia> Plotly.plot(wavread("filename.wav"))

Using the WAV package, you can plot WAV files by passing a call to the `wavread` function.