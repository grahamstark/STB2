using Test
using ScottishTaxBenefitModel
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
