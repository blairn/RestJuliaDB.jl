using Distributed
using JSON3

addprocs()

@everywhere include("./src/JuliaDBQuery.jl")
@everywhere using .JuliaDBQuery
@everywhere using Dates
@everywhere include("./src/Web.jl")
@everywhere using .Web
@everywhere using OnlineStats
@everywhere using JuliaDB

data = JuliaDBQuery.load_table("pop")
sa2_filter = """{ "sa2_code":{ "\$gt" : 100100, "\$lt":100300}}"""
q = JSON3.read(sa2_filter, Dict)
a,b = JuliaDBQuery.predicate_for(q)
@time filter(a, data, select=b)

Web.start()
