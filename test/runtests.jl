# runtests

using Test
using CcyConv

@testset "Currency Conversion tests" begin
    include("test_utils.jl")
    include("test_conv_a_star.jl")
    include("test_pathfinding_algo.jl")
end
