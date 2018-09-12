struct PlotlyError
    msg::String
end

struct PlotlyCredentials
    username::String
    api_key::String
end

mutable struct PlotlyConfig
    plotly_domain::String
    plotly_api_domain::String
    plotly_streaming_domain::String
    plotly_proxy_authorization::Bool
    plotly_ssl_verification::Bool
    sharing::String
    world_readable::Bool
    auto_open::Bool
    fileopt::Symbol
end

const DEFAULT_CONFIG = PlotlyConfig(
    "https://plot.ly",
    "https://api.plot.ly/v2",
    "stream.plot.ly",
    false,
    true,
    "public",
    true,
    true,
    :create
)

function Base.merge(config::PlotlyConfig, other::AbstractDict)
    PlotlyConfig(
        [
            get(other, string(name), getfield(config, name))
            for name in fieldnames(PlotlyConfig)
        ]...
    )
end

Base.show(io::IO, config::PlotlyConfig) = dump(IOContext(io, :limit=>true), config)

function Base.Dict(config::PlotlyConfig)
    Dict(k => getfield(config, k) for k in fieldnames(PlotlyConfig))
end

"""
    signin(username::String, api_key::String, endpoints=nothing)

Define session credentials/endpoint configuration, where endpoint is a Dict
"""
function signin(
        username::String, api_key::String,
        endpoints::Union{Nothing,AbstractDict}=nothing
    )
    global plotlycredentials = PlotlyCredentials(username, api_key)



    # if endpoints are specified both the base and api domains must be
    # specified
    if endpoints != nothing
        if !haskey(endpoints, "plotly_domain") || !haskey(endpoints, "plotly_api_domain")
            error("You must specify both the `plotly_domain` and `plotly_api_domain`")
        end
        global plotlyconfig = merge(DEFAULT_CONFIG, endpoints)
    end
end

"""
    get_credentials()

Return the session credentials if defined --> otherwise use .credentials specs
"""
function get_credentials()
    if !isdefined(Plotly, :plotlycredentials)

        creds = merge(get_credentials_file(), get_credentials_env())

        try
            username = creds["username"]
            api_key = creds["api_key"]

            global plotlycredentials = PlotlyCredentials(username, api_key)

        catch
            error("Please 'signin(username, api_key)' before proceeding. See
            http://plot.ly/API for help!")
        end
    end

    # will persist for the remainder of the session
    return plotlycredentials
end

"""
    get_config()

Return the session configuration if defined --> otherwise use .config specs
"""
function get_config()
    if !isdefined(Plotly, :plotlyconfig)
        config = get_config_file()
        global plotlyconfig = merge(DEFAULT_CONFIG, config)
    end

    # will persist for the remainder of the session
    return plotlyconfig
end

"""
    set_credentials_file(input_creds::AbstractDict)

Save Plotly endpoint configuration as JSON key-value pairs in
userhome/.plotly/.credentials. This includes username and api_key.
"""
function set_credentials_file(input_creds::AbstractDict)
    credentials_folder = joinpath(homedir(), ".plotly")
    credentials_file = joinpath(credentials_folder, ".credentials")

    # check to see if dir/file exists --> if not, create it
    !isdir(credentials_folder) && mkdir(credentials_folder)

    prev_creds = get_credentials_file()
    creds = merge(prev_creds, input_creds)

    # write the json strings to the cred file
    open(credentials_file, "w") do creds_file
        write(creds_file, JSON.json(creds))
    end
end

"""
    set_config_file(input_config::AbstractDict)

Save Plotly endpoint configuration as JSON key-value pairs in
userhome/.plotly/.config. This includes the plotly_domain, and
plotly_api_domain.
"""
function set_config_file(input_config::AbstractDict)
    config_folder = joinpath(homedir(), ".plotly")
    config_file = joinpath(config_folder, ".config")

    # check to see if dir/file exists --> if not create it
    !isdir(config_folder) && mkdir(config_folder)

    prev_config = get_config_file()
    config = merge(prev_config, input_config)

    # write the json strings to the config file
    open(config_file, "w") do config_file
        write(config_file, JSON.json(config))
    end
end

"""
    set_config_file(config::PlotlyConfig)

Set the values in the configuration file to match the values in config
"""
set_config_file(config::PlotlyConfig) = set_config_file(Dict(config))

"""
    get_credentials_file()

Load user credentials informaiton as a dict
"""
function get_credentials_file()
    cred_file = joinpath(homedir(), ".plotly", ".credentials")
    isfile(cred_file) ? JSON.parsefile(cred_file) : Dict()
end

function get_credentials_env()
    out = Dict()
    keymap = Dict(
        "PLOTLY_USERNAME" => "username",
        "PLOTLY_APIKEY" => "api_key",
    )
    for k in ["PLOTLY_USERNAME", "PLOTLY_APIKEY"]
        if haskey(ENV, k)
            out[keymap[k]] = ENV[k]
        end
    end
    out
end

"""
    get_config_file()

Load endpoint configuration as a Dict
"""
function get_config_file()
    config_file = joinpath(homedir(), ".plotly", ".config")
    isfile(config_file) ? JSON.parsefile(config_file) : Dict()
end
