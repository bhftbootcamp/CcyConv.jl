using CcyConv.Pathfinding
using BenchmarkTools
using Random

@testset "Pathfinding Benchmarks" begin
    function create_large_test_graph(n_vertices = 100, density = 0.3)
        graph = FXGraph()
        vertices = ["V$i" for i = 1:n_vertices]

        for i = 1:n_vertices, j = 1:n_vertices
            if i != j && rand() < density
                push!(graph, Price(vertices[i], vertices[j], rand() * 100))
            end
        end

        for i = 2:n_vertices
            push!(graph, Price(vertices[1], vertices[i], rand() * 100))
        end

        return graph, vertices
    end

    graph_sizes = [5, 10]
    test_cases_per_size = 3

    for n_vertices in graph_sizes
        println("\nTesting graph with $n_vertices vertices:")
        graph, vertices = create_large_test_graph(n_vertices)
        test_cases = [
            (vertices[rand(1:n_vertices)], vertices[rand(1:n_vertices)]) for
            _ = 1:test_cases_per_size
        ]

        for algo in [DFSPathFinder, DFSPathFinder_v2, ExtremumPathFinder]
            println("\nBenchmarking $(algo):")

            println(" conv_max")
            time_max = @benchmark begin
                local start, end_ = $test_cases[1]
                $algo.conv_max($graph, start, end_)
            end seconds = 5 samples = 1

            println(" conv_min")
            time_min = @benchmark begin
                local start, end_ = $test_cases[1]
                $algo.conv_min($graph, start, end_)
            end seconds = 5 samples = 1

            println("Max path finding - Mean time: $(mean(time_max).time/1e6) ms")
            println("Min path finding - Mean time: $(mean(time_min).time/1e6) ms")
            println("Memory max: $(mean(time_max).memory/1024) KB")
            println("Memory min: $(mean(time_min).memory/1024) KB")
            println("Allocations max: $(mean(time_max).allocs)")
            println("Allocations min: $(mean(time_min).allocs)")
        end
    end

    @test 1 == 1
end
