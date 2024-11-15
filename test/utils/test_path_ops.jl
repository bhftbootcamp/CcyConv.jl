using CcyConv: calculate_path_rate

@testset "calculate_path_rate" begin
    RTOL = 0.01

    @testset "simple forward path" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))
        push!(graph, Price("B", "C", 3.0))

        # Get IDs for known currencies
        a_id = graph.edge_encode["A"]
        b_id = graph.edge_encode["B"]
        c_id = graph.edge_encode["C"]

        path = [a_id, b_id, c_id]
        rate, chain = calculate_path_rate(graph, path)

        @test isapprox(rate, 6.0, rtol = RTOL)  # 2.0 * 3.0
        @test length(chain) == 2
        @test chain == [Price("A", "B", 2.0), Price("B", "C", 3.0)]
    end

    @testset "simple forward path with string instead of id" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))
        push!(graph, Price("B", "C", 3.0))

        path = ["A", "B", "C"]
        rate, chain = calculate_path_rate(graph, path)

        @test isapprox(rate, 6.0, rtol = RTOL)  # 2.0 * 3.0
        @test length(chain) == 2
        @test chain == [Price("A", "B", 2.0), Price("B", "C", 3.0)]
    end

    @testset "path with implicit reverse" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))    # A->B = 2.0, so B->A = 1/2.0
        push!(graph, Price("C", "B", 4.0))    # C->B = 4.0, so B->C = 1/4.0

        a_id = graph.edge_encode["A"]
        b_id = graph.edge_encode["B"]
        c_id = graph.edge_encode["C"]

        # Test path B->A (using implicit reverse)
        path = [b_id, a_id]
        rate, chain = calculate_path_rate(graph, path)
        @test isapprox(rate, 0.5, rtol = RTOL)  # 1/2.0
        @test length(chain) == 1
        @test chain == [Price("A", "B", 2.0)]

        # Test path with both normal and reverse
        path = [a_id, b_id, c_id]
        rate, chain = calculate_path_rate(graph, path)
        @test isapprox(rate, 0.5, rtol = RTOL)  # 2.0 * (1/4.0)
        @test length(chain) == 2
        @test chain == [Price("A", "B", 2.0), Price("C", "B", 4.0)]
    end

    @testset "empty path" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))

        rate, chain = calculate_path_rate(graph, UInt64[])
        @test rate == 1.0  # multiplicative identity
        @test isempty(chain)
    end

    @testset "single node path" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))

        a_id = graph.edge_encode["A"]
        rate, chain = calculate_path_rate(graph, [a_id])
        @test rate == 1.0  # no conversion needed
        @test isempty(chain)
    end

    @testset "non-existent edge" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))
        # Don't add edge B->C

        a_id = graph.edge_encode["A"]
        b_id = graph.edge_encode["B"]
        c_id = 42  # Non-existent node

        @test_throws KeyError calculate_path_rate(graph, [a_id, b_id, c_id])
    end
end