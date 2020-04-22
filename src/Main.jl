include("Exceptional.jl")

reciprocal(x) = x == 0 ? error(DivisionByZero()) : 1 / x

try
    reciprocal(0)
catch r
    @assert r == DivisionByZero()
end

mystery(n) = 1 + block() do outer
    1 + block() do inner
        1 + if n == 0
            return_from(inner, 1)
        elseif n == 1
            return_from(outer, 1)
        else
            1
        end
    end
end

@assert mystery(0) == 3
@assert mystery(1) == 2
@assert mystery(2) == 4
