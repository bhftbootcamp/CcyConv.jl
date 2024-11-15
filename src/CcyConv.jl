module CcyConv

export ConvRate, FXGraph, Price
export conv_ccys, conv_chain, conv_safe_value, conv_value

using Graphs

include("errors.jl")
include("types/price.jl")
include("types/conv_rate.jl")
include("types/graph.jl")
include("utils/graph_ops.jl")
include("utils/graph_analysis.jl")
include("utils/path_ops.jl")
include("utils/mermaid.jl")

module Pathfinding
export AStar, DFSPathFinder, DFSPathFinder_v2, ExtremumPathFinder
include("pathfinding/a_star.jl")
include("pathfinding/dfs_path_finder_v1.jl")
include("pathfinding/dfs_path_finder_v2.jl")
include("pathfinding/extremum_path_finder.jl")
end

end
