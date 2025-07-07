function StdoBuildVariables!(m, study::StdoStudy)
    @variable(m, 0 <= losses[1:study.circuits.size,1:study.hours,1:study.scenarios])
    @variable(m, flow[1:study.circuits.size,1:study.hours,1:study.scenarios])
    @variable(m, 0 <= powerSupply[1:study.buses.size,1:study.hours])
    @variable(m, powerConsumption[1:study.buses.size,1:study.hours,1:study.scenarios])
    @variable(m, 0 <= deficit[1:study.buses.size,1:study.hours,1:study.scenarios])
    @variable(m, x[1:study.circuits.size, 1:study.hours, 1:study.scenarios], Bin)
    @variable(m, 0 <= batStorage[1:study.batteries.size, 1:study.hours, 1:study.scenarios])
    @variable(m, powerBat[1:study.batteries.size, 1:study.hours, 1:study.scenarios])
end

function StdoBuildObjectiveFunction!(m, study::StdoStudy)
    losses = m[:losses]
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]

    penalty_deficit = 1e6 # penalty for deficit
    scenario_probability = 1.0 / study.scenarios
    @objective(m, Min, 
        sum(scenario_probability * losses[icircuit,ihour,iscenario] for icircuit in 1:study.circuits.size, ihour in 1:study.hours, iscenario in 1:study.scenarios) + 
        sum(scenario_probability * penalty_deficit * deficit[ibus,ihour,iscenario] for ibus in 1:study.buses.size, ihour in 1:study.hours, iscenario in 1:study.scenarios) +
        sum(powerSupply[ibus,ihour] for ibus in 1:study.buses.size, ihour in 1:study.hours)
    )
end

function StdoBuildConstraints!(m, study::StdoStudy)
    
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]
    losses = m[:losses]
    powerBat = m[:powerBat]
    batStorage = m[:batStorage]
    x = m[:x]

    @constraint(m, node_balance[ibus=1:study.buses.size, ihour=1:study.hours, iscenario=1:study.scenarios],
        sum(flow[icircuit,ihour,iscenario] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) - 
        sum(flow[icircuit,ihour,iscenario] for icircuit in 1:study.circuits.size if study.circuits.busFrom[icircuit] == ibus) -
        sum(losses[icircuit,ihour,iscenario] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) +
        powerSupply[ibus,ihour] - powerConsumption[ibus,ihour,iscenario] == 0
    )

    @constraint(m, demand_supply[ibus=1:study.buses.size, ihour=1:study.hours, iscenario=1:study.scenarios],
        powerConsumption[ibus,ihour,iscenario] + deficit[ibus,ihour,iscenario] == 
        sum(study.loads.power[iload] for iload in 1:study.loads.size if study.loads.load2bus[iload] == ibus) - 
        sum(study.renewables.power[igenerator][iscenario][ihour] for igenerator in 1:study.renewables.size if study.renewables.gen2bus[igenerator] == ibus) -
        sum(powerBat[ibattery, ihour, iscenario] for ibattery in 1:study.batteries.size if study.batteries.battery2bus[ibattery] == ibus)
    )

    @constraint(m, max_power_supply[ibus=1:study.buses.size, ihour=1:study.hours],
        powerSupply[ibus,ihour] <= sum(study.generators.power[igenerator] for igenerator in 1:study.generators.size if study.generators.gen2bus[igenerator] == ibus)
    )

    for icircuit in 1:study.circuits.size
        if study.circuits.type[icircuit] != "switch"
            @constraint(m, flow[icircuit,1:study.hours,1:study.scenarios] .<= study.circuits.capacity[icircuit])
            @constraint(m, flow[icircuit,1:study.hours,1:study.scenarios] .>= -study.circuits.capacity[icircuit])
        else
            @constraint(m, flow[icircuit,1:study.hours,1:study.scenarios] .<= study.circuits.capacity[icircuit] * x[icircuit, 1:study.hours, 1:study.scenarios])
            @constraint(m, flow[icircuit,1:study.hours,1:study.scenarios] .>= -study.circuits.capacity[icircuit] * x[icircuit, 1:study.hours, 1:study.scenarios])
        end
    end

    # Radiality constraint
    @constraint(m, [ihour=1:study.hours, iscenario=1:study.scenarios],
        sum(x[icircuit, ihour, iscenario] for icircuit in 1:study.circuits.size if study.circuits.type[icircuit] == "switch")
        ==
        study.buses.size - 1 - sum(study.circuits.type[icircuit] != "switch" for icircuit in 1:study.circuits.size)
    )

    # Battery storage constraints
    @constraint(m, [ibattery=1:study.batteries.size, ihour=1, iscenario=1:study.scenarios],
        batStorage[ibattery, ihour, iscenario] == study.batteries.initial_charge[ibattery] - powerBat[ibattery, ihour, iscenario]
    )
    @constraint(m, [ibattery=1:study.batteries.size, ihour=2:study.hours, iscenario=1:study.scenarios],
        batStorage[ibattery, ihour, iscenario] == batStorage[ibattery, ihour-1, iscenario] - powerBat[ibattery, ihour, iscenario]
    )
    
    return m
end