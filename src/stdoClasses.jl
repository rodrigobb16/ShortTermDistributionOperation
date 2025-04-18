mutable struct StdoBuses
    size::Int
    # id::Vector{Int}
    code::Vector{Int}
    # name::Vector{String}
    # busType::Vector{String}
    # voltage::Vector{Float64}
end

mutable struct StdoCircuits
    size::Int
    # id::Vector{Int}
    code::Vector{Int}
    # name::Vector{String}
    busFrom::Vector{Int}
    busTo::Vector{Int}
    # impedance::Vector{Float64}
    type::Vector{String}
    config::Vector{String}
    capacity::Vector{Float64}
    resistance::Vector{Float64}
end

mutable struct StdoLoads
    size::Int
    # id::Vector{Int}
    code::Vector{Int}
    load2bus::Vector{Int}
    power::Vector{Float64}
end

mutable struct StdoGenerators
    size::Int
    # id::Vector{Int}
    code::Vector{Int}
    # name::Vector{String}
    gen2bus::Vector{Int}
    power::Vector{Float64}
end

mutable struct StdoStudy
    basePower::Float64
    baseVoltage::Float64
    buses::StdoBuses
    circuits::StdoCircuits
    loads::StdoLoads
    generators::StdoGenerators
end