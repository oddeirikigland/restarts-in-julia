module RestartsInJulia
export Exceptional, reciprocal, mystery, mystery_2

include("Exceptional.jl")
using .Exceptional

reciprocal(x) = x == 0 ? Exceptional.error(Exceptional.DivisionByZero()) : 1 / x

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


try
    print("I saw a division by zero == ")
    Exceptional.handler_bind(DivisionByZero => (c) -> print("I saw a division by zero")) do
        reciprocal(0)
    end
catch r
    @assert r == DivisionByZero()
end

println("\n-------------------------------------------------------------")
print("I saw a division by zeroI saw it too == ")

@assert block() do escape
    handler_bind(
        DivisionByZero => (c) -> (print("I saw it too"); return_from(escape, "DoneTest1")),
    ) do
        handler_bind(DivisionByZero => (c) -> print("I saw a division by zero")) do
            reciprocal(0)
        end
    end
end == "DoneTest1"

println("\n-------------------------------------------------------------")
print("I saw a division by zero == ")

@assert block() do escape
    handler_bind(DivisionByZero => (c) -> print("I saw it too")) do
        handler_bind(DivisionByZero => (c) -> (print("I saw a division by zero");
        return_from(escape, "DoneTest2"))) do
            reciprocal(0)
        end
    end
end == "DoneTest2"

println("")

end
