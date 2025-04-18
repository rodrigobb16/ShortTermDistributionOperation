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

function StdoLoadCircuits(circuits_filepath::String, buses::StdoBuses, base_power::Float64, base_resisteance::Float64)
    circuits_input_df = DataFrame(CSV.File(circuits_filepath));
    df_size = size(circuits_input_df, 1);
    code = circuits_input_df.code;
    busFromCode = circuits_input_df.bus_from;
    busToCode = circuits_input_df.bus_to;
    type = String.(circuits_input_df.type);
    config = String.(circuits_input_df.config);
    capacity = Float64.(circuits_input_df.capacity_kW) / base_power; # to pu
    resistance = Float64.(circuits_input_df.resistance_ohm) / base_resisteance; # to pu

    busFrom = Int[];
    busTo = Int[];
    for i in 1:df_size
        busFrom = push!(busFrom, findfirst(buses.code .== busFromCode[i]));
        busTo = push!(busTo, findfirst(buses.code .== busToCode[i]));
    end

    return StdoCircuits(df_size::Int, 
                        code::Vector{Int}, 
                        busFrom::Vector{Int}, 
                        busTo::Vector{Int}, 
                        type::Vector{String}, 
                        config::Vector{String}, 
                        capacity::Vector{Float64},
                        resistance::Vector{Float64});
end

function StdoLoadLoads(loads_filepath::String, buses::StdoBuses, base_power::Float64, base_voltage::Float64)
    
    loads_input_df = DataFrame(CSV.File(loads_filepath));
    df_size = size(loads_input_df, 1);
    code = loads_input_df.code;
    busCode = loads_input_df.bus;
    power = Float64.(loads_input_df.load_kW) / base_power; # to pu

    load2bus = Int[];
    for i in 1:df_size
        load2bus = push!(load2bus, findfirst(buses.code .== busCode[i]));
    end

    return StdoLoads(df_size::Int, 
                     code::Vector{Int}, 
                     load2bus::Vector{Int}, 
                     power::Vector{Float64});
end

function StdoLoadGenerators(generators_filepath::String, buses::StdoBuses, base_power::Float64, base_voltage::Float64)
    generators_input_df = DataFrame(CSV.File(generators_filepath));
    df_size = size(generators_input_df, 1);

    code = Int[];
    gen2bus = Int[];
    power = Float64[]

    if df_size > 0
        code = generators_input_df.code;
        busCode = generators_input_df.bus;
        for i in 1:df_size
            gen2bus = push!(gen2bus, findfirst(buses.code .== busCode[i]));
        end
        power = Float64.(generators_input_df.generation_kW) / base_power; # to pu
    end

    return StdoGenerators(df_size::Int, 
                          code::Vector{Int}, 
                          gen2bus::Vector{Int}, 
                          power::Vector{Float64});
end

function StdoLoadStudy(casepath::String)

    base_power = 1000.0; # kVA
    base_voltage = 4.16;  # kV
    base_resisteance = ((base_voltage * 1000) ^2) / base_power # Ohm
    buses = StdoLoadBuses(joinpath(casepath, "bus_info.csv"));
    circuits = StdoLoadCircuits(joinpath(casepath, "line_info.csv"), buses, base_power, base_resisteance);
    loads = StdoLoadLoads(joinpath(casepath, "load_info.csv"), buses, base_power, base_voltage);
    substations = StdoLoadGenerators(joinpath(casepath, "substation_info.csv"), buses, base_power, base_voltage);

    return StdoStudy(
        base_power,
        base_voltage,
        buses::StdoBuses,
        circuits::StdoCircuits,
        loads::StdoLoads,
        substations::StdoGenerators
        );
end