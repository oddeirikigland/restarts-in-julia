module RestartsInJulia
export Exceptional, mystery, mystery_2

include("Exceptional.jl")
using .Exceptional

mystery(n) = 1 + Exceptional.block() do outer
    1 + Exceptional.block() do inner
        1 + if n == 0
            Exceptional.return_from(inner, 1)
        elseif n == 1
            Exceptional.return_from(outer, 1)
        else
            1
        end
    end
end

mystery_2() =
    Exceptional.block() do outer
        Exceptional.block() do inner
            1
        end
        Exceptional.return_from(outer, 2)
    end

end
