# CcyConv.jl

CcyConv is a Julia package for performing currency conversions. It allows for direct and multi-step conversions using the latest exchange 💱 rates.

## Quickstart

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
