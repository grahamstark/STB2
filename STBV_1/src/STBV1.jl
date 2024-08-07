module STBV1
#=

=#
using Genie
using GenieSession 
using GenieSessionFileSession
import Genie.Renderer.Json: json

using DataFrames
using Format
using JSON3
using Logging, LoggingExtras
using Markdown
using Observables
using PovertyAndInequalityMeasures
using StatsBase
using StructTypes
using UUIDs

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .LocalLevelCalculations
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils
import Base.Threads.@spawn

const up = Genie.up
export up

include( "../../lib/static_texts.jl")
include( "../../lib/table_libs.jl")
include( "../../lib/examples.jl")
include( "../../lib/definitions.jl" )
include( "../../lib/text_html_libs.jl")
include( "../../lib/base_and_cache.jl")
include( "functions.jl" )

#
# Set up job queues 
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
  @info "starting handler $i" 
  errormonitor(@async calc_one())
end

function main() 
  Genie.genie(; context = @__MODULE__)
end

end
