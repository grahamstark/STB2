module ConjApp
# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)
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

#
# hack : AllOutput is not actually needed but is included in some shared libs
#
struct AllOutput
  results
  summary
  gain_lose
  examples  
end

#
#  constants used in html lib
#
const MR_UP_GOOD = [1,0,0,0,0,0,0,-1,-1]
const COST_UP_GOOD = [1,1,1,1,-1,-1,-1,-1,-1,-1,-1]
  
include( "../../lib/static_texts.jl")
include( "../../lib/table_libs.jl")
include( "../../lib/examples.jl")
include( "../../lib/text_html_libs.jl")

const DEFAULT_FACTORS = Factors{Float64}()
const CACHED_RESULTS = Dict{UInt,Any}()


"""
Save output to the cache
"""
function cacheout(facs::Factors,allo::NamedTuple)
	CACHED_RESULTS[riskyhash(facs)] = allo
end

function make_and_cache_base_results()
  settings = Conjoint.make_default_settings()
  obs = Observable( Progress(settings.uuid, "",0,0,0,0))
  tot = 0
  of = on(obs) do p
    tot += p.step
  end
  results = Conjoint.doonerun( DEFAULT_FACTORS, obs; settings=settings )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html_conjoint( ( results..., examples=exres  ))  
  cacheout( DEFAULT_FACTORS, output )
end 

const DEFAULT_RESULTS = make_and_cache_base_results()

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


function getoutput( facs::Factors )::Union{Nothing,NamedTuple}
	
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
      GenieSession.set!( session, :facs, facs )
  end
  return facs
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
return output for the 
"""
function getoutput() 
    facs = factorsfromsession()
    @info "getoutput facs=" facs
    u = riskyhash(facs)
    output = ""
    if haskey(CACHED_RESULTS, u )
      # u = riskyhash( DEFAULT_FACTORS )
      output = CACHED_RESULTS[u]
    end
    
    return (:output=>output) |> json
end


"""
Execute a run from the queue.
"""
function dorun( session::Session, facs :: Factors )
  settings = Conjoint.make_default_settings()  
  @info "dorun entered facs are " facs
  obs = Observable( Progress(settings.uuid, "",0,0,0,0))
  tot = 0
  of = on(obs) do p
  tot += p.step
  @info "monitor tot=$tot p = $(p)"
    GenieSession.set!( session, :progress, (progress=p,total=tot))
  end  
  results = Conjoint.doonerun( facs, obs; settings = settings )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html_conjoint( ( results..., examples=exres  ))  
  cacheout( facs, output )
end

function submit_job(
    session :: GenieSession.Session )
    facs = facsfrompayload( rawpayload() )
    u = riskyhash(facs)
    if ! haskey( CACHED_RESULTS, u )    
      put!( IN_QUEUE, FactorAndSession( facs, session ))
    end
end

"""

"""
function grab_runs_from_queue()
  while true
    params = take!( IN_QUEUE )
    dorun( params.session, params.facs ) 
  end
end

function main()
  Genie.genie(; context = @__MODULE__)
end

#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
  @info "starting handler $i" 
  errormonitor(@async grab_runs_from_queue())
end

end # module
