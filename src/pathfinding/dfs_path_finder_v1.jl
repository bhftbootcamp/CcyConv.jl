module DFSPathFinder

using CcyConv
using Graphs

"""
    Find all paths between two nodes using DFS
"""
function find_all_paths(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64; max_depth::Int = 10)
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
    Find path with maximum/minimum product
"""
function find_path(
    fx::CcyConv.FXGraph,
    from_id::UInt64,
    to_id::UInt64,
    use_max::Bool,
)::Vector{Pair{UInt64,UInt64}}
    # Find all possible paths
    paths = find_all_paths(fx, from_id, to_id)

    if isempty(paths)
        return Pair{UInt64,UInt64}[]
    end

    # Calculate rates for all paths
    best_rate = use_max ? -Inf : Inf
    best_path = UInt64[]

    for path in paths
        rate, _ = CcyConv.calculate_path_rate(fx, path)
        if use_max ? rate > best_rate : rate < best_rate
            best_rate = rate
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

# Path finding algorithms
function max_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    return find_path(fx, from_id, to_id, true)
end

function min_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    return find_path(fx, from_id, to_id, false)
end

"""
    conv_max(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate
    
Find the path that maximizes the conversion rate between currencies.
"""
function conv_max(fx::CcyConv.FXGraph, x...; kw...)::CcyConv.ConvRate
    return fx(CcyConv.MyCtx(), max_path_algorithm, x...; kw...)
end

"""
    conv_min(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate
    
Find the path that minimizes the conversion rate between currencies.
"""
function conv_min(fx::CcyConv.FXGraph, x...; kw...)::CcyConv.ConvRate
    return fx(CcyConv.MyCtx(), min_path_algorithm, x...; kw...)
end

end # module
