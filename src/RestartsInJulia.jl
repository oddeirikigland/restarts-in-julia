module RestartsInJulia
export Exceptional, reciprocal, mystery

include("Exceptional.jl")
using .Exceptional

reciprocal(x) = x == 0 ? Exceptional.error(Exceptional.DivisionByZero()) : 1 / x

mystery(n) = 1 + Exceptional.block() do outer
    1 + block() do inner
        1 + if n == 0
            Exceptional.return_from(inner, 1)
        elseif n == 1
            Exceptional.return_from(outer, 1)
        else
            1
        end
    end
end

@assert mystery(0) == 3
@assert mystery(1) == 2
@assert mystery(2) == 4

mystery_new() =
    Exceptional.block() do outer
        Exceptional.block() do inner
            1
        end
        Exceptional.return_from(outer, 2)
    end

@assert mystery_new() == 2

end
