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
    calc_losses = zeros(study.circuits.size)
    for hour in 1:study.hours
        println("Hour $hour...")
        circuits_beta0 = [Float64[] for _ in 1:study.circuits.size]
        circuits_beta1 = [Float64[] for _ in 1:study.circuits.size]
        iter = 0
        while true
            iter += 1
            println("Iteration $iter...")
            write_to_file(m, "stdo.lp")
            optimize!(m)
            calc_losses = study.circuits.resistance .* (value.(flow[:,hour]) .^ 2)
            if all(abs.(calc_losses .- value.(losses[:,hour])) .< 1e-5) || iter >= max_iter
                break
            end
            
            for icircuit in 1:study.circuits.size
                push!(circuits_beta1[icircuit], 2 * study.circuits.resistance[icircuit] .* value.(flow[icircuit,hour]))
                push!(circuits_beta0[icircuit], calc_losses[icircuit] .- circuits_beta1[icircuit][end] * value.(flow[icircuit,hour]))
            end
            @constraint(m, [icircuit=1:study.circuits.size],
                losses[icircuit,hour] >= circuits_beta0[icircuit][end] + circuits_beta1[icircuit][end] * flow[icircuit,hour]
            )
        end

        println("Iteration count: ", iter)
        println("Losses linearization gap: ", maximum(abs.(calc_losses .- value.(losses[:,hour]))))
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