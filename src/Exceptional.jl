module Exceptional
export DivisionByZero, block, return_from, error, handler_bind

struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block_num = 0

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

function return_from(name, value = nothing)
    throw([name, value])
end

available_restart(name) = nothing

invoke_restart(name, args...) = nothing

restart_bind(func, restarts...) = nothing

error(exception::Exception) = throw(exception)

function handler_bind(func, handlers...)
    try
        func()
    catch e
        if isa(e, Array)
            rethrow(e)
        end
        for handler in handlers
            exception_type, handler_function = handler
            if exception_type == typeof(e)
                handler_function(e)
                rethrow(e)
            end
        end
    end
end

end
