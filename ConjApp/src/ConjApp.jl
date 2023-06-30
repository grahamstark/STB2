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
using .HealthRegressions
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

# const DEFAULT_FACTORS = Factors{Float64}()

@enum Responses output_ready has_progress load_params bad_request

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

function make_default_settings() :: Settings
  settings = Settings()
  settings.do_marginal_rates = false
  settings.requested_threads = 4
  return settings
end


const DEFAULT_SETTINGS = make_default_settings()

"""
FIXME this shouldn't be here.
"""
function load_system(; scotland = false )::TaxBenefitSystem
    sys = load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2022-23.jl"))
    if ! scotland 
        load_file!( sys, joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2022-23_ruk.jl"))
    end
    weeklyise!( sys )
    return sys
end


"""

"""
function map_features!( tb :: TaxBenefitSystem, facs :: Factors )
  tb.ubi.abolished = false
  tb.ubi.mt_bens_treatment = ub_as_is # ub_keep_housing

  if facs.level ==
      "Child - £0; Adult - £63; Pensioner - £190"
      tb.ubi.adult_amount = 63
      tb.ubi.child_amount = 0
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £41; Adult - £63; Pensioner - £190"
      tb.ubi.adult_amount = 63
      tb.ubi.child_amount = 41
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £0; Adult - £145; Pensioner - £190"
      tb.ubi.adult_amount = 145
      tb.ubi.child_amount = 0
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £41; Adult - £145; Pensioner - £190"
      tb.ubi.adult_amount = 145
      tb.ubi.child_amount = 41
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £63; Adult - £145; Pensioner - £190"
      tb.ubi.adult_amount = 145
      tb.ubi.child_amount = 63
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £63; Adult - £190; Pensioner - £190"
      tb.ubi.adult_amount = 190
      tb.ubi.child_amount = 63
      tb.ubi.universal_pension = 190
  elseif facs.level ==
      "Child - £95; Adult - £190; Pensioner - £230"
      tb.ubi.adult_amount = 190
      tb.ubi.child_amount = 95
      tb.ubi.universal_pension = 230
  elseif facs.level ==
      "Child - £41; Adult - £230; Pensioner - £230"
      tb.ubi.adult_amount = 230
      tb.ubi.child_amount = 41
      tb.ubi.universal_pension = 230
  elseif facs.level ==
      "Child - £95; Adult - £230; Pensioner - £230"
      tb.ubi.adult_amount = 230
      tb.ubi.child_amount = 95
      tb.ubi.universal_pension = 230
  else
      @assert false "non mapped facs.level: $(facs.level)"
  end 

  if facs.tax == 
      "Basic rate - 20%; Higher rate - 40%; Additional rate - 45%"
      tb.it.non_savings_rates = [0.2, 0.4, 0.45 ]
  elseif facs.tax == 
      "Basic rate - 23%; Higher rate - 43%; Additional rate - 48%"
      tb.it.non_savings_rates = [0.23, 0.43, 0.48 ]    
  elseif facs.tax == 
      "Basic rate - 30%; Higher rate - 50%; Additional rate - 60%"
      tb.it.non_savings_rates = [0.3, 0.5, 0.6 ]    
  elseif facs.tax == 
      "Basic rate - 40%; Higher rate - 60%; Additional rate - 70%"
      tb.it.non_savings_rates = [0.4, 0.6, 0.7 ]    
  elseif facs.tax == 
      "Basic rate - 48%; Higher rate - 68%; Additional rate - 78%"
      tb.it.non_savings_rates = [0.48, 0.68, 0.78 ]    
  elseif facs.tax == 
      "Basic rate - 50%; Higher rate - 70%; Additional rate - 80%"
      tb.it.non_savings_rates = [0.5, 0.7, 0.8 ]    
  elseif facs.tax == 
      "Basic rate - 65%; Higher rate - 85%; Additional rate - 95%"
      tb.it.non_savings_rates = [0.65, 0.85, 0.95 ]    
  else
      @assert false "non mapped facs.tax: $(facs.tax)"
  end

  if facs.funding ==
      "Removal of income tax-free personal allowance"
      tb.it.personal_allowance = 0.0
  elseif facs.funding in [
      "Increased government borrowing",
      "Corporation tax increase",
      "Tax for businesses based on carbon emissions",
      "Tax for individuals based on carbon emissions",
      "Tax on wealth",
      "VAT increase"]
      # TODO nothing yet
  else
      @assert false "non mapped facs.funding: $(facs.funding)"
  end
  tb.ubi.entitlement = 
      if facs.eligibility == "People in and out of work are entitled"
          ub_ent_all
      elseif facs.eligibility == "Everyone is entitled but people of working age who are not disabled are required to look for work"
          ub_ent_all_but_non_jobseekers
      elseif facs.eligibility == "Only people in work are entitled"
          ub_ent_only_in_work
      elseif facs.eligibility == "Only people out of work are entitled"
          ub_ent_only_not_in_work
      else 
          @assert false "failed to map |$(facs.eligibility)|"
      end
  
  if facs.means_testing == "People with any or no amount of income are entitled to the full benefit"
      tb.ubi.income_limit = -1.0
  elseif facs.means_testing == "Only those with incomes less than £20k are entitled to the full benefit"
      tb.ubi.income_limit = 20_000.0/WEEKS_PER_YEAR
  elseif facs.means_testing == "Only those with incomes less than £50k are entitled to the full benefit"
      tb.ubi.income_limit = 50_000.0/WEEKS_PER_YEAR
  elseif facs.means_testing == "Only those with incomes less than £125k are entitled to the full benefit"
      tb.ubi.income_limit = 125_000.0/WEEKS_PER_YEAR
  else
      @assert false "failed to map |$(facs.means_testing)|"
  end

  ## TODO facs.citizenship

  make_ubi_pre_adjustments!( tb )
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
      @info "got results from CACHED_RESULTS " 
      output = CACHED_RESULTS[nvc]
      return ( response=output_ready, data=output)
    end
    @info "responding with bad_request" 
    return( response=bad_request, data="" )  
end 

"""
Specialised run for conjoint model.

"""
function do_one_conjoint_run!( facs :: Factors, obs :: Observable; settings = DEFAULT_SETTINGS ) :: NamedTuple
    sys1 = load_system( scotland=false ) 
    sys2 = deepcopy(sys1)
    map_features!( sys2, facs )
    sys = [sys1,sys2]
    println( "sys1 income tax\n $(sys1.it)" )
    println( "sys2 income tax\n $(sys2.it)" )
    ## , get_system( year=2019, scotland=true )]
    results = do_one_run( settings, sys, obs )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )
    summary = summarise_frames!( results, settings )
    outps_pre = create_health_indicator( 
        results.hh[1], 
        summary.deciles[1], 
        settings )
    outps_post = create_health_indicator( 
        results.hh[2], 
        summary.deciles[2], 
        settings )
    sf_pre = summarise_sf12( outps_pre, settings )
    sf_post = summarise_sf12( outps_post, settings )
    facs.mental_health = (sf_post.depressed-sf_pre.depressed)/sf_pre.depressed
    println( "sf_post.depressed=$(sf_post.depressed); sf_pre.depressed=$(sf_pre.depressed)")
    facs.poverty = summary.poverty[2].headcount - summary.poverty[1].headcount
    facs.inequality = summary.inequality[2].gini - summary.inequality[1].gini
    preferences = Dict()
    println( "do_one_conjoint_run! made facs as $facs" )
    for breakdown in keys(Conjoint.BREAKDOWNS)
        bvals = Conjoint.BREAKDOWNS[breakdown]
        for bv in bvals
            popularity = calc_conjoint_total( bv, facs )
            default_popularity = calc_conjoint_total( bv, Factors{Float64}() )
            val = ( ; popularity, default_popularity )
            preferences[bv] = val
        end
    end
    return (;facs, sys1, sys2, settings, sf_pre, sf_post, summary,preferences)
end

# const DEFAULT_RESULTS = make_and_cache_base_results()

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
  facs.means_testing = pars.means_testing
  return facs
end

function factorsfromsession()::Factors
  session = GenieSession.session()
  if( GenieSession.isset( session, :facs ))
      facs = GenieSession.get( session, :facs )
  else
      facs = Factors{Float64}()
      GenieSession.set!( session, :facs, facs )
  end
  return facs
end

"""
TODO
"""
function doreset() 
    sess = GenieSession.session()
    facs = Factors{Float64}()
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

function session_obs()::Observable
  obs = Observable( Progress(settings.uuid, "",0,0,0,0))
  completed = 0
  of = on(obs) do p
    completed += p.step
    @info "monitor completed=$completed p = $(p)"
    GenieSession.set!( session, :progress, (phase=p.phase, completed = completed, size=p.size))
  end  
  obs
end 

function screen_obs()::Observable
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(obs) do p
        completed += p.step
        @info "monitor completed=$completed p = $(p)"
    end
    obs
end

"""
Execute a run from the queue.
"""
function dorun( session::Session, facs :: Factors )
  settings = make_default_settings()  
  @info "dorun entered facs are " facs
  obs = session_obs()
  results = do_one_conjoint_run!( facs, obs; settings = settings )  
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
      return ( response=output_ready, data=get_output_from_cache()) |> json      
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

# do & save a startup run
settings = make_default_settings()  
@info "initial startup"

facs = Factors{Float64}()
obs = screen_obs()
results = do_one_conjoint_run!( facs, obs; settings = settings )  
exres = calc_examples( results.sys1, results.sys2, results.settings )    
output = results_to_html_conjoint( ( results..., examples=exres  ))  
GenieSession.set!( :facs, facs ) # save again since poverty, etc. is overwritten in doonerun!
save_output_to_cache( facs, output )

end # module