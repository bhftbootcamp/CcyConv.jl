"""
Get currency name from node ID
"""
function get_currency(fx::FXGraph, id::UInt64)::String
    for (currency, node_id) in fx.edge_encode
        if node_id == id
            return currency
        end
    end
    return error("Currency not found")
end

"""
    Calculate total rate for a path
"""
function calculate_path_rate(
    fx::FXGraph,
    path::Vector{UInt64},
)::Tuple{Float64,Vector{CcyConv.AbstractPrice}}
    total_rate = 1.0
    chain = Vector{CcyConv.AbstractPrice}()

    for i = 1:length(path)-1
        u, v = path[i], path[i+1]
        if haskey(fx.edge_nodes, (u, v))
            price_obj = fx.edge_nodes[(u, v)][1]
            push!(chain, price_obj)
            total_rate *= CcyConv.price(price_obj)
        else
            # Must be an implicit reverse edge
            price_obj = fx.edge_nodes[(v, u)][1]
            push!(chain, price_obj)
            total_rate *= 1 / CcyConv.price(price_obj)
        end
    end

    return total_rate, chain
end

function calculate_path_rate(
    fx::FXGraph,
    path::Vector{String},
)::Tuple{Float64,Vector{CcyConv.AbstractPrice}}
    @info "Use the integer version of the function for better performance"
    path_ids = [fx.edge_encode[currency] for currency in path]
    return calculate_path_rate(fx, path_ids)
end

"""
    find_missing_edges(fx::FXGraph) -> Vector{Tuple{UInt8,UInt8,Float64}}

Find edges in the graph that have a direct connection but no reverse edge.
Returns a vector of tuples containing (from_id, to_id, forward_price).

# Example
```julia
graph = FXGraph()
push!(graph, Price("USD", "EUR", 0.85))
missing = find_missing_edges(graph)
# Returns [(0x02, 0x01, 1.1764705882352942)]  # EUR->USD with price 1/0.85
```
"""
function find_missing_edges(fx::FXGraph)::Vector{Tuple{UInt8,UInt8,Float64}}
    missing_edges = Vector{Tuple{UInt8,UInt8,Float64}}()
    
    for ((u, v), prices) in fx.edge_nodes
        # Skip if reverse edge exists
        haskey(fx.edge_nodes, (v, u)) && continue
        
        # Calculate implied reverse price
        forward_price = CcyConv.price(prices[1])
        reverse_price = 1 / forward_price
        
        push!(missing_edges, (v, u, reverse_price))
    end
    
    # Sort for consistent output
    sort!(missing_edges)
    return missing_edges
end

"""
Defines how prices are selected when creating a bidirectional graph
"""
@enum ReverseBehavior begin
    DUAL_PRICES     # Use existing reverse prices when available, otherwise calculate
    SINGLE_PRICES   # Always calculate reverse prices from forward prices
end

"""
    create_graph_with_reversed_edges(fx::FXGraph; behavior::ReverseBehavior=DUAL_PRICES)::FXGraph

Create a new FXGraph where each edge has exactly two prices (forward and reverse).

# Arguments
- `fx::FXGraph`: The original graph
- `behavior`: Controls how reverse prices are determined
  - `DUAL_PRICES` (default): Use existing reverse prices when available
  - `SINGLE_PRICES`: Always calculate reverse as 1/forward

# Returns
- `FXGraph`: New graph where each edge has exactly two prices
"""
function create_graph_with_reversed_edges(fx::FXGraph; behavior::ReverseBehavior=DUAL_PRICES)::FXGraph
    new_graph = FXGraph()
    processed = Set{Tuple{UInt8,UInt8}}()
    
    # Copy the currency encoding
    for (ccy, id) in fx.edge_encode
        new_graph.edge_encode[ccy] = id
        add_vertex!(new_graph.graph)
    end
    
    for ((u, v), prices) in fx.edge_nodes
        # Only process each edge pair once
        (min(u,v), max(u,v)) in processed && continue
        
        # Get forward price (always use first price if multiple exist)
        forward_price = CcyConv.price(prices[1])
        
        # Determine reverse price based on behavior
        reverse_price = if behavior == DUAL_PRICES && haskey(fx.edge_nodes, (v, u))
            CcyConv.price(fx.edge_nodes[(v, u)][1])
        else
            1 / forward_price
        end
        
        # Add both prices to forward edge
        new_graph.edge_nodes[(u, v)] = AbstractPrice[
            Price(from_asset(prices[1]), to_asset(prices[1]), forward_price),
            Price(to_asset(prices[1]), from_asset(prices[1]), reverse_price)
        ]
        
        # Add edge to graph
        add_edge!(new_graph.graph, Int64(u), Int64(v))
        
        push!(processed, (min(u,v), max(u,v)))
    end

    # Verify each processed edge has exactly 2 prices
    @assert all(length(prices) == 2 for prices in values(new_graph.edge_nodes))
    @assert length(new_graph.edge_nodes) == length(processed)
    
    return new_graph
end

"""
    to_mermaid(fx::FXGraph, show_reverse::Bool=false, round_func = p -> round(p, digits=2))

Convert FXGraph to Mermaid graph syntax. When show_reverse is true, includes reverse prices
as dashed lines for edges without explicit reverse edges.
"""
function to_mermaid(
    fx::FXGraph,
    show_reverse::Bool = false,
    round_func = p -> round(p, digits = 2),
)::String
    mermaid = "graph LR\n"
    processed_edges = Set{Tuple{UInt8,UInt8}}()

    for ((u, v), prices) in fx.edge_nodes
        # Skip if we've already processed this edge pair
        (min(u,v), max(u,v)) in processed_edges && continue
        
        from_ccy = nothing
        to_ccy = nothing
        for (currency, id) in fx.edge_encode
            if id == u
                from_ccy = currency
            elseif id == v
                to_ccy = currency
            end
            if !isnothing(from_ccy) && !isnothing(to_ccy)
                break
            end
        end

        isnothing(from_ccy) || isnothing(to_ccy) && continue

        # Handle forward edge
        price_val = round_func(CcyConv.price(prices[1]))
        mermaid *= "    $(from_ccy) -->|$(price_val)| $(to_ccy)\n"

        # Handle reverse edge
        if haskey(fx.edge_nodes, (v, u))
            # If explicit reverse exists, add it as a regular edge
            rev_price = round_func(CcyConv.price(fx.edge_nodes[(v, u)][1]))
            mermaid *= "    $(to_ccy) -->|$(rev_price)| $(from_ccy)\n"
        elseif show_reverse
            # If no explicit reverse and show_reverse is true, add as dashed line
            rev_price = round_func(1 / price_val)
            mermaid *= "    $(to_ccy) -.->|$(rev_price)| $(from_ccy)\n"
        end

        push!(processed_edges, (min(u,v), max(u,v)))
    end

    return mermaid
end