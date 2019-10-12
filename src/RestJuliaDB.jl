module RestJuliaDB

# include("./Loader.jl")
# using .Loader
#
# include("./Web.jl")
# using .Web

include("./JuliaDBQuery.jl")
using .JuliaDBQuery
export JuliaDBQuery

greet() = print("Hello World!")
export greet

# test()

end # module
