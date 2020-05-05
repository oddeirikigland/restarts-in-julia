include("../src/RestartsInJulia.jl")
using Test, Suppressor, .RestartsInJulia


reciprocal(x) =
    x == 0 ? Exceptional.error(RestartsInJulia.Exceptional.DivisionByZero()) : 1 / x


try
    reciprocal(0)
catch r
    @test r == RestartsInJulia.Exceptional.DivisionByZero()
end


@test RestartsInJulia.mystery(0) == 3
@test RestartsInJulia.mystery(1) == 2
@test RestartsInJulia.mystery(2) == 4


@test mystery_2() == 2


@test "I saw a division by zero" == @capture_out try
    RestartsInJulia.Exceptional.handler_bind(
        RestartsInJulia.Exceptional.DivisionByZero =>
            (c) -> print("I saw a division by zero"),
    ) do
        reciprocal(0)
    end
catch r
    @test r == RestartsInJulia.Exceptional.DivisionByZero()
end


@test "I saw a division by zeroI saw it too" ==
      @capture_out @test RestartsInJulia.Exceptional.block() do escape
    RestartsInJulia.Exceptional.handler_bind(
        RestartsInJulia.Exceptional.DivisionByZero =>
            (c) -> (print("I saw it too");
            RestartsInJulia.Exceptional.return_from(escape, "HandlerBindTest1")),
    ) do
        RestartsInJulia.Exceptional.handler_bind(
            RestartsInJulia.Exceptional.DivisionByZero =>
                (c) -> print("I saw a division by zero"),
        ) do
            reciprocal(0)
        end
    end
end == "HandlerBindTest1"


@test "I saw a division by zero" ==
      @capture_out @test RestartsInJulia.Exceptional.block() do escape
    RestartsInJulia.Exceptional.handler_bind(
        RestartsInJulia.Exceptional.DivisionByZero => (c) -> print("I saw it too"),
    ) do
        RestartsInJulia.Exceptional.handler_bind(
            RestartsInJulia.Exceptional.DivisionByZero =>
                (c) -> (print("I saw a division by zero");
                RestartsInJulia.Exceptional.return_from(escape, "HandlerBindTest2")),
        ) do
            reciprocal(0)
        end
    end
end == "HandlerBindTest2"
