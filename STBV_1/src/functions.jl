using JSON3
using GenieSession 
using GenieSessionFileSession
using ScottishTaxBenefitModel
using .Monitor: Progress
import Genie.Renderer.Json: json

function do_run(
    session :: GenieSession.Session,
    simple  :: SimpleParams ) :: AllOutput
	@info "do_run entered"
	settings = initialise_settings()
	sys :: TaxBenefitSystem = map_simple_to_full( simple )
    weeklyise!( sys )
	obs = Observable(
		Progress(settings.uuid, "",0,0,0,0))
	tot = 0
	of = on(obs) do p
        tot += p.step
        @info "monitor tot=$tot p = $(p)"
		GenieSession.set!( session, :progress, (progress=p,total=tot))
	end
	results = do_one_run( settings, [sys], obs )
	settings.poverty_line = make_poverty_line( results.hh[1], settings )
	outf = summarise_frames!( results, settings )
	gl = make_gain_lose( DEFAULT_RESULTS.results.hh[1], results.hh[1], settings )
	exres = calc_examples( DEFAULT_WEEKLY_PARAMS, sys, settings )
	aout = AllOutput( results, outf, gl, exres )
    cacheout(simple,aout)
    obs[]= Progress( settings.uuid, "end", -99, -99, -99, -99 )
    aout
end

function submit_job( 
    session :: GenieSession.Session, 
    simple  :: SimpleParams )
    @info "submit_job entered"
    put!( IN_QUEUE, ParamsAndSettings( simple, session ))
	@info "submit exiting queue is now $IN_QUEUE"
end

function calc_one()
	while true
		@info "calc_one entered"
		params = take!( IN_QUEUE )
		@info "params taken from IN_QUEUE; got params"
		do_run( params.session, params.simple )
		@info "model run OK; putting results into CACHED_RESULTS"		
	end
end

function paramsfromsession()::SimpleParams
    session = GenieSession.session()
    if( GenieSession.isset( session, :pars ))
        pars = GenieSession.get( session, :pars )
    else
        pars = deepcopy( DEFAULT_SIMPLE_PARAMS )
        GenieSession.set!( session, :pars, pars )
    end
    return pars
end

function getparams()
    pars = paramsfromsession()
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function paramsfrompayload( payload )
    @show payload
    pars = JSON3.read(payload, SimpleParams{Float64})
    return pars
end

function set_param( )
    
end

function dorun()
    sess = GenieSession.session()
    pars = paramsfrompayload( rawpayload() )
    @info "dorun entered pars are " pars
    GenieSession.set!( sess, :pars, pars )
    res = getout(pars)
    output = ""
    if ! isnothing(res)
        @info "output from cache"        
        output = results_to_html( DEFAULT_RESULTS, res )
    else
        @info "submitting job"
        submit_job( sess, pars )    
    end
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS,:output=>output) |> json
end

function dosave() 
    pars = paramsfrompayload(rawpayload())
    sess = GenieSession.session()
    GenieSession.set!( sess, :pars, pars )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function doreset() 
    sess = GenieSession.session()
    pars = deepcopy( DEFAULT_SIMPLE_PARAMS )
    GenieSession.set!( sess, :pars, pars )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS,:output=>DEFAULT_TEXT_OUTPUT) |> json
end

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

function getoutput() 
    pars = paramsfromsession()
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

function douprate( v :: Real ) 
    pars = paramsfromsession()
    # TODO
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function delonerb!( 
    rates::AbstractVector, 
    bands::AbstractVector, 
    pos::Integer )
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos > sz
        return
    end
    deleteat!( rates, pos )
    # top case where there's no explicit top band
    if sz > sb && pos == sz
        deleteat!( bands, pos-1)
    else
        deleteat!( bands, pos )
    end
end

function addonerb!( 
    rates::AbstractVector{T}, 
    bands::AbstractVector{T}, 
    pos::Integer, 
    val :: T = zero(T) ) where T
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos in 1:sz
        insert!( rates, pos, val )
        if pos <= sb
            insert!( bands, pos, val )
        else
            push!(  bands, val )
        end
    else
        push!( bands, val )
        push!( rates, val )
    end
end

function getdefaults()
    (:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function addtax( n :: Int ) 
    pars = paramsfromsession()
    addonerb!( pars.taxrates, pars.taxbands, n )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function deltax( n )
    pars = paramsfromsession()
    delonerb!( pars.taxrates, pars.taxbands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function addni( n )
    pars = paramsfromsession()
    addonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function delni( n )
    pars = paramsfromsession()
    delonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end
