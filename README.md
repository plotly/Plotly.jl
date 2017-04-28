# Plotly.jl

[![Build Status](https://travis-ci.org/plotly/Plotly.jl.svg)](https://travis-ci.org/plotly/Plotly.jl)

> A Julia interface to the plot.ly plotting library and cloud services

## Install

Simply run `Pkg.add("Plotly")`.

## Usage

Plotting functions provided by this package are identical to [PlotlyJS](https://github.com/spencerlyon2/PlotlyJS.jl). Please consult its [documentation](http://spencerlyon.com/PlotlyJS.jl/).

For example, this will display a basic scatter plot:

```
my_plot = plot([scatter(x=[1,2], y=[3,4])], Layout(title="My plot"))
```

## Using the Plotly cloud

### New user signup
Find your username and API key in the [Plotly settings](https://plot.ly/settings).

### Signin
```julia
julia> Plotly.signin("username","your api key")
PlotlyAccount("username","your api key")
```

Note: you may also specify your session endpoints using sign in as follows:

```julia
julia> Plotly.signin("username","your api key",Dict("plotly_domain"=> "your_plotly_base_endpoint", "plotly_api_domain"=> "your_plotly_api_endpoint"))
```

### Saving your credentials
```julia
julia> Plotly.set_credentials_file(Dict("username"=>"your_user_name","api_key"=>"your_api_key"))
```

Note: your credentials will be saved within /YOUR_HOME_DIR/.plotly/.credentials

### Saving your endpoint configuration
```julia
julia> Plotly.set_config_file(Dict("plotly_domain"=> "your_plotly_base_endpoint", "plotly_api_domain"=> "your_plotly_api_endpoint"))
```

Note: your configuration will be saved within /YOUR_HOME_DIR/.plotly/.config

### Saving a plot to the cloud

Use the `post` function to upload a local plot to the Plotly cloud:

```
> my_plot  = plot([scatter(y=[1,2])])
> remote_plot = post(my_plot)
Plotly.RemotePlot(URI(https://plot.ly/~malmaud/73))
```

Visiting <https://plot.ly/~malmaud/73> in a browser will show the plot.

### Download a plot from the cloud

Use the `download` function with a remote plot object to download a plot stored on the Plotly cloud to a local `Plot` object:

```
local_plot = download(RemotePlot("https://plot.ly/~malmaud/73"))
# or equivalently, local_plot = download_plot("https://plot.ly/~malmaud/73")
```

## Acknowledgements

[PlotlyJS.jl ](https://github.com/spencerlyon2/PlotlyJS.jl), which provides the large majority of the functionality of this package, is developed primarily by Spencer Lyon.

This package, which adds to PlotlyJS.jl the functionality for interacting with the Plotly cloud, is developed by Jon Malmaud and others.

## Contribute

Please do! This is an open source project. Check out [the issues](https://github.com/plotly/Plotly.jl/issues) or open a PR!

We want to encourage a warm, welcoming, and safe environment for contributing to this project. See the [code of conduct](CODE_OF_CONDUCT.md) for more information.

## License

[MIT](LICENSE.md) © 2016-2017 Shilei Zheng, Leah Hanson, Bryan A. Knowles, Chris Palmer, Jon Malmaud
