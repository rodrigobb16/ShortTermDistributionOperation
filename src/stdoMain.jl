function main(casepath::String)

    # Load the study file
    if !isdir(casepath)
        error("Path not found: $casepath")
    end
    
    println("Loading study from $casepath...")
    study = StdoLoadStudy(casepath);
    println("Study loaded successfully!")

    println("Building base model...")
    m = Model(HiGHS.Optimizer)
    StdoBuildVariables!(m, study);
    StdoBuildObjectiveFunction!(m, study);
    StdoBuildConstraints!(m, study);
    println("Base model built successfully!")
    
    println("Solving model...")
    flow = m[:flow]
    losses = m[:losses]    

    max_iter = 15
    calc_losses = zeros(study.circuits.size, study.scenarios)
    for hour in 1:study.hours
        println("Hour $hour...")
        circuits_beta0 = [[Float64[] for _ in 1:study.scenarios] for _ in 1:study.circuits.size]
        circuits_beta1 = [[Float64[] for _ in 1:study.scenarios] for _ in 1:study.circuits.size]
        iter = 0
        while true
            iter += 1
            println("Iteration $iter...")
            write_to_file(m, "stdo.lp")
            set_silent(m)
            optimize!(m)
            
            # Calculate losses for each scenario
            max_gap = 0.0
            for iscenario in 1:study.scenarios
                calc_losses[:, iscenario] = study.circuits.resistance .* (value.(flow[:,hour,iscenario]) .^ 2)
                gap = maximum(abs.(calc_losses[:, iscenario] .- value.(losses[:,hour,iscenario])))
                max_gap = max(max_gap, gap)
            end
            
            if max_gap < 1e-5 || iter >= max_iter
                break
            end
            
            # Add cuts for each circuit and scenario
            for icircuit in 1:study.circuits.size
                for iscenario in 1:study.scenarios
                    push!(circuits_beta1[icircuit][iscenario], 2 * study.circuits.resistance[icircuit] * value.(flow[icircuit,hour,iscenario]))
                    push!(circuits_beta0[icircuit][iscenario], calc_losses[icircuit, iscenario] - circuits_beta1[icircuit][iscenario][end] * value.(flow[icircuit,hour,iscenario]))
                    @constraint(m, 
                        losses[icircuit,hour,iscenario] >= circuits_beta0[icircuit][iscenario][end] + circuits_beta1[icircuit][iscenario][end] * flow[icircuit,hour,iscenario]
                    )
                end
            end
        end

        println("Iteration count: ", iter)
        println("Losses linearization gap: ", maximum(abs.(calc_losses .- value.(losses[:,hour,:]))))
    end
    
    println("Model solved successfully!")
    println("Objective value: ", objective_value(m))
    
    

    println("STDO SUCCESS!")

    # Save results
    println("Saving results...")
    StdoSaveResults(casepath,m, study)
    println("Results saved successfully!")

    return 0
end