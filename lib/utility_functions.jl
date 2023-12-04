module Utility

struct Funcs
    δ :: Number
    β :: AbstractVector{Number}
    utility :: Function
    expenditure :: Function
    indirect :: Function
    marshallian :: Function 
    hicksian :: Function
end

module CES

    """
    CES utility u = [ x^δ + y^δ ]^(1/δ) (for 2 goods) for δ != [0,1]
    δ : δ/(δ-1) is elasticity of substitution.
    a : shares parameters
    x : goods
    """
    function utility( δ :: Number, a::AbstractVector{Number}, x :: AbstractVector{Number})::Number
        n=length(x)
        u = 0.0
        for i in 1:n
            u += a[i]*x[i]^δ
        end
        u^(1/δ)
    end

    function expenditure( δ :: Number, a::AbstractVector{Number}, u :: Number, p :: AbstractVector{Number} )
        n=length(p)
        r = δ/(δ-1)
        c = 0.0
        for i in 1:n
            c += (p[i]/a[i])^r
        end
        c = c^(1/r)
        c*u
    end

    function indirect( δ :: Number, a::AbstractVector{Number}, y :: Number, p :: AbstractVector{Number} )
        n=length(p)
        r = δ/(δ-1)
        u = 0.0
        for i in 1:n
            u += a[i]*p[i]^r
        end
        u = u^(-1/r)
        y*u
    end



    function marshallian( δ :: Number, a::AbstractVector{Number}, y :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        r = δ/(δ-1)
        v1 = a[which]*p[which]^(r-1)
        v2 = 0.0
        n = length(p)
        for i in 1:n
            v2 += a[i]*p[i]^r
        end
        y*v1/v2
    end

    function hicksian( δ :: Number, a::AbstractVector{Number}, u :: Number, p :: AbstractVector{Number}, which :: Int ) :: Number
        r = δ/(δ-1)
        v1=a[which]*p[which]^(r-1)
        v2=0.0
        n = length(p)
        for i in 1:n
            v2 += a[i]*p[i]^r
        end
        v2 = v2^((1/r)-1) 
        v2 * v1 * u
    end

end # module CES

module CobbDouglas

    function utility( δ :: Vector, x :: Vector ) :: Number
        u = 0.0
        n=length(x)
        for i in 1:n
            u += x[i]^δ[i]
        end
        u
    end

    function marshallian( δ :: Number, y :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        @assert δ ≈ 1

    end

    function hicksian( δ :: Number, u :: Number, p :: AbstractVector{Number}, which :: Int) :: Number
        @assert δ ≈ 1
    end

end # CobbDouglas

function icurve( δ :: Number, u :: Number, hicks, start_1=5, end_2=5 ) :: AbstractVector{Number}
    p = ones(2)
    v = zeros(100,2)
    p[2] = 0.1
    for i in 1:100
        v[i,1] = hicks( δ, u, p, 1 )
        v[i,2] = hicks( δ, u, p, 2 )
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




