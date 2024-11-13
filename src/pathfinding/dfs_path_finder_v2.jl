module DFSPathFinder_v2

using CcyConv
using Graphs
import CcyConv: from_asset, to_asset, price

struct PathState
    value::Float64
    chain::Vector{CcyConv.AbstractPrice}
end

function find_all_paths(g::SimpleGraph, from::Int, to::Int, max_depth::Int=10)
    paths = Vector{Vector{Int}}()
    visited = fill(false, nv(g))
    current_path = [from]

    function dfs(current::Int)
        length(current_path) > max_depth && return
        
        if current == to
            push!(paths, copy(current_path))
            return
        end

        visited[current] = true
        for neighbor in neighbors(g, current)
            if !visited[neighbor]
                push!(current_path, neighbor)
                dfs(neighbor)
                pop!(current_path)
            end
        end
        visited[current] = false
    end

    dfs(from)
    return paths
end

function compute_path_value(fx::CcyConv.FXGraph, path::Vector{Int})::PathState
    total = 1.0
    chain = CcyConv.AbstractPrice[]
    
    for i in 1:length(path)-1
        u, v = path[i], path[i+1]
        if haskey(fx.edge_nodes, (u, v))
            price_obj = fx.edge_nodes[(u, v)][1]
            push!(chain, price_obj)
            total *= price(price_obj)
        elseif haskey(fx.edge_nodes, (v, u))
            price_obj = fx.edge_nodes[(v, u)][1]
            value = 1.0 / price(price_obj)
            total *= value
            # Create a new Price object for the reverse direction
            reversed_price = CcyConv.Price(to_asset(price_obj), from_asset(price_obj), value)
            push!(chain, reversed_price)
        else
            return PathState(NaN, CcyConv.AbstractPrice[])
        end
    end
    
    return PathState(total, chain)
end

function find_optimal_path(
    fx::CcyConv.FXGraph,
    from_id::UInt64, 
    to_id::UInt64,
    use_max::Bool
)::Vector{Pair{UInt64,UInt64}}
    from_int, to_int = Int(from_id), Int(to_id)
    all_paths = find_all_paths(fx.graph, from_int, to_int)
    isempty(all_paths) && return Pair{UInt64,UInt64}[]
    
    # Initialize with first valid path
    best_state = PathState(NaN, CcyConv.AbstractPrice[])
    for path in all_paths
        state = compute_path_value(fx, path)
        if isnan(best_state.value) || (use_max ? state.value > best_state.value : state.value < best_state.value)
            best_state = state
        end
    end
    
    isnan(best_state.value) && return Pair{UInt64,UInt64}[]
    
    # Convert path to pairs
    result = Pair{UInt64,UInt64}[]
    for price_obj in best_state.chain
        push!(result, UInt64(fx.edge_encode[from_asset(price_obj)]) => 
                     UInt64(fx.edge_encode[to_asset(price_obj)]))
    end
    
    return result
end

function max_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    find_optimal_path(fx, from_id, to_id, true)
end

function min_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)  
    find_optimal_path(fx, from_id, to_id, false)
end

function conv_max(fx::CcyConv.FXGraph, from_asset::String, to_asset::String)::CcyConv.ConvRate
    from_asset == to_asset && return CcyConv.ConvRate(from_asset, to_asset, 1.0)
    fx(CcyConv.MyCtx(), max_path_algorithm, from_asset, to_asset)
end

function conv_min(fx::CcyConv.FXGraph, from_asset::String, to_asset::String)::CcyConv.ConvRate
    from_asset == to_asset && return CcyConv.ConvRate(from_asset, to_asset, 1.0)
    fx(CcyConv.MyCtx(), min_path_algorithm, from_asset, to_asset)
end

end # module