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

    global plotlycredentials = PlotlyCredentials(username, api_key)

    # if endpoints are specified both the base and api domains must be specified
    if endpoints != None
        try
            base_domain = endpoints["plotly_domain"]
            api_domain = endpoints["plotly_api_domain"]
            global plotlyconfig = PlotlyConfig(base_domain, api_domain)
        catch
            error("You must specify both the base and api endpoints.")
        end
    end
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

        if isempty(config)
            base_domain = default_endpoints["base"]
            api_domain = default_endpoints["api"]
        else
            base_domain = get(config, "plotly_domain", default_endpoints["base"])
            api_domain = get(config, "plotly_api_domain", default_endpoints["api"])
        end

        global plotlyconfig = PlotlyConfig(base_domain, api_domain)

    end

    # will persist for the remainder of the session
    return plotlyconfig
end

function set_credentials_file(input_creds::Dict)
# Save Plotly endpoint configuration as JSON key-value pairs in
# userhome/.plotly/.credentials. This includes username and api_key.

    # plotly credentials file
    userhome = homedir()
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    #check to see if dir/file exists --> if not, create it
    try
        mkdir(plotly_credentials_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    prev_creds = get_credentials_file()

    #merge input creds with prev creds
    if !isempty(prev_creds)
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

    # plotly configuration file
    userhome = homedir()
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    #check to see if dir/file exists --> if not create it
    try
        mkdir(plotly_config_folder)
    catch err
        isa(err, SystemError) || rethrow(err)
    end

    prev_config = get_config_file()

    #merge input config with prev config
    if !isempty(prev_config)
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
    userhome = homedir()
    plotly_credentials_folder = joinpath(userhome, ".plotly")
    plotly_credentials_file = joinpath(plotly_credentials_folder, ".credentials")

    if !isfile(plotly_credentials_file)
        creds = {}
    else
        creds_file = open(plotly_credentials_file)
        creds = JSON.parse(creds_file)

        if creds == nothing
            creds = {}
        end

    end

    return creds

end

function get_config_file()
# Load endpoint configuration as a Dict

    # plotly configuration file
    userhome = homedir()
    plotly_config_folder = joinpath(userhome, ".plotly")
    plotly_config_file = joinpath(plotly_config_folder, ".config")

    if !isfile(plotly_config_file)
        config = {}
    else
        config_file = open(plotly_config_file)
        config = JSON.parse(config_file)

        if config == nothing
            config = {}
        end

    end

    return config
end
