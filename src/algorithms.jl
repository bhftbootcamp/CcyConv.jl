# First valid (non-NaN) price from a list of edges.
function _first_valid(ctx::AbstractCtx, items::Vector{P}) where {P<:AbstractPrice}
    for x in items
        w = price(ctx, x)
        isnan(w) || return (x, w)
    end
    return (nothing, NaN)
end

# Edge weight w(u,v): resolve stored direction, invert if needed.
function _w(ctx::AbstractCtx, fx::FXGraph, u, v)
    fwd = get(fx.edge_prices, (u, v), nothing)
    fwd !== nothing && return _first_valid(ctx, fwd)
    rev = get(fx.edge_prices, (v, u), nothing)
    rev !== nothing || return (nothing, NaN)
    x, w = _first_valid(ctx, rev)
    return (x, inv(w))
end

# Resolve node names → ids, run path algorithm.
function _graph_path(path_alg, ctx, fx, from_name, to_name)
    s = get(fx.node_ids, from_name, nothing)
    t = get(fx.node_ids, to_name, nothing)
    (s === nothing || t === nothing) && return Pair{Int64,Int64}[]
    return path_alg(ctx, fx, s, t)
end

# ── DFS: exhaustive min-product simple path ─────────────────────────

mutable struct _DFSBest
    rate::Float64
    chain::Vector{AbstractPrice}
end

function _dfs!(ctx, fx, u, t, visited, w_acc, path, best, cmp)
    if u == t
        if cmp(w_acc, best.rate)
            best.rate = w_acc
            best.chain = copy(path)
        end
        return
    end
    for v in neighbors(fx.graph, u)
        v in visited && continue
        x, w = _w(ctx, fx, u, v)
        (isnan(w) || isinf(w)) && continue
        push!(visited, v)
        push!(path, x)
        _dfs!(ctx, fx, v, t, visited, w_acc * w, path, best, cmp)
        pop!(path)
        delete!(visited, v)
    end
end

function _optimal_rate(ctx, fx, from_name, to_name, init, cmp)
    from_name == to_name && return ConvRate(from_name, to_name, 1.0)
    s = get(fx.node_ids, from_name, nothing)
    t = get(fx.node_ids, to_name, nothing)
    (s === nothing || t === nothing) && return ConvRate(from_name, to_name, NaN)
    best = _DFSBest(init, AbstractPrice[])
    _dfs!(ctx, fx, s, t, Set{Int64}(s), 1.0, AbstractPrice[], best, cmp)
    isinf(best.rate) && return ConvRate(from_name, to_name, NaN)
    return ConvRate(from_name, to_name, best.rate, best.chain)
end

# DFS fallback for A* (returns Vector{Pair} edge list).
function _dfs_path(ctx, fx, s, t)
    id_name = Dict(v => k for (k, v) in fx.node_ids)
    cr = _optimal_rate(ctx, fx, id_name[s], id_name[t], Inf, <)
    isnan(cr.conv) && return Pair{Int64,Int64}[]
    path = Pair{Int64,Int64}[]
    cur = s
    for x in cr.chain
        u = fx.node_ids[from_asset(x)]
        v = fx.node_ids[to_asset(x)]
        nxt = cur == u ? v : u
        push!(path, cur => nxt)
        cur = nxt
    end
    return path
end

# ── Log-weight matrix W[u,v] = log(rate(u→v)) ──────────────────────

function _weight_matrix(ctx, fx)
    n = nv(fx.graph)
    W = fill(Inf, n, n)
    for e in edges(fx.graph)
        u, v = src(e), dst(e)
        fwd = get(fx.edge_prices, (u, v), nothing)
        if fwd !== nothing
            _, val = _first_valid(ctx, fwd)
        else
            rev = get(fx.edge_prices, (v, u), nothing)
            rev === nothing && continue
            _, val = _first_valid(ctx, rev)
            u, v = v, u
        end
        if !isnan(val) && !isinf(val) && val > 0
            lv = log(val)
            W[u, v] = lv
            W[v, u] = -lv
        end
    end
    return W
end

# ── Bellman–Ford backward heuristic h(v) → t ────────────────────────
# Computes shortest-path distances to target t on the log-weight graph.
# Returns nothing if a negative cycle is detected.

function _bf_heuristic(W, n, t)
    E = Tuple{Int64,Int64,Float64}[]
    @inbounds for u in 1:n, v in 1:n
        w = W[u, v]
        isinf(w) || push!(E, (u, v, w))
    end
    h = fill(Inf, n)
    h[t] = 0.0
    for _ in 1:(n - 1)
        changed = false
        for (u, v, w) in E
            d = h[v] + w
            if d < h[u]
                h[u] = d
                changed = true
            end
        end
        changed || break
    end
    for (u, v, w) in E
        h[v] + w < h[u] - 1e-12 && return nothing
    end
    return h
end

# ── Binary min-heap for A* open set ─────────────────────────────────

struct _Heap
    data::Vector{Tuple{Float64,Tuple{Int64,UInt64}}}
    _Heap() = new(Tuple{Float64,Tuple{Int64,UInt64}}[])
end

Base.isempty(Q::_Heap) = isempty(Q.data)

function Base.push!(Q::_Heap, item::Tuple{Float64,Tuple{Int64,UInt64}})
    push!(Q.data, item)
    _siftup!(Q.data, length(Q.data))
    return Q
end

function _popmin!(Q::_Heap)
    a = Q.data
    a[1], a[end] = a[end], a[1]
    item = pop!(a)
    isempty(a) || _siftdown!(a, 1)
    return item
end

function _siftup!(a, i)
    @inbounds while i > 1
        p = i >> 1
        a[p][1] <= a[i][1] && break
        a[p], a[i] = a[i], a[p]
        i = p
    end
end

function _siftdown!(a, i)
    @inbounds begin
        n = length(a)
        while true
            m = i
            l, r = 2i, 2i + 1
            l <= n && a[l][1] < a[m][1] && (m = l)
            r <= n && a[r][1] < a[m][1] && (m = r)
            m == i && break
            a[i], a[m] = a[m], a[i]
            i = m
        end
    end
end

# ── Pareto front: dominance pruning in (visited_set, cost) space ────

function _dominated(F, v, S, d)
    fv = get(F, v, nothing)
    fv === nothing && return false
    @inbounds for (Sp, dp) in fv
        (Sp & S) == Sp && dp <= d && return true
    end
    return false
end

function _update_front!(F, v, S, d)
    fv = get!(() -> Tuple{UInt64,Float64}[], F, v)
    filter!(p -> !((S & p[1]) == S && d <= p[2]), fv)
    push!(fv, (S, d))
end

# ── State-space A* ──────────────────────────────────────────────────
# Search graph: vertices are (node, visited_bitmask) pairs.
# Edge weights: log(rate). Finds minimum-product simple path s → t.

function _a_star(ctx, fx, s, t)
    W = _weight_matrix(ctx, fx)
    n = nv(fx.graph)

    h = _bf_heuristic(W, n, t)

    # If BF detects negative cycle, use min-edge lower bound.
    wmin = 0.0
    if h === nothing
        @inbounds for j in 1:n, i in 1:n
            w = W[i, j]
            !isinf(w) && w < wmin && (wmin = w)
        end
    end

    lb(u, S) = u == t ? 0.0 : h !== nothing ? h[u] : (n - count_ones(S)) * wmin

    S₀ = UInt64(1) << (s - 1)
    q₀ = (s, S₀)
    g = Dict{Tuple{Int64,UInt64},Float64}(q₀ => 0.0)
    π = Dict{Tuple{Int64,UInt64},Tuple{Int64,UInt64}}()
    Q = _Heap()
    push!(Q, (lb(s, S₀), q₀))
    F = Dict{Int64,Vector{Tuple{UInt64,Float64}}}()

    g_best = Inf
    q_best = q₀

    while !isempty(Q)
        _, q = _popmin!(Q)
        d = g[q]
        u, S = q

        _dominated(F, u, S, d) && continue

        if u == t
            g_best = d
            q_best = q
            break
        end

        d + lb(u, S) >= g_best && continue
        _update_front!(F, u, S, d)

        for v in neighbors(fx.graph, u)
            vb = UInt64(1) << (v - 1)
            (S & vb) != 0 && continue
            w = W[u, v]
            isinf(w) && continue
            Sv = S | vb
            qv = (v, Sv)
            dv = d + w
            dv < get(g, qv, Inf) || continue
            _dominated(F, v, Sv, dv) && continue
            g[qv] = dv
            π[qv] = q
            push!(Q, (dv + lb(v, Sv), qv))
        end
    end

    isinf(g_best) && return Pair{Int64,Int64}[]
    path = Pair{Int64,Int64}[]
    q = q_best
    while q != q₀
        prev = π[q]
        push!(path, prev[1] => q[1])
        q = prev
    end
    reverse!(path)
    return path
end

# A* with DFS fallback for large graphs (bitmask limit: 64 nodes).
function _min_path(ctx, fx, s, t)
    nv(fx.graph) > 64 && return _dfs_path(ctx, fx, s, t)
    return _a_star(ctx, fx, s, t)
end
