using CcyConv:
    get_currency, UnknownCurrencyError, calculate_path_rate, find_missing_edges, create_graph_with_reversed_edges, ReverseBehavior, DUAL_PRICES, SINGLE_PRICES, to_mermaid
using CcyConv.Pathfinding.AStar: conv as conv_a_star

const RTOL = 0.01

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
            @test_throws UnknownCurrencyError get_currency(
                my_graph,
                invalid_id,
            )
        end

        @testset "empty graph" begin
            empty_graph = FXGraph()
            # Test with ID on empty graph
            @test_throws UnknownCurrencyError get_currency(
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
            @test missing_edges[1] == (eur_id, usd_id, 1/0.85)
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
            @test (eur_id, usd_id, 1/0.85) in missing_edges
            @test (gbp_id, eur_id, 1/0.87) in missing_edges
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
            @test (eur_id, usd_id, 1/0.85) in missing_edges
            @test (gbp_id, eur_id, 1/0.87) in missing_edges
            @test (usd_id, gbp_id, 1/1.35) in missing_edges
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
            @test missing_edges[1] == (gbp_id, eur_id, 1/0.87)
        end
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

    @testset "to_mermaid" begin
        # Helper function to parse and sort Mermaid edges
        function parse_mermaid_edges(mermaid::String)
            lines = filter(
                l -> !isempty(l) && !startswith(l, "graph"),
                split(strip(mermaid), '\n'),
            )
            return sort(strip.(lines))
        end

        @testset "empty graph" begin
            graph = FXGraph()
            mermaid = to_mermaid(graph)
            @test mermaid == "graph LR\n"
        end

        @testset "single edge graph" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.85))

            # Test without reverse edges
            mermaid = to_mermaid(graph)
            expected = """
            graph LR
                USD -->|0.85| EUR
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)

            # Test with reverse edges
            mermaid_with_reverse = to_mermaid(graph, true)
            expected_with_reverse = """
            graph LR
                USD -->|0.85| EUR
                EUR -.->|1.18| USD
            """
            @test parse_mermaid_edges(mermaid_with_reverse) ==
                  parse_mermaid_edges(expected_with_reverse)
        end

        @testset "multiple edges" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.85))
            push!(graph, Price("EUR", "GBP", 0.87))
            push!(graph, Price("GBP", "JPY", 155.5))

            # Test without reverse edges
            mermaid = to_mermaid(graph)
            expected = """
            graph LR
                USD -->|0.85| EUR
                EUR -->|0.87| GBP
                GBP -->|155.5| JPY
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)

            # Test with reverse edges
            mermaid_with_reverse = to_mermaid(graph, true)
            expected_with_reverse = """
            graph LR
                USD -->|0.85| EUR
                EUR -->|0.87| GBP
                GBP -->|155.5| JPY
                EUR -.->|1.18| USD
                GBP -.->|1.15| EUR
                JPY -.->|0.01| GBP
            """
            @test parse_mermaid_edges(mermaid_with_reverse) ==
                  parse_mermaid_edges(expected_with_reverse)
        end

        @testset "custom rounding function" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.8523))
            push!(graph, Price("EUR", "GBP", 0.8675))

            # Test with 3 decimal places
            round_3dp = p -> round(p, digits = 3)
            mermaid = to_mermaid(graph, false, round_3dp)
            expected = """
            graph LR
                USD -->|0.852| EUR
                EUR -->|0.868| GBP
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)

            # Test with 1 decimal place
            round_1dp = p -> round(p, digits = 1)
            mermaid = to_mermaid(graph, false, round_1dp)
            expected = """
            graph LR
                USD -->|0.9| EUR
                EUR -->|0.9| GBP
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)
        end

        @testset "graph with cycle" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.85))
            push!(graph, Price("EUR", "GBP", 0.87))
            push!(graph, Price("GBP", "USD", 1.35))

            mermaid = to_mermaid(graph)
            expected = """
            graph LR
                USD -->|0.85| EUR
                EUR -->|0.87| GBP
                GBP -->|1.35| USD
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)
        end

        @testset "graph with existing reverse edges" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.85))
            push!(graph, Price("EUR", "USD", 1.18))  # Explicit reverse edge

            # Test without showing reverse edges
            mermaid = to_mermaid(graph)
            expected = """
            graph LR
                USD -->|0.85| EUR
                EUR -->|1.18| USD
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)

            # Test with showing reverse edges - shouldn't add any since reverse already exists
            mermaid_with_reverse = to_mermaid(graph, true)
            @test parse_mermaid_edges(mermaid_with_reverse) == parse_mermaid_edges(expected)
        end

        @testset "disconnected components" begin
            graph = FXGraph()
            push!(graph, Price("USD", "EUR", 0.85))
            push!(graph, Price("BTC", "ETH", 18.5))  # Disconnected from USD/EUR

            mermaid = to_mermaid(graph)
            expected = """
            graph LR
                USD -->|0.85| EUR
                BTC -->|18.5| ETH
            """
            @test parse_mermaid_edges(mermaid) == parse_mermaid_edges(expected)
        end
    end

end
