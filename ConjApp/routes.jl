using Genie.Router
using ConjApp

route("/") do
  serve_static_file("welcome.html")
end

route( "/run", ConjApp.submit_job, method = POST )
# route( "/reset", doreset, method = POST )
route( "/progress", ConjApp.getprogress, method = POST )
route( "/output", ConjApp.getoutput, method = POST )

