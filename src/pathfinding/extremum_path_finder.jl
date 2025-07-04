module ExtremumPathFinder

using CcyConv

@enum ExtremumType begin
    MAX = 1
    MIN = -1
end

struct GraphFormatAdapter
    edges::Vector{Tuple{UInt64,UInt64,Float64}}
    num_vertexes::UInt64
end

function graph_format_adapter(graph::CcyConv.FXGraph)::GraphFormatAdapter
    edges = keys(graph.edge_nodes)
    num_vertexes = length(keys(graph.edge_encode))
    output_vector = Vector{Tuple{UInt64,UInt64,Float64}}()

    for edge in edges
        vertex_from = edge[1]
        vertex_to = edge[2]
        price_value = get(graph.edge_nodes, edge, 0)
        weight = CcyConv.price(price_value[1])
        push!(output_vector, (vertex_from, vertex_to, weight))
        if get(graph.edge_nodes, (vertex_to, vertex_from), 0) == 0
            push!(output_vector, (vertex_to, vertex_from, 1 / weight))
        end
    end

    return GraphFormatAdapter(output_vector, num_vertexes)
end

function get_adjacency_list(
    roads::GraphFormatAdapter,
)::Vector{Vector{Tuple{UInt64,Float64}}}
    num_vertexes = roads.num_vertexes
    edges = roads.edges
    adj = [Vector{Tuple{UInt64,Float64}}() for _ = 1:(num_vertexes+1)]
    for road in edges
        push!(adj[road[1]], (road[2], road[3]))
    end
    return adj
end

function all_path_source_target(
    graph::Vector{Vector{Tuple{UInt64,Float64}}},
    start_index::UInt64,
    end_index::UInt64,
    total_elements::UInt64,
)::Tuple{Vector{Vector{UInt64}},Vector{Float64}}
    ans_path = Vector{Vector{UInt64}}()
    ans_product_weight = Vector{Float64}()

    function dfs(
        element::Tuple{UInt64,Float64},
        depth::UInt64,
        max_product::Float64,
        path::Vector{UInt64},
    )
        for item in graph[element[1]]
            next_vertex, next_weight = item
            if next_vertex == start_index
                continue
            end
            if next_vertex in path[1:depth]
                continue
            end
            if next_vertex == end_index
                path[depth+1] = next_vertex
                if path[1:depth+1] in ans_path
                    return
                end
                push!(ans_path, path[1:depth+1])
                push!(ans_product_weight, max_product * next_weight)
                continue
            end
            path[depth+1] = next_vertex
            dfs(item, depth + UInt64(1), max_product * next_weight, path)
        end
    end

    dfs((start_index, 0.0), UInt64(0), Float64(1.0), fill(UInt64(0), total_elements + 1))
    return (ans_path, ans_product_weight)
end

function find_extremum_path(
    fx::CcyConv.FXGraph,
    from_id::UInt64,
    to_id::UInt64,
    type::ExtremumType,
)::Vector{Pair{UInt64,UInt64}}
    extrema_function = type == MAX ? findmax : findmin
    vector_of_pairs = Vector{Pair{UInt64,UInt64}}()

    adapted_graph = graph_format_adapter(fx)
    adjacent_array = get_adjacency_list(adapted_graph)
    all_paths_products = all_path_source_target(
        adjacent_array,
        from_id,
        to_id,
        adapted_graph.num_vertexes * 2,
    )

    non_zero_elements = filter(x -> x > 0, all_paths_products[2])

    if isempty(non_zero_elements)
        return Vector{Pair{UInt64,UInt64}}()
    end

    max_value, index_max_value = extrema_function(non_zero_elements)
    path = vcat([from_id], all_paths_products[1][index_max_value])

    for i = 1:length(path)-1
        vertex_from = path[i]
        vertex_to = path[i+1]
        push!(vector_of_pairs, vertex_from => vertex_to)
    end

    return vector_of_pairs
end

function max_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    return find_extremum_path(fx, from_id, to_id, MAX)
end

function min_path_algorithm(fx::CcyConv.FXGraph, from_id::UInt64, to_id::UInt64)
    return find_extremum_path(fx, from_id, to_id, MIN)
end

"""
    conv_max(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate
    
Find the path that maximizes the conversion rate between currencies using the extremum path finding algorithm.
"""
function conv_max(fx::CcyConv.FXGraph, x...; kw...)::CcyConv.ConvRate
    return fx(CcyConv.MyCtx(), max_path_algorithm, x...; kw...)
end

"""
    conv_min(fx::FXGraph, from_asset::String, to_asset::String) -> ConvRate
    
Find the path that minimizes the conversion rate between currencies using the extremum path finding algorithm.
"""
function conv_min(fx::CcyConv.FXGraph, x...; kw...)::CcyConv.ConvRate
    return fx(CcyConv.MyCtx(), min_path_algorithm, x...; kw...)
end

end # module
