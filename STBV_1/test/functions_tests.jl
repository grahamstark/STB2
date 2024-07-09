using Test
using ScottishTaxBenefitModel
using STBV1

@testset "addonerb" begin
   rates = [1,2,3]
   bands = [4,5]
   STBV1.addonerb!( rates, bands, 2 )
   @test rates == [1,0,2,3]
   @test bands == [4,0,5]
   STBV1.addonerb!( rates, bands, 1 )
   @test rates == [0,1,0,2,3]
   @test bands == [0,4,0,5]
   STBV1.addonerb!( rates, bands, 6,100 )
   @test rates == [0,1,0,2,3,100]
   @test bands == [0,4,0,5,100]
   STBV1.addonerb!( rates, bands, 99,101 )
   @test rates == [0,1,0,2,3,100,101]
   @test bands == [0,4,0,5,100,101]
end
