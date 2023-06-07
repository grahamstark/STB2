module ConjApp

using Genie
using Conjoint
using GenieSession 
using GenieSessionFileSession
import Genie.Renderer.Json: json

using DataFrames
using Formatting
using JSON3
using Logging, LoggingExtras
using Markdown
using Observables
using PovertyAndInequalityMeasures
using StatsBase
using StructTypes
using UUIDs

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils

const up = Genie.up
export up

include( "../../lib/static_texts.jl")
include( "../../lib/table_libs.jl")
include( "../../lib/examples.jl")
include( "../../lib/definitions.jl" )
include( "../../lib/text_html_libs.jl")
include( "../../lib/base_and_cache.jl")

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
  facs = paramsfrompayload( rawpayload() )
  @info "dorun entered pars are " pars
  GenieSession.set!( sess, :pars, pars )
  results = Conjoint.do_one_run(facs)
  
  output = results_to_html( results )
  (:output=>output) |> json
end

end
