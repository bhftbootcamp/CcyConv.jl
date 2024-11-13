function a_star_alg(fx::FXGraph, from_id::UInt64, to_id::UInt64)
    return map(x -> x.src => x.dst, a_star(fx.graph, from_id, to_id))
end

"""
    conv_a_star(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate

Uses an [`A*`](https://en.wikipedia.org/wiki/A*_search_algorithm) search algorithm to find the shortest path between `from_asset` and `to_asset` currencies in graph `fx`.

## Examples
```julia-repl
julia> crypto = FXGraph();

julia> append!(
           crypto,
           [
               Price("ADA",  "USDT", 0.4037234),
               Price("USDT", "BTC",  0.0000237),
               Price("BTC",  "ETH",  18.808910),
               Price("ETH",  "ALGO", 14735.460),
           ],
       );

julia> conv = conv_a_star(crypto, "ADA", "BTC");

julia> conv_value(conv)
0.000009582698067

julia> conv_chain(conv)
2-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.4037234)
 Price("USDT", "BTC",  0.0000237)
```
"""
function conv_a_star(fx::FXGraph, x...; kw...)::ConvRate
    return fx(MyCtx(), a_star_alg, x...; kw...)
end