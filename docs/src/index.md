# Exceptional.jl Documentation

```@docs
Exceptional
Exceptional.block(func)
Exceptional.return_from(name, value = nothing)
Exceptional.available_restart(name)
Exceptional.invoke_restart(name, args...)
Exceptional.restart_bind(func, restarts...)
Exceptional.error(exception::Exception)
Exceptional.handler_bind(func, handlers...)
```
