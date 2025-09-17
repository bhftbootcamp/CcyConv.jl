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
        return length(fx.edge_encode) + 1
    end

    to_id = get!(fx.edge_encode, to_asset(node)) do
        add_vertex!(fx.graph)
        return length(fx.edge_encode) + 1
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
        isempty(fx.edge_nodes[(from_id, to_id)]) ||
            deleteat!(fx.edge_nodes[(from_id, to_id)], 1)
        isempty(fx.edge_nodes[(from_id, to_id)]) && rem_edge!(fx.graph, from_id, to_id)
    elseif haskey(fx.edge_nodes, (to_id, from_id))
        isempty(fx.edge_nodes[(to_id, from_id)]) ||
            deleteat!(fx.edge_nodes[(to_id, from_id)], 1)
        isempty(fx.edge_nodes[(to_id, from_id)]) && rem_edge!(fx.graph, to_id, from_id)
    end
end

#__ alg

function graph_path(path_alg::Function, fx::FXGraph, from_asset::String, to_asset::String)
    from_id = get(fx.edge_encode, from_asset, nothing)
    to_id = get(fx.edge_encode, to_asset, nothing)

    return if isnothing(from_id) || isnothing(to_id)
        Vector{Pair{Int64,Int64}}()
    else
        path_alg(fx, from_id, to_id)
    end
end

"""
    (fx::FXGraph)(ctx::AbstractCtx, path_alg::Function, from_asset::String, to_asset::String) -> ConvRate

Applies algorithm `path_alg` to find a path on graph `fx` between base currency `from_asset` and target currency `to_asset` using context `ctx`.

!!! note
    This method is low-level and is required when using a custom context.

"""
function (fx::FXGraph)(
    ctx::AbstractCtx,
    path_alg::Function,
    from_asset::String,
    to_asset::String,
)::ConvRate
    from_asset == to_asset && return ConvRate(from_asset, to_asset, 1.0)
    g_path = graph_path(path_alg, fx, from_asset, to_asset)
    isempty(g_path) && return ConvRate(from_asset, to_asset, NaN)
    chain = Vector{AbstractPrice}()
    conv::Float64 = 1.0
    for (from_id::UInt64, to_id::UInt64) in g_path
        val::Float64 =
            if has_edge(fx.graph, from_id, to_id) && haskey(fx.edge_nodes, (from_id, to_id))
                item, value = price_first_non_nan(ctx, fx.edge_nodes[(from_id, to_id)])
                item !== nothing && push!(chain, item)
                value
            elseif has_edge(fx.graph, to_id, from_id) &&
                   haskey(fx.edge_nodes, (to_id, from_id))
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
