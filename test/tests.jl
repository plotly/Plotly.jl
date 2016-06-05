using Plotly
using JSON
using Base.Test

# just check that http://plot.ly/clientresp behaves as expected -- nothing to see here

Plotly.signin("unittest","tfzz811f5n", Dict("plotly_domain"=>"https://plot.ly","plotly_api_domain"=>"https://api.plot.ly"))

# Check for no error
original_plot = Plotly.plot([scatter(x=[1,2],y=[3,4])])
remote_plot = post(original_plot)
downloaded_plot = download(remote_plot)

# TODO: check that downloaded plot matches the original plot

#test get_plot_endpoint
endpoints = Dict("plotly_domain"=>"my_plotly_domain", "plotly_api_domain"=>"my_plotly_api_domain")
Plotly.signin("test_username", "test_api_key", endpoints)
plot_endpoint = Plotly.get_plot_endpoint()
@test plot_endpoint == "my_plotly_domain/clientresp"
