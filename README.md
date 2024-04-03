# CcyConv.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bhftbootcamp.github.io/CcyConv.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bhftbootcamp.github.io/CcyConv.jl/dev/)
[![Build Status](https://github.com/bhftbootcamp/CcyConv.jl/actions/workflows/Coverage.yml/badge.svg?branch=master)](https://github.com/bhftbootcamp/CcyConv.jl/actions/workflows/Coverage.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/bhftbootcamp/CcyConv.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bhftbootcamp/CcyConv.jl)
[![Registry](https://img.shields.io/badge/registry-Green-green)](https://github.com/bhftbootcamp/Green)

CcyConv is a Julia package for performing currency conversions. It allows for direct and multi-step conversions using the latest exchange 💱 rates.

## Installation
If you haven't installed our [local registry](https://github.com/bhftbootcamp/Green) yet, do that first:
```
] registry add https://github.com/bhftbootcamp/Green.git
```

To install CcyConv, simply use the Julia package manager:

```julia
] add CcyConv
```

## Usage

Here's how you can find a conversion path from `ADA` to `BNB`:

```mermaid
graph LR;
    ADA  --> |0.5911| USDT;
    ADA  -.->|0.00000892| BTC;
    BTC  -.->|19.9089| ETH;
    USDT --> |0.0003| ETH;
    ETH  --> |5.9404| BNB;
    USDT -.->|1.6929| XRP;
    XRP  -.- |NaN| BNB;
    USDC -.- |1.6920| XRP;
    ADA  -.- |0.5909| USDC;

    classDef julia_blue fill:#4063D8,stroke:#333,stroke-width:2px;
    classDef julia_green fill:#389826,stroke:#333,stroke-width:2px;
    classDef julia_red fill:#CB3C33,stroke:#333,stroke-width:2px;
    classDef julia_purple fill:#9558B2,stroke:#333,stroke-width:2px;
    classDef def_color fill:#eee,stroke:#ccc,stroke-width:2px;

    class ADA julia_blue;
    class USDT julia_red;
    class ETH julia_green;
    class BNB julia_purple;
```

```julia
using CcyConv

crypto = FXGraph()

push!(crypto, Price("ADA",  "USDT", 0.5911))
push!(crypto, Price("ADA",  "BTC",  0.00000892))
push!(crypto, Price("BTC",  "ETH",  19.9089))
push!(crypto, Price("USDT", "ETH",  0.0003))
push!(crypto, Price("ETH",  "BNB",  5.9404))
push!(crypto, Price("USDT", "XRP",  1.6929))
push!(crypto, Price("XRP",  "BNB",  NaN))
push!(crypto, Price("USDC", "XRP",  1.6920))
push!(crypto, Price("ADA",  "USDC", 0.5909))

conv = conv_a_star(crypto, "ADA", "BNB")

julia> conv_value(conv)
0.0010534111319999999

julia> conv_chain(conv)
3-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.5911)
 Price("USDT", "ETH",  0.0003)
 Price("ETH",  "BNB",  5.9404)
```

The package lets you to set up a directed graph containing currencies as vertices and convert rates as edges. The graph can fill the missing data from anywhere and directly during the running conversion path calculation.

```julia
using CcyConv
using CryptoAPIs

struct MyCtx <: CcyConv.AbstractCtx
    prices::Dict{String,Float64}

    MyCtx() = new(Dict{String,Float64}())
end

struct ExSymbol <: CcyConv.AbstractPrice
    base_asset::String
    quote_asset::String
    symbol::String
end

function CcyConv.from_asset(x::ExSymbol)::String
    return x.base_asset
end

function CcyConv.to_asset(x::ExSymbol)::String
    return x.quote_asset
end

function CcyConv.price(ctx::MyCtx, x::ExSymbol)::Float64
    return get!(ctx.prices, x.symbol) do
        try
            CryptoAPIs.Binance.Spot.avg_price(; symbol = x.symbol).result.price
        catch
            NaN
        end
    end
end

my_graph = FXGraph()
my_ctx = MyCtx()

append!(
    my_graph,
    [
        ExSymbol("ADA",  "BTC",  "ADABTC"),
        ExSymbol("BTC",  "USDT", "BTCUSDT"),
        ExSymbol("PEPE", "USDT", "PEPEUSDT"),
        ExSymbol("EOS",  "USDT", "EOSUSDT"),
    ],
)

my_conv = (to, from) -> conv_value(my_graph(my_ctx, CcyConv.a_star_alg, to, from))

julia> @time my_conv("ADA", "EOS")
  4.740000 seconds (1.80 M allocations: 120.606 MiB, 0.52% gc time, 14.55% compilation time)
0.6004274502578457

julia> @time my_conv("ADA", "EOS")
  0.000130 seconds (46 allocations: 2.312 KiB)
0.6004274502578457
```

## Contributing

Contributions to CcyConv are welcome! If you encounter a bug, have a feature request, or would like to contribute code, please open an issue or a pull request on GitHub.
