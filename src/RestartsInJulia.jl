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

end
