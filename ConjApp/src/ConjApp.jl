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
export dorun,
  progress,
  output,
  reset  
struct AllOutput
  results
  summary
  gain_lose
  examples
end

function make_base_results()
end

include( "../../lib/static_texts.jl")
include( "../../lib/table_libs.jl")
include( "../../lib/examples.jl")
# include( "../../lib/definitions.jl" )
include( "../../lib/text_html_libs.jl")
# include( "../../lib/base_and_cache.jl")

const DEFAULT_FACTORS = Factors{Float64}
const DEFAULT_RESULTS = "" #make_base_results()
# const DEFAULT_TEXT_OUTPUT = results_to_html( DEFAULT_RESULTS, DEFAULT_RESULTS )
const CACHED_RESULTS = Dict{UInt,AllOutput}()
logger = FileLogger("log/conjapp_log.txt")
global_logger(logger)
LogLevel( Logging.Debug )


# ==== Queue stuff
struct FactorAndSession{T}
	facs   :: Factors{T}
	session  :: GenieSession.Session
end

# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 4

const QSIZE = 32

IN_QUEUE = Channel{FactorAndSession}(QSIZE)

const MR_UP_GOOD = [1,0,0,0,0,0,0,-1,-1]
const COST_UP_GOOD = [1,1,1,1,-1,-1,-1,-1,-1,-1,-1]


function cacheout(simp::Factors,allo::AllOutput)
	CACHED_RESULTS[riskyhash(simp)] = allo
end

function getout( simp::Factors )::Union{Nothing,AllOutput}
	u = riskyhash(simp)
	if ! haskey(CACHED_RESULTS, u )
		return nothing
	end
	CACHED_RESULTS[u]
end

function results_to_html( 
  results      :: NamedTuple ) :: NamedTuple
  gain_lose = gain_lose_table( results.summary.gain_lose )
  gains_by_decile = results.summary.deciles[2][:,4] -
        results.summary.deciles[1][:,4]
  @info "gains_by_decile = $gains_by_decile"
  costs = costs_table( 
      results.summary.income_summary[1],
      results.summary.income_summary[2])
  overall_costs = overall_cost( 
      results.summary.income_summary[1],
      results.summary.income_summary[2])
  mrs = mr_table(
      results.summary.metrs[1], 
      results.summary.metrs[2] )       
  poverty = pov_table(
      results.summary.poverty[1],
      results.summary.poverty[2],
      results.summary.child_poverty[1],
      results.summary.child_poverty[2])
  inequality = ineq_table(
      results.summary.inequality[1],
      results.summary.inequality[2])
  lorenz_pre = results.summary.deciles[1][:,2]
  lorenz_post = results.summary.deciles[2][:,2]
  example_text = make_examples( results.examples )
  big_costs = costs_frame_to_table( 
      detailed_cost_dataframe( 
          results.summary.income_summary[1],
          results.summary.income_summary[2] )) 
  popularity = "<table><tr><td>POPTABLE GOES HERE</td></tr></table>"
  outt = ( 
      phase = "end", 
      popularity = popularity_table,
      gain_lose = gain_lose, 
      gains_by_decile = gains_by_decile,
      costs = costs, 
      overall_costs = overall_costs,
      mrs = mrs, 
      poverty=poverty, 
      inequality=inequality, 
      lorenz_pre=lorenz_pre, 
      lorenz_post=lorenz_post,
      examples = example_text,
      big_costs_table = big_costs,
      endnotes = Markdown.html( ENDNOTES ))
  return outt
end

# cacheout(DEFAULT_SIMPLE_PARAMS,DEFAULT_RESULTS)

function main()
  Genie.genie(; context = @__MODULE__)
end

function paramsfrompayload( payload )
  @show payload
  pars = JSON3.read( payload, Conjoint.Factors{Float64} )
  return pars
end

function factorsfromsession()::Factors
  session = GenieSession.session()
  if( GenieSession.isset( session, :facs ))
      facs = GenieSession.get( session, :facs )
  else
      facs = deepcopy( DEFAULT_FACTORS )
      GenieSession.set!( session, :facs, pars )
  end
  return pars
end

function reset()

end

function output()

end

function dorun( session :: GenieSession.Session )
  sess = GenieSession.session()
  facs = paramsfrompayload( rawpayload() )
  @info "dorun entered pars are " facs
  GenieSession.set!( sess, :facs, facs )
  results = Conjoint.doonerun(facs)
  output = results_to_html( DEFAULT_RESULTS, results )
  (:output=>output) |> json
end

end
