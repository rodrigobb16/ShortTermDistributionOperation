mutable struct StdoBus
    size::Int
    id::Vector{Int}
    name::Vector{String}
    busType::Vector{String}
    voltage::Vector{Float64}
end

mutable struct StdoCircuit
    size::Int
    id::Vector{Int}
    name::Vector{String}
    busFrom::Vector{StdoBus}
    busTo::Vector{StdoBus}
    impedance::Vector{Float64}
end

mutable struct StdoLoads
    size::Int
    id::Vector{Int}
    load2bus::Vector{StdoBus}
    power::Vector{Float64}
end

mutable struct StdoGenerator
    size::Int
    id::Vector{Int}
    name::Vector{String}
    gen2bus::Vector{StdoBus}
    power::Vector{Float64}
end

mutable struct StdoStudy
    buses::StdoBuses
    circuits::StdoCircuits
    loads::StdoLoads
    generators::StdoGenerators
end