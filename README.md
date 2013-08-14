#A Julia interface to the plot.ly API

## Usage

    julia> using Plotly

    julia> acc = Plotly.PlotlyAccount("username","your api key")
    PlotlyAccount("username","your api key")

You'll need to create a plot.ly account and find out your API key before you'll be able to use this package.

    julia> Plotly.openurl(Plotly.plot(acc,["z"=>rand(6,6)],["style"=>["type"=>"heatmap"]]))
    START /bin/firefox "https://plot.ly/~astrieanna/0"

That last line is what the REPL prints out,
as a Firefox tab opens with the plot.
You can also just call `plot` by itself, and you'll get a String that's the url of your chart.


