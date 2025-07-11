function main(casepath::String)

    # Load the study file
    if !isdir(casepath)
        error("Path not found: $casepath")
    end
    
    println("Loading study from $casepath...")
    study = StdoLoadStudy(casepath);
    println("Study loaded successfully!")

    println("Building base model...")
    XpressPSR.initialize()
    m = Model(XpressPSR.Xpress.Optimizer)
    StdoBuildVariables!(m, study);
    StdoBuildObjectiveFunction!(m, study);
    StdoBuildConstraints!(m, study);
    println("Base model built successfully!")
    
    println("Solving model...")
    flow = m[:flow]
    losses = m[:losses]    

    # Modelo sem linearização
    @constraint(m, non_linear_losses[icircuit=1:study.circuits.size, ihour=1:study.hours, iscenario=1:study.scenarios],
        losses[icircuit, ihour, iscenario] >= study.circuits.resistance[icircuit] * flow[icircuit, ihour, iscenario] * flow[icircuit, ihour, iscenario]
    )
    
    set_silent(m)
    optimize!(m)

    # max_iter = 15
    # calc_losses = zeros(study.circuits.size, study.scenarios)
    # for hour in 1:study.hours
    #     println("Hour $hour...")
    #     circuits_beta0 = [[Float64[] for _ in 1:study.scenarios] for _ in 1:study.circuits.size]
    #     circuits_beta1 = [[Float64[] for _ in 1:study.scenarios] for _ in 1:study.circuits.size]
    #     iter = 0
    #     while true
    #         iter += 1
    #         println("Iteration $iter...")
    #         write_to_file(m, "stdo.lp")
    #         set_silent(m)
    #         optimize!(m)
            
    #         flow_values = value.(flow[:, hour, :])
    #         losses_values = value.(losses[:, hour, :])

    #         # Calculate losses for each scenario
    #         max_gap = 0.0
    #         for iscenario in 1:study.scenarios
    #             calc_losses[:, iscenario] = study.circuits.resistance .* (flow_values[:, iscenario] .^ 2)
    #             gap = maximum(abs.(calc_losses[:, iscenario] .- losses_values[:, iscenario]))
    #             max_gap = max(max_gap, gap)
    #         end
    #         # println("Max gap: ", max_gap)
    #         if max_gap < 1e-5 || iter >= max_iter
    #             break
    #         end
            
    #         # Add cuts for each circuit and scenario
    #         for icircuit in 1:study.circuits.size
    #             for iscenario in 1:study.scenarios
    #                 # println("Adding cuts for circuit $icircuit, scenario $iscenario...")
    #                 beta1 = 2 * study.circuits.resistance[icircuit] * flow_values[icircuit, iscenario];
    #                 beta0 = calc_losses[icircuit, iscenario] - beta1 * flow_values[icircuit, iscenario];

    #                 cut_violation = beta0 + beta1 * flow_values[icircuit, iscenario] - losses_values[icircuit, iscenario]

    #                 if cut_violation < 1e-8
    #                     # println("pulei - circuit $icircuit, scenario $iscenario, cut violation: ", cut_violation)
    #                     continue
    #                 end

    #                 push!(circuits_beta1[icircuit][iscenario], beta1)
    #                 push!(circuits_beta0[icircuit][iscenario], beta0)
    #                 @constraint(m, 
    #                     losses[icircuit,hour,iscenario] >= circuits_beta0[icircuit][iscenario][end] + circuits_beta1[icircuit][iscenario][end] * flow[icircuit,hour,iscenario]
    #                 )
    #             end
    #         end
    #     end

    #     println("Iteration count: ", iter)
    #     println("Losses linearization gap: ", maximum(abs.(calc_losses .- value.(losses[:,hour,:]))))
    # end
    
    println("Model solved successfully!")
    println("Objective value: ", objective_value(m))
    println("STDO SUCCESS!")

    # Save results
    println("Saving results...")
    StdoSaveResults(casepath,m, study)
    println("Results saved successfully!")

    return 0
end