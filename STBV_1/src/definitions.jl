# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)

function initialise_settings()::Settings
    settings = Settings()
        # settings.uuid = BASE_UUID
    settings.means_tested_routing = modelled_phase_in
    settings.run_name="run-$(date_string())"
    settings.income_data_source = ds_frs
    settings.dump_frames = false
    settings.do_marginal_rates = true
    settings.requested_threads = 4
    return settings
end

const BASE_SETTINGS = initialise_settings()

const BIG_A = 9999999999
mutable struct SimpleParams{T}
    taxrates :: Vector{T}
    taxbands :: Vector{T}
    nirates :: Vector{T}
    nibands :: Vector{T}
    taxallowance :: T
    child_benefit :: T
    pension :: T
    scottish_child_payment :: T
    scp_age :: Int
    uc_single :: T
    uc_taper :: T
    wtc_basic :: T
    target :: Int
end
StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()

function loaddefs() :: TaxBenefitSystem 
    return load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2022-23.jl" ))
end

const DEFAULT_PARAMS ::  TaxBenefitSystem = loaddefs()

function weeklyparams() :: TaxBenefitSystem
   pars = deepcopy( DEFAULT_PARAMS )
   weeklyise!( pars )
   pars;
end

const DEFAULT_WEEKLY_PARAMS :: TaxBenefitSystem = weeklyparams()

function map_full_to_simple( sys :: TaxBenefitSystem )::SimpleParams
    return SimpleParams(
        copy(sys.it.non_savings_rates),
        copy(sys.it.non_savings_thresholds),
        copy(sys.ni.primary_class_1_rates),
        copy(sys.ni.primary_class_1_bands),
        sys.it.personal_allowance,
    	sys.nmt_bens.child_benefit.first_child,
		sys.nmt_bens.pensions.new_state_pension,
		sys.scottish_child_payment.amount,
		sys.scottish_child_payment.maximum_age,
	    sys.uc.age_25_and_over,
		sys.uc.taper,
        sys.lmt.working_tax_credit.basic,
        0 )
end

function roundm( v::T, m::T, digits=2)::T where T<:Number
    v *= m
    round(v,digits=digits)
end

function map_simple_to_full( sm :: SimpleParams ) :: TaxBenefitSystem
    sys = deepcopy( DEFAULT_PARAMS )
    sys.it.non_savings_rates = sm.taxrates
    sys.it.non_savings_thresholds = sm.taxbands

    sys.ni.primary_class_1_rates = sm.nirates
    sys.ni.primary_class_1_bands = sm.nibands
    sys.it.personal_allowance = sm.taxallowance

    p = sm.child_benefit/sys.nmt_bens.child_benefit.first_child
    sys.nmt_bens.child_benefit.first_child = sm.child_benefit
    sys.nmt_bens.child_benefit.other_children = roundm( sys.nmt_bens.other_children, p)

    p = sm.pension / sys.nmt_bens.pensions.new_state_pension
    sys.nmt_bens.pensions.new_state_pension = sm.pension
    sys.nmt_bens.pensions.cat_a  = roundm( sys.nmt_bens.pensions.cat_a, p )
    sys.nmt_bens.pensions.cat_b  = roundm( sys.nmt_bens.pensions.cat_b, p )
    sys.nmt_bens.pensions.cat_d  = roundm( sys.nmt_bens.pensions.cat_d, p )
    sys.nmt_bens.pensions.cat_b_survivor  = roundm( sys.nmt_bens.pensions.cat_b_survivor, p )

    sys.scottish_child_payment.amount = sm.scottish_child_payment
    sys.scottish_child_payment.maximum_age = sm.scp_age

    sys.uc.taper = sm.uc_taper
    p = sm.uc_single/sys.uc.age_25_and_over
    sys.uc.age_25_and_over = sm.uc_single
    sys.uc.threshold = roundm( sys.uc.threshold, p )
    sys.uc.age_18_24  = roundm( sys.uc.age_18_24 , p )
    sys.uc.age_25_and_over  = roundm( sys.uc.age_25_and_over , p )
    sys.uc.couple_both_under_25  = roundm( sys.uc.couple_both_under_25 , p )
    sys.uc.couple_oldest_25_plus  = roundm( sys.uc.couple_oldest_25_plus , p )
    sys.uc.minimum_income_floor_hours = roundm( sys.uc.minimum_income_floor_hours, p )
    sys.uc.first_child   = roundm( sys.uc.first_child  , p )
    sys.uc.subsequent_child  = roundm( sys.uc.subsequent_child , p )
    sys.uc.disabled_child_lower  = roundm( sys.uc.disabled_child_lower , p )
    sys.uc.disabled_child_higher  = roundm( sys.uc.disabled_child_higher , p )
    sys.uc.limited_capcacity_for_work_activity = roundm( sys.uc.limited_capcacity_for_work_activity, p )
    sys.uc.carer  = roundm( sys.uc.carer , p )
    sys.uc.ndd = roundm( sys.uc.ndd, p )
    sys.uc.childcare_max_2_plus_children  = roundm( sys.uc.childcare_max_2_plus_children , p )
    sys.uc.childcare_max_1_child  = roundm( sys.uc.childcare_max_1_child , p )
    sys.uc.work_allowance_w_housing = roundm( sys.uc.work_allowance_w_housing, p )
    sys.uc.work_allowance_no_housing = roundm( sys.uc.work_allowance_no_housing, p )

    p = sm.wtc_basic/sys.lmt.working_tax_credit.basic
    wtc.basic = sm.wtc_basic
    sys.wtc.lone_parent = roundm( sys.wtc.lone_parent, p,  0 )
    sys.wtc.couple = roundm( sys.wtc.couple, p,  0 )
    sys.wtc.hours_ge_30 = roundm( sys.wtc.hours_ge_30, p,  0 )
    sys.wtc.disability = roundm( sys.wtc.disability, p,  0 )
    sys.wtc.severe_disability = roundm( sys.wtc.severe_disability, p,  0 )
    sys.wtc.age_50_plus = roundm( sys.wtc.age_50_plus, p,  0 )
    sys.wtc.age_50_plus_30_hrs = roundm( sys.wtc.age_50_plus_30_hrs, p,  0 )
    sys.wtc.childcare_proportion = roundm( sys.wtc.childcare_proportion, p,  0 )
    sys.wtc.non_earnings_minima = roundm( sys.wtc.non_earnings_minima, p,  0 )
    sys.wtc.threshold = roundm( sys.wtc.threshold, p,  0 )
    sys.wtc.taper = roundm( sys.wtc.taper, p,  0 )

    return tb
end

const DEFAULT_SIMPLE_PARAMS :: SimpleParams = map_full_to_simple( DEFAULT_PARAMS )

struct ParamsAndSettings{T}
	simple   :: SimpleParams{T}
	session  :: GenieSession.Session
end

struct AllOutput
	results
	summary
	gain_lose
	examples
end

# Save results by query string & just return that
# TODO complete this.
const CACHED_RESULTS = Dict{SimpleParams,AllOutput}()

#
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 4

const QSIZE = 32

IN_QUEUE = Channel{ParamsAndSettings}(QSIZE)

# configure logger; see: https://docs.julialang.org/en/v1/stdlib/Logging/index.html
# and: https://github.com/oxinabox/LoggingExtras.jl
logger = FileLogger("/var/tmp/stb_log.txt")
global_logger(logger)
LogLevel( Logging.Debug )

const MR_UP_GOOD = [1,0,0,0,0,0,0,-1,-1]
const COST_UP_GOOD = [1,1,1,1,-1,-1,-1,-1,-1,-1,-1]

function format_and_class( change :: Real ) :: Tuple
    gnum = format( abs(change), commas=true, precision=2 )
    glclass = "";
    glstr = ""
    if change > 20.0
        glstr = "positive_strong"
        glclass = "text-success"
    elseif change > 10.0
        glstr = "positive_med"
        glclass = "text-success"
    elseif change > 0.01
        glstr = "positive_weak"
        glclass = "text-success"
    elseif change < -20.0
        glstr = "negative_strong"
        glclass = "text-danger"
    elseif change < -10
        glstr = "negative_med"
        glclass = "text-danger"
    elseif change < -0.01
        glstr = "negative_weak"
        glclass = "text-danger"
    else
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    end
    ( gnum, glclass, glstr )
end

## FIXME POVERTY LINE!
function make_base_results()
	settings = initialise_settings()	
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	tot = 0
	of = on(obs) do p
		tot += p.step
		PROGRESS[p.uuid] = (progress=p,total=tot)
	end
    settings = deepcopy(settings)
	results = do_one_run( settings, [BASE_PARAMS], obs )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )        
    outf = summarise_frames( results, settings )
	gl = make_gain_lose( results.hh[1], results.hh[1], settings ) 
	exres = calc_examples( BASE_PARAMS, BASE_PARAMS, settings )
    aout = AllOutput( results, outf, gl, exres ) 
	return aout;
end

const BASE_RESULTS = make_base_results()
const BASE_TEXT_OUTPUT = results_to_html( BASE_UUID, BASE_RESULTS, BASE_RESULTS )