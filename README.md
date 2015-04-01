# A Julia interface to the plot.ly API

[![Build Status](https://travis-ci.org/plotly/Plotly-Julia.svg)](https://travis-ci.org/plotly/Plotly-Julia)

README quickly to get started. Alternately, checkout out the pretty Julia docs at http://plot.ly/api

## Installation

Given that you have Julia v0.2.1,

```julia
Pkg.clone("https://github.com/plotly/Plotly.jl")
```

## Usage
```julia
julia> using Plotly
INFO: Cloning Plotly from https://github.com/plotly/Plotly.jl
INFO: Computing changes...
INFO: No packages to install, update or remove.
```

You'll need to create a plot.ly account and find out your API key before you'll be able to use this package.

## New user signup
Find your username and API key in the [Plotly settings](https://plot.ly/settings).

## Signin
```julia
julia> Plotly.signin("username","your api key")
PlotlyAccount("username","your api key")
```

Note: you may also specify your session endpoints using signin as follows: 

```julia
julia> Plotly.signin("username","your api key",{"plotly_domain"=> "your_plotly_base_endpoint", "plotly_api_domain"=> "your_plotly_api_endpoint"})
```

## Saving your credentials
```julia
julia> Plotly.set_credentials_file({"username"=>"your_user_name","api_key"=>"your_api_key"})
```

Note: your credentials will be saved within /YOUR_HOME_DIR/.plotly/.credentials

## Saving your endpoint configuration
```julia
julia> Plotly.set_config_file({"plotly_domain"=> "your_plotly_base_endpoint", "plotly_api_domain"=> "your_plotly_api_endpoint"})
```

Note: your configuration will be saved within /YOUR_HOME_DIR/.plotly/.config

## Plot && Open in browser
```julia
julia> Plotly.openurl(Plotly.plot(["z"=>rand(6,6)],["style"=>["type"=>"heatmap"]]))
START /bin/firefox "https://plot.ly/~astrieanna/0"
```

That last line is what the REPL prints out,
as a Firefox tab opens with the plot.
You can also just call `plot` by itself, and you'll get a String that's the url of your chart.

## Style and Layout
```julia
julia> Plotly.style(["line"=>["color"=>"rgb(255,0,0)","width"=>10]])
julia> Plotly.layout(["layout"=>["title"=>"Time Wasted"]])
```

# Quick Plotting
## Functions and Polynomials
```julia
julia> Plotly.plot(abs)
julia> Plotly.plot([sqrt, log], ["left"=>10, "right"=>20, "step"=>0.1])
julia> Plotly.plot() do x
       savings = 3000
       income = x*1000
       expenses = x*800
       return savings+income-expenses
       end
```

You can now plot functions directly.
The first line shows how to plot the absolute value function, and the second line plots
the square root and logarithm functions, both from 10 to 20 at increments of 0.1.
The last line shows how to use Julia's `do` syntax to plot complicated anonymous functions.

```julia
julia> using Polynomial
julia> x = Poly([1,0])
julia> Plotly.plot(3x^3 + 2x^2 - x + 1)
julia> Plotly.plot([x, 2x, 3x^2-x])
```

Using the Polynomial package, you can plot polynomials directly the same way as math functions.

## DataFrames and TimeSeries
```julia
julia> using DataFrames
julia> df = readtable("height_vs_weight.csv")
julia> Plotly.plot(df, ["xs"=>:height, "ys"=>:weight])
```

Using the DataFrames package, you can read CSV data and plot it directly by passing the data frame and setting the xs and/or ys options. These are symbols or arrays of symbols refering to columns names in the CSV file.

```julia
julia> using TimeSeries
julia> d = [date(2012,5,29):date(2013,5,29)]
julia> t = TimeArray(d, rand(length(d),2), ["foo","bar"])
julia> Plotly.plot(t)
```

Using the TimeSeries package, you can plot them directly by passing a TimeArray argument.

## WAV Files
```julia
julia> using WAV
julia> Plotly.plot(wavread("filename.wav"))
```

Using the WAV package, you can plot WAV files by passing a call to the `wavread` function.

# Detailed Plotting
## Arrays and Dicts
```julia
julia> trace1 = Plotly.line([3x for x in 1:1000])
julia> trace2 = Plotly.histogram([3x for x in 1:1000])
julia> trace3 = Plotly.scatter([2x => 3x for x in 1:1000])
julia> trace4 = Plotly.box([2x => 3x for x in 1:1000])
julia
```

## Functions and Polynomials
```julia
julia> trace1 = Plotly.line(abs, ["left"=>10, "right"=>20, "step"=>0.1])
julia> trace2 = Plotly.box(sin, ["left"=>10, "right"=>20, "step"=>0.1])
julia> trace3 = Plotly.scatter(cos, ["left"=>10, "right"=>20, "step"=>0.1])
julia> trace4 = Plotly.histogram(cos, ["left"=>10, "right"=>20, "step"=>0.1])
julia> Plotly.plot([trace1, trace2, trace3, trace4])

julia> using Polynomial
julia> x = Poly([1,0])
julia> trace1 = Plotly.line(3x^3 + 2x^2 - x + 1)
julia> trace2 = Plotly.histogram(3x^3 + 2x^2 - x + 1)
julia> Plotly.plot([trace1, trace2])
```

## DataFrames and TimeSeries
```julia
julia> using DataFrames
julia> df = readtable("height_vs_weight.csv")
julia> trace1 = Plotly.line(df, ["xs"=>:height, "ys"=>:weight])
julia> trace2 = Plotly.scatter(df, ["xs"=>:height, "ys"=>:weight])
julia> trace3 = Plotly.histogram(df, ["xs"=>:height])
julia> trace4 = Plotly.box(df, ["ys"=>:weight])
julia> Plotly.plot([trace1, trace2, trace3, trace4])

julia> using TimeSeries
julia> d = [date(2012,5,29):date(2013,5,29)]
julia> t = TimeArray(d, rand(length(d),2), ["foo","bar"])
julia> trace1 = Plotly.line(t)
julia> trace2 = Plotly.scatter(t)
julia> trace3 = Plotly.box(t)
julia> trace4 = Plotly.histogram(t)
julia> Plotly.plot([trace1, trace2, trace3, trace4])
```

## WAV Files
```julia
julia> using WAV
julia> trace1 = Plotly.line(wavread("filename.wav"))
julia> trace2 = Plotly.histogram(wavread("filename.wav"))
julia> trace3 = Plotly.box(wavread("filename.wav"))
julia> trace4 = Plotly.scatter(wavread("filename.wav"))
julia> Plotly.plot([trace1, trace2, trace3, trace4])
```
