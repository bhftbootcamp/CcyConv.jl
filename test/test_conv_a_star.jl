@testset "conv_a_star" begin
    crypto = FXGraph()

    # Add exchange rates
    crypto = push!(crypto, Price("ADA", "USDT", 0.4037))
    crypto = push!(crypto, Price("USDT", "BTC", 2.373717628722553e-5))
    crypto = push!(crypto, Price("BTC", "ETH", 18.80891065680265))
    crypto = push!(crypto, Price("ETH", "ALGO", 14735.46052631579))
    crypto = push!(crypto, Price("ALGO", "EOS", 0.2122905027932961))
    crypto = push!(crypto, Price("EOS", "SOL", 0.011661237785016286))
    crypto = push!(crypto, Price("SOL", "AAVE", 0.6190140135094263))
    crypto = push!(crypto, Price("AAVE", "DOT", 17.731498033607433))

    @test conv_a_star(crypto, "DOT", "AAVE").from_asset == "DOT"
    @test conv_a_star(crypto, "DOT", "AAVE").to_asset   == "AAVE"
    @test conv_a_star(crypto, "DOT", "AAVE").from_asset == "DOT"
    @test conv_a_star(crypto, "DOT", "AAVE").to_asset   == "AAVE"

    # Direct conversion tests
    @test conv_a_star(crypto, "ADA", "USDT") |> conv_value ≈ 0.4037
    @test conv_a_star(crypto, "USDT", "BTC") |> conv_value ≈ 2.373717628722553e-5
    @test conv_a_star(crypto, "BTC", "ETH")  |> conv_value ≈ 18.80891065680265
    @test conv_a_star(crypto, "ETH", "ALGO") |> conv_value ≈ 14735.46052631579
    @test conv_a_star(crypto, "ALGO", "EOS") |> conv_value ≈ 0.2122905027932961
    @test conv_a_star(crypto, "EOS", "SOL")  |> conv_value ≈ 0.011661237785016286
    @test conv_a_star(crypto, "SOL", "AAVE") |> conv_value ≈ 0.6190140135094263
    @test conv_a_star(crypto, "AAVE", "DOT") |> conv_value ≈ 17.731498033607433

    # 2-step conversion tests
    @test conv_a_star(crypto, "ADA", "USDT") |> conv_value ≈ 0.4037
    @test conv_a_star(crypto, "ADA", "BTC")  |> conv_value ≈ 9.582698067152947e-6
    @test conv_a_star(crypto, "ADA", "ETH")  |> conv_value ≈ 0.00018024011179619518
    @test conv_a_star(crypto, "ADA", "ALGO") |> conv_value ≈ 2.6559210526315793
    @test conv_a_star(crypto, "ADA", "EOS")  |> conv_value ≈ 0.5638268156424581
    @test conv_a_star(crypto, "ADA", "SOL")  |> conv_value ≈ 0.006574918566775245
    @test conv_a_star(crypto, "ADA", "AAVE") |> conv_value ≈ 0.004069966730517189
    @test conv_a_star(crypto, "ADA", "DOT")  |> conv_value ≈ 0.07216660707901322
    @test conv_a_star(crypto, "USDT", "ADA") |> conv_value ≈ 2.477086945751796
    @test conv_a_star(crypto, "USDT", "BTC") |> conv_value ≈ 2.373717628722553e-5
    @test conv_a_star(crypto, "USDT", "ETH") |> conv_value ≈ 0.0004464704280311994
    @test conv_a_star(crypto, "USDT", "ALGO")|> conv_value ≈ 6.578947368421053
    @test conv_a_star(crypto, "USDT", "EOS") |> conv_value ≈ 1.3966480446927374
    @test conv_a_star(crypto, "USDT", "SOL") |> conv_value ≈ 0.016286644951140065
    @test conv_a_star(crypto, "USDT", "AAVE")|> conv_value ≈ 0.010081661457808247
    @test conv_a_star(crypto, "USDT", "DOT") |> conv_value ≈ 0.1787629603146228
    @test conv_a_star(crypto, "BTC", "ADA")  |> conv_value ≈ 104354.74362150113
    @test conv_a_star(crypto, "BTC", "USDT") |> conv_value ≈ 42128.01
    @test conv_a_star(crypto, "BTC", "ETH")  |> conv_value ≈ 18.80891065680265
    @test conv_a_star(crypto, "BTC", "ALGO") |> conv_value ≈ 277157.96052631584
    @test conv_a_star(crypto, "BTC", "EOS")  |> conv_value ≈ 58838.00279329609
    @test conv_a_star(crypto, "BTC", "SOL")  |> conv_value ≈ 686.1239413680782
    @test conv_a_star(crypto, "BTC", "AAVE") |> conv_value ≈ 424.72033471116043
    @test conv_a_star(crypto, "BTC", "DOT")  |> conv_value ≈ 7530.9277797640325
    @test conv_a_star(crypto, "ETH", "ADA")  |> conv_value ≈ 5548.154570225415
    @test conv_a_star(crypto, "ETH", "USDT") |> conv_value ≈ 2239.79
    @test conv_a_star(crypto, "ETH", "BTC")  |> conv_value ≈ 0.05316629007636487
    @test conv_a_star(crypto, "ETH", "ALGO") |> conv_value ≈ 14735.46052631579
    @test conv_a_star(crypto, "ETH", "EOS")  |> conv_value ≈ 3128.1983240223462
    @test conv_a_star(crypto, "ETH", "SOL")  |> conv_value ≈ 36.478664495114
    @test conv_a_star(crypto, "ETH", "AAVE") |> conv_value ≈ 22.580804516584333
    @test conv_a_star(crypto, "ETH", "DOT")  |> conv_value ≈ 400.391490883089
    @test conv_a_star(crypto, "ALGO", "ADA") |> conv_value ≈ 0.37651721575427294
    @test conv_a_star(crypto, "ALGO", "USDT")|> conv_value ≈ 0.152
    @test conv_a_star(crypto, "ALGO", "BTC") |> conv_value ≈ 3.6080507956582803e-6
    @test conv_a_star(crypto, "ALGO", "ETH") |> conv_value ≈ 6.78635050607423e-5
    @test conv_a_star(crypto, "ALGO", "EOS") |> conv_value ≈ 0.2122905027932961
    @test conv_a_star(crypto, "ALGO", "SOL") |> conv_value ≈ 0.00247557003257329
    @test conv_a_star(crypto, "ALGO", "AAVE")|> conv_value ≈ 0.0015324125415868534
    @test conv_a_star(crypto, "ALGO", "DOT") |> conv_value ≈ 0.027171969967822666
    @test conv_a_star(crypto, "EOS", "ADA")  |> conv_value ≈ 1.7735942531582858
    @test conv_a_star(crypto, "EOS", "USDT") |> conv_value ≈ 0.716
    @test conv_a_star(crypto, "EOS", "BTC")  |> conv_value ≈ 1.699581822165348e-5
    @test conv_a_star(crypto, "EOS", "ETH")  |> conv_value ≈ 0.00031967282647033874
    @test conv_a_star(crypto, "EOS", "ALGO") |> conv_value ≈ 4.7105263157894735
    @test conv_a_star(crypto, "EOS", "SOL")  |> conv_value ≈ 0.011661237785016286
    @test conv_a_star(crypto, "EOS", "AAVE") |> conv_value ≈ 0.007218469603790704
    @test conv_a_star(crypto, "EOS", "DOT")  |> conv_value ≈ 0.12799427958526993
    @test conv_a_star(crypto, "SOL", "ADA")  |> conv_value ≈ 152.09313846916027
    @test conv_a_star(crypto, "SOL", "USDT") |> conv_value ≈ 61.4
    @test conv_a_star(crypto, "SOL", "BTC")  |> conv_value ≈ 0.0014574626240356475
    @test conv_a_star(crypto, "SOL", "ETH")  |> conv_value ≈ 0.02741328428111564
    @test conv_a_star(crypto, "SOL", "ALGO") |> conv_value ≈ 403.94736842105266
    @test conv_a_star(crypto, "SOL", "EOS")  |> conv_value ≈ 85.75418994413407
    @test conv_a_star(crypto, "SOL", "AAVE") |> conv_value ≈ 0.6190140135094263
    @test conv_a_star(crypto, "SOL", "DOT")  |> conv_value ≈ 10.97604576331784
    @test conv_a_star(crypto, "AAVE", "ADA") |> conv_value ≈ 245.70225414912062
    @test conv_a_star(crypto, "AAVE", "USDT")|> conv_value ≈ 99.19
    @test conv_a_star(crypto, "AAVE", "BTC") |> conv_value ≈ 0.0023544905159299002
    @test conv_a_star(crypto, "AAVE", "ETH") |> conv_value ≈ 0.04428540175641466
    @test conv_a_star(crypto, "AAVE", "ALGO")|> conv_value ≈ 652.5657894736843
    @test conv_a_star(crypto, "AAVE", "EOS") |> conv_value ≈ 138.5335195530726
    @test conv_a_star(crypto, "AAVE", "SOL") |> conv_value ≈ 1.615472312703583
    @test conv_a_star(crypto, "AAVE", "DOT") |> conv_value ≈ 17.731498033607433
    @test conv_a_star(crypto, "DOT", "ADA")  |> conv_value ≈ 13.856824374535547
    @test conv_a_star(crypto, "DOT", "USDT") |> conv_value ≈ 5.594
    @test conv_a_star(crypto, "DOT", "BTC")  |> conv_value ≈ 0.00013278576415073963
    @test conv_a_star(crypto, "DOT", "ETH")  |> conv_value ≈ 0.0024975555744065295
    @test conv_a_star(crypto, "DOT", "ALGO") |> conv_value ≈ 36.80263157894737
    @test conv_a_star(crypto, "DOT", "EOS")  |> conv_value ≈ 7.812849162011173
    @test conv_a_star(crypto, "DOT", "SOL")  |> conv_value ≈ 0.09110749185667753
    @test conv_a_star(crypto, "DOT", "AAVE") |> conv_value ≈ 0.056396814194979335
end