include("../src/Exceptional.jl")
using Test, Suppressor, .Exceptional


reciprocal(x) = x == 0 ? Exceptional.error(Exceptional.DivisionByZero()) : 1 / x


try
    reciprocal(0)
catch r
    @test r == Exceptional.DivisionByZero()
end


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


@test mystery(0) == 3
@test mystery(1) == 2
@test mystery(2) == 4


@test Exceptional.block() do outer
    Exceptional.block() do inner
        1
    end
    Exceptional.return_from(outer, 2)
end == 2


@test "I saw a division by zero" == @capture_out try
    Exceptional.handler_bind(
        Exceptional.DivisionByZero => (c) -> print("I saw a division by zero"),
    ) do
        reciprocal(0)
    end
catch r
    @test r == Exceptional.DivisionByZero()
end


@test "I saw a division by zeroI saw it too" ==
      @capture_out @test Exceptional.block() do escape
    Exceptional.handler_bind(
        Exceptional.DivisionByZero =>
            (c) -> (print("I saw it too");
            Exceptional.return_from(escape, "HandlerBindTest1")),
    ) do
        Exceptional.handler_bind(
            Exceptional.DivisionByZero => (c) -> print("I saw a division by zero"),
        ) do
            reciprocal(0)
        end
    end
end == "HandlerBindTest1"


@test "I saw a division by zero" == @capture_out @test Exceptional.block() do escape
    Exceptional.handler_bind(
        Exceptional.DivisionByZero => (c) -> print("I saw it too"),
    ) do
        Exceptional.handler_bind(
            Exceptional.DivisionByZero =>
                (c) -> (print("I saw a division by zero");
                Exceptional.return_from(escape, "HandlerBindTest2")),
        ) do
            reciprocal(0)
        end
    end
end == "HandlerBindTest2"


reciprocal(value) =
    Exceptional.restart_bind(
        :return_zero => () -> 0,
        :return_value => identity,
        :retry_using => reciprocal,
    ) do
        value == 0 ? Exceptional.error(Exceptional.DivisionByZero()) : 1 / value
    end


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_zero),
) do
    reciprocal(0)
end == 0


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_value, 123),
) do
    reciprocal(0)
end == 123


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:retry_using, 10),
) do
    reciprocal(0)
end == 0.1


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_zero),
) do
    reciprocal(0)
end == 0


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_value, 123),
) do
    reciprocal(0)
end == 123


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:retry_using, 10),
) do
    reciprocal(0)
end == 0.1


@test Exceptional.Exceptional.handler_bind(
    Exceptional.DivisionByZero =>
        (c) -> for restart in (:return_one, :return_zero, :die_horribly)
            if Exceptional.available_restart(restart)
                return Exceptional.invoke_restart(restart)
            end
        end,
) do
    reciprocal(0)
end == 0


infinity() =
    Exceptional.restart_bind(:just_do_it => () -> 1 / 0) do
        reciprocal(0)
    end


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_zero),
) do
    infinity()
end == 0


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:return_value, 1),
) do
    infinity()
end == 1


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:retry_using, 10),
) do
    infinity()
end == 0.1


@test Exceptional.handler_bind(
    Exceptional.DivisionByZero => (c) -> Exceptional.invoke_restart(:just_do_it),
) do
    infinity()
end == Inf
