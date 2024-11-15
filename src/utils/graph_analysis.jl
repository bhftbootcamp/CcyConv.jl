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
