module Exceptional
export DivisionByZero, block, return_from, error

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

return_from(name, value = nothing) = throw([name, value])

available_restart(name) = nothing

invoke_restart(name, args...) = nothing

restart_bind(func, restarts...) = nothing

error(exception::Exception) = throw(exception)

handler_bind(func, handlers...) = nothing

end
