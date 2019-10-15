module RestJuliaDB
using Distributed
addprocs()

@everywhere include("./src/JuliaDBQuery.jl")
@everywhere using .JuliaDBQuery

@everywhere include("./src/Web.jl")
@everywhere using .Web
@everywhere using OnlineStats
@everywhere using JuliaDB

Web.start()



end
