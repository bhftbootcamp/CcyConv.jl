"""
    FixedFeeConversionFunction <: AbstractConversionFunction

Conversion with fixed fee in target currency.

## Fields
- `rate::Float64`: Base exchange rate
- `fee::Float64`: Fixed fee in target currency
"""
struct FixedFeeConversionFunction <: AbstractConversionFunction
    rate::Float64
    fee::Float64

    forward_fn::Function
    backward_fn::Function

    function FixedFeeConversionFunction(rate::Float64, fee::Float64)
        fee >= 0 || throw(ArgumentError("Fee must be non-negative"))
        forward_fn = amount -> rate * amount - fee
        backward_fn = amount -> (amount + fee) / rate
        return new(rate, fee, forward_fn, backward_fn)
    end
end

function convert(f::FixedFeeConversionFunction, amount::Float64)::Float64
    return f.forward_fn(amount)
end

function rev_convert(f::FixedFeeConversionFunction, amount::Float64)::Float64
    return f.backward_fn(amount)
end

"""
    ProportionalFeeConversionFunction <: AbstractConversionFunction

Conversion with percentage-based fee.

## Fields
- `rate::Float64`: Base exchange rate
- `fee_percent::Float64`: Fee percentage (e.g., 0.01 for 1%)
"""
struct ProportionalFeeConversionFunction <: AbstractConversionFunction
    rate::Float64
    fee_percent::Float64

    forward_fn::Function
    backward_fn::Function

    function ProportionalFeeConversionFunction(rate::Float64, fee_percent::Float64)
        0 <= fee_percent < 1 ||
            throw(ArgumentError("Fee percentage must be between 0 and 1"))
        forward_fn = amount -> rate * amount * (1.0 - fee_percent)
        backward_fn = amount -> amount / (rate * (1.0 - fee_percent))
        return new(rate, fee_percent, forward_fn, backward_fn)
    end
end

function convert(f::ProportionalFeeConversionFunction, amount::Float64)::Float64
    return f.forward_fn(amount)
end

function rev_convert(f::ProportionalFeeConversionFunction, amount::Float64)::Float64
    return f.backward_fn(amount)
end
