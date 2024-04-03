module CcyConv

export ConvRate,
    FXGraph,
    Price

export conv_a_star,
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

struct MyCtx <: AbstractCtx
    #__ empty
end

"""
    from_asset(x::AbstractPrice) -> String

Returns the name of the base currency of `x`.
"""
function from_asset(x::AbstractPrice)::String
    return throw("not implemented for $(typeof(x))")
end

"""
    to_asset(x::AbstractPrice) -> String

Returns the name of the quote currency of `x`.
"""
function to_asset(x::AbstractPrice)::String
    return throw("not implemented for $(typeof(x))")
end

"""
    price(x::AbstractPrice) -> Float64

Returns price of the currency pair `x`.
"""
function price(x::AbstractPrice)::Float64
    return throw("not implemented for $(typeof(x))")
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

"""
    FXGraph

This type describes a weighted directed graph in which:
- The nodes are currencies.
- The edges between such nodes represent a currency pair.
- The direction of the edge determines the base and quote currency.
- The weight of the edge is determined by the conversion price of the currency pair.

## Fields
- `edge_nodes::Dict{NTuple{2,UInt64},Vector{AbstractPrice}}`: Dictionary containing information about conversion prices between nodes.
- `edge_encode::Dict{String,UInt64}`: A dictionary containing the names of currencies as keys and their identification numbers as values.
- `graph::Graphs.SimpleGraph{Int64}`: A graph containing basic information about vertices and edges.
"""
struct FXGraph
    edge_nodes::Dict{NTuple{2,UInt64},Vector{AbstractPrice}}
    edge_encode::Dict{String,UInt64}
    graph::SimpleGraph{Int64}

    function FXGraph()
        return new(
            Dict{NTuple{2,UInt64},Vector{AbstractPrice}}(),
            Dict{String,UInt64}(),
            SimpleGraph{Int64}(),
        )
    end
end

"""
    conv_ccys(fx::FXGraph) -> Vector{String}

Returns the names of all currencies stored in the graph `fx`.
"""
function conv_ccys(fx::FXGraph)::Vector{String}
    return collect(keys(fx.edge_encode))
end

"""
    Base.push!(fx::FXGraph, node::AbstractPrice)

Adds a new edge to the graph `fx` corresponding to the currency pair `node`.
"""
function Base.push!(fx::FXGraph, node::P)::FXGraph where {P<:AbstractPrice}
    from_id = get!(fx.edge_encode, from_asset(node)) do
        add_vertex!(fx.graph)
        length(fx.edge_encode) + 1
    end

    to_id = get!(fx.edge_encode, to_asset(node)) do
        add_vertex!(fx.graph)
        length(fx.edge_encode) + 1
    end

    if !haskey(fx.edge_nodes, (from_id, to_id))
        fx.edge_nodes[(from_id, to_id)] = P[node]
    else
        push!(fx.edge_nodes[(from_id, to_id)], node)
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

function rm_edge!(fx::FXGraph, from_id::UInt64, to_id::UInt64)::Bool
    return if haskey(fx.edge_nodes, (from_id, to_id))
        isempty(fx.edge_nodes[(from_id, to_id)]) || deleteat!(fx.edge_nodes[(from_id, to_id)], 1)
        isempty(fx.edge_nodes[(from_id, to_id)]) && rem_edge!(fx.graph, from_id, to_id)
    elseif haskey(fx.edge_nodes, (to_id, from_id))
        isempty(fx.edge_nodes[(to_id, from_id)]) || deleteat!(fx.edge_nodes[(to_id, from_id)], 1)
        isempty(fx.edge_nodes[(to_id, from_id)]) && rem_edge!(fx.graph, to_id, from_id)
    end
end

#__ alg

function graph_path(path_alg::Function, fx::FXGraph, from_asset::String, to_asset::String)
    from_id = get(fx.edge_encode, from_asset, nothing)
    to_id   = get(fx.edge_encode, to_asset, nothing)

    return if isnothing(from_id) || isnothing(to_id)
        Vector{Pair{Int64,Int64}}()
    else
        path_alg(fx, from_id, to_id)
    end
end

function a_star_alg(fx::FXGraph, from_id::UInt64, to_id::UInt64)
    return map(x -> x.src => x.dst, a_star(fx.graph, from_id, to_id))
end

"""
    ConvRate

An object describing the price and conversion path between two currencies.

## Fields
- `from_asset::String`: The name of an initial curreny.
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

function price_first_non_nan(ctx::AbstractCtx, items::Vector{P}) where {P<:AbstractPrice}
    for item in items
        value = price(ctx, item)
        isnan(value) || return (item, value)
    end
    return (nothing, NaN)
end

"""
    (fx::FXGraph)(ctx::AbstractCtx, path_alg::Function, from_asset::String, to_asset::String) -> ConvRate

Applies algorithm `path_alg` to find a path on graph `fx` between base currency `from_asset` and target currency `to_asset` using context `ctx`.

!!! note
    This method is low-level and is required when using a custom context.

"""
function FXGraph(::AbstractCtx, ::Function, ::String, ::String) end

function (fx::FXGraph)(ctx::AbstractCtx, path_alg::Function, from_asset::String, to_asset::String)::ConvRate
    from_asset == to_asset && return ConvRate(from_asset, to_asset, 1.0)
    g_path = graph_path(path_alg, fx, from_asset, to_asset)
    isempty(g_path) && return ConvRate(from_asset, to_asset, NaN)
    chain = Vector{AbstractPrice}()
    conv::Float64 = 1.0
    for (from_id::UInt64, to_id::UInt64) in g_path
        val::Float64 = if has_edge(fx.graph, from_id, to_id) && haskey(fx.edge_nodes, (from_id, to_id))
            item, value = price_first_non_nan(ctx, fx.edge_nodes[(from_id, to_id)])
            item !== nothing && push!(chain, item)
            value
        elseif has_edge(fx.graph, to_id, from_id) && haskey(fx.edge_nodes, (to_id, from_id))
            item, value = price_first_non_nan(ctx, fx.edge_nodes[(to_id, from_id)])
            item !== nothing && push!(chain, item)
            inv(value)
        else
            NaN
        end
        (isnan(val) || isinf(val)) && rm_edge!(fx, from_id, to_id)
        conv *= val
    end
    return if isnan(conv)
        fx(ctx, path_alg, from_asset, to_asset)
    else
        ConvRate(from_asset, to_asset, conv, chain)
    end
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

end
