using CcyConv: get_currency, UnknownCurrencyError, get_currency_id

@testset "get_currency" begin

    @testset "new graph" begin
        my_graph = FXGraph()
        push!(my_graph, Price("USD", "EUR", 0.85))
        push!(my_graph, Price("EUR", "GBP", 0.87))

        @test get_currency_id(my_graph, "USD") == 0x01
        @test get_currency_id(my_graph, "EUR") == 0x02
        @test get_currency_id(my_graph, "GBP") == 0x03
    end

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
        @test_throws UnknownCurrencyError get_currency(my_graph, invalid_id)
    end

    @testset "empty graph" begin
        empty_graph = FXGraph()
        # Test with ID on empty graph
        @test_throws UnknownCurrencyError get_currency(empty_graph, UInt64(1))
    end
end
