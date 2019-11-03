module Web
using HTTP
using JuliaDB
include("./JuliaDBQuery.jl")
using .JuliaDBQuery
using CSVFiles

function write_row(http, row)
    write(http,join(row,","))
    write(http,"\n")
end

function write_chunk(http, chunk)
    local rows = chunk |> collect
    foreach(row -> write_row(http, row), rows)
end

const BASE_PATH = r"/api/v1/.*"
const API_PATH = r"/api/v1/([a-zA-Z0-9_]+)"

"""
This handles the http get requests
The url is expected to be of the form /api/{table}
and it will return the contents of the table, after the roles have been applied
in the form the accept header has asked for
"""
function handle_get(http::HTTP.Stream)
    local message = http.message
    local path = match(API_PATH,http.message.target)
    if isnothing(path)
        local path = match(BASE_PATH,http.message.target)
        startwrite(http)
        if isnothing(path)
            write(http,"our api urls are of the form /api/v1/{table}\n")
        else
            write(http,"nice try, but sadly, we check our API paths for that kind of shenanigans\n")
        end
        closewrite(http)
        return
    end
    t = JuliaDBQuery.load_table(path[1])
    startwrite(http)
    write_row(http, colnames(t)) # write header
    foreach(chunk -> write_chunk(http, chunk),t.chunks)
    closewrite(http)
end


function handle_post(http::HTTP.Stream)
    local message = http.message
    local query = join(readlines(http))
    println("QUERY:" , query)
    local path = match(API_PATH,http.message.target)
    if isnothing(path)
        local path = match(BASE_PATH,http.message.target)
        startwrite(http)
        if isnothing(path)
            write(http,"our api urls are of the form /api/v1/{table}\n")
        else
            write(http,"nice try, but sadly, we check our API paths for that kind of shenanigans\n")
        end
        closewrite(http)
        return
    end
    local table = JuliaDBQuery.load_table(path[1])
    local result = JuliaDBQuery.run_basic_query(table,query)
    startwrite(http)
    write_row(http, colnames(result)) # write header
    foreach(chunk -> write_chunk(http, chunk),result.chunks)
    closewrite(http)
end

"""
since this is AFTER the proxy, we can just ask for roles in the header
the role list is space seperated
"user admin" means someone is both a user and an admin
"""
function auth_handler(http::HTTP.Stream)
    @show http.message
    @show http.message.target
    @show http.message.method
    local roles = split(HTTP.header(http, "roles", "anonymous"))
    local token = HTTP.header(http, "Authorization", "")
    if token != "qWohIIuX5Oc0DxPHUAyX"
        HTTP.setstatus(http, 404)
        startwrite(http)
        write(http, "Bad auth, contact data ventures for a token\n")
        closewrite(http)
        return
    end
    println("roles: $roles")
    task_local_storage("roles", roles) do
        if http.message.method=="POST"
            handle_post(http)
        else
            handle_get(http)
        end
    end
end

function start()
    println("starting")
    HTTP.serve(auth_handler,"0.0.0.0"; stream=true)
end

end
