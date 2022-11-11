module STBV1

using Genie

const up = Genie.up
export up

include( "functions.jl" )

function main()
  Genie.genie(; context = @__MODULE__)
end

end
