"""
    ConvRate

An object describing the price and conversion path between two currencies.

## Fields
- `from_asset::String`: The name of an initial curreny.
- `to_asset::String`: The name of a target currency.
- `conv::Float64`: Total currency conversion price.
- `chain::Vector{AbstractPrice}`: Chain of currency pairs involved in conversion.
"""
struct ConvRate
    from_asset::String
    to_asset::String
    conv::Float64
    chain::Vector{AbstractPrice}
end

function ConvRate(f::String, t::String, c::Float64)
    return ConvRate(f, t, c, Vector{AbstractPrice}())
end

"""
    conv_value(x::ConvRate) -> Float64

Returns the convert rate of `x`.
"""
function conv_value(x::ConvRate)::Float64
    return x.conv
end

"""
    conv_safe_value(x::ConvRate) -> Float64

Asserts that the conversion rate of `x` is not a `NaN` value and then returns it.
Otherwise throws an `AssertionError`.
"""
function conv_safe_value(x::ConvRate)::Float64
    isnan(x.conv) && throw(
        InvalidConversionError(
            "Conversion rate is NaN: $(x.conv)",
            x.from_asset,
            x.to_asset,
            "No valid conversion path exists between currencies",
        ),
    )
    return x.conv
end

"""
    conv_chain(x::ConvRate) -> Vector{AbstractPrice}

Returns the path chain of `x`.
"""
function conv_chain(x::ConvRate)::Vector{AbstractPrice}
    return x.chain
end
