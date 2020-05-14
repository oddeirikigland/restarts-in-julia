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

return_from(name, value = nothing) = throw([name, value])

function available_restart(name)
    for restart in global_restarts
        restart_name, _ = restart
        if restart_name == name
            return true
        end
    end
    false
end

function invoke_restart(name, args...)
    for restart in global_restarts
        restart_name, restart_function = restart
        if restart_name == name
            return restart_function(args...)
        end
    end
end

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

function error(exception::Exception)
    res = signal(exception)
    if res !== nothing
        return res
    end
    throw(exception)
end

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
