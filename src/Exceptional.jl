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

return_from(name, value = nothing) = throw([name, value])

function available_restart(name)
    println(name)
    false
end

invoke_restart(name, args...) = name, args

function restart_bind(func, restarts...)
    try
        func()
    catch e
        rethrow([e, restarts])
    end
end

error(exception::Exception) = throw(exception)

function handler_bind(func, handlers...)
    try
        func()
    catch e
        for handler in handlers
            exception_type, handler_function = handler
            if isa(e, Array)
                if exception_type == typeof(e[1])
                    name, args = handler_function(e[1])
                    for restart_action in e[2]
                        restart_name, restart_function = restart_action
                        if name == restart_name
                            return restart_function(args...)
                        end
                    end
                else
                    rethrow(e)
                end
            end
            if exception_type == typeof(e)
                handler_function(e)
                rethrow(e)
            end
        end
    end
end


reciprocal(value) =
    restart_bind(
        :return_zero => () -> 0,
        :return_value => identity,
        :retry_using => reciprocal,
    ) do
        value == 0 ? error(DivisionByZero()) : 1 / value
    end

println(handler_bind(DivisionByZero => (c) -> invoke_restart(:return_zero)) do
    reciprocal(0)
end == 0)

println(handler_bind(DivisionByZero => (c) -> invoke_restart(:return_value, 123)) do
    reciprocal(0)
end == 123)

println(handler_bind(DivisionByZero => (c) -> invoke_restart(:retry_using, 10)) do
    reciprocal(0)
end == 0.1)

# println(
#     handler_bind(
#         DivisionByZero => (c) -> for restart in (:return_one, :return_zero, :die_horribly)
#             if available_restart(restart)
#                 invoke_restart(restart)
#             end
#         end,
#     ) do
#         reciprocal(0)
#     end,
# )


end
