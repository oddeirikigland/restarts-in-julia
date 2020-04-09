include("Exceptional.jl")

reciprocal(x) = x == 0 ? error(DivisionByZero()) : 1 / x

# reciprocal(0)

handler_bind(DivisionByZero => (c) -> println("I saw a division by zero")) do
    reciprocal(0)
end
