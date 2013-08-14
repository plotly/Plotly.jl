#A Julia interface to the plot.ly API

## Usage

    julia> using Plotly

    julia> acc = Plotly.PlotlyAccount("astrieanna","o0ggrhu9ie")
    PlotlyAccount("astrieanna","o0ggrhu9ie")

    julia> Plotly.openurl(Plotly.plot(acc,["z"=>rand(6,6)],["style"=>["type"=>"heatmap"]]))
    START /bin/firefox "https://plot.ly/~astrieanna/0"
    # ^ that's what the REPL prints out, as a firefox tab opens with the plot


