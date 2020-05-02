using Test, RestartsInJulia

try
    RestartsInJulia.reciprocal(0)
catch r
    @test r == RestartsInJulia.Exceptional.DivisionByZero()
end

@test RestartsInJulia.mystery(0) == 3
@test RestartsInJulia.mystery(1) == 2
@test RestartsInJulia.mystery(2) == 4
