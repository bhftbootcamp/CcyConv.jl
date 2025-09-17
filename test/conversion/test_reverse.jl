using CcyConv:
    LinearConversionFunction,
    ReverseConversionFunction,
    FixedFeeConversionFunction,
    ProportionalFeeConversionFunction,
    TieredBonusConversionFunction,
    convert,
    rev_convert,
    rev_convert_amount

@testset "ReverseConversionFunction" begin
    @testset "basic reversing" begin
        # Create a simple linear conversion (rate = 1.1)
        f = LinearConversionFunction(1.1)

        # Create its reverse
        r = ReverseConversionFunction(f)

        # Test forward conversion (should use original's reverse)
        @test convert(r, 110.0) ≈ 100.0 rtol = RTOL

        # Test reverse conversion (should use original's forward)
        @test rev_convert(r, 100.0) ≈ 110.0 rtol = RTOL

        # Test with Price type
        p = Price("EUR", "USD", r)
        @test convert_amount(p, 110.0) ≈ 100.0 rtol = RTOL
        @test rev_convert_amount(p, 100.0) ≈ 110.0 rtol = RTOL
    end

    @testset "reverse of reverse" begin
        # Original function
        f = LinearConversionFunction(1.1)

        # First reverse
        r1 = ReverseConversionFunction(f)

        # Reverse of reverse (should return original)
        r2 = ReverseConversionFunction(r1)

        # Should be identical to original function
        @test r2 === f

        # Test conversions
        amount = 100.0
        @test convert(r2, amount) ≈ convert(f, amount) rtol = RTOL
        @test rev_convert(r2, amount) ≈ rev_convert(f, amount) rtol = RTOL
    end

    @testset "with different conversion types" begin
        # Test with fixed fee conversion
        f1 = FixedFeeConversionFunction(1.1, 5.0)
        r1 = ReverseConversionFunction(f1)

        # Original function:
        # forward: amount * 1.1 - 5.0
        # reverse: (amount + 5.0) / 1.1

        # For amount = 100:
        # Original forward: 100 * 1.1 - 5 = 105
        # Original reverse: (105 + 5) / 1.1 = 100

        @test convert(f1, 100.0) ≈ 105.0 rtol = RTOL  # Forward
        @test rev_convert(f1, 105.0) ≈ 100.0 rtol = RTOL  # Reverse

        # Reversed function should swap these:
        @test convert(r1, 105.0) ≈ 100.0 rtol = RTOL  # Uses original's reverse
        @test rev_convert(r1, 100.0) ≈ 105.0 rtol = RTOL  # Uses original's forward

        # Test with proportional fee conversion
        f2 = ProportionalFeeConversionFunction(1.1, 0.01)  # 1% fee
        r2 = ReverseConversionFunction(f2)

        # Original function:
        # forward: amount * 1.1 * (1 - 0.01)
        # reverse: amount / (1.1 * (1 - 0.01))

        # For amount = 100:
        # Original forward: 100 * 1.1 * 0.99 = 108.9
        # Original reverse: 108.9 / (1.1 * 0.99) = 100

        @test convert(f2, 100.0) ≈ 108.9 rtol = RTOL
        @test rev_convert(f2, 108.9) ≈ 100.0 rtol = RTOL

        # Reversed function should swap these:
        @test convert(r2, 108.9) ≈ 100.0 rtol = RTOL
        @test rev_convert(r2, 100.0) ≈ 108.9 rtol = RTOL

        # Test with tiered bonus conversion
        f3 = TieredBonusConversionFunction(1.1, [(1000.0, 0.02)], fee = 5.0)
        r3 = ReverseConversionFunction(f3)

        # For amount = 1000:
        # Original forward: 1000 * 1.1 * 1.02 - 5 = 1117
        # Original reverse: rev_convert(f3, 1117) = 1000

        @test convert(f3, 1000.0) ≈ 1117.0 rtol = RTOL
        @test rev_convert(f3, 1117.0) ≈ 1000.0 rtol = RTOL

        # Reversed function should swap these:
        @test convert(r3, 1117.0) ≈ 1000.0 rtol = RTOL
        @test rev_convert(r3, 1000.0) ≈ 1117.0 rtol = RTOL
    end
end
