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