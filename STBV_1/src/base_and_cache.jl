#
# needs to be here 
#
# Save results by query string & just return that
# TODO complete this.
const CACHED_RESULTS = Dict{UInt,AllOutput}()

function cacheout(simp::SimpleParams,allo::AllOutput)
	CACHED_RESULTS[riskyhash(simp)] = allo
end

function getout( simp::SimpleParams )::Union{Nothing,AllOutput}
	u = riskyhash(simp)
	if ! haskey(CACHED_RESULTS, u )
		return nothing
	end
	CACHED_RESULTS[u]
end


## FIXME POVERTY LINE!
function make_base_results()
	settings = initialise_settings()	
    obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	tot = 0
	of = on(obs) do p
		tot += p.step
		# PROGRESS[p.uuid] = (progress=p,total=tot)
	end
    println( DEFAULT_WEEKLY_PARAMS.ni )
	results = do_one_run( settings, [DEFAULT_WEEKLY_PARAMS], obs )
    settings.poverty_line = make_poverty_line( results.hh[1], settings )        
    outf = summarise_frames( results, settings )
	gl = make_gain_lose( results.hh[1], results.hh[1], settings ) 
	exres = calc_examples( DEFAULT_WEEKLY_PARAMS, DEFAULT_WEEKLY_PARAMS, settings )
    aout = AllOutput( results, outf, gl, exres ) 
	return aout;
end

const DEFAULT_RESULTS = make_base_results()
const DEFAULT_TEXT_OUTPUT = results_to_html( DEFAULT_RESULTS, DEFAULT_RESULTS )
cacheout(DEFAULT_SIMPLE_PARAMS,DEFAULT_RESULTS)