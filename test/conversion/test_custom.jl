using CcyConv:
    FunctionWrapper,
    convert,
    rev_convert,
    TieredBonusConversionFunction,
    CompositeConversionFunction

@testset "Custom Conversion Functions" begin
    @testset "FunctionWrapper" begin
        @testset "basic usage" begin
            # Simple conversion function
            f = FunctionWrapper(amount -> amount * 1.1)
            @test convert(f, 100.0) ≈ 110.0 rtol = RTOL
            # Check backward conversion
            #@test rev_convert(f, 110.0) ≈ 100.0 rtol = RTOL

            # Function with parameters
            f = FunctionWrapper(
                (amount; rate, fee) -> amount * rate + fee;
                params = (rate = 1.1, fee = 5.0),
            )
            @test convert(f, 100.0) ≈ 115.0 rtol = RTOL
            # Check backward conversion
            #@test rev_convert(f, 115.0) ≈ 100.0 rtol = RTOL
        end

        @testset "with Price type" begin
            p = Price("EUR", "USD", FunctionWrapper(amount -> amount * 1.1 + 5.0))
            @test convert_amount(p, 100.0) ≈ 115.0 rtol = RTOL
            @test price(p) ≈ 6.1 rtol = RTOL  # 1.0 * 1.1 + 5.0
            # Check backward conversion
            #@test rev_convert_amount(p, 115.0) ≈ 100.0 rtol = RTOL
        end

        @testset "reverse price" begin
            p = Price("EUR", "USD", FunctionWrapper(amount -> amount * 1.1 + 5.0))
            @test convert_amount(p, 100.0) ≈ 115.0 rtol = RTOL
            #r = reverse_price(p)
            #@test rev_convert_amount(p, 115.0) ≈ 100.0 rtol = RTOL
        end
    end

    @testset "CompositeConversionFunction" begin
        @testset "basic composition" begin
            # Combine rate and fixed fee
            f = CompositeConversionFunction([
                LinearConversionFunction(1.1),
                FixedFeeConversionFunction(1.0, 5.0),
            ])
            @test convert(f, 100.0) ≈ 105.0 rtol = RTOL  # (100 * 1.1) -> 110, then (110 * 1 - 5) -> 105
            # Check backward conversion
            @test rev_convert(f, 105.0) ≈ 100.0 rtol = RTOL  # (105 + 5) / 1.1 -> 100

            # More complex composition with detailed calculation:
            # 1. LinearConversionFunction(1.1):     100.0 * 1.1 = 110.0
            # 2. ProportionalFeeConversionFunction: 110.0 * (1 - 0.01) = 108.9
            # 3. FixedFeeConversionFunction:        108.9 * 1.0 - 5.0 = 103.9
            f = CompositeConversionFunction([
                LinearConversionFunction(1.1),
                ProportionalFeeConversionFunction(1.0, 0.01),
                FixedFeeConversionFunction(1.0, 5.0),
            ])
            @test convert(f, 100.0) ≈ 103.9 rtol = RTOL
            # Check backward conversion
            @test rev_convert(f, 103.9) ≈ 100.0 rtol = RTOL
        end

        @testset "with Price type" begin
            p = Price(
                "EUR",
                "USD",
                CompositeConversionFunction([
                    LinearConversionFunction(1.1),
                    FixedFeeConversionFunction(1.0, 5.0),
                ]),
            )
            @test convert_amount(p, 100.0) ≈ 105.0 rtol = RTOL  # (100 * 1.1) -> 110, then (110 * 1 - 5) -> 105
            # Check backward conversion
            @test rev_convert_amount(p, 105.0) ≈ 100.0 rtol = RTOL

            # Reverse price
            r = reverse_price(p)
            @test convert_amount(r, 105.0) ≈ 100.0 rtol = RTOL
        end
    end

    @testset "TieredBonusConversion tests" begin
        @testset "basic tiers" begin
            base_rate = 1.1
            tiers = [
                (1000.0, 0.02),    # 2% bonus
                (10000.0, 0.05),   # 5% bonus
            ]
            f = TieredBonusConversionFunction(base_rate, tiers)

            # Base rate tests
            @test convert(f, 100.0) ≈ 110.0 rtol = RTOL      # Base rate only
            @test convert(f, 1000.0) ≈ 1122.0 rtol = RTOL    # With 2% bonus: 1000 * 1.1 * 1.02
            @test convert(f, 10000.0) ≈ 11550.0 rtol = RTOL  # With 5% bonus: 10000 * 1.1 * 1.05

            # Check backward conversion
            @test rev_convert(f, 110.0) ≈ 100.0 rtol = RTOL
            @test rev_convert(f, 1122.0) ≈ 1000.0 rtol = RTOL
            @test rev_convert(f, 11550.0) ≈ 10000.0 rtol = RTOL
        end

        @testset "tiers with fee" begin
            f = TieredBonusConversionFunction(
                1.1,  # base rate
                [
                    (1000.0, 0.02),    # 2% bonus
                    (10000.0, 0.05),   # 5% bonus
                ],
                fee = 5.0,
            )

            # Forward conversion tests
            @test convert(f, 100.0) ≈ 105.0 rtol = RTOL      # Base rate - fee
            @test convert(f, 1000.0) ≈ 1117.0 rtol = RTOL    # With 2% bonus - fee
            @test convert(f, 10000.0) ≈ 11545.0 rtol = RTOL  # With 5% bonus - fee

            # Backward conversion tests
            @test rev_convert(f, 105.0) ≈ 100.0 rtol = RTOL
            @test rev_convert(f, 1117.0) ≈ 1000.0 rtol = RTOL
            @test rev_convert(f, 11545.0) ≈ 10000.0 rtol = RTOL
        end

        @testset "with Price type" begin
            p = Price(
                "EUR",
                "USD",
                TieredBonusConversionFunction(
                    1.1,
                    [(1000.0, 0.02)],  # 2% bonus above 1000
                    fee = 5.0,
                ),
            )

            @test convert_amount(p, 100.0) ≈ 105.0 rtol = RTOL   # Base rate - fee
            @test convert_amount(p, 1000.0) ≈ 1117.0 rtol = RTOL # With 2% bonus - fee

            # Backward conversion tests
            @test rev_convert_amount(p, 105.0) ≈ 100.0 rtol = RTOL
            @test rev_convert_amount(p, 1117.0) ≈ 1000.0 rtol = RTOL

            # Reverse price
            r = reverse_price(p)
            @test convert_amount(r, 105.0) ≈ 100.0 rtol = RTOL
        end

        @testset "boundary values" begin
            f = TieredBonusConversionFunction(
                1.1,
                [(1000.0, 0.02), (10000.0, 0.05)],
                fee = 5.0,
            )

            # Test just below, at, and just above first tier
            @test convert(f, 999.0) ≈ 1093.9 rtol = RTOL     # Base rate only
            @test convert(f, 1000.0) ≈ 1117.0 rtol = RTOL    # First bonus kicks in
            @test convert(f, 1001.0) ≈ 1118.122 rtol = RTOL  # First bonus continues

            # Test just below, at, and just above second tier
            @test convert(f, 9999.0) ≈ 11213.878 rtol = RTOL  # First bonus only
            @test convert(f, 10000.0) ≈ 11545.0 rtol = RTOL   # Second bonus kicks in
            @test convert(f, 10001.0) ≈ 11546.155 rtol = RTOL # Second bonus continues

            # Round-trip tests at boundaries
            for amount in [999.0, 1000.0, 1001.0, 9999.0, 10000.0, 10001.0]
                converted = convert(f, amount)
                reversed = rev_convert(f, converted)
                @test isapprox(amount, reversed, rtol = RTOL)
            end
        end

        @testset "error conditions" begin
            # Test invalid bonus rates
            @test_throws AssertionError TieredBonusConversionFunction(
                1.1,
                [(1000.0, -0.01)],
            )

            # Test negative amounts (we need to add this check to the convert function)
            f = TieredBonusConversionFunction(1.1, [(1000.0, 0.02)], fee = 5.0)
            @test_throws DomainError convert(f, -100.0)
        end

        @testset "comprehensive value tests" begin
            f = TieredBonusConversionFunction(
                1.1,
                [(1000.0, 0.02), (10000.0, 0.05)],
                fee = 5.0,
            )

            test_cases = [
                (100.0, 105.0),     # Below first tier: 100 * 1.1 - 5
                (500.0, 545.0),     # Below first tier: 500 * 1.1 - 5
                (999.0, 1093.9),    # Just below first tier: 999 * 1.1 - 5
                (1000.0, 1117.0),    # At first tier: 1000 * 1.1 * 1.02 - 5
                (1001.0, 1118.122),  # Just above first tier: 1001 * 1.1 * 1.02 - 5
                (5000.0, 5605.0),    # Between tiers: 5000 * 1.1 * 1.02 - 5
                (9999.0, 11213.878), # Just below second tier: 9999 * 1.1 * 1.02 - 5
                (10000.0, 11545.0),   # At second tier: 10000 * 1.1 * 1.05 - 5
                (10001.0, 11546.155), # Just above second tier: 10001 * 1.1 * 1.05 - 5
                (15000.0, 17320.0),    # Well above all tiers: 15000 * 1.1 * 1.05 - 5
            ]

            for (input, expected) in test_cases
                @test convert(f, input) ≈ expected rtol = RTOL
                @test rev_convert(f, convert(f, input)) ≈ input rtol = RTOL
            end
        end
    end
end
