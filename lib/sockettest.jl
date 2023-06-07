using HTTP
using HTTP.WebSockets
using Observables

const PORT=9001
const URL="127.0.0.1"

function longrunthing(secs::Int)
    sleep(secs)
    rand(Int)
end
