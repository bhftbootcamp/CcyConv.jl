using Test
using CcyConv
using CcyConv:
    from_asset, to_asset, price, convert_amount, rev_convert_amount, reverse_price
using CcyConv:
    LinearConversionFunction, FixedFeeConversionFunction, ProportionalFeeConversionFunction

@testset "Price Tests" begin
    @testset "Construction" begin
        @testset "Basic Construction" begin
            # Test basic float constructor
            p1 = Price("EUR", "USD", 1.1)
            @test p1.from_asset == "EUR"
            @test p1.to_asset == "USD"
            @test p1.conversion isa LinearConversionFunction
            @test price(p1) ≈ 1.1

            # Test with LinearConversionFunction
            p2 = Price("EUR", "USD", LinearConversionFunction(1.1))
            @test p2.from_asset == "EUR"
            @test p2.to_asset == "USD"
            @test p2.conversion isa LinearConversionFunction
            @test price(p2) ≈ 1.1

            # Test with FixedFeeConversionFunction
            p3 = Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0))
            @test p3.from_asset == "EUR"
            @test p3.to_asset == "USD"
            @test p3.conversion isa FixedFeeConversionFunction

            # Test with ProportionalFeeConversionFunction
            p4 = Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.01))
            @test p4.from_asset == "EUR"
            @test p4.to_asset == "USD"
            @test p4.conversion isa ProportionalFeeConversionFunction
        end

        @testset "Edge Cases" begin
            # Same currency
            p = Price("USD", "USD", 1.0)
            @test from_asset(p) == to_asset(p)
            @test price(p) ≈ 1.0

            # Zero rate (should work even if not meaningful)
            p = Price("EUR", "USD", 0.0)
            @test price(p) ≈ 0.0

            # Very small rate
            p = Price("BTC", "USDT", 1e-8)
            @test price(p) ≈ 1e-8

            # Very large rate
            p = Price("SHIB", "BTC", 1e8)
            @test price(p) ≈ 1e8
        end
    end

    @testset "Interface Functions" begin
        @testset "Basic Interface" begin
            p = Price("EUR", "USD", 1.1)

            # Test basic interface methods
            @test from_asset(p) == "EUR"
            @test to_asset(p) == "USD"
            @test price(p) ≈ 1.1

            # Test conversion methods
            @test convert_amount(p, 100.0) ≈ 110.0
            @test rev_convert_amount(p, 110.0) ≈ 100.0
        end

        @testset "Conversion Edge Cases" begin
            p = Price("EUR", "USD", 1.1)

            # Test zero amount
            @test convert_amount(p, 0.0) ≈ 0.0
            @test rev_convert_amount(p, 0.0) ≈ 0.0

            # Test very small amounts
            @test convert_amount(p, 1e-8) ≈ 1.1e-8
            @test rev_convert_amount(p, 1.1e-8) ≈ 1e-8

            # Test very large amounts
            @test convert_amount(p, 1e8) ≈ 1.1e8
            @test rev_convert_amount(p, 1.1e8) ≈ 1e8
        end
    end

    @testset "Conversion Functions" begin
        @testset "Linear Conversion" begin
            p = Price("EUR", "USD", 1.1)

            # Test basic conversion
            @test convert_amount(p, 100.0) ≈ 110.0
            @test rev_convert_amount(p, 110.0) ≈ 100.0

            # Test round-trip conversion
            amount = 100.0
            converted = convert_amount(p, amount)
            reverted = rev_convert_amount(p, converted)
            @test amount ≈ reverted
        end

        @testset "Fixed Fee Conversion" begin
            p = Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0))

            # Test conversion with fee
            @test convert_amount(p, 100.0) ≈ 105.0  # (100 * 1.1) - 5
            @test rev_convert_amount(p, 105.0) ≈ 100.0

            # Test different amounts
            @test convert_amount(p, 1000.0) ≈ 1095.0  # (1000 * 1.1) - 5
            @test rev_convert_amount(p, 1095.0) ≈ 1000.0

            # Test round-trip conversion
            amount = 100.0
            converted = convert_amount(p, amount)
            reverted = rev_convert_amount(p, converted)
            @test amount ≈ reverted
        end

        @testset "Proportional Fee Conversion" begin
            p = Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.01))

            # Test conversion with proportional fee
            @test convert_amount(p, 100.0) ≈ 108.9  # 100 * 1.1 * (1 - 0.01)
            @test rev_convert_amount(p, 108.9) ≈ 100.0

            # Test different amounts
            @test convert_amount(p, 1000.0) ≈ 1089.0  # 1000 * 1.1 * (1 - 0.01)
            @test rev_convert_amount(p, 1089.0) ≈ 1000.0

            # Test round-trip conversion
            amount = 100.0
            converted = convert_amount(p, amount)
            reverted = rev_convert_amount(p, converted)
            @test amount ≈ reverted
        end
    end

    @testset "Reverse Price" begin
        @testset "Basic Reverse" begin
            # Test basic rate reverse
            p = Price("EUR", "USD", 1.1)
            rev_p = reverse_price(p)

            @test from_asset(rev_p) == "USD"
            @test to_asset(rev_p) == "EUR"
            @test convert_amount(rev_p, 110.0) ≈ 100.0
            @test rev_convert_amount(rev_p, 100.0) ≈ 110.0
        end

        @testset "Fee-based Reverse" begin
            # Test reverse with fixed fee
            p1 = Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0))
            rev_p1 = reverse_price(p1)

            amount = 100.0
            forward = convert_amount(p1, amount)
            backward = convert_amount(rev_p1, forward)
            @test amount ≈ backward

            # Test reverse with proportional fee
            p2 = Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.01))
            rev_p2 = reverse_price(p2)

            amount = 100.0
            forward = convert_amount(p2, amount)
            backward = convert_amount(rev_p2, forward)
            @test amount ≈ backward
        end

        @testset "Double Reverse" begin
            # Test that double reverse equals original
            p = Price("EUR", "USD", 1.1)
            double_rev = reverse_price(reverse_price(p))

            amount = 100.0
            original = convert_amount(p, amount)
            double_rev_result = convert_amount(double_rev, amount)
            @test original ≈ double_rev_result
        end
    end

    @testset "Complex Scenarios" begin
        @testset "Chained Conversions" begin
            # Create chain of prices
            p1 = Price("EUR", "USD", 1.1)
            p2 = Price("USD", "GBP", FixedFeeConversionFunction(0.85, 2.0))
            p3 = Price("GBP", "JPY", ProportionalFeeConversionFunction(155.0, 0.01))

            # Test forward chain
            amount = 100.0
            result1 = convert_amount(p1, amount)
            result2 = convert_amount(p2, result1)
            result3 = convert_amount(p3, result2)

            # Test reverse chain
            rev_result3 = rev_convert_amount(p3, result3)
            rev_result2 = rev_convert_amount(p2, rev_result3)
            rev_result1 = rev_convert_amount(p1, rev_result2)

            @test amount ≈ rev_result1
        end

        @testset "Mixed Fee Types" begin
            # Create prices with significant fees to clearly show the difference
            fixed_fee = 5.0
            prop_fee = 0.01  # 1% fee

            p1 = Price("EUR", "USD", FixedFeeConversionFunction(1.0, fixed_fee))
            p2 = Price("USD", "GBP", ProportionalFeeConversionFunction(1.0, prop_fee))

            # Test with small and large amounts
            small_amount = 10.0
            large_amount = 10000.0

            # Calculate effective fee rates
            # For fixed fee price (p1)
            small_fixed_rate = fixed_fee / small_amount  # Should be large (5/10 = 50%)
            large_fixed_rate = fixed_fee / large_amount  # Should be small (5/10000 = 0.05%)

            # For proportional fee price (p2)
            prop_rate = prop_fee  # Always 1%

            # The fixed fee should have a larger relative impact on small amounts
            @test small_fixed_rate > prop_rate
            # The proportional fee should have a larger relative impact on large amounts
            @test large_fixed_rate < prop_rate

            # Verify actual conversion results
            small_result_fixed = convert_amount(p1, small_amount)
            small_result_prop = convert_amount(p2, small_amount)

            large_result_fixed = convert_amount(p1, large_amount)
            large_result_prop = convert_amount(p2, large_amount)

            # Calculate actual fee impacts
            small_fixed_impact = (small_amount - small_result_fixed) / small_amount
            small_prop_impact = (small_amount - small_result_prop) / small_amount

            large_fixed_impact = (large_amount - large_result_fixed) / large_amount
            large_prop_impact = (large_amount - large_result_prop) / large_amount

            # Verify that fixed fee has larger relative impact on small amounts
            @test abs(small_fixed_impact) > abs(small_prop_impact)
            # Verify that proportional fee has larger relative impact on large amounts
            @test abs(large_fixed_impact) < abs(large_prop_impact)
        end
    end
end
