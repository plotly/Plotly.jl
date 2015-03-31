using JSON

default_endpoints = {
"base" => "https://plot.ly",
"api" => "https://api.plot.ly/v2"}

type PlotlyCredentials
    username::String
    api_key::String
end

type PlotlyConfig
    plotly_domain::String
    plotly_api_domain::String
end

function signin(username::String, api_key::String, endpoints=None)
# Define session credentials/endpoint configuration, where endpoint is a Dict

    if endpoints != None
        base_domain = get(endpoints, "plotly_domain", default_endpoints["base"])
        api_domain = get(endpoints, "plotly_api_domain", default_endpoints["api"])
        global plotlyconfig = PlotlyConfig(base_domain, api_domain)
    end
    global plotlycredentials = PlotlyCredentials(username, api_key)
end

function get_credentials()
# Return the session credentials if defined --> otherwise use .credentials specs

    if !isdefined(Plotly,:plotlycredentials)
        creds = get_credentials_file()
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

function get_config()
# Return the session configuration if defined --> otherwise use .config specs

    if !isdefined(Plotly,:plotlyconfig)
        config = get_config_file()
        base_domain = get(config, "plotly_domain", default_endpoints["base"])
        api_domain = get(config, "plotly_api_domain", default_endpoints["api"])
        global plotlyconfig = PlotlyConfig(base_domain, api_domain)
    end

    # will persist for the remainder of the session
    return plotlyconfig
end

function set_credentials_file(input_creds::Dict)
# Save Plotly endpoint configuration as JSON key-value pairs in
# userhome/.plotly/.credentials. This includes username and api_key.

    prev_creds = {}

    try
        prev_creds = get_credentials_file()
    end

    # plotly credentials file
    userhome = get(ENV, "HOME", "")
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    #check to see if dir/file exists --> if not create it
    try
        mkdir(plotly_credentials_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    #merge input creds with prev creds
    if prev_creds != {}
        creds = merge(prev_creds, input_creds)
    else
        creds = input_creds
    end

    #write the json strings to the cred file
    creds_file = open(plotly_credentials_file, "w")
    write(creds_file, JSON.json(creds))
    close(creds_file)
end

function set_config_file(input_config::Dict)
# Save Plotly endpoint configuration as JSON key-value pairs in
# userhome/.plotly/.config. This includes the plotly_domain, and plotly_api_domain.

    prev_config = {}

    try
        prev_config = get_config_file()
    end

    # plotly configuration file
    userhome = get(ENV, "HOME", "")
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    #check to see if dir/file exists --> if not create it
    try
        mkdir(plotly_config_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    #merge input config with prev config
    if prev_config != {}
        config = merge(prev_config, input_config)
    else
        config = input_config
    end

    #write the json strings to the config file
    config_file = open(plotly_config_file, "w")
    write(config_file, JSON.json(config))
    close(config_file)
end

function get_credentials_file()
# Load user credentials as a Dict

    # plotly credentials file
    userhome = get(ENV, "HOME", "")
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    if !isfile(plotly_credentials_file)
        error(" No credentials file found. Please Set up your credentials
        file by running set_credentials_file({\"username\": \"your_plotly_username\", ...
        \"api_key\": \"your_plotly_api_key\"})")
    end

    creds_file = open(plotly_credentials_file)
    creds = JSON.parse(creds_file)

    if creds == nothing
        creds = {}
    end

    return creds
end

function get_config_file()
# Load endpoint configuration as a Dict

    # plotly configuration file
    userhome = get(ENV, "HOME", "")
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    if !isfile(plotly_config_file)
        error(" No configuration file found. Please Set up your configuration
        file by running set_config_file({\"plotly_domain\": \"your_plotly_domain\", ...
        \"plotly_api_domain\": \"your_plotly_api_domain\"})")
    end

    config_file = open(plotly_config_file)
    config = JSON.parse(config_file)

    if config == nothing
        config = {}
    end

    return config
end
