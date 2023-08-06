using GCodeCraft
using Test
using Aqua
using JET

@testset "GCodeCraft.jl" begin
    Aqua.test_all(GCodeCraft)
    JET.test_package(GCodeCraft)
    # Write your tests here.
end
