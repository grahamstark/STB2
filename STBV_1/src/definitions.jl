# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)

using .STBParameters
using .Definitions
using StructTypes
using JSON3

const BIG_A = 9999999999
mutable struct SimpleParams{T}
    taxrates :: Vector{T}
    taxbands :: Vector{T}
    nirates :: Vector{T}
    nibands :: Vector{T}
    taxallowance :: T
    target :: Int
    # ....
end
StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()

function loaddefs() :: TaxBenefitSystem 
    return load_file( joinpath( Definitions.MODEL_PARAMS_DIR, "sys_2022-23.jl" ))
end

const DEFAULT_PARAMS = loaddefs()

function map_simple_to_full( params :: TaxBenefitSystem )::SimpleParams

    return SimpleParams(
        copy(params.it.non_savings_rates),
        copy(params.it.non_savings_thresholds),
        copy(params.ni.primary_class_1_rates),
        copy(params.ni.primary_class_1_bands),
        params.it.personal_allowance,
        0 )
end


function map_full_to_simple( sm :: SimpleParams ) :: TaxBenefitSystem
   tb = deepcopy( DEFAULT_PARAMS )
    # ...
   return tb
end

const DEFAULT_SIMPLE_PARAMS = map_simple_to_full( DEFAULT_PARAMS )
