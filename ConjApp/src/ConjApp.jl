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

include( "../../lib/static_texts.jl")
include( "../../lib/table_libs.jl")
include( "../../lib/examples.jl")
include( "../../lib/text_html_libs.jl")

const DEFAULT_FACTORS = Factors{Float64}
const CACHED_RESULTS = Dict{UInt,AllOutput}()

"""
Save output to the cache
"""
function cacheout(facs::Factors,allo::NamedTuple)
	CACHED_RESULTS[riskyhash(facs)] = allo
end

function make_base_results()
  obs = Observable( 
    Progress(settings.uuid, "",0,0,0,0))
  tot = 0
  of = on(obs) do p
    tot += p.step
  end
  results = Conjoint.doonerun( DEFAULT_FACTORS, obs )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html( ( results..., examples=exres  ))  
  cacheout( facs, output )
end 

const DEFAULT_RESULTS = make_base_results()

cacheout( DEFAULT_FACTORS, DEFAULT_RESULTS )

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

#
# This number of submissions
#
const QSIZE = 32

IN_QUEUE = Channel{FactorAndSession}(QSIZE)

const MR_UP_GOOD = [1,0,0,0,0,0,0,-1,-1]
const COST_UP_GOOD = [1,1,1,1,-1,-1,-1,-1,-1,-1,-1]


function getoutput( facs::Factors )::Union{Nothing,NamedTuple}
	u = riskyhash(facs)
	if ! haskey(CACHED_RESULTS, u )
          def = riskyhash( DEFAULT_FACTORS )
          return CACHED_RESULTS[def]
	end
	return CACHED_RESULTS[u]
end

function make_popularity_table( pop :: Number )
  v1 = format(pop*100, precision=1)
  s = "<table class='table'><tr><th>Popularity<td class='text-right; text-primary'>$v1</td></tr></table>"
  return s
end

function results_to_html_x( 
  results      :: NamedTuple ) :: NamedTuple
  # table expects a tuple
  gls = ( gainers = results.summary.gain_lose[2].gainers, 
          losers=results.summary.gain_lose[2].losers, 
          nc=results.summary.gain_lose[2].nc,
          popn = results.summary.gain_lose[2].popn )
  gain_lose = gain_lose_table( gls )
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
  popularity_table = make_popularity_table( results.popularity )
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

function facsfrompayload( payload ) :: Factors
  @show payload
  pars = JSON3.read( payload )
  facs = Conjoint.Factors{Float64}()
  facs.level = pars.level
  facs.tax = pars.tax
  facs.funding = pars.funding
  facs.eligibility = pars.eligibility
  facs.citizenship = pars.citizenship
  return facs
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


"""
TODO
"""
function doreset() 
    sess = GenieSession.session()
    facs = deepcopy( DEFAULT_FACTORS )
    GenieSession.set!( sess, :facs, facs )
    (:facs=>facs,:output=>DEFAULT_RESULTS ) |> json
end


"""

"""
function getprogress() 
    sess = GenieSession.session()
    @info "getprogress entered"
    progress = NO_PROGRESS
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress"
        progress = GenieSession.get( sess, :progress )
    else
        @info "getprogress: no progress"
        GenieSession.set!( sess, :progress, progress )
    end
    (:progress=>progress) |> json
end

"""

"""
function getoutput() 
    facs = facsfromsession()
    @info "getoutput pars="  pars
    res = getout( pars )
    @info "CACHED_RESULTS keys= " keys(CACHED_RESULTS)
    output = ""
    if ! isnothing(res)
        @info "getting cached results"
        output = results_to_html( DEFAULT_RESULTS, res )
    end
    (:output=>output) |> json
end


"""
grab run from Queue
"""
function dorun( session :: GenieSession.Session )
  sess = GenieSession.session()
  facs = facsfrompayload( rawpayload() )
  @info "dorun entered pars are " facs
  GenieSession.set!( sess, :facs, facs )
  obs = Observable(
          Progress(settings.uuid, "",0,0,0,0))
  tot = 0
  of = on(obs) do p
  tot += p.step
  @info "monitor tot=$tot p = $(p)"
          GenieSession.set!( session, :progress, (progress=p,total=tot))
  end  
  results = Conjoint.doonerun( facs, obs )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html( ( results..., examples=exres  ))  
  cacheout( facs, output )
  # (:output=>output) |> json
end

function submit_job(
    session :: GenieSession.Session, 
    facs    :: Factors )
    put!( IN_QUEUE, FactorAndSession( facs, session )
end

function calc_one()
  while true
    params = take!( IN_QUEUE )
    dorun( params.session, params.facs ) 
  end
end


function main()
  Genie.genie(; context = @__MODULE__)
end

end # module
