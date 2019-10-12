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

const goodrow1 = Dict(["home" => "gore", "age" => 30, "retired" => true, "job" => "manager"])
const goodrow2 = Dict(["home" => "gore", "age" => 30, "retired" => false, "job" => "programmer"])
const badrow1 = Dict(["home" => "napier", "age" => 30, "retired" => true, "job" => "manager"]) # wrong home
const badrow2 = Dict(["home" => "gore", "age" => 60, "retired" => true, "job" => "manager"]) # wrong age
const badrow3 = Dict(["home" => "gore", "age" => 30, "retired" => false, "job" => "manager"]) # not retired and job is wrong

@testset "RestJuliaDB.jl" begin
    local pt = @show JSON3.read(predicate_test, Dict)
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
