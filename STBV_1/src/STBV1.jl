module STBV1
#=

=#
using Genie
using GenieSession 
using GenieSessionFileSession
import Genie.Renderer.Json: json

using DataFrames
using Formatting
using JSON3
using Logging, LoggingExtras
using Observables
using PovertyAndInequalityMeasures
using StatsBase
using StructTypes

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
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

include( "definitions.jl" )
include( "examples.jl")
include( "functions.jl" )
include( "table_libs.jl")
include( "text_html_libs.jl")
include( "static_texts.jl")

function main() 
  Genie.genie(; context = @__MODULE__)
end

end