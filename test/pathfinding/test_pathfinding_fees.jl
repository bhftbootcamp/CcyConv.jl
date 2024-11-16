using CcyConv: convert_through_chain

@testset "Fee-based paths" begin
    conv_max = CcyConv.Pathfinding.DFSPathFinder.conv_max
    conv_min = CcyConv.Pathfinding.DFSPathFinder.conv_min

    @testset "fixed fees - path selection" begin
        fx = FXGraph()

        push!(fx, Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0)))
        push!(fx, Price("EUR", "GBP", 0.85))
        push!(fx, Price("GBP", "USD", 1.25))

        let amount = 10.0
            result = conv_max(fx, "EUR", "USD", amount = amount)
            converted_amount = convert_through_chain(conv_chain(result), amount)
            @test converted_amount ≈ 10.625 rtol = RTOL
            @test length(conv_chain(result)) == 2  # EUR -> GBP -> USD
        end

        let amount = 1000.0
            result = conv_max(fx, "EUR", "USD", amount = amount)
            converted_amount = convert_through_chain(conv_chain(result), amount)
            @test converted_amount ≈ 1095.0 rtol = RTOL
            @test length(conv_chain(result)) == 1  # EUR -> USD
        end
    end

    @testset "proportional fees - path selection" begin
        fx = FXGraph()

        # Two possible paths EUR -> USD:
        push!(fx, Price("EUR", "USD", ProportionalFeeConversionFunction(1.1, 0.02)))
        push!(fx, Price("EUR", "GBP", ProportionalFeeConversionFunction(0.85, 0.01)))
        push!(fx, Price("GBP", "USD", ProportionalFeeConversionFunction(1.25, 0.01)))

        let amount = 100.0
            result = conv_max(fx, "EUR", "USD", amount = amount)
            converted_amount = convert_amount(conv_chain(result)[1], amount)
            # Direct path (100 * 1.1 * 0.98 = 107.8) should beat
            # Indirect path (100 * 0.85 * 0.99 * 1.25 * 0.99 ≈ 104.7)
            @test converted_amount ≈ 107.8 rtol = RTOL
            @test length(conv_chain(result)) == 1
        end
    end

    @testset "mixed fees" begin
        fx = FXGraph()

        push!(fx, Price("EUR", "USD", FixedFeeConversionFunction(1.1, 5.0)))
        push!(fx, Price("EUR", "GBP", ProportionalFeeConversionFunction(0.85, 0.01)))
        push!(fx, Price("GBP", "USD", ProportionalFeeConversionFunction(1.25, 0.01)))

        # Test specific conversion amounts
        let amount = 10.0
            result = conv_max(fx, "EUR", "USD", amount = amount)
            # Proportional path should win for small amounts
            @test length(conv_chain(result)) == 2
            chain = result |> conv_chain
            converted_amount = convert_through_chain(chain, amount)
            @test converted_amount ≈ (10.0 * 0.85 * 0.99 * 1.25 * 0.99) rtol = RTOL
        end

        let amount = 10000.0
            result = conv_max(fx, "EUR", "USD", amount = amount)
            # Fixed fee path should win for large amounts
            @test length(conv_chain(result)) == 1
            chain = result |> conv_chain
            converted_amount = convert_through_chain(chain, amount)
            @test converted_amount ≈ (10000.0 * 1.1 - 5.0) rtol = RTOL
        end
    end
end
