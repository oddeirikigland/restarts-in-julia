block(func) = nothing

return_from(name, value = nothing) = nothing

available_restart(name) = nothing

invoke_restart(name, args...) = nothing

restart_bind(func, restarts...) = nothing

error(exception::Exception) = Base.error("$(exception) was not handled.")

handler_bind(func, handlers...) = nothing