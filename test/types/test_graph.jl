using Test
using CcyConv
using CcyConv:
    FixedFeeConversionFunction, ProportionalFeeConversionFunction, LinearConversionFunction
using Graphs

@testset "FXGraph Tests" begin
    @testset "Construction" begin
        # Test basic construction
        graph = FXGraph()
        @test isempty(graph.edge_nodes)
        @test isempty(graph.edge_encode)
        @test nv(graph.graph) == 0
        @test ne(graph.graph) == 0
    end

    @testset "Adding Prices" begin
        graph = FXGraph()

        # Test adding single price
        price1 = Price("USD", "EUR", 0.85)
        push!(graph, price1)
        @test length(graph.edge_nodes) == 1
        @test length(graph.edge_encode) == 2
        @test nv(graph.graph) == 2
        @test ne(graph.graph) == 1

        # Test adding multiple prices for same pair
        price2 = Price("USD", "EUR", 0.86)
        push!(graph, price2)
        @test length(graph.edge_nodes) == 1
        @test length(graph.edge_encode) == 2
        @test length(graph.edge_nodes[(0x01, 0x02)]) == 2

        # Test adding price with new currencies
        price3 = Price("GBP", "JPY", 155.0)
        push!(graph, price3)
        @test length(graph.edge_nodes) == 2
        @test length(graph.edge_encode) == 4
        @test nv(graph.graph) == 4
        @test ne(graph.graph) == 2
    end

    @testset "Appending Multiple Prices" begin
        graph = FXGraph()
        prices = [
            Price("EUR", "USD", 1.18),
            Price("USD", "JPY", 110.0),
            Price("JPY", "GBP", 0.0067),
        ]

        append!(graph, prices)
        @test length(graph.edge_nodes) == 3
        @test length(graph.edge_encode) == 4
        @test nv(graph.graph) == 4
        @test ne(graph.graph) == 3
    end

    @testset "Currency Listing" begin
        graph = FXGraph()
        prices = [
            Price("EUR", "USD", 1.18),
            Price("USD", "JPY", 110.0),
            Price("JPY", "GBP", 0.0067),
        ]
        append!(graph, prices)

        currencies = conv_ccys(graph)
        @test length(currencies) == 4
        @test Set(currencies) == Set(["EUR", "USD", "JPY", "GBP"])
    end

    @testset "Edge Cases" begin
        graph = FXGraph()

        # Test circular references
        push!(graph, Price("USD", "EUR", 0.85))
        push!(graph, Price("EUR", "GBP", 0.87))
        push!(graph, Price("GBP", "USD", 1.35))

        @test length(graph.edge_nodes) == 3
        @test length(graph.edge_encode) == 3
        @test nv(graph.graph) == 3
        @test ne(graph.graph) == 3

        # Test self-reference (should work but might not be meaningful)
        push!(graph, Price("USD", "USD", 1.0))
        @test length(graph.edge_nodes) == 4
        @test length(graph.edge_encode) == 3
    end

    @testset "Integration with Conversion Types" begin
        graph = FXGraph()

        # Test with different conversion function types
        push!(graph, Price("USD", "EUR", 0.85))  # Linear conversion
        push!(graph, Price("EUR", "GBP", FixedFeeConversionFunction(0.87, 1.0)))  # With fixed fee
        push!(graph, Price("GBP", "JPY", ProportionalFeeConversionFunction(155.0, 0.01)))  # With proportional fee

        @test length(graph.edge_nodes) == 3
        @test length(graph.edge_encode) == 4
        @test nv(graph.graph) == 4
        @test ne(graph.graph) == 3

        # Verify conversion types are preserved
        @test graph.edge_nodes[(0x01, 0x02)][1].conversion isa LinearConversionFunction
        @test graph.edge_nodes[(0x02, 0x03)][1].conversion isa FixedFeeConversionFunction
        @test graph.edge_nodes[(0x03, 0x04)][1].conversion isa
              ProportionalFeeConversionFunction
    end

    @testset "Graph Operations" begin
        graph = FXGraph()
        prices = [
            Price("EUR", "USD", 1.18),
            Price("USD", "JPY", 110.0),
            Price("JPY", "GBP", 0.0067),
        ]
        append!(graph, prices)

        # Test graph connectivity
        @test has_edge(graph.graph, 1, 2)  # EUR -> USD
        @test has_edge(graph.graph, 2, 3)  # USD -> JPY
        @test has_edge(graph.graph, 3, 4)  # JPY -> GBP
        @test !has_edge(graph.graph, 1, 4) # EUR -> GBP (not direct)

        # Test vertex mapping
        @test graph.edge_encode["EUR"] == 0x01
        @test graph.edge_encode["USD"] == 0x02
        @test graph.edge_encode["JPY"] == 0x03
        @test graph.edge_encode["GBP"] == 0x04
    end
end
