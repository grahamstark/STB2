module ConjApp
# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)
using Genie
using Genie.Requests # rawpayload
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
  getoutput,
  reset,
  submit_job

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


struct NonVariableFacts 
    level :: String 
    tax  :: String 
    funding :: String 
    eligibility :: String 
    means_testing :: String 
    citizenship :: String 
    
    NonVariableFacts(facs::Factors) = new(
      facs.level,
      facs.tax,
      facs.funding,
      facs.eligibility,
      facs.means_testing,
      facs.citizenship
    )
    
end

const CACHED_RESULTS = Dict{NonVariableFacts,Any}()

"""
Save output to the cache
"""
function save_output_to_cache(facs::Factors,allo::NamedTuple)
  CACHED_RESULTS[NonVariableFacts(facs)] = allo
end

"""

"""
function get_output_from_cache() # removed bacause json doesn't like ::Union{NamedTuple,String}
    facs = factorsfromsession()
    @info "getoutput facs=" facs
    nvc = NonVariableFacts( facs )
    @info "getoutput; nvc = " nvc 
    @info "getoutput keys are " keys(CACHED_RESULTS)
    if haskey(CACHED_RESULTS, nvc )
      # u = riskyhash( DEFAULT_FACTORS )
      @info "got results from CACHED_RESULTS "
      output = CACHED_RESULTS[nvc]
      return ( response=output_ready, data=output) |> json
    end
    return( response=bad_request, data="" )  
end 



function make_and_cache_base_results()
  settings = Conjoint.make_default_settings()
  obs = Observable( Progress(settings.uuid, "",0,0,0,0))
  tot = 0
  of = on(obs) do p
    tot += p.step
  end
  results = Conjoint.doonerun!( DEFAULT_FACTORS, obs; settings=settings )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html_conjoint( ( results..., examples=exres  ))  
  save_output_to_cache( DEFAULT_FACTORS, output )
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

@enum Responses output_ready has_progress load_params bad_request

"""
TODO
"""
function doreset() 
    sess = GenieSession.session()
    facs = deepcopy( DEFAULT_FACTORS )
    GenieSession.set!( sess, :facs, facs )
    ( response=load_params, data=facs ) |> json
end

"""

"""
function getprogress() 
    sess = GenieSession.session()
    @info "getprogress entered"
    progress = ( phase="missing", completed = 0, size=0 )
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress"
        progress = GenieSession.get( sess, :progress )
    else
        @info "getprogress: no progress"
        GenieSession.set!( sess, :progress, progress )
    end
    ( response=has_progress, data=progress) |> json
end

"""
return output for the 
"""
function getoutput() 
    return get_output_from_cache()|> json 
end


"""
Execute a run from the queue.
"""
function dorun( session::Session, facs :: Factors )
  settings = Conjoint.make_default_settings()  
  @info "dorun entered facs are " facs
  obs = Observable( Progress(settings.uuid, "",0,0,0,0))
  completed = 0
  of = on(obs) do p
    completed += p.step
    @info "monitor completed=$completed p = $(p)"
    GenieSession.set!( session, :progress, (phase=p.phase, completed = completed, size=p.size))
  end  
  results = Conjoint.doonerun!( facs, obs; settings = settings )  
  exres = calc_examples( results.sys1, results.sys2, results.settings )    
  output = results_to_html_conjoint( ( results..., examples=exres  ))  
  GenieSession.set!( :facs, facs ) # save again since poverty, etc. is overwritten in doonerun!
  save_output_to_cache( facs, output )
end

function submit_job()
    session = GenieSession.session() #  :: GenieSession.Session 
    facs = facsfrompayload( rawpayload() )
    GenieSession.set!( session, :facs, facs )
    
    @info "submit_job facs=" facs
    if ! haskey( CACHED_RESULTS, NonVariableFacts(facs))    
      put!( IN_QUEUE, FactorAndSession( facs, session ))
      qp = ( phase="queued" ,completed=0, size=0 )
      GenieSession.set!( session, :progress, qp )
      return ( response=has_progress, data=qp ) |> json
    else
      GenieSession.set!( session, :progress, (phase="end",completed=0, size=0 ))
      # return ( response=output_ready, data=get_output_from_cache()) |> json      
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
