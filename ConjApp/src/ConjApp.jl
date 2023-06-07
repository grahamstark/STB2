module ConjApp

import Genie.Renderer.Json: json
using Genie
using Conjoint

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

function paramsfrompayload( payload )
  @show payload
  pars = JSON3.read( payload, Conjoint.Factors{Float64} )
  return pars
end

function run( session :: GenieSession.Session )
  sess = GenieSession.session()
  pars = paramsfrompayload( rawpayload() )
  @info "dorun entered pars are " pars
  GenieSession.set!( sess, :pars, pars )
  results = Conjoint.do_one_run()
  output = results_to_html( results )
  (:output=>output) |> json
end

end
