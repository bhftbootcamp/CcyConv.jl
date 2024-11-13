"""
    Find all paths between two nodes using DFS
"""
function find_all_paths(fx::FXGraph, from_id::Int, to_id::Int, max_depth::Int=10)
    paths = Vector{Vector{Int}}()
    visited = fill(false, nv(fx.graph))
    current_path = [from_id]
    
    function dfs(current::Int)
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
                push!(current_path, neighbor)
                dfs(neighbor)
                pop!(current_path)
            end
        end
        
        visited[current] = false
    end
    
    dfs(from_id)
    return paths
end

"""
    Find path with maximum/minimum product
"""
function find_path(fx::FXGraph, from_id::UInt64, to_id::UInt64, use_max::Bool)::Vector{Pair{UInt64,UInt64}}
    # Find all possible paths
    paths = find_all_paths(fx, Int(from_id), Int(to_id))
    
    if isempty(paths)
        return Pair{UInt64,UInt64}[]
    end
    
    # Calculate rates for all paths
    best_rate = use_max ? -Inf : Inf
    best_path = Int[]
    
    for path in paths
        rate, _ = calculate_path_rate(fx, path)
        if use_max ? rate > best_rate : rate < best_rate
            best_rate = rate
            best_path = path
        end
    end
    
    # Convert path to pairs
    result = Vector{Pair{UInt64,UInt64}}()
    for i in 1:length(best_path)-1
        push!(result, UInt64(best_path[i]) => UInt64(best_path[i+1]))
    end
    
    return result
end

# Wrapper functions for max and min paths
dfs_product_max_path_finder(fx::FXGraph, from_id::UInt64, to_id::UInt64) = find_path(fx, from_id, to_id, true)
dfs_product_min_path_finder(fx::FXGraph, from_id::UInt64, to_id::UInt64) = find_path(fx, from_id, to_id, false)

conv_max(fx, from, to) = fx(CcyConv.MyCtx(), dfs_product_max_path_finder, from, to)
conv_min(fx, from, to) = fx(CcyConv.MyCtx(), dfs_product_min_path_finder, from, to)