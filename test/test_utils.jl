using Plotly
using JSON
using Test

#test signin only one endpoint specified
@test_throws ErrorException Plotly.signin("fake_username", "fake_api_key", Dict("plotly_domain"=>"test"))

#test signin and get_credentials
Plotly.signin("test_username", "test_api_key")
creds = Plotly.get_credentials()
@test creds.username == "test_username"
@test creds.api_key == "test_api_key"

#test signin + endpoints and get_config
endpoints = Dict("plotly_domain"=>"my_plotly_domain", "plotly_api_domain"=>"my_plotly_api_domain")
Plotly.signin("test_username", "test_api_key", endpoints)
config = Plotly.get_config()
@test config.plotly_domain == "my_plotly_domain"
@test config.plotly_api_domain== "my_plotly_api_domain"
