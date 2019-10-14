module JuliaDBQuery
using JuliaDB
using OnlineStats

const table_cache = Dict()

"loads a table from disk, if it hasn't already loaded, returns the table either way"
function load_table(table_name)
    return get!(table_cache, table_name) do
        load(table_name)
    end
end

function run_basic_query(table, q::String)
    run_basic_query(table,JSON2.parse(q))
end

function run_pipeline_query(table, q::String)
    run_pipeline_query(table, JSON2.parse(q))
end

function run_basic_query(table, q::Dict{String,Any})
    _filter(table, q)
end

function run_pipeline_query(table, q::Array{Dict{String, Any}})
    # we do this first, so that we can work on any parsing errors before we start processing
    # yeah, it isn't the julia way, but it is better this way ;).

    foldl(q; init=table) do step
        # each step is a Dict, with a key describing the operation
        local ks = keys(step)
        local vs = values(step)

        if length(ks) != 1
            throw(ArgumentError("each step in a pipline must have only one instruction \n" * JSON2.write(step)))
        end
        local k = ks[1]
        local v = vs[1]
        if k == "$filter"
            filter(table,v)
        elseif k == "$group"
            group(table,v)
        elseif k == "$fields"
            fields(table,v)
        else k == "$distinct"
            distinct(table,v)
        end
    end
    reduce(pipeline_steps, table)
end

# due to name collisions, I've called anything which is a method for handling
# query fragments, with an _ on the front eg, _filter, is the method which handles
# $filter fragments.

"""
this takes a spec like
{
    home:{
        \$eq:"gore"
    },
    age:{
        \$gt:25,
        \$lt:45
    },
    \$or:[
        {
            job:{
                \$eq:"programmer"
            }
        }, {
            retired:{
                \$eq:true
            }
        }
    ]
}
and returns a function which you can apply to a row, giving a true or false
"""
function predicate_for(q::Dict)
    local symbols = Set{Symbol}()
    functions = map(keys(q) |> collect) do k
        local v = q[k]
        # this if, returns the function for the current branch in the json
        if k == "\$and"
            local fs_with_symbols = map(predicate_for,v) |> collect
            local fs = getindex.(fs_with_symbols,1)
            local symbol_tuples = getindex.(fs_with_symbols,2)
            symbols = symbols ∪ reduce(∪, symbol_tuples)
            function(r) return all(map(f -> f(r),fs)) end
        elseif k == "\$or"
            local fs_with_symbols = map(predicate_for,v) |> collect
            local fs = getindex.(fs_with_symbols,1)
            local symbol_tuples = getindex.(fs_with_symbols,2)
            symbols = reduce(∪, symbol_tuples; init=symbols)
            function(r) return any(map(f -> f(r),fs)) end
        else
            # we need to know the fields which we need to select on
            # so add it to the list
            local field = Symbol(k)
            push!(symbols, field)

            # make a function for each predicate
            local fs = map(keys(v) |> collect) do vk
                local vv = v[vk]
                lookup_predicate(vk,field,vv)
            end
            # if the row handles all of the predicates, then the row should return true
            function(r) return all(map(f -> f(r),fs)) end
        end
    end
    # if the row handles all of the predicates, then the row should return true
    local symbols_tuple = ((symbols |> collect)...,)
    return function(r) all(map(f -> f(r),functions)) end, symbols_tuple
end

function lookup_predicate(name, field, q)
    # if name == "$and"
    #     _and(q)
    # elseif name == "$or"
    #     _or(q)
    return if name == "\$not"
        _not(field, q)
    elseif name == "\$gt"
        _gt(field, q)
    elseif name == "\$gte"
        _gte(field, q)
    elseif name == "\$lt"
        _lt(field, q)
    elseif name == "\$lte"
        _lte(field, q)
    elseif name == "\$eq"
        _eq(field, q)
    elseif name == "\$in"
        _in(field, q)
    end
end

#
# function _or(q)
#     return x -> x[field] ∈ q
# end

function _eq(field, q)
    return x -> x[field] == q
end


function _not(field, q)
    return x -> !x[field]
end

function _gt(field, q)
    return x -> x[field] > q
end

function _gte(field, q)
    return x -> x[field] >= q
end

function _lt(field, q)
    return x -> x[field] < q
end

function _lte(field, q)
    return x -> x[field] <= q
end

function _in(field, q::Array)
    return x -> x[field] ∈ q
end

function _filter(table, q::Dict)
    local f, symbols = predicate_for(q)
    filter(f, table ; select=symbols)
end

function _group(table, q::Dict)
end

function _fields(table, q::Dict)
end

function _min(table, q::Dict)
end

function _max(table, q::Dict)
end

function _avg(table, q::Dict)
end

function _sum(table, q::Dict)
end

function _distinct(table, q::Dict)
end

function _js(table,q::Dict)
end

function _julia(table,q::Dict)
end

function _r(table,q::Dict)
end


end
