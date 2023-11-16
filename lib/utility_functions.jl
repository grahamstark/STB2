module Utility

using Parameters

abstract type UFuncs

function hicksian( )

end

function marshallian( prices :: Vector{Number}, y :: Number )::Number

end

function cost()

end

function indirect()

function utility()


@with_kw struct U
    e :: Number = 1
    β :: Vector{Number} = []
    cost :: Function

end

end

struct Funcs
    θ :: Number
    β :: AbstractVector{Number}
    utility :: Function
    expenditure :: Function
    indirect :: Function
    marshallian :: Function 
    hicksian :: Function
end

module CES

    function utility( θ :: Number, x :: Vector)
        n=length(x)
        u = 0.0
        for i in 1:n
        u += x[i]^θ
        end
        u^(1/θ)
    end

    function expenditure( θ :: Number, u :: Number, p :: AbstractVector{Number} )
        n=length(p)
        r = θ/(θ-1)
        c = 0.0
        for i in 1:n
            c += p[i]^r
        end
        c = c^(1/r)
        c*u
    end

    function indirect( θ :: Number, y :: Number, p :: AbstractVector{Number} )
        n=length(p)
        r = θ/(θ-1)
        u = 0.0
        for i in 1:n
            u += p[i]^r
        end
        u = u^(-1/r)
        y*u
    end

    function marshallian( θ :: Number, y :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        r = θ/(θ-1)
        v1 = p[which]^(r-1)
        v2 = 0.0
        n = length(p)
        for i in 1:n
        v2 += p[i]^r
        end
        y*v1/v2
    end

    function hicksian( θ :: Number, u :: Number, p :: AbstractVector{Number}, which :: Int ) :: Number
        r = θ/(θ-1)
        v1=p[which]^(r-1)
        v2=0.0
        n = length(p)
        for i in 1:n
            v2 += p[i]^r
        end
        v2 = v2^((1/r)-1) 
        # println( "r=$r v1=$v1 v2=$v2 u=$u")
        v2 * v1 * u
    end

end # module CES

module CobbDouglas

    function utility( θ :: Vector, x :: Vector ) :: Number
        u = 0.0
        n=length(x)
        for i in 1:n
            u += x[i]^θ[i]
        end
        u
    end

    function marshallian( θ :: Number, y :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        @assert θ ≈ 1

    end

    function hicksian( θ :: Number, u :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        @assert θ ≈ 1
    end

end # CobbDouglas

function icurve( θ :: Number, u :: Number, hicks, start_1=5, end_2=5 ) :: AbstractVector{Number}
    p = ones(2)
    v = zeros(100,2)
    p[2] = 0.1
    for i in 1:100
        v[i,1] = hicks( θ, u, p, 1 )
        v[i,2] = hicks( θ, u, p, 2 )
        p[2] += 0.1
    end
    v
end



# start examples
u55 = CES.utility(0.1,[5,5])
ic55 = icurve( 0.1, u55, CES.hicksian )
y55 = CES.expenditure( 0.1, u55, ones(2)) # 10, obvs

u44 = CES.utility(0.1,[4,4])
ic44 = icurve( 0.1, u44, CES.hicksian )
y44 = CES.expenditure( 0.1, u44, ones(2)) # 10, obvs

u33 = CES.utility(0.1,[3,3])
ic33 = icurve( 0.1, u33, CES.hicksian )
y33 = CES.expenditure( 0.1, u33, ones(2))




