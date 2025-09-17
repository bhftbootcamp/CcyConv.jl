# runtests

using Test
using CcyConv

include("test_helpers.jl")

@testset "Currency Conversion tests" begin
    @testset "types" begin
        include("types/test_conv_rate.jl")
        include("types/test_price.jl")
        include("types/test_graph.jl")
    end

    @testset "conversion" begin
        include("conversion/test_linear.jl")
        include("conversion/test_reverse.jl")
        include("conversion/test_fees.jl")
        include("conversion/test_custom.jl")
    end

    @testset "utils" begin
        include("utils/test_graph_ops.jl")
        include("utils/test_path_ops.jl")
        include("utils/test_graph_analysis.jl")
        include("utils/test_mermaid.jl")
    end
    @testset "pathfinding" begin
        include("pathfinding/test_conv_a_star.jl")
        include("pathfinding/test_pathfinding_algo.jl")
        include("pathfinding/test_pathfinding_fees.jl")
    end
    #include("test_benchmarks_pathfinding.jl")
end
