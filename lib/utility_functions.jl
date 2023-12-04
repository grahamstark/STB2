# TODO module Utility

struct Funcs
    δ :: Number
    β :: AbstractVector{<:Number}
    utility :: Function
    expenditure :: Function
    indirect :: Function
    marshallian :: Function 
    hicksian :: Function
end

module CES

    """
    CES utility u = [ x^δ + y^δ ]^(1/δ) (for 2 goods) for δ != [0,1]
    a : kinda sorta shares parameters
    x : goods
    NOTE: elasticity of substitution = 1/(1 - δ)
    """
    function utility( δ :: Number, a::AbstractVector{<:Number}, x :: AbstractVector{<:Number})::Number
        @assert sum( a ) ≈ 1
        @assert length(a) == length(x)
        n=length(x)
        u = 0.0
        for i in 1:n
            u += a[i]*(x[i]^δ)
        end
        u^(1/δ)
    end

    """
    Expenditure function - min cost of attaining `u` at prices p with `δ` 
    """
    function expenditure( δ :: Number, a::AbstractVector{<:Number}, u :: Number, prices :: AbstractVector{<:Number} )
        @assert sum( a ) ≈ 1
        p = prices
        n=length(p)
        @assert length(a) == n
        c = 0.0
        for i in 1:n
            c += (a[i]^δ)*(p[i]^(1-δ))
        end
        c = c^(1/(1-δ))
        c*u
    end

    """
    The utility attainable for income y at prices p given `δ` and weights `a`
    `a`s are kinda sorta shares and should sum to 1. It's common also to set them all to 1.
    `δ` 
    """
    function indirect( δ :: Number, a::AbstractVector{<:Number}, y :: Number, prices :: AbstractVector{<:Number} )
        u1 = expenditure( δ, a, 1, prices ) # cost of 1 unit of utility
        return y/u1
    end


    """
    uncompensated demand for good `which` with prices and income
    """
    function marshallian( δ :: Number, a::AbstractVector{<:Number}, income :: Number, prices :: AbstractVector{<:Number}, which :: Int) :: Number
        y = income
        p = prices
        v1 = (a[which]/p[which])^δ
        v2 = 0.0
        n = length(p)
        for i in 1:n
            v2 += a[i]^δ * p[i]^(1-δ)
        end
        y*v1/v2
    end

    """
    compensated demand for good `which` with `prices` and `utility` 
    same as the marshallian demand at the income needed for that utility
    """
    function hicksian( δ :: Number, a::AbstractVector{<:Number}, utility :: Number, prices :: AbstractVector{<:Number}, which :: Int ) :: Number
        # 
        income = expenditure( δ, a, utility, prices )
        return marshallian( δ, a, income, prices, which )
    end

end # module CES

module CobbDouglas

    function utility( δ :: Number, a :: AbstractVector{<:Number}, x :: AbstractVector{<:Number} ) :: Number
        @assert δ ≈ 1
        n=length(x)
        println("n=$n length(a) $(length(a))")
        @assert length(a) == n 
        u = 0.0
        for i in 1:n
            u += x[i]^a[i]
        end
        u
    end

    """
    Expenditure function - min cost of attaining `u` at prices p with `δ` 
    """
    function expenditure( δ :: Number, a::AbstractVector{<:Number}, utility :: Number, prices :: AbstractVector{<:Number} )
        @assert sum( a ) ≈ 1
        @assert δ ≈ 1
        p = prices
        n=length(p)
        @assert length(a) == n 
        x = utility
        for i in 1:n  
            x *= p[i]^a[i]
        end
        x
    end

    """
    The utility attainable for income y at prices p given `δ` and weights `a`
    `a`s are kinda sorta shares and should sum to 1. It's common also to set them all to 1.
    `δ` 
    """
    function indirect( δ :: Number, a::AbstractVector{<:Number}, income :: Number, prices :: AbstractVector{<:Number} )
        @assert sum( a ) ≈ 1
        @assert δ ≈ 1
        p = prices
        n=length(p)
        t = 1.0
        for i in 1:n
            t *= p[i]^a[i]
        end
        return income/t
    end

    function marshallian( δ :: Number, a::AbstractVector{<:Number}, income :: Number, prices :: AbstractVector{<:Number}, which :: Int) :: Number
        @assert sum( a ) ≈ 1
        @assert δ ≈ 1
        return income*a[which]/prices[which]
    end

    function hicksian( δ :: Number, a::AbstractVector{<:Number}, utility :: Number, prices :: AbstractVector{<:Number}, which :: Int) :: Number
        @assert sum( a ) ≈ 1
        @assert δ ≈ 1
        x = expenditure( δ, a, utility, prices )
        return marshallian( δ, a,  x, prices, which )
    end

end # CobbDouglas

module Leontief

end # Leontief

module Fixed 

end # Fixed

function icurve( δ :: Number, a::AbstractVector{<:Number}, u :: Number, hicks, start_1=5, end_2=5 ) :: AbstractMatrix{<:Number}
    p = ones(2)
    v = zeros(100,2)
    p[2] = 0.1
    for i in 1:100
        v[i,1] = hicks( δ, a, u, p, 1 )
        v[i,2] = hicks( δ, a, u, p, 2 )
        p[2] += 0.1
    end
    v
end



# start examples
shares = [0.5,0.5]
prices = ones(2)
u55 = CES.utility(0.1, shares, [5,5])
ic55 = icurve( 0.1, shares, u55, CES.hicksian )
y55 = CES.expenditure( 0.1, shares, u55, prices ) # 10, obvs
u55i = CES.indirect( 0.1, shares, 10, prices )
@assert y55 ≈ 10
println( "u55 $u55 y55 $y55 ic55 $ic55 u55i $u55i")

u44 = CES.utility(0.1,shares, [4,4])
ic44 = icurve( 0.1, shares, u44, CES.hicksian )
y44 = CES.expenditure( 0.1, shares, u44, prices) # 10, obvs

u33 = CES.utility(0.1,shares, [3,3])
ic33 = icurve( 0.1, shares, u33, CES.hicksian )
y33 = CES.expenditure( 0.1, shares, u33, prices )




