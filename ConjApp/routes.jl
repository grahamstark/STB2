using Genie.Router

route("/") do
  serve_static_file("welcome.html")
end

route( "/run", dorun, method = POST )
route( "/reset", doreset, method = POST )
route( "/progress", getprogress, method = POST )
route( "/output", getoutput, method = POST )

