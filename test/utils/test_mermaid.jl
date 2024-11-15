
using CcyConv: to_mermaid

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