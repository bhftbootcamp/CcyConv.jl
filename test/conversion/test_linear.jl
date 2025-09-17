using CcyConv:
    LinearConversionFunction,
    rev_convert,
    convert_amount,
    price,
    ErrorException,
    AbstractConversionFunction,
    convert,
    Price

@testset "LinearConversionFunction" begin
    @testset "basic conversion" begin
        f = LinearConversionFunction(1.1)
        @test convert(f, 100.0) ≈ 110.0
        @test rev_convert(f, 110.0) ≈ 100.0

        @test convert(f, 0.0) == 0.0
        @test rev_convert(f, 0.0) == 0.0

        @test convert(f, 1000.0) ≈ 1100.0
        @test rev_convert(f, 1100.0) ≈ 1000.0
    end

    @testset "backward compatibility" begin
        # Old style
        p1 = Price("EUR", "USD", 1.1)
        @test price(p1) ≈ 1.1
        @test convert_amount(p1, 100.0) ≈ 110.0

        # New style
        p2 = Price("EUR", "USD", LinearConversionFunction(1.1))
        @test price(p2) ≈ 1.1
        @test convert_amount(p2, 100.0) ≈ 110.0

        # Both should behave the same
        @test price(p1) == price(p2)
        @test convert_amount(p1, 100.0) == convert_amount(p2, 100.0)
    end

    @testset "error handling" begin
        # Create a concrete test type that doesn't implement convert
        struct TestConversionFunction <: AbstractConversionFunction end

        @test_throws ErrorException convert(TestConversionFunction(), 1.0)
    end
end
