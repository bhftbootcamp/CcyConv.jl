# runtests

using Test
using CcyConv

@testset "Currency Conversion tests" begin
    crypto = FXGraph()

    # Add exchange rates
    push!(crypto, Price("ADA",  "USDT", 0.4037))
    push!(crypto, Price("USDT", "BTC",  2.373717628722553e-5))
    push!(crypto, Price("BTC",  "ETH",  18.80891065680265))
    push!(crypto, Price("ETH",  "ALGO", 14735.46052631579))
    push!(crypto, Price("ALGO", "EOS",  0.2122905027932961))
    push!(crypto, Price("EOS",  "SOL",  0.011661237785016286))
    push!(crypto, Price("SOL",  "AAVE", 0.6190140135094263))
    push!(crypto, Price("AAVE", "DOT",  17.731498033607433))

    @test conv(crypto, "DOT", "AAVE").from_asset == "DOT"
    @test conv(crypto, "DOT", "AAVE").to_asset   == "AAVE"

    # Direct conversion tests
    @test conv(crypto, "ADA", "USDT") |> conv_value ≈ 0.4037
    @test conv(crypto, "USDT", "BTC") |> conv_value ≈ 2.373717628722553e-5
    @test conv(crypto, "BTC", "ETH")  |> conv_value ≈ 18.80891065680265
    @test conv(crypto, "ETH", "ALGO") |> conv_value ≈ 14735.46052631579
    @test conv(crypto, "ALGO", "EOS") |> conv_value ≈ 0.2122905027932961
    @test conv(crypto, "EOS", "SOL")  |> conv_value ≈ 0.011661237785016286
    @test conv(crypto, "SOL", "AAVE") |> conv_value ≈ 0.6190140135094263
    @test conv(crypto, "AAVE", "DOT") |> conv_value ≈ 17.731498033607433

    # 2-step conversion tests
    @test conv(crypto, "ADA", "USDT") |> conv_value ≈ 0.4037
    @test conv(crypto, "ADA", "BTC")  |> conv_value ≈ 9.582698067152947e-6
    @test conv(crypto, "ADA", "ETH")  |> conv_value ≈ 0.00018024011179619518
    @test conv(crypto, "ADA", "ALGO") |> conv_value ≈ 2.6559210526315793
    @test conv(crypto, "ADA", "EOS")  |> conv_value ≈ 0.5638268156424581
    @test conv(crypto, "ADA", "SOL")  |> conv_value ≈ 0.006574918566775245
    @test conv(crypto, "ADA", "AAVE") |> conv_value ≈ 0.004069966730517189
    @test conv(crypto, "ADA", "DOT")  |> conv_value ≈ 0.07216660707901322
    @test conv(crypto, "USDT", "ADA") |> conv_value ≈ 2.477086945751796
    @test conv(crypto, "USDT", "BTC") |> conv_value ≈ 2.373717628722553e-5
    @test conv(crypto, "USDT", "ETH") |> conv_value ≈ 0.0004464704280311994
    @test conv(crypto, "USDT", "ALGO") |> conv_value ≈ 6.578947368421053
    @test conv(crypto, "USDT", "EOS") |> conv_value ≈ 1.3966480446927374
    @test conv(crypto, "USDT", "SOL") |> conv_value ≈ 0.016286644951140065
    @test conv(crypto, "USDT", "AAVE") |> conv_value ≈ 0.010081661457808247
    @test conv(crypto, "USDT", "DOT") |> conv_value ≈ 0.1787629603146228
    @test conv(crypto, "BTC", "ADA")  |> conv_value ≈ 104354.74362150113
    @test conv(crypto, "BTC", "USDT") |> conv_value ≈ 42128.01
    @test conv(crypto, "BTC", "ETH")  |> conv_value ≈ 18.80891065680265
    @test conv(crypto, "BTC", "ALGO") |> conv_value ≈ 277157.96052631584
    @test conv(crypto, "BTC", "EOS")  |> conv_value ≈ 58838.00279329609
    @test conv(crypto, "BTC", "SOL")  |> conv_value ≈ 686.1239413680782
    @test conv(crypto, "BTC", "AAVE") |> conv_value ≈ 424.72033471116043
    @test conv(crypto, "BTC", "DOT")  |> conv_value ≈ 7530.9277797640325
    @test conv(crypto, "ETH", "ADA")  |> conv_value ≈ 5548.154570225415
    @test conv(crypto, "ETH", "USDT") |> conv_value ≈ 2239.79
    @test conv(crypto, "ETH", "BTC")  |> conv_value ≈ 0.05316629007636487
    @test conv(crypto, "ETH", "ALGO") |> conv_value ≈ 14735.46052631579
    @test conv(crypto, "ETH", "EOS")  |> conv_value ≈ 3128.1983240223462
    @test conv(crypto, "ETH", "SOL")  |> conv_value ≈ 36.478664495114
    @test conv(crypto, "ETH", "AAVE") |> conv_value ≈ 22.580804516584333
    @test conv(crypto, "ETH", "DOT")  |> conv_value ≈ 400.391490883089
    @test conv(crypto, "ALGO", "ADA") |> conv_value ≈ 0.37651721575427294
    @test conv(crypto, "ALGO", "USDT") |> conv_value ≈ 0.152
    @test conv(crypto, "ALGO", "BTC") |> conv_value ≈ 3.6080507956582803e-6
    @test conv(crypto, "ALGO", "ETH") |> conv_value ≈ 6.78635050607423e-5
    @test conv(crypto, "ALGO", "EOS") |> conv_value ≈ 0.2122905027932961
    @test conv(crypto, "ALGO", "SOL") |> conv_value ≈ 0.00247557003257329
    @test conv(crypto, "ALGO", "AAVE") |> conv_value ≈ 0.0015324125415868534
    @test conv(crypto, "ALGO", "DOT") |> conv_value ≈ 0.027171969967822666
    @test conv(crypto, "EOS", "ADA")  |> conv_value ≈ 1.7735942531582858
    @test conv(crypto, "EOS", "USDT") |> conv_value ≈ 0.716
    @test conv(crypto, "EOS", "BTC")  |> conv_value ≈ 1.699581822165348e-5
    @test conv(crypto, "EOS", "ETH")  |> conv_value ≈ 0.00031967282647033874
    @test conv(crypto, "EOS", "ALGO") |> conv_value ≈ 4.7105263157894735
    @test conv(crypto, "EOS", "SOL")  |> conv_value ≈ 0.011661237785016286
    @test conv(crypto, "EOS", "AAVE") |> conv_value ≈ 0.007218469603790704
    @test conv(crypto, "EOS", "DOT")  |> conv_value ≈ 0.12799427958526993
    @test conv(crypto, "SOL", "ADA")  |> conv_value ≈ 152.09313846916027
    @test conv(crypto, "SOL", "USDT") |> conv_value ≈ 61.4
    @test conv(crypto, "SOL", "BTC")  |> conv_value ≈ 0.0014574626240356475
    @test conv(crypto, "SOL", "ETH")  |> conv_value ≈ 0.02741328428111564
    @test conv(crypto, "SOL", "ALGO") |> conv_value ≈ 403.94736842105266
    @test conv(crypto, "SOL", "EOS")  |> conv_value ≈ 85.75418994413407
    @test conv(crypto, "SOL", "AAVE") |> conv_value ≈ 0.6190140135094263
    @test conv(crypto, "SOL", "DOT")  |> conv_value ≈ 10.97604576331784
    @test conv(crypto, "AAVE", "ADA") |> conv_value ≈ 245.70225414912062
    @test conv(crypto, "AAVE", "USDT") |> conv_value ≈ 99.19
    @test conv(crypto, "AAVE", "BTC") |> conv_value ≈ 0.0023544905159299002
    @test conv(crypto, "AAVE", "ETH") |> conv_value ≈ 0.04428540175641466
    @test conv(crypto, "AAVE", "ALGO") |> conv_value ≈ 652.5657894736843
    @test conv(crypto, "AAVE", "EOS") |> conv_value ≈ 138.5335195530726
    @test conv(crypto, "AAVE", "SOL") |> conv_value ≈ 1.615472312703583
    @test conv(crypto, "AAVE", "DOT") |> conv_value ≈ 17.731498033607433
    @test conv(crypto, "DOT", "ADA")  |> conv_value ≈ 13.856824374535547
    @test conv(crypto, "DOT", "USDT") |> conv_value ≈ 5.594
    @test conv(crypto, "DOT", "BTC")  |> conv_value ≈ 0.00013278576415073963
    @test conv(crypto, "DOT", "ETH")  |> conv_value ≈ 0.0024975555744065295
    @test conv(crypto, "DOT", "ALGO") |> conv_value ≈ 36.80263157894737
    @test conv(crypto, "DOT", "EOS")  |> conv_value ≈ 7.812849162011173
    @test conv(crypto, "DOT", "SOL")  |> conv_value ≈ 0.09110749185667753
    @test conv(crypto, "DOT", "AAVE") |> conv_value ≈ 0.056396814194979335
end

@testset "Max/Min rate pathfinding" begin
    #=
        A --2.0--> B --3.0--> D --0.5--> F
        A --1.5--> C --4.0--> D
                   C --2.0--> E --3.0--> F
    =#
    fx = FXGraph()
    push!(fx, Price("A", "B", 2.0))
    push!(fx, Price("B", "D", 3.0))
    push!(fx, Price("D", "F", 0.5))
    push!(fx, Price("A", "C", 1.5))
    push!(fx, Price("C", "D", 5.0))
    push!(fx, Price("C", "E", 2.0))
    push!(fx, Price("E", "F", 3.0))

    # Identity
    @test conv(fx, "A", "A", DFS()) |> conv_value == 1.0

    # Disconnected
    @test conv(fx, "A", "Y", DFS()) |> conv_value |> isnan

    # Min rate A→F: A→B→D→F = 2.0 * 3.0 * 0.5 = 3.0
    @test conv(fx, "A", "F", DFS()) |> conv_value ≈ 3.0

    # Min F→A: inverse of max A→F path = 1/9.0
    @test conv(fx, "F", "A", DFS()) |> conv_value ≈ 1.0 / 9.0

    # Chain correctness for min A→F
    min_chain = conv(fx, "A", "F", DFS()) |> conv_chain
    @test length(min_chain) == 3
    @test min_chain[1] == Price("A", "B", 2.0)
    @test min_chain[2] == Price("B", "D", 3.0)
    @test min_chain[3] == Price("D", "F", 0.5)

    # conv(AStar()) should match conv(DFS())
    @test conv(fx, "A", "F") |> conv_value ≈ 3.0
    @test conv(fx, "F", "A") |> conv_value ≈ 1.0 / 9.0
    @test conv(fx, "A", "F") |> conv_chain == min_chain
end

@testset "Utility functions" begin
    fx = FXGraph()
    push!(fx, Price("A", "B", 2.0))
    push!(fx, Price("B", "C", 3.0))

    # conv_ccys
    @test conv_ccys(fx) |> sort == ["A", "B", "C"]

    # conv_safe_value
    @test conv(fx, "A", "B") |> conv_safe_value == 2.0
    @test_throws AssertionError conv(fx, "A", "X") |> conv_safe_value

    # Price equality
    @test Price("A", "B", 1.0) == Price("A", "B", 1.0)
    @test Price("A", "B", 1.0) != Price("A", "B", 2.0)
    @test Price("A", "B", 1.0) != Price("B", "A", 1.0)

    # Price hash
    @test hash(Price("A", "B", 1.0)) == hash(Price("A", "B", 1.0))
    @test hash(Price("A", "B", 1.0)) != hash(Price("A", "B", 2.0))
end

@testset "FXGraph construction" begin
    # Vector constructor
    fx = FXGraph([Price("A", "B", 2.0), Price("B", "C", 3.0)])
    @test conv(fx, "A", "C") |> conv_value ≈ 6.0

    # Empty graph
    fx = FXGraph()
    @test conv(fx, "A", "B") |> conv_value |> isnan
    @test conv_ccys(fx) |> isempty
end

@testset "Edge cases" begin
    fx = FXGraph()
    push!(fx, Price("A", "B", 2.0))

    # Identity
    @test conv(fx, "A", "A") |> conv_value == 1.0

    # Unknown currency
    @test conv(fx, "A", "Z") |> conv_value |> isnan

    # Reverse direction (inverse rate)
    @test conv(fx, "B", "A") |> conv_value ≈ 0.5

    # Self-loop on a node should be ignored (no simple path can revisit it).
    fx_self = FXGraph()
    push!(fx_self, Price("A", "A", 1.5))
    push!(fx_self, Price("A", "B", 2.0))
    @test conv(fx_self, "A", "B") |> conv_value ≈ 2.0

    # Both directions stored as non-inverse rates (bid/ask) — `_weight_matrix`
    # must agree with `_w` on each direction independently.
    fx_ba = FXGraph()
    push!(fx_ba, Price("A", "B", 2.0))
    push!(fx_ba, Price("B", "A", 0.6))
    push!(fx_ba, Price("B", "C", 3.0))
    push!(fx_ba, Price("C", "B", 0.4))
    @test conv(fx_ba, "A", "C") |> conv_value ≈ 6.0
    @test conv(fx_ba, "C", "A") |> conv_value ≈ 0.24
end

@testset "NaN edges bypass" begin
    # A→B is NaN, but alternative path A→C→B exists.
    fx = FXGraph()
    push!(fx, Price("A", "B", NaN))
    push!(fx, Price("A", "C", 2.0))
    push!(fx, Price("C", "B", 3.0))
    @test conv(fx, "A", "B") |> conv_value ≈ 6.0
    @test conv(fx, "A", "B", DFS()) |> conv_value ≈ 6.0

    # All paths to target contain NaN — should return NaN.
    fx2 = FXGraph()
    push!(fx2, Price("A", "B", NaN))
    @test conv(fx2, "A", "B") |> conv_value |> isnan
    @test conv(fx2, "A", "B", DFS()) |> conv_value |> isnan

    # Multiple prices per edge: first is NaN, second is valid.
    fx3 = FXGraph()
    push!(fx3, Price("A", "B", NaN))
    push!(fx3, Price("A", "B", 5.0))
    @test conv(fx3, "A", "B") |> conv_value ≈ 5.0
    @test conv(fx3, "A", "B", DFS()) |> conv_value ≈ 5.0
end

@testset "Property: conv(AStar()) == conv(DFS()) (random graphs)" begin
    using Random
    Random.seed!(12345)
    mismatches = 0
    runs = 0
    for trial in 1:30
        n_nodes = rand(4:8)
        fx = FXGraph()
        nodes = ["N$i" for i in 1:n_nodes]
        used = Set{Tuple{Int,Int}}()
        for i in 1:n_nodes-1
            push!(fx, Price(nodes[i], nodes[i+1], exp(randn() * 1.5)))
            push!(used, (i, i+1)); push!(used, (i+1, i))
        end
        for _ in 1:rand(1:6)
            i, j = rand(1:n_nodes), rand(1:n_nodes)
            i == j && continue
            (i, j) in used && continue
            push!(fx, Price(nodes[i], nodes[j], exp(randn() * 1.5)))
            push!(used, (i, j)); push!(used, (j, i))
        end
        for s in nodes, t in nodes
            s == t && continue
            ra = conv_value(conv(fx, s, t))
            rm = conv_value(conv(fx, s, t, DFS()))
            runs += 1
            if !(isapprox(ra, rm; rtol=1e-9, atol=1e-12) || (isnan(ra) && isnan(rm)))
                mismatches += 1
            end
        end
    end
    @test mismatches == 0
    @test runs > 100
end
