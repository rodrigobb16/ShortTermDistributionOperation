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
    circuits_beta0 = [Float64[] for _ in 1:study.circuits.size]
    circuits_beta1 = [Float64[] for _ in 1:study.circuits.size]
    max_iter = 10
    iter = 0
    while true
        iter += 1
        println("Iteration $iter...")
        write_to_file(m, "stdo.lp")
        optimize!(m)
        calc_losses = study.circuits.resistance .* (value.(m[:flow]) .^ 2)
        if all(abs.(calc_losses .- value.(m[:losses])) ./ calc_losses .< 0.01) || iter >= max_iter
            break
        end
        
        for icircuit in 1:study.circuits.size
            push!(circuits_beta1[icircuit], 2 * study.circuits.resistance[icircuit] .* value.(m[:flow][icircuit]))
            push!(circuits_beta0[icircuit], calc_losses[icircuit] .- circuits_beta1[icircuit][end] * value.(m[:flow][icircuit]))
        end
        @constraint(m, [icircuit=1:study.circuits.size],
            m[:losses][icircuit] >= circuits_beta0[icircuit][end] + circuits_beta1[icircuit][end] * m[:flow][icircuit]
        )
    end

    @show iter
    @show circuits_beta0
    @show circuits_beta1
    @show value.(m[:losses])
    
    println("Model solved successfully!")
    println("Objective value: ", objective_value(m))

    println("STDO SUCCESS!")
    return 0
end