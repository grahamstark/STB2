using Genie.Router, Genie.Requests

#
# see: https://genieframework.github.io/Genie.jl/dev/guides/Simple_API_backend.html
#

using Genie
import Genie.Renderer.Json: json
#=
const config = Settings(
  server_port                     = 8005,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true,
)
=# 

route( "/run", dorun, method = POST )
route( "/save", dosave, method = POST )
route( "/reset", doreset, method = POST )
route( "/progress", getprogress, method = POST )
route( "/output", getoutput, method = POST )
route( "/params", getparams, method = POST)
route( "/defaults", getdefaults, method = POST)

route( "/uprate/:v", method = POST) do
  v = parse(Float64, payload(:v))
  douprate( v )
end

route("/addtax/:n", method = POST) do 
  n::Int = parse(Int, payload(:n))
  addtax( n )
end

route("/deltax/:n", method = POST ) do
  n::Int = parse(Int, payload(:n))
  deltax( n )
end

route("/addni/:n", method = POST ) do 
  n::Int = parse(Int, payload(:n))
  addni( n )
end

route("/delni/:n", method = POST ) do 
  n::Int = parse(Int,  payload(:n))
  delni( n )
end

route("/") do
  (:message => "Welcome to Scotben 2022/3.") |> json
end
