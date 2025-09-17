"""
    LinearConversionFunction <: AbstractConversionFunction

Simple linear conversion with fixed rate.
Maintains backward compatibility with existing rate-based conversions.

## Fields
- `rate::Float64`: The exchange rate
"""
struct LinearConversionFunction <: AbstractConversionFunction
    rate::Float64
end

function convert(f::LinearConversionFunction, amount::Float64)::Float64
    return f.rate * amount
end

function rev_convert(f::LinearConversionFunction, amount::Float64)::Float64
    return amount / f.rate
end
