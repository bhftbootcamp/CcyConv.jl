"""
    AbstractPrice

An abstract type representing price of a currency pair.

For types using this interface the following methods must be defined:
- [`from_asset`](@ref)
- [`to_asset`](@ref)
- [`price`](@ref)
"""
abstract type AbstractPrice end

"""
    AbstractCtx

An abstract type representing workspace context.
"""
abstract type AbstractCtx end

struct MyCtx <: AbstractCtx
    #__ empty
end

"""
    from_asset(x::AbstractPrice) -> String

Returns the name of the base currency of `x`.
"""
function from_asset(x::AbstractPrice)::String
    return throw("not implemented for $(typeof(x))")
end

"""
    to_asset(x::AbstractPrice) -> String

Returns the name of the quote currency of `x`.
"""
function to_asset(x::AbstractPrice)::String
    return throw("not implemented for $(typeof(x))")
end

"""
    price(x::AbstractPrice) -> Float64

Returns price of the currency pair `x`.
"""
function price(x::AbstractPrice)::Float64
    return throw("not implemented for $(typeof(x))")
end

"""
    price(ctx::AbstractCtx, x::AbstractPrice) -> Float64

Advanced function for getting the price of a currency pair `x` that can take into account the context of the `ctx`.

!!! note
    This function is called when searching for a currency conversion path and can be overloaded to achieve advanced functionality using context (for example, caching the requested data for subsequent requests).
    See [context guide](@ref context_manual).

"""
function price(ctx::AbstractCtx, x::AbstractPrice)::Float64
    return price(x)
end

"""
    Price <: AbstractPrice

A type representing the price of currency pair.

## Fields
- `from_asset::String`: Base currency name.
- `to_asset::String`: Quote currency name.
- `price::Float64`: The currency pair price.
"""
struct Price <: AbstractPrice
    from_asset::String
    to_asset::String
    price::Float64
end

function from_asset(x::Price)::String
    return x.from_asset
end

function to_asset(x::Price)::String
    return x.to_asset
end

function price(x::Price)::Float64
    return x.price
end

function price_first_non_nan(ctx::AbstractCtx, items::Vector{P}) where {P<:AbstractPrice}
    for item in items
        value = price(ctx, item)
        isnan(value) || return (item, value)
    end
    return (nothing, NaN)
end
