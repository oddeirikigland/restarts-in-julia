# struct IntrospectableFunction
#     name
#     parameters
#     body
#     native_function
# end

# square = IntrospectableFunction(:square, (:x,), :(x*x), x->x*x)

# # println(square.parameters)

# (f::IntrospectableFunction)(x) = f.native_function(x)

# # println(square(3))

# macro introspectable(form)
#     # dump(form)
#     let name = form.args[1].args[1],
#         parameters = tuple(form.args[1].args[2:end]...),
#         body = form.args[2],
#         quoted_name = QuoteNode(name)
#         quoted_body = QuoteNode(body)

#         # dump(body)
#         :($(esc(name)) = IntrospectableFunction($(quoted_name), $(parameters), $(quoted_body), ($(parameters...),)->$(body)))


#     end
# end

# @introspectable square(x) = x*x

# println(square(2))
# println(square.name)
# println(square.parameters)
# println(square.body)