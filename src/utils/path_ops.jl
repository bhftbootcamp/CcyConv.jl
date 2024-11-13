"""
    convert_through_chain(chain::Vector{<:AbstractPrice}, amount::Float64)::Float64

Convert amount through a chain of prices.
"""
function convert_through_chain(chain::Vector{<:AbstractPrice}, amount::Float64)::Float64
    result = amount
    for price in chain
        result = convert_amount(price, result)
    end
    return result
end

"""
    calculate_path_value(
        fx::CcyConv.FXGraph,
        path::Vector{UInt64},
        amount::Float64
    )::Tuple{Float64,Vector{CcyConv.AbstractPrice}}

Calculate the total converted amount and collect the chain of conversions for a path.
"""
function calculate_path_value(
    fx::CcyConv.FXGraph,
    path::Vector{UInt64},
    amount::Float64,
)::Tuple{Float64,Vector{CcyConv.AbstractPrice}}
    isempty(path) && return (amount, CcyConv.AbstractPrice[])
    length(path) == 1 && return (amount, CcyConv.AbstractPrice[])

    total_amount = amount  # Start with initial amount
    chain = Vector{CcyConv.AbstractPrice}()

    for i = 1:length(path)-1
        u, v = path[i], path[i+1]
        if haskey(fx.edge_nodes, (u, v))
            price_obj = fx.edge_nodes[(u, v)][1]
            push!(chain, price_obj)
            total_amount = convert_amount(price_obj, total_amount)
        else
            # Must be an implicit reverse edge
            price_obj = fx.edge_nodes[(v, u)][1]
            push!(chain, price_obj)
            total_amount = convert_amount(reverse_price(price_obj), total_amount)
        end
    end

    return total_amount, chain
end
