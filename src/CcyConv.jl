module CcyConv

export ConvRate,
    FXGraph,
    Price,
    AStar,
    DFS,
    conv,
    conv_ccys,
    conv_chain,
    conv_safe_value,
    conv_value

using Graphs

"""
    AbstractPrice

An abstract type representing price of a currency pair.

For types using this interface the following methods must be defined:
- [`from_asset`](@ref)
- [`to_asset`](@ref)
- [`price`](@ref)
"""
abstract type AbstractPrice end

"""
    AbstractCtx

An abstract type representing workspace context.
"""
abstract type AbstractCtx end

struct MyCtx <: AbstractCtx end

"""
    from_asset(x::AbstractPrice) -> String

Returns the name of the base currency of `x`.
"""
function from_asset(x::AbstractPrice)::String
    error("not implemented for $(typeof(x))")
end

"""
    to_asset(x::AbstractPrice) -> String

Returns the name of the quote currency of `x`.
"""
function to_asset(x::AbstractPrice)::String
    error("not implemented for $(typeof(x))")
end

"""
    price(x::AbstractPrice) -> Float64

Returns price of the currency pair `x`.
"""
function price(x::AbstractPrice)::Float64
    error("not implemented for $(typeof(x))")
end

"""
    price(ctx::AbstractCtx, x::AbstractPrice) -> Float64

Advanced function for getting the price of a currency pair `x` that can take into account the context of the `ctx`.

!!! note
    This function is called when searching for a currency conversion path and can be overloaded to achieve advanced functionality using context (for example, caching the requested data for subsequent requests).
    See [context guide](@ref context_manual).

"""
function price(ctx::AbstractCtx, x::AbstractPrice)::Float64
    return price(x)
end

"""
    Price <: AbstractPrice

A type representing the price of currency pair.

## Fields
- `from_asset::String`: Base currency name.
- `to_asset::String`: Quote currency name.
- `price::Float64`: The currency pair price.
"""
struct Price <: AbstractPrice
    from_asset::String
    to_asset::String
    price::Float64
end

function from_asset(x::Price)::String
    return x.from_asset
end

function to_asset(x::Price)::String
    return x.to_asset
end

function price(x::Price)::Float64
    return x.price
end

Base.:(==)(a::Price, b::Price) = a.from_asset == b.from_asset && a.to_asset == b.to_asset && a.price == b.price
Base.hash(x::Price, h::UInt) = hash((x.from_asset, x.to_asset, x.price), h)

"""
    FXGraph

This type describes a weighted directed graph in which:
- The nodes are currencies.
- The edges between such nodes represent a currency pair.
- The direction of the edge determines the base and quote currency.
- The weight of the edge is determined by the conversion price of the currency pair.

## Fields
- `edge_prices::Dict{NTuple{2,Int64},Vector{AbstractPrice}}`: Dictionary containing information about conversion prices between nodes.
- `node_ids::Dict{String,Int64}`: A dictionary containing the names of currencies as keys and their identification numbers as values.
- `graph::Graphs.SimpleGraph{Int64}`: A graph containing basic information about vertices and edges.
"""
struct FXGraph
    edge_prices::Dict{NTuple{2,Int64},Vector{AbstractPrice}}
    node_ids::Dict{String,Int64}
    graph::SimpleGraph{Int64}

    function FXGraph()
        return new(
            Dict{NTuple{2,Int64},Vector{AbstractPrice}}(),
            Dict{String,Int64}(),
            SimpleGraph{Int64}(),
        )
    end
end

function FXGraph(nodes::Vector{P})::FXGraph where {P<:AbstractPrice}
    fx = FXGraph()
    append!(fx, nodes)
    return fx
end

"""
    conv_ccys(fx::FXGraph) -> Vector{String}

Returns the names of all currencies stored in the graph `fx`.
"""
function conv_ccys(fx::FXGraph)::Vector{String}
    return collect(keys(fx.node_ids))
end

"""
    Base.push!(fx::FXGraph, node::AbstractPrice)

Adds a new edge to the graph `fx` corresponding to the currency pair `node`.
"""
function Base.push!(fx::FXGraph, node::P)::FXGraph where {P<:AbstractPrice}
    from_id = get!(fx.node_ids, from_asset(node)) do
        add_vertex!(fx.graph)
        length(fx.node_ids) + 1
    end

    to_id = get!(fx.node_ids, to_asset(node)) do
        add_vertex!(fx.graph)
        length(fx.node_ids) + 1
    end

    if !haskey(fx.edge_prices, (from_id, to_id))
        fx.edge_prices[(from_id, to_id)] = P[node]
    else
        push!(fx.edge_prices[(from_id, to_id)], node)
    end

    add_edge!(fx.graph, from_id, to_id)

    return fx
end

"""
    Base.append!(fx::FXGraph, nodes::Vector{AbstractPrice})

Does the same as [`push!`](@ref) but can pass several currency pairs `nodes` at once.
"""
function Base.append!(fx::FXGraph, nodes::Vector{P})::FXGraph where {P<:AbstractPrice}
    for node in nodes
        push!(fx, node)
    end
    return fx
end


"""
    ConvRate

An object describing the price and conversion path between two currencies.

## Fields
- `from_asset::String`: The name of an initial currency.
- `to_asset::String`: The name of a target currency.
- `conv::Float64`: Total currency conversion price.
- `chain::Vector{AbstractPrice}`: Chain of currency pairs involved in conversion.
"""
struct ConvRate
    from_asset::String
    to_asset::String
    conv::Float64
    chain::Vector{AbstractPrice}
end

function ConvRate(f::String, t::String, c::Float64)
    return ConvRate(f, t, c, Vector{AbstractPrice}())
end

"""
    conv_value(x::ConvRate) -> Float64

Returns the convert rate of `x`.
"""
function conv_value(x::ConvRate)::Float64
    return x.conv
end

"""
    conv_safe_value(x::ConvRate) -> Float64

Asserts that the conversion rate of `x` is not a `NaN` value and then returns it.
Otherwise throws an `AssertionError`.
"""
function conv_safe_value(x::ConvRate)::Float64
    @assert !isnan(x.conv) "conv is $(x.conv)"
    return x.conv
end

"""
    conv_chain(x::ConvRate) -> Vector{AbstractPrice}

Returns the path chain of `x`.
"""
function conv_chain(x::ConvRate)::Vector{AbstractPrice}
    return x.chain
end

include("algorithms.jl")

"""
    (fx::FXGraph)(ctx::AbstractCtx, path_alg::Function, from_asset::String, to_asset::String) -> ConvRate

Applies algorithm `path_alg` to find a path on graph `fx` between base currency `from_asset` and target currency `to_asset` using context `ctx`.

!!! note
    This method is low-level. Prefer using [`conv`](@ref) with the `ctx` keyword argument.

"""
function FXGraph(::AbstractCtx, ::Function, ::String, ::String) end

function (fx::FXGraph)(ctx::AbstractCtx, path_alg::Function, from_asset::String, to_asset::String)::ConvRate
    from_asset == to_asset && return ConvRate(from_asset, to_asset, 1.0)
    g_path = _graph_path(path_alg, ctx, fx, from_asset, to_asset)
    isempty(g_path) && return ConvRate(from_asset, to_asset, NaN)
    chain = Vector{AbstractPrice}()
    rate = 1.0
    for (u, v) in g_path
        x, w = _w(ctx, fx, u, v)
        x !== nothing && push!(chain, x)
        rate *= w
    end
    isnan(rate) && return ConvRate(from_asset, to_asset, NaN)
    return ConvRate(from_asset, to_asset, rate, chain)
end

"""
    AStar

Algorithm type for state-space A* pathfinding.
Default algorithm for [`conv`](@ref).
"""
struct AStar end

"""
    DFS

Algorithm type for exhaustive depth-first search pathfinding.
"""
struct DFS end

"""
    conv(fx::FXGraph, from_asset::String, to_asset::String, [::AStar]; ctx::AbstractCtx = MyCtx()) -> ConvRate

Finds the conversion path with the **minimum** product rate between `from_asset` and `to_asset` in graph `fx`.

Uses **state-space [`A*`](https://en.wikipedia.org/wiki/A*_search_algorithm)** over `log(rate)`-weighted edges: the search runs on a lifted graph whose vertices are `(currency, visited_set)` pairs, so every walk is a simple path in the original graph by construction. This means the algorithm returns the same answer as the exhaustive [`DFS`](@ref) on every graph, including those with arbitrage cycles. A min-edge-weight admissible heuristic prunes branches that cannot improve the best path found so far.

The minimum-product simple path is NP-hard in general, so the worst-case state count is `O(V * 2^V)`; in practice the priority-queue ordering and admissible heuristic let it beat the exhaustive DFS on most inputs. For graphs with more than 64 currencies the implementation falls back to DFS (the bitmask representation no longer fits).

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

julia> result = conv(crypto, "ADA", "BTC");

julia> conv_value(result)
0.000009582698067

julia> conv_chain(result)
2-element Vector{CcyConv.AbstractPrice}:
 Price("ADA",  "USDT", 0.4037234)
 Price("USDT", "BTC",  0.0000237)
```
"""
function conv(fx::FXGraph, from_asset::String, to_asset::String, ::AStar = AStar(); ctx::AbstractCtx = MyCtx())::ConvRate
    return fx(ctx, _min_path, from_asset, to_asset)
end

"""
    conv(fx::FXGraph, from_asset::String, to_asset::String, ::DFS; ctx::AbstractCtx = MyCtx()) -> ConvRate

Finds the conversion path with the **minimum** product rate between `from_asset` and `to_asset`.
Uses exhaustive DFS over all simple paths in graph `fx`.
"""
function conv(fx::FXGraph, from_asset::String, to_asset::String, ::DFS; ctx::AbstractCtx = MyCtx())::ConvRate
    return _optimal_rate(ctx, fx, from_asset, to_asset, Inf, <)
end

end
