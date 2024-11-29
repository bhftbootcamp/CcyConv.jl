module CcyConv

export ConvRate, FXGraph, Price
export conv_ccys, conv_chain, conv_safe_value, conv_value

using Graphs

include("errors.jl")

include("conversion/abstract.jl")
include("conversion/linear.jl")
include("conversion/reverse.jl")
include("conversion/fees.jl")
include("conversion/custom.jl")

include("types/price.jl")
include("types/conv_rate.jl")
include("types/graph.jl")

include("utils/graph_ops.jl")
include("utils/graph_analysis.jl")
include("utils/path_ops.jl")
include("utils/mermaid.jl")

module Pathfinding
export AStar, DFSPathFinder, ExtremumPathFinder
export estimate_cost, calculate_edge_weight
include("pathfinding/a_star.jl")
include("pathfinding/dfs_path_finder.jl")
include("pathfinding/extremum_path_finder.jl")
end

end
