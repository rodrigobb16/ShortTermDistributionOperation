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
    resistance = Float64.(circuits_input_df.resistance_pu) #/ base_resisteance; # to pu

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

function StdoLoadRenewables(renewables_filepath::String, buses::StdoBuses, base_power::Float64, base_voltage::Float64)
    renewables_input_df = DataFrame(CSV.File(renewables_filepath));
    renewable_header = names(renewables_input_df);

    size = 0;
    code = Int[];
    gen2bus = Int[];
    power = Vector{Dict{Int, Vector{Float64}}}();
    scn = 0;
    hor = 0;
    if length(renewable_header) > 2
        scn = maximum(renewables_input_df.scn);
        hor = maximum(renewables_input_df.hora);
        code = parse.(Int, renewable_header[3:end]);
        size = length(code);
        for i in 1:(length(renewable_header) - 2)
            gen2bus = push!(gen2bus, findfirst(buses.code .== code[i]));

            power_aux = Dict{Int,Vector{Float64}}();
            for row in eachrow(renewables_input_df)
                scn = row.scn;
                if !haskey(power_aux, scn)
                    power_aux[scn] = Float64[];
                end
                push!(power_aux[scn], row[i + 2] / base_power);
            end
            push!(power, power_aux);
        end
    end

    return StdoRenewable(size::Int, 
                         code::Vector{Int}, 
                         gen2bus::Vector{Int}, 
                         power::Vector{Dict{Int,Vector{Float64}}}), scn, hor;
end
function StdoLoadStudy(casepath::String)

    base_power = 1000.0; # kVA
    base_voltage = 4.16;  # kV
    base_resisteance = ((base_voltage * 1000) ^2) / base_power # Ohm
    buses = StdoLoadBuses(joinpath(casepath, "bus_info.csv"));
    circuits = StdoLoadCircuits(joinpath(casepath, "line_info.csv"), buses, base_power, base_resisteance);
    loads = StdoLoadLoads(joinpath(casepath, "load_info.csv"), buses, base_power, base_voltage);
    substations = StdoLoadGenerators(joinpath(casepath, "substation_info.csv"), buses, base_power, base_voltage);
    renewables, scn, hor = StdoLoadRenewables(joinpath(casepath, "GD_info.csv"), buses, base_power, base_voltage);
    return StdoStudy(
        scn,
        hor,
        base_power,
        base_voltage,
        buses::StdoBuses,
        circuits::StdoCircuits,
        loads::StdoLoads,
        substations::StdoGenerators,
        renewables::StdoRenewable,
        );
end

function StdoSaveResults(casepath::String, m, study::StdoStudy)
    
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]
    losses = m[:losses]   

    # Create a DataFrame to store the results

    losses_results = DataFrame(
        circuit_code = Int[],
        hour = Int[],
        losses = Float64[],
    )

    flow_results = DataFrame(
        circuit_code = Int[],
        hour = Int[],
        flow = Float64[],
    )

    powerSupply_results = DataFrame(
        bus_code = Int[],
        hour = Int[],
        powerSupply = Float64[],
    )

    powerConsumption_results = DataFrame(
        bus_code = Int[],
        hour = Int[],
        powerConsumption = Float64[],
    )

    deficit_results = DataFrame(
        bus_code = Int[],
        hour = Int[],
        scen = Int[],
        deficit = Float64[],
    )

    # Fill the DataFrame with the results
    for icircuit in 1:study.circuits.size
        for ihour in 1:study.hours
            push!(losses_results, (circuit_code = study.circuits.code[icircuit], hour = ihour, losses = value(losses[icircuit,ihour])))
            push!(flow_results, (circuit_code = study.circuits.code[icircuit], hour = ihour, flow = value(flow[icircuit,ihour])))
        end
    end

    for ibus in 1:study.buses.size
        for ihour in 1:study.hours
            push!(powerSupply_results, (bus_code = study.buses.code[ibus], hour = ihour, powerSupply = value(powerSupply[ibus,ihour])))
            push!(powerConsumption_results, (bus_code = study.buses.code[ibus], hour = ihour, powerConsumption = value(powerConsumption[ibus,ihour])))
            for iscenario in 1:study.scenarios
                push!(deficit_results, (bus_code = study.buses.code[ibus], hour = ihour, scen = iscenario, deficit = value(deficit[ibus,ihour,iscenario])))
            end
        end
    end

    # Save the DataFrame to a CSV file
    output_filepath = joinpath(casepath, "outputs")
    if !isdir(output_filepath)
        mkpath(output_filepath)
    end
    losses_filepath = joinpath(output_filepath, "losses.csv")
    CSV.write(losses_filepath, losses_results)

    flow_filepath = joinpath(output_filepath, "flow.csv")
    CSV.write(flow_filepath, flow_results)

    powerSupply_filepath = joinpath(output_filepath, "powerSupply.csv")
    CSV.write(powerSupply_filepath, powerSupply_results)

    powerConsumption_filepath = joinpath(output_filepath, "powerConsumption.csv")
    CSV.write(powerConsumption_filepath, powerConsumption_results)

    deficit_filepath = joinpath(output_filepath, "deficit.csv")
    CSV.write(deficit_filepath, deficit_results)

    println("Results saved to $output_filepath")
end