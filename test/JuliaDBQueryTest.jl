using JuliaDBQuery
using Test


const predicate_test = """{
    home:{
        $eq:"gore"
    },
    age:{
        $gt:25,
        $lt:45
    },
    $or:[
        {
            job:{
                $eq:"programmer"
            }
        }, {
            retired:{
                $eq:true
            }
        }
    ]
}"""

@testset "predicate tests" begin

end




#basic queries
const basic_query = """{
    sa2_code:100100
}"""

#pipeline queries
const pipeline_query = """
[
    {
        $filter: {
            date:{
                $gte:"2018-1-1",
                $lt:"2019-1-1"
            }
        }
    },{
        $group: {
            sa2_code:{
                min_count: {
                    $min:"count"
                }
            }
        }
    },{
        $filter: {
            min_count:{
                $lte:100
            }
        }
    },{
        $fields:["sa2_code"]
    }
]
"""


@testset "JuliaDBQuery.jl" begin
    @test table = JuliaDBQuery.load("")
    @test basic_results = JuliaDBQuery.run_pipeline_query(table, basic_query)
    @test pipeline_results = JuliaDBQuery.run_pipeline_query(table, pipeline_query)
end
