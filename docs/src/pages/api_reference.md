# API Reference

```@docs
CcyConv.AbstractPrice
CcyConv.AbstractCtx
```

## Price

```@docs
CcyConv.Price
CcyConv.from_asset
CcyConv.to_asset
CcyConv.price
```

## FXGraph

```@docs
CcyConv.FXGraph
CcyConv.conv_ccys
CcyConv.push!
CcyConv.append!
```

## ConvRate

```@docs
CcyConv.ConvRate
CcyConv.conv_value
CcyConv.conv_safe_value
CcyConv.conv_chain
```

## [Pathfinding](@id algorithms)

```@docs
CcyConv.AStar
CcyConv.DFS
CcyConv.conv
```

```@docs
CcyConv.FXGraph(::CcyConv.AbstractCtx, ::Function, ::String, ::String)
```
