"""
Get currency name from node ID
"""
function get_currency(fx::FXGraph, id::UInt64)::String
    for (currency, node_id) in fx.edge_encode
        if node_id == id
            return currency
        end
    end
    error("Currency not found")
end

"""
    Calculate total rate for a path
"""
function calculate_path_rate(fx::FXGraph, path::Vector{Int})::Tuple{Float64,Vector{CcyConv.AbstractPrice}}
    total_rate = 1.0
    chain = Vector{CcyConv.AbstractPrice}()
    
    for i in 1:length(path)-1
        u, v = path[i], path[i+1]
        if haskey(fx.edge_nodes, (u, v))
            price_obj = fx.edge_nodes[(u, v)][1]
            push!(chain, price_obj)
            total_rate *= CcyConv.price(price_obj)
        else
            # Must be an implicit reverse edge
            price_obj = fx.edge_nodes[(v, u)][1]
            push!(chain, price_obj)
            total_rate *= 1/CcyConv.price(price_obj)
        end
    end
    
    return total_rate, chain
end

"""
    debug_paths(fx::FXGraph, from::String, to::String)

Debug helper that prints all possible conversion paths between two currencies.
"""
function debug_paths(fx::FXGraph, from::String, to::String)
    from_id = get(fx.edge_encode, from, nothing)
    to_id = get(fx.edge_encode, to, nothing)
    paths = find_all_paths(fx, Int(from_id), Int(to_id))
    
    println("All paths from $from to $to:")
    for path in paths
        rate, chain = calculate_path_rate(fx, path)
        println("Rate: $rate")
        println("Path: ", [get_currency(fx, UInt64(id)) for id in path])
        println("Chain: ", chain)
        println()
    end
end

"""
    create_graph_with_reversed_edges(fx::FXGraph)::FXGraph

Create a new FXGraph with all implicit reverse edges added.
Original graph remains unchanged.

# Arguments
- `fx::FXGraph`: The original graph

# Returns
- `FXGraph`: New graph with both original and reverse edges
"""
function create_graph_with_reversed_edges(fx::FXGraph)::FXGraph
    # Create new graph
    new_graph = FXGraph()
    
    # First copy all original edges
    for edge in edges(fx.graph)
        u, v = edge.src, edge.dst
        if haskey(fx.edge_nodes, (u, v))
            for price_obj in fx.edge_nodes[(u, v)]
                push!(new_graph, price_obj)
            end
        end
    end
    
    # Add reverse edges where missing
    for edge in edges(fx.graph)
        u, v = edge.src, edge.dst
        
        # If forward edge exists but reverse doesn't
        if haskey(fx.edge_nodes, (u, v)) && !haskey(fx.edge_nodes, (v, u))
            # Get currency names
            from_ccy = nothing
            to_ccy = nothing
            for (currency, id) in fx.edge_encode
                if id == u
                    from_ccy = currency
                elseif id == v
                    to_ccy = currency
                end
            end
            
            isnothing(from_ccy) || isnothing(to_ccy) && continue
            
            # Create reverse edge with 1/price
            price_obj = fx.edge_nodes[(u, v)][1]
            reverse_price = Price(to_ccy, from_ccy, 1/CcyConv.price(price_obj))
            push!(new_graph, reverse_price)
        end
    end
    
    return new_graph
end

"""
    to_mermaid(fx::FXGraph, show_reverse::Bool=false, round_func = p -> round(p, digits=2))

Convert FXGraph to Mermaid graph syntax
"""
function to_mermaid(fx::FXGraph, show_reverse::Bool=false, round_func = p -> round(p, digits=2))::String
    mermaid = "graph LR\n"
    processed_edges = Set{Tuple{String, String}}()
    
    for ((u, v), prices) in fx.edge_nodes
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
        
        if (from_ccy, to_ccy) ∉ processed_edges
            price_val = round_func(CcyConv.price(prices[1]))
            mermaid *= "    $(from_ccy) -->|$(price_val)| $(to_ccy)\n"
            push!(processed_edges, (from_ccy, to_ccy))
            
            if show_reverse && !haskey(fx.edge_nodes, (v, u)) && (to_ccy, from_ccy) ∉ processed_edges
                rev_price = round_func(1/price_val)
                mermaid *= "    $(to_ccy) -.->|$(rev_price)| $(from_ccy)\n"
                push!(processed_edges, (to_ccy, from_ccy))
            end
        end
    end
    
    return mermaid
end
