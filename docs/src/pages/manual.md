# Manual

Let's take a closer look at a few examples of how this package can be used in practice.

## Basic usage

In the simplest case, you need to create a new [`FXGraph`](@ref) graph object:

```julia
using CcyConv

# Create a new graph
crypto = FXGraph()
```

Then add information about currency pairs to it as [`Price`](@ref) objects:

```julia
# Add exchange rates
push!(crypto, Price("ADA",  "USDT", 0.4037234))
push!(crypto, Price("USDT", "BTC",  0.0000237))
push!(crypto, Price("BTC",  "ETH",  18.808910))
push!(crypto, Price("ETH",  "ALGO", 14735.460))

# Or use 'append!':
append!(
    crypto,
    [
        Price("ADA",  "USDT", 0.4037234),
        Price("USDT", "BTC",  0.0000237),
        Price("BTC",  "ETH",  18.808910),
        Price("ETH",  "ALGO", 14735.460),
    ],
);
```

Finally, you can use one of the [`algorithms`](@ref algorithms) to find a path between required currency pairs:

```julia-repl
# Convert ADA to BTC
julia> result = conv(crypto, "ADA", "BTC");

julia> conv_value(result)
0.000009582698067

julia> conv_chain(result)
2-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.4037234)
 Price("USDT", "BTC",  0.0000237)
```

## Custom price

You can also define a new custom subtype of an abstract type [`AbstractPrice`](@ref CcyConv.AbstractPrice) representing the price of a currency pair and, for example, having information about the exchange to which it belongs.
In this case, there may be several edges between two currencies with different prices of the corresponding exchanges.

```julia
using CcyConv

# Create a new graph
crypto = FXGraph()

# Custom Price
struct MyPrice <: CcyConv.AbstractPrice
    exchange::String
    from_asset::String
    to_asset::String
    price::Float64
end
```

In this case, it is important to override the following getter methods for the new custom type `MyPrice` because they will be used during pathfinding:

```julia
CcyConv.from_asset(x::MyPrice) = x.from_asset
CcyConv.to_asset(x::MyPrice) = x.to_asset
CcyConv.price(x::MyPrice) = x.price
```

Now we can add objects of our new custom type to the graph and find the conversion path using the available [`algorithms`](@ref algorithms):

```julia
# Add exchange rates
push!(crypto, MyPrice("Binance", "ADA",  "USDT", 0.4037234))
push!(crypto, MyPrice("Huobi",   "USDT", "BTC",  0.0000237))
push!(crypto, MyPrice("Okex",    "BTC",  "ETH",  18.808910))
push!(crypto, MyPrice("Gateio",  "ETH",  "ALGO", 14735.460))
```

```julia-repl
# Convert ADA to BTC
julia> result = conv(crypto, "ADA", "BTC");

julia> conv_value(result)
0.000009582698067

julia> conv_chain(result)
2-element Vector{CcyConv.AbstractPrice}:
 MyPrice("Binance", "ADA",  "USDT", 0.4037234)
 MyPrice("Huobi",   "USDT", "BTC",  0.0000237)
```

## [Using context](@id context_manual)

The graph topology can be built upfront — without actual prices — and the rates resolved lazily at query time through a custom context.
This lets you fetch and cache live data from any source on the fly.

First, let's define a new context `BinanceCtx` that can store the previously requested data, and a custom price type `BinancePair` that holds only the symbol name (no price value).

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
```

New getter methods must be defined to conform to the [`AbstractPrice`](@ref CcyConv.AbstractPrice) interface.
The `price` method first checks the context cache and only fetches from the exchange API on a cache miss.

```julia
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
```

Create a graph, a context, and add custom currency pairs:

```julia
fx = FXGraph()
ctx = BinanceCtx()

push!(fx, BinancePair("ADA",  "BTC",  "ADABTC"))
push!(fx, BinancePair("BTC",  "USDT", "BTCUSDT"))
push!(fx, BinancePair("PEPE", "USDT", "PEPEUSDT"))
push!(fx, BinancePair("EOS",  "USDT", "EOSUSDT"))
```

Pass the context as a keyword argument to `conv`:

```julia-repl
# First call fetches prices from the exchange
julia> @time conv(fx, "ADA", "EOS"; ctx = ctx) |> conv_value
  0.350000 seconds (...)
0.6004274502578457

# Subsequent calls use cached prices
julia> @time conv(fx, "ADA", "EOS"; ctx = ctx) |> conv_value
  0.000130 seconds (46 allocations: 2.312 KiB)
0.6004274502578457
```

Only the first request is slow (fetches from the exchange). Subsequent calls hit the cache.

## Min rate pathfinding

By default, [`conv`](@ref) uses state-space A* ([`AStar`](@ref)) to find the path whose **product of exchange rates** is minimum, running over edges weighted with `log(rate)`. Negative log-weights — produced whenever a rate is below 1 — would normally break a Dijkstra-style search, so the algorithm lifts the search onto a graph whose vertices are `(currency, visited_set)` pairs. Every walk in the lifted graph is a simple path in the original by construction, which means the algorithm returns the same minimum-rate answer as [`DFS`](@ref) on every graph (including those with arbitrage cycles). A min-edge-weight admissible heuristic prunes branches that cannot improve the best path found so far. For graphs with more than 64 currencies the implementation falls back to an exhaustive DFS.

[`DFS`](@ref) finds the path whose **product of exchange rates** is minimum, using an exhaustive DFS that enumerates all simple paths between the source and target currencies. This guarantees the optimal result but has exponential worst-case complexity, so prefer these functions for small and medium-sized graphs.

```julia
using CcyConv

fx = FXGraph()

append!(
    fx,
    [
        Price("A", "B", 2.0),
        Price("B", "D", 3.0),
        Price("D", "F", 0.5),
        Price("A", "C", 1.5),
        Price("C", "E", 2.0),
        Price("E", "F", 3.0),
    ],
)
```

```julia-repl
julia> conv(fx, "A", "F", DFS()) |> conv_value
3.0
```

## Custom pathfinding algorithm

You can define a custom algorithm type and extend [`conv`](@ref):

```julia
struct MyAlg end

function CcyConv.conv(fx::FXGraph, from::String, to::String, ::MyAlg; ctx::CcyConv.AbstractCtx = CcyConv.MyCtx())
    # custom pathfinding logic
end
```

Then use it like any built-in algorithm:

```julia-repl
julia> fx = FXGraph();

julia> conv(fx, "ADA", "USDT", MyAlg())
[...]
```
