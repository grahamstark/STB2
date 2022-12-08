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

route( "/run", runt, method = POST )
route( "/save", savet, method = POST )
route( "/reset", resett, method = POST )
route( "/progress", progress, method = POST )
route( "/output", output, method = POST )
route( "/params", params, method = POST)

route( "/uprate/:v", method = POST) do
  v = parse(Float64, payload(:v))
  uprate( v )
end

route("/addtax/:n", method = POST) do 
  n::Int = parse(Int, payload(:n))
  addtax( n )
end

route("/defaults", method = POST) do 
  defaults()
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

route( "/submit/", method = POST ) do 
  # req = Requests.getrequest()
  jp = jsonpayload()
  rp = rawpayload()
  @show jp
  @show rp
  pars = handlesubmit( rp ) 
end

route("/") do
  (:message => "Hi there!") |> json
end
