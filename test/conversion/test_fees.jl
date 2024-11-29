using CcyConv:
    FixedFeeConversionFunction,
    ProportionalFeeConversionFunction,
    rev_convert,
    calculate_path_value,
    rev_convert_amount

@testset "Fee-based Conversions" begin
    @testset "FixedFeeConversionFunction" begin
        @testset "construction" begin
            @test FixedFeeConversionFunction(1.1, 5.0) isa FixedFeeConversionFunction
            @test_throws ArgumentError FixedFeeConversionFunction(1.1, -1.0)
        end

        @testset "basic conversion" begin
            f = FixedFeeConversionFunction(1.1, 5.0)
            # amount * rate - fee
            @test convert(f, 100.0) ≈ 105.0 rtol = RTOL
            @test convert(f, 1000.0) ≈ 1095.0 rtol = RTOL
            # Check backward conversion
            @test rev_convert(f, 105.0) ≈ 100.0 rtol = RTOL
            @test rev_convert(f, 1095.0) ≈ 1000.0 rtol = RTOL
        end

        @testset "zero fee" begin
            f = FixedFeeConversionFunction(1.1, 0.0)
            @test convert(f, 100.0) ≈ 110.0 rtol = RTOL
            # Check backward conversion
            @test rev_convert(f, 110.0) ≈ 100.0 rtol = RTOL
        end

        @testset "with Price type" begin
            p = Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0))
            @test convert_amount(p, 100.0) ≈ 105.0 rtol = RTOL
            @test price(p) ≈ 1.1 - 5.0 rtol = RTOL
            # Check backward conversion            
            @test rev_convert_amount(p, 105.0) ≈ 100.0 rtol = RTOL
        end

        @testset "reverse price" begin
            p = Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0))
            @test convert_amount(p, 100.0) ≈ 105.0 rtol = RTOL
            r = reverse_price(p)
            @test rev_convert_amount(p, 105.0) ≈ 100.0 rtol = RTOL
        end
    end

    @testset "ProportionalFeeConversionFunction" begin
        @testset "construction" begin
            @test ProportionalFeeConversionFunction(1.1, 0.01) isa
                  ProportionalFeeConversionFunction
            @test_throws ArgumentError ProportionalFeeConversionFunction(1.1, -0.1)
            @test_throws ArgumentError ProportionalFeeConversionFunction(1.1, 1.5)
        end

        @testset "basic conversion" begin
            f = ProportionalFeeConversionFunction(1.1, 0.01)  # 1% fee
            # amount * rate * (1 - fee_percent)
            @test convert(f, 100.0) ≈ 108.9 rtol = RTOL
            @test convert(f, 1000.0) ≈ 1089.0 rtol = RTOL
            # Check backward conversion
            @test rev_convert(f, 108.9) ≈ 100.0 rtol = RTOL
            @test rev_convert(f, 1089.0) ≈ 1000.0 rtol = RTOL
        end

        @testset "zero fee" begin
            f = ProportionalFeeConversionFunction(1.1, 0.0)
            @test convert(f, 100.0) ≈ 110.0 rtol = RTOL
            # Check backward conversion
            @test rev_convert(f, 110.0) ≈ 100.0 rtol = RTOL
        end

        @testset "with Price type" begin
            p = Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.01))
            @test convert_amount(p, 100.0) ≈ 108.9 rtol = RTOL
            @test price(p) ≈ 1.1 * (1 - 0.01) rtol = RTOL
            # Check backward conversion
            @test rev_convert_amount(p, 108.9) ≈ 100.0 rtol = RTOL
        end

        @testset "reverse price" begin
            p = Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.01))
            @test convert_amount(p, 100.0) ≈ 108.9 rtol = RTOL
            r = reverse_price(p)
            @test rev_convert_amount(p, 108.9) ≈ 100.0 rtol = RTOL
        end
    end

    @testset "combining with existing code" begin
        fx = FXGraph()

        # Add prices with different conversion types
        push!(fx, Price("EUR", "USD", 1.1))  # old style
        push!(fx, Price("USD", "GBP", FixedFeeConversionFunction(0.85, 2.0)))
        push!(fx, Price("GBP", "JPY", ProportionalFeeConversionFunction(155.0, 0.01)))

        # Test individual conversions
        eur_usd = fx.edge_nodes[(0x01, 0x02)][1]
        usd_gbp = fx.edge_nodes[(0x02, 0x03)][1]
        gbp_jpy = fx.edge_nodes[(0x03, 0x04)][1]

        @test convert_amount(eur_usd, 100.0) ≈ 110.0 rtol = RTOL
        @test convert_amount(usd_gbp, 110.0) ≈ 91.5 rtol = RTOL
        @test convert_amount(gbp_jpy, 91.5) ≈ 14040.675 rtol = RTOL

        # Test full conversion chain
        @testset "full conversion chain" begin
            path = UInt64[1, 2, 3, 4]
            amount = 100.0
            final_amount, chain = calculate_path_value(fx, path, amount)
            @test final_amount ≈ 14040.675 rtol = RTOL
            @test length(chain) == 3
        end

        # Test reverse conversion
        @testset "reverse conversion" begin
            path = UInt64[4, 3, 2, 1]
            amount = 14040.675
            final_amount, chain = calculate_path_value(fx, path, amount)
            @test final_amount ≈ 100.0 rtol = RTOL
            @test length(chain) == 3
        end
    end
end
