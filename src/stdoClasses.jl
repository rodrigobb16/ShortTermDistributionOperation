struct StdoBus
    id::Int
    name::String
    busType::String
    voltage::Float64
end

struct StdoCircuit
    id::Int
    name::String
    busFrom::StdoBus
    busTo::StdoBus
    impedance::Float64
end

struct StdoLoad
    id::Int
    name::String
    load2bus::StdoBus
    power::Float64
end

struct StdoGenerator
    id::Int
    name::String
    gen2bus::StdoBus
    power::Float64
end

struct StdoStudy
    buses::Vector{StdoBus}
    circuits::Vector{StdoCircuit}
    loads::Vector{StdoLoad}
    generators::Vector{StdoGenerator}
end