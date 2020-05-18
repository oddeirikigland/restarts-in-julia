"""
Exceptional signals and handles exceptional situations, including use of restarts. 
An exceptional situation occur when a program reaches a point where a planned operation cannot be done.
"""
module Exceptional
export DivisionByZero,
    block, return_from, available_restart, invoke_restart, restart_bind, error, handler_bind

struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block_num = 0
global_restarts = nothing
global_handlers = nothing

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
error recives an exception as input. It check the registered handlers, if any of these handlers is the
same type as the input exception, or a parent of the input exception, that handler function is called.
If none of the handler functions returns a result the incoming error is thrown.
"""
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
