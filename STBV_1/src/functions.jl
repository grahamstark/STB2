using JSON3
using GenieSession 
using GenieSessionFileSession
using ScottishTaxBenefitModel
using .Monitor: Progress
import Genie.Renderer.Json: json

function do_run(
    session,
    simple :: SimpleParams )
	@debug "do_run_a entered"
	settings = Settings()
	if haskey( CACHED_RESULTS, simple )
        p = Progress( settings.uuid, "end", -99, -99, -99, -99 )
        GenieSession.set!( session, :progress, (progress=p,total=0))
        return
	end
	sys :: TaxBenefitSystem = map_simple_to_full( simple )

	obs = Observable(
		Progress(settings.uuid, "",0,0,0,0))
	tot = 0
	of = on(obs) do p
        tot += p.step
		GenieSession.set!( session, :progress, (progress=p,total=tot))
	end
	results = do_one_run( settings, [sys], obs )
	settings.poverty_line = make_poverty_line( results.hh[1], settings )
	outf = summarise_frames( results, settings )
	gl = make_gain_lose( BASE_RESULTS.results.hh[1], results.hh[1], settings )
	exres = calc_examples( BASE_PARAMS, sys, settings )
	aout = AllOutput( results, outf, gl, exres )
    res_text = results_to_html( BASE_RESULTS, aout )
    CACHED_RESULTS[ simple ] = res_text
end



function submit_job( 
    session::GenieSession.Session, 
    simple :: SimpleParams )
    put!( IN_QUEUE, ParamsAndSettings( session, simple ))
	@debug "submit exiting queue is now $IN_QUEUE"
end



function calc_one()
	while true
		@debug "calc_one entered"
		params = take!( IN_QUEUE )
		@debug "params taken from IN_QUEUE; got params"
		do_run( params.session, params.simple )
		@debug "model run OK; putting results into CACHED_RESULTS"		
	end
end

#
# Set up job queues 
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
    errormonitor(@async calc_one())
end

function getparams()::SimpleParams
    session = GenieSession.session()
    pars = nothing
    if( GenieSession.isset( session, :pars ))
        return GenieSession.get( session, :pars )
    else
        pars = deepcopy( DEFAULT_SIMPLE_PARAMS )
        GenieSession.set!( session, :pars, pars )
        return pars
    end
end

function params()
    pars = getparams()
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function handlesubmit( payload )
    @show payload
    session = GenieSession.session()
    pars = JSON3.read(payload, SimpleParams{Float64})
    GenieSession.set!( session, :pars, pars )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function runt()
    rp = rawpayload()
    # @show jp
    @show rp
    pars = handlesubmit( rp ) 

    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function savet() 
    rp = rawpayload()
    @show rp
    pars = handlesubmit( rp ) 
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function resett() 
    session = GenieSession.session()
    pars = deepcopy( DEFAULT_SIMPLE_PARAMS )
    GenieSession.set!( session, :pars, pars )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function progress() 
    pars = getparams()
    (:prog=>"Goes Here") |> json
end

function output() 
    pars = getparams()
    (:out=>"Goes Here") |> json
end

function uprate( v :: Real ) 
    pars = getparams()
    
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function delonerb!( rates::AbstractVector, bands::AbstractVector, pos::Integer )
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

function addonerb!( rates::AbstractVector{T}, bands::AbstractVector{T}, pos::Integer, val :: T = zero(T) ) where T
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

function defaults()
    (:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function addtax( n :: Int ) 
    pars = getparams()
    addonerb!( pars.taxrates, pars.taxbands, n )
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function deltax( n )
    pars = getparams()
    delonerb!( pars.taxrates, pars.taxbands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function addni( n )
    pars = getparams()
    addonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

function delni( n )
    pars = getparams()
    delonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end
