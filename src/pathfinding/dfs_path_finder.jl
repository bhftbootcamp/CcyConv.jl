module DFSPathFinder

using CcyConv
using CcyConv: calculate_path_value
using Graphs

import CcyConv: price, get_currency_id

"""
    find_all_paths(
        fx::CcyConv.FXGraph,
        from_id::UInt64,
        to_id::UInt64;
        max_depth::Int = 10
    )

Find all paths between two nodes using DFS.
Returns Vector{Vector{UInt64}} of all possible paths.
"""
function find_all_paths(
    fx::CcyConv.FXGraph,
    from_id::UInt64,
    to_id::UInt64;
    max_depth::Int = 10,
)
    paths = Vector{Vector{UInt64}}()
    visited = fill(false, nv(fx.graph))
    current_path = [from_id]

    function dfs(current::UInt64)
        if length(current_path) > max_depth
            return
        end

        if current == to_id
            push!(paths, copy(current_path))
            return
        end

        visited[current] = true

        for neighbor in neighbors(fx.graph, current)
            if !visited[neighbor]
                push!(current_path, UInt64(neighbor))
                dfs(UInt64(neighbor))
                pop!(current_path)
            end
        end

        return visited[current] = false
    end

    dfs(from_id)
    return paths
end

"""
    find_best_path(
        fx::CcyConv.FXGraph,
        from_id::UInt64,
        to_id::UInt64,
        amount::Float64,
        use_max::Bool
    )::Vector{Pair{UInt64,UInt64}}

Find path with maximum/minimum total converted amount.
Uses common calculate_path_value function.
"""
function find_best_path(
    fx::CcyConv.FXGraph,
    from_id::UInt64,
    to_id::UInt64,
    amount::Float64,
    use_max::Bool,
)::Vector{Pair{UInt64,UInt64}}
    # Find all possible paths
    paths = find_all_paths(fx, from_id, to_id)
    isempty(paths) && return Pair{UInt64,UInt64}[]

    # Calculate converted amounts for all paths
    best_amount = use_max ? -Inf : Inf
    best_path = UInt64[]

    for path in paths
        final_amount, _ = calculate_path_value(fx, path, amount)
        if use_max ? final_amount > best_amount : final_amount < best_amount
            best_amount = final_amount
            best_path = path
        end
    end

    # Convert path to pairs
    result = Vector{Pair{UInt64,UInt64}}()
    for i = 1:length(best_path)-1
        push!(result, best_path[i] => best_path[i+1])
    end

    return result
end

# Export interface functions
function conv_max(
    fx::CcyConv.FXGraph,
    from_asset::String,
    to_asset::String;
    amount::Float64 = 1.0,
)::CcyConv.ConvRate
    #if from_asset == to_asset
    #    return CcyConv.ConvRate(from_asset, to_asset, 1.0)
    #end

    from_id = get_currency_id(fx, from_asset)
    to_id = get_currency_id(fx, to_asset)
    path_edges = find_best_path(fx, from_id, to_id, amount, true)

    isempty(path_edges) && return CcyConv.ConvRate(from_asset, to_asset, NaN)

    path = UInt64[from_id]
    append!(path, last.(path_edges))

    final_amount, chain = calculate_path_value(fx, path, amount)
    return CcyConv.ConvRate(from_asset, to_asset, final_amount / amount, chain)
end

function conv_min(
    fx::CcyConv.FXGraph,
    from_asset::String,
    to_asset::String;
    amount::Float64 = 1.0,
)::CcyConv.ConvRate
    #if from_asset == to_asset
    #    return CcyConv.ConvRate(from_asset, to_asset, 1.0)
    #end

    from_id = get_currency_id(fx, from_asset)
    to_id = get_currency_id(fx, to_asset)
    path_edges = find_best_path(fx, from_id, to_id, amount, false)

    isempty(path_edges) && return CcyConv.ConvRate(from_asset, to_asset, NaN)

    path = UInt64[from_id]
    append!(path, last.(path_edges))

    final_amount, chain = calculate_path_value(fx, path, amount)
    return CcyConv.ConvRate(from_asset, to_asset, final_amount / amount, chain)
end

end # module DFSPathFinder
