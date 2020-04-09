struct DivisionByZero <: Exception end
Base.showerror(io::IO, e::DivisionByZero) = print(io, e, " was not handled.")

block(func) = nothing

return_from(name, value = nothing) = nothing

available_restart(name) = nothing

invoke_restart(name, args...) = nothing

restart_bind(func, restarts...) = nothing

error(exception::Exception) = throw(exception)

handler_bind(func, handlers...) =
    try
        func()
    catch e
        for handler in handlers
            (key, value) = handler
            if key() === e
                value(e)
            end
        end
    end
