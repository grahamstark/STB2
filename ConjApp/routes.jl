using Genie.Router
using ConjApp

route("/") do
  serve_static_file("welcome.html")
end

route( "/run", submit_job, method = POST )
# route( "/reset", doreset, method = POST )
route( "/progress", getprogress, method = POST )
route( "/output", getoutput, method = POST )

