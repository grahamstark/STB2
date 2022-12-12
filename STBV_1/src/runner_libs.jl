function do_run_a( 
	cache_key, 
	sys :: TaxBenefitSystem, 
	settings :: Settings ) :: AllOutput
	@debug "do_run_a entered"
	obs = Observable( 
		Progress(settings.uuid, "",0,0,0,0))
	tot = 0
	of = on(obs) do p
		tot += p.step
		PROGRESS[p.uuid] = (progress=p,total=tot)
	end
	results = do_one_run( settings, [sys], obs )
	settings.poverty_line = make_poverty_line( results.hh[1], settings )
	outf = summarise_frames( results, settings )
	gl = make_gain_lose( BASE_RESULTS.results.hh[1], results.hh[1], settings ) 
	exres = calc_examples( BASE_PARAMS, sys, settings )
	aout = AllOutput( settings.uuid, cache_key, results, outf, gl, exres ) 
	return aout;
end
