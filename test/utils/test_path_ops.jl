using CcyConv: AbstractPrice, calculate_path_value, convert_through_chain

@testset "calculate_path_value" begin
    @testset "simple forward path" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))
        push!(graph, Price("B", "C", 3.0))

        path = UInt64[1, 2, 3]
        amount = 100.0
        final_amount, chain = calculate_path_value(graph, path, amount)
        @test final_amount ≈ 600.0 rtol = RTOL  # 100 * 2 * 3
        @test length(chain) == 2
        @test all(p isa AbstractPrice for p in chain)
    end

    @testset "path with reverse conversion" begin
        graph = FXGraph()
        push!(graph, Price("A", "B", 2.0))
        push!(graph, Price("C", "B", 4.0))

        path = UInt64[1, 2, 3]
        amount = 100.0
        final_amount, chain = calculate_path_value(graph, path, amount)
        @test final_amount ≈ 50.0 rtol = RTOL  # 100 * 2 * (1/4)
        @test length(chain) == 2
    end

    @testset "empty path" begin
        graph = FXGraph()
        amount = 100.0
        final_amount, chain = calculate_path_value(graph, UInt64[], amount)
        @test final_amount == amount
        @test isempty(chain)
    end

    @testset "single node path" begin
        graph = FXGraph()
        amount = 100.0
        final_amount, chain = calculate_path_value(graph, UInt64[1], amount)
        @test final_amount == amount
        @test isempty(chain)
    end
end

@testset "convert_through_chain" begin
    @testset "linear conversions" begin
        chain = [Price("A", "B", 2.0), Price("B", "C", 3.0)]
        amount = 100.0
        @test convert_through_chain(chain, amount) ≈ 600.0 rtol = RTOL  # 100 * 2 * 3
    end

    @testset "with fees" begin
        chain = [
            Price("A", "B", FixedFeeConversionFunction(2.0, 5.0)),
            Price("B", "C", ProportionalFeeConversionFunction(3.0, 0.01)),
        ]
        amount = 100.0
        expected = convert_amount(chain[2], convert_amount(chain[1], amount))
        @test convert_through_chain(chain, amount) ≈ expected rtol = RTOL
    end

    @testset "empty chain" begin
        amount = 100.0
        @test convert_through_chain(AbstractPrice[], amount) == amount
    end
end
