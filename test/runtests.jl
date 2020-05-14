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

@test "I saw a division by zeroI saw it too" == @capture_out try
    Exceptional.handler_bind(Exceptional.DivisionByZero => (c) -> print("I saw it too")) do
        Exceptional.handler_bind(
            Exceptional.DivisionByZero => (c) -> print("I saw a division by zero"),
        ) do
            reciprocal(0)
        end
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

line_end = 20
struct LineEndLimit <: Exception end

function print_line(str)
    let col = 0
        for c in str
            print(c)
            if col < line_end
                col += 1
            else
                Exceptional.signal(LineEndLimit())
            end
        end
        println()
        col
    end
end

@test "Hi, everybody!\n" == @capture_out @test print_line("Hi, everybody!") == 14
@test "Hi, everybody! How are you feeling today?\n" == @capture_out @test print_line("Hi, everybody! How are you feeling today?") == 20

@test "Hi, everybody! How ar" == @capture_out try
    Exceptional.toogle_break_on_signal()
    print_line("Hi, everybody! How are you feeling today?") == 20
catch e
    @test e == LineEndLimit()
finally
    Exceptional.toogle_break_on_signal()
end


function print_computing_excess(str)
    let excess = 0
        Exceptional.handler_bind(LineEndLimit => (c) -> begin
            excess += 1
            nothing
        end) do
            print_line(str)
        end
        excess
    end
end

@test "Hi, everybody!\n" == @capture_out @test print_computing_excess("Hi, everybody!") == 0
@test "Hi, everybody! How are you feeling today?\n" == @capture_out @test print_computing_excess("Hi, everybody! How are you feeling today?") == 21


function print_maybe_aborting(str)
    Exceptional.block() do escape
        Exceptional.handler_bind(
            LineEndLimit => (c) -> Exceptional.return_from(escape, "Line too long"),
        ) do
            print_line(str)
        end
    end
end

@test "Hi, everybody! How ar" == @capture_out @test print_maybe_aborting("Hi, everybody! How are you feeling today?") == "Line too long"

function aborting_on_line_end_limit(f)
    Exceptional.block() do escape
        Exceptional.handler_bind(
            LineEndLimit => (c) -> Exceptional.return_from(escape, nothing),
        ) do
            f()
        end
    end
end

@test "Hi, everybody! How ar" == @capture_out @test aborting_on_line_end_limit(
    () -> print_line("Hi, everybody! How are you feeling today?"),
) === nothing


function warning_on_signals(f)
    Exceptional.handler_bind(Exception => (c) -> println("I saw a signal")) do
        f()
    end
end

@test "Hi, everybody! How arI saw a signal\n" == @capture_out @test aborting_on_line_end_limit(
    () -> warning_on_signals(() -> print_line("Hi, everybody! How are you feeling today?")),
) === nothing


@test Exceptional.handler_bind(Exceptional.DivisionByZero => (c)->Exceptional.invoke_restart(:return_zero)) do
    1 + reciprocal(0)
end == 1

divide(x, y) = x*reciprocal(y)

@test Exceptional.handler_bind(Exceptional.DivisionByZero => (c)->Exceptional.invoke_restart(:return_value, 3)) do
    divide(2, 0)
end == 6