push!(LOAD_PATH, joinpath(pwd(),"src"))
import ShortTermDistributionOperation as STDO

import Pkg
Pkg.instantiate()

STDO.main("D:\\projeto_modelagem_puc\\cases\\feeder123\\data_base")