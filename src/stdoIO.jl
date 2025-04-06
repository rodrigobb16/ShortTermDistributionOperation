function StdoLoadParameters(case_path::String)

    diretorio = joinpath(case_path, "inputs.txt");
    dict_parm = Dict();
    open(diretorio) do txt
        while !eof(txt)
            line = readline(txt);
            local (parameters, value) = strip.(split(line, "="));
            push!(dict_parm, parameters => parse(Float64, value));
        end
    end

end

function StdoLoadBuses(buses_filepath::String)
    bus_input_df = DataFrame(CSV.File(buses_filepath));
    df_size = size(bus_input_df, 1);
    code = bus_input_df.code;

    return StdoBuses(df_size::Int, 
                     code::Vector{Int});
end

function StdoLoadCircuits(circuits_filepath::String)
    circuits_input_df = DataFrame(CSV.File(circuits_filepath));
    df_size = size(circuits_input_df, 1);
    code = circuits_input_df.code;
    busFrom = circuits_input_df.bus_from;
    busTo = circuits_input_df.bus_to;
    type = String.(circuits_input_df.type);
    config = String.(circuits_input_df.config);
    capacity = Float64.(circuits_input_df.capacity_kW);

    return StdoCircuits(df_size::Int, 
                        code::Vector{Int}, 
                        busFrom::Vector{Int}, 
                        busTo::Vector{Int}, 
                        type::Vector{String}, 
                        config::Vector{String}, 
                        capacity::Vector{Float64});
end

function StdoLoadLoads(loads_filepath::String)
    
    loads_input_df = DataFrame(CSV.File(loads_filepath));
    df_size = size(loads_input_df, 1);
    code = loads_input_df.code;
    load2bus = loads_input_df.bus;
    power = Float64.(loads_input_df.load_kW);

    return StdoLoads(df_size::Int, 
                     code::Vector{Int}, 
                     load2bus::Vector{Int}, 
                     power::Vector{Float64});
end

function StdoLoadGenerators(generators_filepath::String)
    generators_input_df = DataFrame(CSV.File(generators_filepath));
    df_size = size(generators_input_df, 1);

    code = Int[];
    gen2bus = Int[];
    power = Float64[]

    if df_size > 0
        code = generators_input_df.code;
        gen2bus = generators_input_df.bus;
        power = Float64.(generators_input_df.generation_kW);
    end

    return StdoGenerators(df_size::Int, 
                          code::Vector{Int}, 
                          gen2bus::Vector{Int}, 
                          power::Vector{Float64});
end

function StdoLoadStudy(casepath::String)

    buses = StdoLoadBuses(joinpath(casepath, "bus_info.csv"));
    circuits = StdoLoadCircuits(joinpath(casepath, "line_info.csv"));
    loads = StdoLoadLoads(joinpath(casepath, "load_info.csv"));
    substation = StdoLoadGenerators(joinpath(casepath, "substation_info.csv"));

    return StdoStudy(buses::StdoBuses, 
                      circuits::StdoCircuits,
                      loads::StdoLoads,
                      substation::StdoGenerators);
    
end