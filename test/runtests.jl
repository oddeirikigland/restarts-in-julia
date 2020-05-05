include("../src/RestartsInJulia.jl")
using Test, .RestartsInJulia

try
    RestartsInJulia.reciprocal(0)
catch r
    @test r == Exceptional.DivisionByZero()
end

@test RestartsInJulia.mystery(0) == 3
@test RestartsInJulia.mystery(1) == 2
@test RestartsInJulia.mystery(2) == 4

@test mystery_2() == 2
