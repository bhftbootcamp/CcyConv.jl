"""
    calculate_path_rate(
        fx::FXGraph,
        path::Vector{UInt64}
    )::Tuple{Float64,Vector{AbstractPrice}}

Calculate total conversion rate and collect prices for a path.
"""
function calculate_path_rate(
    fx::FXGraph,
    path::Vector{UInt64}
)::Tuple{Float64,Vector{AbstractPrice}}
    isempty(path) && return (1.0, AbstractPrice[])
    length(path) == 1 && return (1.0, AbstractPrice[])

    total_rate = 1.0
    chain = Vector{AbstractPrice}()

    for i = 1:length(path)-1
        u, v = path[i], path[i+1]
        if haskey(fx.edge_nodes, (u, v))
            price_obj = fx.edge_nodes[(u, v)][1]
            push!(chain, price_obj)
            total_rate *= price(price_obj)
        else
            # Must be an implicit reverse edge
            price_obj = fx.edge_nodes[(v, u)][1]
            push!(chain, price_obj)
            total_rate *= 1.0 / price(price_obj)
        end
    end

    return total_rate, chain
end

"""
    calculate_path_rate(
        fx::FXGraph,
        path::Vector{String}
    )::Tuple{Float64,Vector{AbstractPrice}}

Convenience method accepting currency names instead of IDs.
"""
function calculate_path_rate(
    fx::FXGraph,
    path::Vector{String}
)::Tuple{Float64,Vector{AbstractPrice}}
    path_ids = [get_currency_id(fx, currency) for currency in path]
    return calculate_path_rate(fx, path_ids)
end