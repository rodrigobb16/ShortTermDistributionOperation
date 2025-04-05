push!(LOAD_PATH, joinpath(pwd(),"src"))
import ShortTermDistributionOperation as STDO

import Pkg
Pkg.instantiate()

STDO.main(ARGS[1])