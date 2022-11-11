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

route( "/run", runt )
route( "/save", savet )
route( "/reset", resett )
route( "/progress", progress )
route( "/output", output )

route( "/uprate/:v") do
  v = parse(Float64, payload(:v))
  uprate( v )
end

route("/addtax/:n") do 
  n::Int = parse(Int, payload(:n))
  addtax( n )
end


route("/deltax/:n" ) do
  n::Int = parse(Int, payload(:n))
  deltax( n )
end

route("/addni/:n" ) do 
  n::Int = parse(Int, payload(:n))
  addni( n )
end

route("/delni/:n" ) do 
  n::Int = parse(Int,  payload(:n))
  delni( n )
end

route( "/submit/" ) do 
  req = Requests.getrequest()
  pars = handlesubmit( req ) 
end

route("/") do
  (:message => "Hi there!") |> json
end
