function StdoBuildVariables!(m, study::StdoStudy)
    @variable(m, 0 <= losses[1:study.circuits.size])
    @variable(m, flow[icir=1:study.circuits.size])
    @variable(m, 0 <= powerSupply[1:study.buses.size])
    @variable(m, 0 <= powerConsumption[1:study.buses.size])
    @variable(m, 0 <= deficit[1:study.buses.size])
end

function StdoBuildObjectiveFunction!(m, study::StdoStudy)
    losses = m[:losses]
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]

    penalty_deficit = 1e6 # penalty for deficit
    @objective(m, Min, 
        sum(losses[icircuit] for icircuit in 1:study.circuits.size) + 
        sum(penalty_deficit * deficit[ibus] for ibus in 1:study.buses.size)
    )
end

function StdoBuildConstraints!(m, study::StdoStudy)
    
    flow = m[:flow]
    powerSupply = m[:powerSupply]
    powerConsumption = m[:powerConsumption]
    deficit = m[:deficit]
    losses = m[:losses]    

    @constraint(m, node_balance[ibus=1:study.buses.size],
        sum(flow[icircuit] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) - 
        sum(flow[icircuit] for icircuit in 1:study.circuits.size if study.circuits.busFrom[icircuit] == ibus) -
        sum(losses[icircuit] for icircuit in 1:study.circuits.size if study.circuits.busTo[icircuit] == ibus) +
        powerSupply[ibus] - powerConsumption[ibus] == 0
    )

    @constraint(m, demand_supply[ibus=1:study.circuits.size],
        powerConsumption[ibus] + deficit[ibus] == sum(study.loads.power[iload] for iload in 1:study.loads.size if study.loads.load2bus[iload] == ibus)
    )

    @constraint(m, max_power_supply[ibus=1:study.buses.size],
        powerSupply[ibus] <= sum(study.generators.power[igenerator] for igenerator in 1:study.generators.size if study.generators.gen2bus[igenerator] == ibus)
    )

    @constraint(m, circuit_capacity_up[icircuit=1:study.circuits.size],
        flow[icircuit] <= study.circuits.capacity[icircuit]
    )
    @constraint(m, circuit_capacity_down[icircuit=1:study.circuits.size],
        flow[icircuit] >= -study.circuits.capacity[icircuit]
    )
    
    return m
end