using JSON3
using GenieSession 
using GenieSessionFileSession
import Genie.Renderer.Json: json

mutable struct SimpleParams
    taxrates 
    taxbands
    nirates
    nibands
    taxallowance
end



function getparams()::SimpleParams
    session = GenieSession.session()
    pars = nothing
    if( GenieSession.isset( session, :pars ))
        return GenieSession.get( session, :pars )
    else
        pars = SimpleParams( [20,34,56],[1000,4000],[2,3,4],[2002,3044,2020],66000)
        GenieSession.set!( session, :pars, pars )
        return pars
    end
end

function handlesubmit( req )
    resp = Genie.Responses.getresponse()
    session = GenieSession.session()
    # if session === nothing 
    #     session, resp = GenieSession.start( id, req, resp )
    # end
    pars = nothing
    if( ! GenieSession.isset( session, :pars ))
        pars = SimpleParams( [20,34,56],[1000,4000],[2,3,4],[2002,3044,2020],66000)
        GenieSession.set!( session, :pars, pars )
    else
        pars = GenieSession.get( session, :pars )
    end
    (:pars=>pars) |> json
end


function runt()
    pars = getparams()

    (:pars=>pars) |> json
end

function savet() 
    pars = getparams()

    (:pars=>pars) |> json
end
function resett() 
    pars = getparams()

    (:pars=>pars) |> json
end

function progress() 
    pars = getparams()

    (:pars=>pars) |> json
end

function output() 
    pars = getparams()

    (:pars=>pars) |> json
end

function uprate( v :: Real ) 
    pars = getparams()

    (:pars=>pars) |> json
end

function delonerb!( rates::AbstractVector, bands::AbstractVector, pos::Integer )
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos > sz
        return
    end
    deleteat!( rates, pos )
    # top case where there's no explicit top band
    if sz > sb && pos == sz
        deleteat!( bands, pos-1)
    else
        deleteat!( bands, pos )
    end
end

function addonerb!( rates::AbstractVector{T}, bands::AbstractVector{T}, pos::Integer, val :: T = zero(T) ) where T
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos in 1:sz
        insert!( rates, pos, val )
        if pos <= sb
            insert!( bands, pos, val )
        else
            push!(  bands, val )
        end
    else
        push!( bands, val )
        push!( rates, val )
    end
end

function addtax( n :: Int ) 
    pars = getparams()
    addonerb!( pars.taxrates, pars.taxbands, n )
    (:rates=>pars.taxrates, :bands=>pars.taxbands) |> json
end



function deltax( n )
    pars = getparams()
    delonerb!( pars.taxrates, pars.taxbands, n );
    (:pars=>pars) |> json
end

function addni( n )
    pars = getparams()
    addonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars) |> json
end

function delni( n )
    pars = getparams()
    delonerb!( pars.nirates, pars.nibands, n );
    (:pars=>pars) |> json
end
