"""
Exceptional signals and handles exceptional situations, including use of restarts. 
An exceptional situation occur when a program reaches a point where a planned operation cannot be done.
"""
module Exceptional
export DivisionByZero,
    block,
    return_from,
    available_restart,
    invoke_restart,
    restart_bind,
    error,
    handler_bind,
    pick_restart

struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block_num = 0
global_restarts = nothing
global_handlers = nothing
break_on_signal = false

toogle_break_on_signal() = global break_on_signal = !break_on_signal

"""
block makes it possible to do a non-local transfer of control.
By using block, a named exit point is set. 
Calling the return_from function inside the block context make it possible to
return values from those named exit points.
"""
function block(func)
    try
        global block_num += 1
        res = func(block_num)
        global block_num -= 1
        res
    catch e
        name, value = e
        if name == block_num
            return value
        end
        global block_num -= 1
        rethrow()
    end
end

"""
return_from works together with the block function. It's telling the block function which value to return,
and from which context this value should be returned.
"""
return_from(name, value = nothing) = throw([name, value])

"""
available_restart takes a named restarts as input and returns true if this is a possible
restart to do.
"""
function available_restart(name)
    for restart in global_restarts
        restart_name, _ = restart
        if restart_name == name
            return true
        end
    end
    false
end

"""
invoke_restart finds the registered restart connected to the input argument name. It returns the
corresponding restart function with corresponding arguments.
"""
function invoke_restart(name, args...)
    for restart in global_restarts
        restart_name, restart_function = restart
        if restart_name == name
            return restart_function(args...)
        end
    end
end

"""
pick_restart gives the user the possibility to decide which of the registered restarts to use when an exceptional situation occur.
"""
function pick_restart()
    numb_to_restart = Dict()
    count = 1
    println("\nRestarts:")
    for restart in global_restarts
        numb_to_restart[count] = restart
        println("$(count): [$(restart[1])]")
        count += 1
    end
    from_user = 0
    while from_user < 1 || from_user > count - 1
        print("Choose restart [1-$(count - 1)]: ")
        try
            from_user = parse(Int8, readline())
        catch e
            println("Invalid input, choose a number in the range 1-$(count - 1)")
        end
    end
    restart_name, restart_function = numb_to_restart[from_user]
    numb_args = methods(restart_function).mt.max_args - 1
    println("You choosed $(restart_name), the function require $(numb_args) arguments")
    args = []
    for i in 1:numb_args
        print("Arg $(i): ")
        from_user = nothing
        while from_user === nothing
            try
                from_user = parse(Float16, readline())
                append!(args, [from_user])
            catch e
                println("Invalid input, needs to be a number") # TODO: accept several input types
            end
        end
    end
    println()
    return restart_function(args...)
end

"""
restart_bind gives the ability to go back to the place where an exceptional situation happened,
from this place a given action called restart can be done to fix the occuring error.
"""
function restart_bind(func, restarts...)
    previous_restarts = global_restarts
    if global_restarts === nothing
        global global_restarts = restarts
    else
        global global_restarts = tuple(restarts..., global_restarts...)
    end
    res = func()
    global global_restarts = previous_restarts
    return res
end

"""
signal checks the registered handlers, if any of these handlers is the
same type as the input exception, or a parent of the input exception, that handler function is called.
If any of these handler functions return something this is returned from signal. If the global variable
break_on_signal is set, the error is thrown.
"""
function signal(exception::Exception)
    if global_handlers !== nothing
        for handler in global_handlers
            handler_name, handler_function = handler
            if isa(exception, handler_name)
                res = handler_function(exception)
                if res !== nothing
                    return res
                end
            end
        end
    end
    if break_on_signal
        throw(exception)
    end
end

"""
error recives an exception as input. If no result is returned from the signal function the error is thrown.
"""
function error(exception::Exception)
    res = signal(exception)
    if res !== nothing
        return res
    end
    throw(exception)
end

"""
handler_bind makes it possible to be notified when an exceptional situation occur. This is done by
wrapping a function who could give an exceptional situation within handlers.
"""
function handler_bind(func, handlers...)
    previous_handlers = global_handlers
    if global_handlers === nothing
        global global_handlers = handlers
    else
        global global_handlers = tuple(handlers..., global_handlers...)
    end

    try
        func()
    catch e
        throw(e)
    finally
        global global_handlers = previous_handlers
    end
end
end

macro handler_case(func, handlers...)
    introspected_handlers = []
    for handler in handlers
        module_name = handler.args[1].args[1]
        exception_type = handler.args[1].args[2].value
        parameters = tuple(handler.args[2].args...)
        body = handler.args[3]
        # append!(introspected_handlers, [:($(module_name).$(exception_type) => ($(parameters...),) -> $(body))])
        append!(
            introspected_handlers,
            [:($(module_name).$(exception_type) => (c) -> $(body))],
        )
    end
    :(
        Exceptional.handler_bind($(introspected_handlers...)) do
            $(func)
        end
    )
end

reciprocal(x) = x == 0 ? Exceptional.error(Exceptional.DivisionByZero()) : 1 / x

res = @handler_case(
    reciprocal(0),
    (Exceptional.DivisionByZero, (), println("I saw a division by zero")),
    (Exceptional.DivisionByZero, (), println("I saw it too")),
)

println("res: $(res)")
