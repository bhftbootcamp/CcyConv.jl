module AStar

using CcyConv
using Graphs

export conv

function path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    return map(x -> x.src => x.dst, a_star(fx.graph, from_id, to_id))
end

"""
    conv(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate

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

julia> conv = AStar.conv(crypto, "ADA", "BTC");

julia> conv_value(conv)
0.000009582698067

julia> conv_chain(conv)
2-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.4037234)
 Price("USDT", "BTC",  0.0000237)
```
"""
function conv(fx::CcyConv.FXGraph, x...; kw...)::CcyConv.ConvRate
    return fx(CcyConv.MyCtx(), path_algorithm, x...; kw...)
end

end # module
