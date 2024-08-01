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
julia> conv = conv_a_star(crypto, "ADA", "BTC");

julia> conv_value(conv)
0.000009582698067

julia> conv_chain(conv)
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
julia> conv = conv_a_star(crypto, "ADA", "BTC");

julia> conv_value(conv)
0.000009582698067

julia> conv_chain(conv)
2-element Vector{CcyConv.AbstractPrice}:
 MyPrice("Binance", "ADA",  "USDT", 0.4037234)
 MyPrice("Huobi",   "USDT", "BTC",  0.0000237)
```

## [Using context](@id context_manual)

Finally, we can go further and implement a context into our workspace.
This will allow us to request and cache data from different sources without crossing them with each other.

First, let's define a new context `MyCtx` that can store the previously requested data.

```julia
using CcyConv
using CryptoExchangeAPIs.Binance

struct MyCtx <: CcyConv.AbstractCtx
    prices::Dict{String,Float64}

    MyCtx() = new(Dict{String,Float64}())
end
```

Also, now the currency pair `ExSymbol` will not store a specific price value, but instead will contain only the corresponding symbol required for the API request.
This will be achieved by further overloading the `price` method.

```julia
struct ExSymbol <: CcyConv.AbstractPrice
    base_asset::String
    quote_asset::String
    symbol::String
end
```

As before, new getter methods must be defined to conform to the [`AbstractPrice`](@ref CcyConv.AbstractPrice) interface.
Particular attention should be paid to the `price` method, which now first tries to find the desired price in the context cache `MyCtx` and only if this price has not been previously requested - makes a request to the exchange API.

```julia
function CcyConv.from_asset(x::ExSymbol)::String
    return x.base_asset
end

function CcyConv.to_asset(x::ExSymbol)::String
    return x.quote_asset
end

function CcyConv.price(ctx::MyCtx, x::ExSymbol)::Float64
    return get!(ctx.prices, x.symbol) do
        try
            Binance.Spot.avg_price(; symbol = x.symbol).result.price
        catch
            NaN
        end
    end
end
```

Finally, you need to create a new graph, a custom context and add custom currency pairs to the graph:

```julia
my_graph = FXGraph()
my_ctx = MyCtx()
my_conv = (to, from) -> conv_value(my_graph(my_ctx, CcyConv.a_star_alg, to, from))

push!(my_graph, ExSymbol("ADA",  "BTC",  "ADABTC"))
push!(my_graph, ExSymbol("BTC",  "USDT", "BTCUSDT"))
push!(my_graph, ExSymbol("PEPE", "USDT", "PEPEUSDT"))
push!(my_graph, ExSymbol("EOS",  "USDT", "EOSUSDT"))
```

To set the context `my_ctx`, you must use a lower-level [`method`](@ref CcyConv.FXGraph(::CcyConv.AbstractCtx, ::Function, ::String, ::String)) with an explicit specification of the used context, as well as the path search algorithm.

```julia-repl
# "long" request for prices from the exchange
julia> @time my_conv("ADA", "EOS")
  4.740000 seconds (1.80 M allocations: 120.606 MiB, 0.52% gc time, 14.55% compilation time)
0.6004274502578457

# "quick" request for prices from cache
julia> @time my_conv("ADA", "EOS")
  0.000130 seconds (46 allocations: 2.312 KiB)
0.6004274502578457
```

With this approach, due to the context, only the first data request will take a long time.
Subsequent requests will take much less time.

You can go further and add a refresh rate for updating the data in the cache.

## Pathfinding algorithm

If you are planning to implement your own graph pathfinding method, you should use the following function signature:
```julia
custom_alg(fx::FXGraph, from_id::UInt64, to_id::UInt64) -> Vector{Pair{Integer, Integer}}
```

Which returns a vector with pairs of indices corresponding to the `fx` graph currencies.

The vector of such pairs should form a chain of conversions of the following form:
```julia
2-element Vector{Pair{Int64, Int64}}:
 1 => 2
 2 => 3
```

Then you can use a low-level [`method`](@ref CcyConv.FXGraph(::CcyConv.AbstractCtx, ::Function, ::String, ::String)) to apply your pathfinding algorithm.

See previous [`section`](@ref context_manual) to add your own context or just use a dummy one:

```julia-repl
julia> my_graph = FXGraph();

julia> dummy_ctx = CcyConv.MyCtx();

julia> my_graph(dummy_ctx, custom_alg, "ADA", "USDT")
[...]
```
