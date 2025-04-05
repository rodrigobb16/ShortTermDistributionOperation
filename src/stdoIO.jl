function StdoLoadBuses(buses_filepath::String)
    
    return buses
end

function StdoLoadCircuits(circuits_filepath::String)
    
    return circuits
end

function StdoLoadLoads(loads_filepath::String)
    
    return loads
end

function StdoLoadGenerators(generators_filepath::String)
    
    return generators
end

function StdoLoadStudy(casepath::String)

    buses = StdoLoadBuses(joinpath(casepath, "buses.csv"))
    circuits = StdoLoadCircuits(joinpath(casepath, "circuits.csv"))
    loads = StdoLoadLoads(joinpath(casepath, "loads.csv"))
    generators = StdoLoadGenerators(joinpath(casepath, "generators.csv"))

    study = StdoStudy(
        buses = buses,
        circuits = circuits,
        loads = loads,
        generators = generators
    )
    
    return study
end