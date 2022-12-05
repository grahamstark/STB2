module STBV1

using Genie

using ScottishTaxBenefitModel

const up = Genie.up
export up

include( "definitions.jl" )
include( "functions.jl" )

function main()
  
  Genie.genie(; context = @__MODULE__)
end

end
