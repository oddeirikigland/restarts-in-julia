module Exceptional
export DivisionByZero,
    block, return_from, available_restart, invoke_restart, restart_bind, error, handler_bind

struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block_num = 0
global_restarts = nothing

function block(func)
    try
        global block_num += 1
        res = func(block_num)
        global block_num -= 1
        res
    catch r
        name, value = r
        if name == block_num
            return value
        end
        rethrow([name + 1, value])
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
    if global_restarts != nothing
        global global_restarts = tuple(global_restarts..., restarts...)
    else
        global global_restarts = restarts
    end

    try
        func()
    catch e
        rethrow()
    end
end

error(exception::Exception) = throw(exception)

function handler_bind(func, handlers...)
    try
        func()
    catch e
        if isa(e, Array)
            rethrow()
        end
        for handler in handlers
            exception_type, handler_function = handler
            if exception_type == typeof(e)
                res = handler_function(e)
                if res == nothing
                    rethrow()
                end
                return res
            end
        end
    finally
        global global_restarts = nothing
    end
end
end
