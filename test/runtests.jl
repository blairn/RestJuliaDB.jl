using RestJuliaDB
using Test
using JSON3

const predicate_test = """{
    "home":{
        "\$eq":"gore"
    },
    "age":{
        "\$gt":25,
        "\$lt":45
    },
    "\$or":[
        {
            "job":{
                "\$eq":"programmer"
            }
        }, {
            "retired":{
                "\$eq":true
            }
        }
    ]
}"""

const goodrow1 = Dict([:home => "gore", :age => 30, :retired => true, :job => "manager"])
const goodrow2 = Dict([:home => "gore", :age => 30, :retired => false, :job => "programmer"])
const badrow1 = Dict([:home => "napier", :age => 30, :retired => true, :job => "manager"]) # wrong home
const badrow2 = Dict([:home => "gore", :age => 60, :retired => true, :job => "manager"]) # wrong age
const badrow3 = Dict([:home => "gore", :age => 30, :retired => false, :job => "manager"]) # not retired and job is wrong

@testset "predicate test" begin
    local pt = JSON3.read(predicate_test, Dict)
    local pred,fields = JuliaDBQuery.predicate_for(pt)
    @test pred(goodrow1) == true
    @test pred(goodrow2) == true
    @test pred(badrow1) == false
    @test pred(badrow2) == false
    @test pred(badrow3) == false
    @test fields ∋ :home
    @test fields ∋ :age
    @test fields ∋ :retired
    @test fields ∋ :job
    @test length(fields) == 4
end


# const sa_filter = """
# {
#     "sa2_code": {
#         "\$eq": 100100
#     },
#     "hour": {
#         "\$eq": 1
#     }
# }
# """

const sa_filter = """
{
    "sa2_code": {
        "\$eq": 100100
    },
    "hour": {
        "\$eq": 12
    }
}
"""


@testset "database test" begin
    local q = JSON3.read(sa_filter, Dict)
    local data = @show JuliaDBQuery.load_table("data")
    local results = @show JuliaDBQuery.run_basic_query(data, q)
    @test length(results) != 0
end
