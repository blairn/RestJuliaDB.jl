module RestJuliaDB

include("./Loader.jl")
using .Loader

include("./Web.jl")
using .Web

greet() = print("Hello World!")
export greet

test()

end # module
