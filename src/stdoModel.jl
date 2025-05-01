function StdoBuildVariables!(m, study::StdoStudy)
    @variable(m, 0 <= losses[1:study.circuits.size,1:study.hours])
    @variable(m, flow[icir=1:study.circuits.size,1:study.hours])
    @variable(m, 0 <= powerSupply[1:study.buses.size,1:study.hours])
    @variable(m, 0 <= powerConsumption[1:study.buses.size,1:study.hours])
    @variable(m, 0 <= deficit[1:study.buses.size,1:study.hours,1:study.scenarios])
end

function StdoBuildObjectiveFunction!(m, study::StdoStudy)
    losses = m[:losses]
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]

    penalty_deficit = 1e6 # penalty for deficit
    @objective(m, Min, 
        sum(losses[icircuit,ihour] for icircuit in 1:study.circuits.size, ihour in 1:study.hours) + 
        sum(penalty_deficit * deficit[ibus,ihour,iscenario] for ibus in 1:study.buses.size, ihour in 1:study.hours, iscenario in 1:study.scenarios)
    )
end

function StdoBuildConstraints!(m, study::StdoStudy)
    
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]
    losses = m[:losses]    

    @constraint(m, node_balance[ibus=1:study.buses.size, ihour=1:study.hours],
        sum(flow[icircuit,ihour] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) - 
        sum(flow[icircuit,ihour] for icircuit in 1:study.circuits.size if study.circuits.busFrom[icircuit] == ibus) -
        sum(losses[icircuit,ihour] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) +
        powerSupply[ibus,ihour] - powerConsumption[ibus,ihour] == 0
    )

    @constraint(m, demand_supply[ibus=1:study.circuits.size, ihour=1:study.hours, iscenario=1:study.scenarios],
        powerConsumption[ibus,ihour] + deficit[ibus,ihour,iscenario] == sum(study.loads.power[iload] for iload in 1:study.loads.size if study.loads.load2bus[iload] == ibus)
    )

    @constraint(m, max_power_supply[ibus=1:study.buses.size, ihour=1:study.hours],
        powerSupply[ibus,ihour] <= sum(study.generators.power[igenerator] for igenerator in 1:study.generators.size if study.generators.gen2bus[igenerator] == ibus)
    )

    @constraint(m, circuit_capacity_up[icircuit=1:study.circuits.size, ihour=1:study.hours],
        flow[icircuit,ihour] <= study.circuits.capacity[icircuit]
    )
    @constraint(m, circuit_capacity_down[icircuit=1:study.circuits.size, ihour=1:study.hours],
        flow[icircuit,ihour] >= -study.circuits.capacity[icircuit]
    )
    
    return m
end