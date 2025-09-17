using CcyConv: find_missing_edges
using CcyConv: create_graph_with_reversed_edges, ReverseBehavior, DUAL_PRICES, SINGLE_PRICES

@testset "find_missing_edges" begin
    @testset "empty graph" begin
        graph = FXGraph()
        @test isempty(find_missing_edges(graph))
    end

    @testset "fully connected graph" begin
        graph = FXGraph()
        push!(graph, Price("USD", "EUR", 0.85))
        push!(graph, Price("EUR", "USD", 1.18))

        @test isempty(find_missing_edges(graph))
    end

    @testset "single missing reverse" begin
        graph = FXGraph()
        push!(graph, Price("USD", "EUR", 0.85))

        usd_id = graph.edge_encode["USD"]
        eur_id = graph.edge_encode["EUR"]

        missing_edges = find_missing_edges(graph)
        @test length(missing_edges) == 1
        @test missing_edges[1] == (eur_id, usd_id, 1 / 0.85)
    end

    @testset "multiple missing reverses" begin
        graph = FXGraph()
        push!(graph, Price("USD", "EUR", 0.85))
        push!(graph, Price("EUR", "GBP", 0.87))

        usd_id = graph.edge_encode["USD"]
        eur_id = graph.edge_encode["EUR"]
        gbp_id = graph.edge_encode["GBP"]

        missing_edges = find_missing_edges(graph)
        @test length(missing_edges) == 2
        @test (eur_id, usd_id, 1 / 0.85) in missing_edges
        @test (gbp_id, eur_id, 1 / 0.87) in missing_edges
    end

    @testset "circular dependencies" begin
        graph = FXGraph()
        # Circular: USD->EUR->GBP->USD
        push!(graph, Price("USD", "EUR", 0.85))
        push!(graph, Price("EUR", "GBP", 0.87))
        push!(graph, Price("GBP", "USD", 1.35))

        usd_id = graph.edge_encode["USD"]
        eur_id = graph.edge_encode["EUR"]
        gbp_id = graph.edge_encode["GBP"]

        missing_edges = find_missing_edges(graph)
        @test length(missing_edges) == 3
        @test (eur_id, usd_id, 1 / 0.85) in missing_edges
        @test (gbp_id, eur_id, 1 / 0.87) in missing_edges
        @test (usd_id, gbp_id, 1 / 1.35) in missing_edges
    end

    @testset "mixed connected and missing" begin
        graph = FXGraph()
        push!(graph, Price("USD", "EUR", 0.85))
        push!(graph, Price("EUR", "USD", 1.18))  # Provided reverse
        push!(graph, Price("EUR", "GBP", 0.87))  # Missing reverse

        eur_id = graph.edge_encode["EUR"]
        gbp_id = graph.edge_encode["GBP"]

        missing_edges = find_missing_edges(graph)
        @test length(missing_edges) == 1
        @test missing_edges[1] == (gbp_id, eur_id, 1 / 0.87)
    end

    @testset "create_graph_with_reversed_edges" begin
        @testset "example" begin
            g = FXGraph()
            append!(
                g,
                [
                    Price("A", "F", 50.0),
                    # F->A is missing
                    Price("A", "B", 5.0),
                    # B->A is missing
                    Price("A", "C", 4.0),
                    # C->A is missing
                    Price("B", "D", 4.0),
                    # B->C is missing
                    Price("B", "C", 1.0),
                    Price("C", "B", 2.0),
                    Price("C", "D", 2.0),
                    # D->C is missing
                    Price("C", "E", 2.0),
                    # E->C is missing
                    Price("D", "F", 2.0),
                    # F->D is missing
                    Price("E", "F", 1.0),
                    # F->E is missing
                    Price("X", "Y", 42.0),
                    Price("Y", "X", 24.0),
                ],
            )
            new_g = create_graph_with_reversed_edges(g, behavior = DUAL_PRICES)
            @test all(length(prices) == 2 for prices in values(new_g.edge_nodes))
        end
    end
end
