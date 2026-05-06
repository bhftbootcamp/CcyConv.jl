# CcyConv.jl

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

append!(
    crypto,
    [
        Price("ADA", "USDT", 0.5911),
        Price("ADA", "BTC", 0.00000892),
        Price("BTC", "ETH", 19.9089),
        Price("USDT", "ETH", 0.0003),
        Price("ETH", "BNB", 5.9404),
        Price("USDT", "XRP", 1.6929),
        Price("XRP", "BNB", NaN),
        Price("USDC", "XRP", 1.6920),
        Price("ADA", "USDC", 0.5909),
    ],
)

result = conv(crypto, "ADA", "BNB")

julia> conv_value(result)
0.0010534111319999999

julia> conv_chain(result)
3-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.5911)
 Price("USDT", "ETH",  0.0003)
 Price("ETH",  "BNB",  5.9404)
```

The graph topology can be built upfront — without actual prices — and the rates resolved lazily at query time through a custom context. This lets you fetch and cache live data from any source on the fly.

```julia
using CcyConv
using EasyCurl
using Serde

struct BinanceCtx <: CcyConv.AbstractCtx
    prices::Dict{String,Float64}

    BinanceCtx() = new(Dict{String,Float64}())
end

struct BinancePair <: CcyConv.AbstractPrice
    base_asset::String
    quote_asset::String
    symbol::String
end

CcyConv.from_asset(x::BinancePair) = x.base_asset
CcyConv.to_asset(x::BinancePair) = x.quote_asset

function CcyConv.price(ctx::BinanceCtx, x::BinancePair)::Float64
    return get!(ctx.prices, x.symbol) do
        try
            resp = http_get("https://api.binance.com/api/v3/avgPrice?symbol=$(x.symbol)")
            data = Serde.parse_json(http_body(resp))
            parse(Float64, data["price"])
        catch
            NaN
        end
    end
end

fx = FXGraph()
ctx = BinanceCtx()

append!(
    fx,
    [
        BinancePair("ADA",  "BTC",  "ADABTC"),
        BinancePair("BTC",  "USDT", "BTCUSDT"),
        BinancePair("PEPE", "USDT", "PEPEUSDT"),
        BinancePair("EOS",  "USDT", "EOSUSDT"),
    ],
)

# First call fetches prices from the exchange
julia> @time conv(fx, "ADA", "EOS"; ctx = ctx) |> conv_value
  0.350000 seconds (...)
0.6004274502578457

# Subsequent calls use cached prices
julia> @time conv(fx, "ADA", "EOS"; ctx = ctx) |> conv_value
  0.000130 seconds (46 allocations: 2.312 KiB)
0.6004274502578457
```
