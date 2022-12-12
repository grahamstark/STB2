using Test
using ScottishTaxBenefitModel.STBParameters

@testset "map_simple_to_full" begin
   smp = map_simple_to_full( DEFAULT_PARAMS )
   @test smp.it.personal_allowance == 12_500.0
end

@testset "map_full_to_simple" begin
   a = 90
   b = 100
   c = 12
   d = 1000
   propchange(a,b,c,d)
   @test c ≈ 12*100/90
   @test d ≈ 1000*100/90
   @test a == 100
end
