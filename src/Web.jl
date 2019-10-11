module Web
using HTTP

"""
This handles the http get requests
The url is expected to be of the form /api/{table}
and it will return the contents of the table, after the roles have been applied
in the form the accept header has asked for
"""
function handle_get(http::HTTP.Stream)
    local message = http.message
    println("get")
    while !eof(http)
        println("body data: ", String(readavailable(http)))
    end
    startwrite(http)
    write(http, "stream from get\n")
    write(http, "more response body")
end

function handle_post(http::HTTP.Stream)
    local message = http.message
    while !eof(http)
        println("body data: ", String(readavailable(http)))
    end
    startwrite(http)
    write(http, "stream from post\n")
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
    println("roles: $roles")
    task_local_storage("roles", roles) do
        handle_get(http)
    end
end
#
# const security = HTTP.Router()
# HTTP.@register(security, "GET", "/", auth_handler)

println("starting")
HTTP.serve(auth_handler; stream=true)
println("running")

end
