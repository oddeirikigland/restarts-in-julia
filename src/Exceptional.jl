module Exceptional
export DivisionByZero,
    block, return_from, available_restart, invoke_restart, restart_bind, error, handler_bind

struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block_num = 0
global_restarts = nothing
global_handlers = nothing

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

function error(exception::Exception)
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
