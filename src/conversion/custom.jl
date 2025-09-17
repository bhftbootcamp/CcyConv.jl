"""
    FunctionWrapper <: AbstractConversionFunction

Wrapper for custom conversion functions.

## Fields
- `forward_fn::Function`: The conversion function
- `backward_fn::Function`: The reverse conversion function
- `params::NamedTuple`: Optional parameters for the function
"""
struct FunctionWrapper <: AbstractConversionFunction
    forward_fn::Function
    backward_fn::Function

    params::NamedTuple

    function FunctionWrapper(f::Function; params::NamedTuple = NamedTuple())
        # using Roots
        # x0 = 0.0  # TOFIX: Use a more robust method to find x0
        # backward_fn = y -> fzero(x -> f(x; params...) - y, x0; order = 0)
        # using InverseFunctions
        # backward_fn = y -> reverse(f(y; params...))
        backward_fn = x -> error("Reverse conversion not implemented with FunctionWrapper")
        return new(f, backward_fn, params)
    end
end

function convert(f::FunctionWrapper, amount::Float64)::Float64
    return f.forward_fn(amount; f.params...)
end

function rev_convert(f::FunctionWrapper, amount::Float64)::Float64
    return f.backward_fn(amount)
end

"""
    CompositeConversionFunction <: AbstractConversionFunction

Combines multiple conversion functions that are applied in sequence.

## Fields
- `functions::Vector{AbstractConversionFunction}`: Functions to apply in sequence
"""
struct CompositeConversionFunction <: AbstractConversionFunction
    functions::Vector{AbstractConversionFunction}
end

function convert(f::CompositeConversionFunction, amount::Float64)::Float64
    result = amount
    for func in f.functions
        result = convert(func, result)
    end
    return result
end

function rev_convert(f::CompositeConversionFunction, amount::Float64)::Float64
    result = amount
    for func in reverse(f.functions)
        result = rev_convert(func, result)
    end
    return result
end

"""
    TieredBonusConversionFunction <: AbstractConversionFunction

Conversion function with tiered bonuses.
## Fields:
- `base_rate::Float64`: Base exchange rate
- `tiers::Vector{Tuple{Float64,Float64}}`: Bonus tiers (threshold, bonus_rate)
- `fee::Float64`: Fixed fee in target currency
"""
struct TieredBonusConversionFunction <: AbstractConversionFunction
    base_rate::Float64
    tiers::Vector{Tuple{Float64,Float64}}  # (threshold, bonus_rate)
    fee::Float64

    function TieredBonusConversionFunction(
        base_rate::Float64,
        tiers::Vector{Tuple{Float64,Float64}};
        fee::Float64 = 0.0,
    )
        sorted_tiers = sort(tiers)
        @assert all(t[2] >= 0 for t in tiers) "Bonus rates must be non-negative"
        return new(base_rate, sorted_tiers, fee)
    end
end

function get_rate_multiplier(amount::Float64, tiers::Vector{Tuple{Float64,Float64}})
    bonus = 0.0  # No bonus by default
    for (threshold, bonus_rate) in sort(tiers)
        if amount >= threshold
            bonus = bonus_rate
        end
    end
    return 1.0 + bonus
end

function get_tier_for_output(
    target_pre_fee::Float64,
    base_rate::Float64,
    tiers::Vector{Tuple{Float64,Float64}},
)
    # Try each possible tier and see which one would produce this output
    if isempty(tiers)
        return 0.0  # No bonus
    end

    # Try no bonus first
    amount_no_bonus = target_pre_fee / base_rate
    if amount_no_bonus < tiers[1][1]
        return 0.0
    end

    # Check each tier
    for i = 1:length(tiers)
        threshold, bonus = tiers[i]
        amount = target_pre_fee / (base_rate * (1.0 + bonus))

        # Special case for the amount exactly at a threshold
        if isapprox(amount, threshold, rtol = 1e-10)
            return bonus
        end

        # If this is the last tier
        if i == length(tiers)
            if amount >= threshold
                return bonus
            end
        else
            next_threshold = tiers[i+1][1]
            if amount >= threshold && amount < next_threshold
                return bonus
            end
        end
    end

    return error("Could not determine appropriate tier")
end

function convert(f::TieredBonusConversionFunction, amount::Float64)::Float64
    amount >= 0 || throw(DomainError(amount, "Amount must be non-negative"))
    return amount * f.base_rate * get_rate_multiplier(amount, f.tiers) - f.fee
end

function rev_convert(f::TieredBonusConversionFunction, target_amount::Float64)::Float64
    pre_fee = target_amount + f.fee
    bonus = get_tier_for_output(pre_fee, f.base_rate, f.tiers)
    return pre_fee / (f.base_rate * (1.0 + bonus))
end
