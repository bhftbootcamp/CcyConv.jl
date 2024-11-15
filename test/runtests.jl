# runtests

using Test
using CcyConv

@testset "Currency Conversion tests" begin
    @testset "utils" begin
        include("utils/test_graph_ops.jl")
        include("utils/test_path_ops.jl")
        include("utils/test_graph_analysis.jl")
        include("utils/test_mermaid.jl")
        include("test_utils.jl")
    end
    @testset "pathfinding" begin
        include("pathfinding/test_conv_a_star.jl")
        include("pathfinding/test_pathfinding_algo.jl")
    end
    #include("test_benchmarks_pathfinding.jl")
end
