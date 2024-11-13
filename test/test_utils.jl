using CcyConv: get_currency, calculate_path_rate

@testset "utils" begin
    @testset "get_currency" begin
        my_graph = FXGraph()
        push!(my_graph, Price("USD", "EUR", 0.85))
        push!(my_graph, Price("EUR", "GBP", 0.87))

        @testset "existing currencies" begin
            # Get IDs for known currencies
            usd_id = my_graph.edge_encode["USD"]
            eur_id = my_graph.edge_encode["EUR"]
            gbp_id = my_graph.edge_encode["GBP"]

            # Test existing currencies
            @test get_currency(my_graph, usd_id) == "USD"
            @test get_currency(my_graph, eur_id) == "EUR"
            @test get_currency(my_graph, gbp_id) == "GBP"
        end

        @testset "non-existent currency" begin
            # Test invalid ID
            invalid_id = UInt64(999)
            @test_throws ErrorException("Currency not found") get_currency(
                my_graph,
                invalid_id,
            )
        end

        @testset "empty graph" begin
            empty_graph = FXGraph()
            # Test with ID on empty graph
            @test_throws ErrorException("Currency not found") get_currency(
                empty_graph,
                UInt64(1),
            )
        end
    end

    @testset "calculate_path_rate" begin
        @testset "simple forward path" begin
            graph = FXGraph()
            push!(graph, Price("A", "B", 2.0))
            push!(graph, Price("B", "C", 3.0))

            # Get IDs for known currencies
            a_id = Int64(graph.edge_encode["A"])
            b_id = Int64(graph.edge_encode["B"])
            c_id = Int64(graph.edge_encode["C"])

            path = [a_id, b_id, c_id]
            rate, chain = calculate_path_rate(graph, path)

            @test rate ≈ 6.0  # 2.0 * 3.0
            @test length(chain) == 2
            @test chain == [Price("A", "B", 2.0), Price("B", "C", 3.0)]
        end

        @testset "path with implicit reverse" begin
            graph = FXGraph()
            push!(graph, Price("A", "B", 2.0))    # A->B = 2.0, so B->A = 1/2.0
            push!(graph, Price("C", "B", 4.0))    # C->B = 4.0, so B->C = 1/4.0

            a_id = Int64(graph.edge_encode["A"])
            b_id = Int64(graph.edge_encode["B"])
            c_id = Int64(graph.edge_encode["C"])

            # Test path B->A (using implicit reverse)
            path = [b_id, a_id]
            rate, chain = calculate_path_rate(graph, path)
            @test rate ≈ 0.5  # 1/2.0
            @test length(chain) == 1
            @test chain == [Price("A", "B", 2.0)]

            # Test path with both normal and reverse
            path = [a_id, b_id, c_id]
            rate, chain = calculate_path_rate(graph, path)
            @test rate ≈ 0.5  # 2.0 * (1/4.0)
            @test length(chain) == 2
            @test chain == [Price("A", "B", 2.0), Price("C", "B", 4.0)]
        end

        @testset "empty path" begin
            graph = FXGraph()
            push!(graph, Price("A", "B", 2.0))

            rate, chain = calculate_path_rate(graph, Int[])
            @test rate == 1.0  # multiplicative identity
            @test isempty(chain)
        end

        @testset "single node path" begin
            graph = FXGraph()
            push!(graph, Price("A", "B", 2.0))

            a_id = Int64(graph.edge_encode["A"])
            rate, chain = calculate_path_rate(graph, [a_id])
            @test rate == 1.0  # no conversion needed
            @test isempty(chain)
        end

        @testset "non-existent edge" begin
            graph = FXGraph()
            push!(graph, Price("A", "B", 2.0))
            # Don't add edge B->C

            a_id = Int64(graph.edge_encode["A"])
            b_id = Int64(graph.edge_encode["B"])
            c_id = Int64(-1)  # Non-existent node

            @test_throws KeyError calculate_path_rate(graph, [a_id, b_id, c_id])
        end
    end
end
