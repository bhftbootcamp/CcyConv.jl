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
    Price{T} <: AbstractPrice

A type representing a currency pair price.
T can be either Float64 (backward compatible) or AbstractConversionFunction.

## Fields
- `from_asset::String`: Base currency name
- `to_asset::String`: Quote currency name
- `conversion::T`: The conversion rate or function
"""
struct Price{T} <: AbstractPrice
    from_asset::String
    to_asset::String
    conversion::T

    # Constructor for Float64 (backward compatibility)
    function Price(from_asset::String, to_asset::String, rate::Float64)
        return new{LinearConversionFunction}(
            from_asset,
            to_asset,
            LinearConversionFunction(rate),
        )
    end

    # Constructor for conversion functions
    function Price(
        from_asset::String,
        to_asset::String,
        conversion::AbstractConversionFunction,
    )
        return new{typeof(conversion)}(from_asset, to_asset, conversion)
    end
end

# Interface implementations
from_asset(p::Price)::String = p.from_asset
to_asset(p::Price)::String = p.to_asset
price(p::Price)::Float64 = convert(p.conversion, 1.0)

"""
    convert_amount(p::Price, amount::Float64)::Float64

Convert an amount using the price's conversion function.
"""
function convert_amount(p::Price, amount::Float64)::Float64
    return convert(p.conversion, amount)
end

"""
    rev_convert_amount(x::Price, amount::Float64)::Float64

Convert an amount using the price's reverse conversion function.
"""
function rev_convert_amount(p::Price, amount::Float64)::Float64
    return rev_convert(p.conversion, amount)
end

"""
    price_first_non_nan(ctx::AbstractCtx, items::Vector{P}) where {P<:AbstractPrice}

Find the first non-NaN price in a list of prices.
"""
function price_first_non_nan(ctx::AbstractCtx, items::Vector{P}) where {P<:AbstractPrice}
    for item in items
        value = price(ctx, item)
        isnan(value) || return (item, value)
    end
    return (nothing, NaN)
end

"""
    reverse_price(x::Price)::Price

Create a new Price with currencies swapped and reverse conversion.
"""
function reverse_price(x::Price)::Price
    return Price(to_asset(x), from_asset(x), ReverseConversionFunction(x.conversion))
end
