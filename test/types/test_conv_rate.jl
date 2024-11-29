using CcyConv: ConvRate, InvalidConversionError, conv_safe_value, FXGraph, Price
using CcyConv.Pathfinding.AStar: conv as conv_a_star

@testset "conv_safe_value" begin
    @testset "valid conversions" begin
        # Test normal conversion rate
        rate = ConvRate("USD", "EUR", 0.85)
        @test conv_safe_value(rate) ≈ 0.85

        # Test zero conversion rate
        rate_zero = ConvRate("USD", "EUR", 0.0)
        @test conv_safe_value(rate_zero) == 0.0

        # Test very small conversion rate
        rate_small = ConvRate("BTC", "USD", 0.000001)
        @test conv_safe_value(rate_small) ≈ 0.000001
    end

    @testset "invalid conversions" begin
        # Test NaN conversion rate
        rate_nan = ConvRate("USD", "XXX", NaN)
        @test_throws InvalidConversionError conv_safe_value(rate_nan)

        # Verify error message content
        try
            conv_safe_value(rate_nan)
        catch e
            @test e isa InvalidConversionError
            @test e.message == "Conversion rate is NaN: NaN"
            @test e.from_asset == "USD"
            @test e.to_asset == "XXX"
            @test e.details == "No valid conversion path exists between currencies"
        end
    end

    @testset "integration with FXGraph" begin
        fx = FXGraph()
        push!(fx, Price("USD", "EUR", 0.85))

        # Test valid conversion through graph
        valid_rate = conv_a_star(fx, "USD", "EUR")
        @test conv_safe_value(valid_rate) ≈ 0.85

        # Test invalid conversion through graph
        invalid_rate = conv_a_star(fx, "USD", "GBP")
        @test_throws InvalidConversionError conv_safe_value(invalid_rate)
    end
end
