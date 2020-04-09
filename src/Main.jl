include("Exceptional.jl")

reciprocal(x) = 
x == 0 ?
error(DivisionByZero()) :
1 / x

reciprocal(0)