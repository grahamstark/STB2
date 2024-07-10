using Test
using ScottishTaxBenefitModel
using .ModelHousehold
using .STBParameters
using STBV1

@testset "Nearest" begin
   a = collect(1:2:100)
   @test STBV1.nearest(a, 50 ) == 25
end


@testset "map_simple_to_full" begin
   smp = STBV1.map_simple_to_full( STBV1.DEFAULT_SIMPLE_PARAMS )
   @test smp.it.personal_allowance == 12_570

   @show smp
   @test smp.it == STBV1.DEFAULT_PARAMS.it
end

@testset "rate change examples" begin
   p1 = deepcopy( STBV1.DEFAULT_PARAMS )
   p2 = deepcopy(  STBV1.DEFAULT_PARAMS)

   p2.it.non_savings_rates = [20,20,21,42,45,48] # 1p increase
   p2.it.non_savings_thresholds = [1000.0,13991,31092,62430,125140] # 1p increase
   p2.it.non_savings_basic_rate = 1
   weeklyise!( p1 )
   weeklyise!( p2 )
   exres = STBV1.calc_examples( p1, p2, STBV1.DEFAULT_SETTINGS )
   n = length(exres)
   for i in 1:n
      hh = EXAMPLE_HHS[i].hh
      ex = exres[i]
      label = EXAMPLE_HHS[i].label
      println( label)
      bus = get_benefit_units( hh )
      head = get_head( bus[1] )
      spouse = get_spouse( bus[1] )
      @show "HEAD" head
      @show "head-pre-IT" ex.bres.bus[1].pers[head.pid].it
      @show "head-post-IT" ex.pres.bus[1].pers[head.pid].it
      if ! isnothing( spouse )
         @show "Spouse " spouse
         @show "spouse-pre-IT" ex.bres.bus[1].pers[spouse.pid].it   
         @show "spouse-pre-IT" ex.bres.bus[1].pers[spouse.pid].it   
      end
   end
end