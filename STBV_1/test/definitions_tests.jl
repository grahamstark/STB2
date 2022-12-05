using Test
using ScottishTaxBenefitModel.STBParameters

@testset "map_simple_to_full" begin
   smp = map_simple_to_full( DEFAULT_PARAMS )
   @test smp.it.personal_allowance == 12_500.0
end
