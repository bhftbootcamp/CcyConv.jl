using CcyConv: AbstractConversionFunction, convert, rev_convert

"""
    ReverseConversionFunction{T} <: AbstractConversionFunction

Reverses any conversion function. The reverse of a reverse is the original function.

## Type Parameters
- `T`: Type of the wrapped conversion function

## Fields
- `f::T`: The conversion function to reverse

## Examples
```julia
# Create a linear conversion function
linear = LinearConversionFunction(1.1)

# Create its reverse
reverse_linear = ReverseConversionFunction(linear)

# The reverse of the reverse is the original function
original = ReverseConversionFunction(reverse_linear)  # Returns linear
"""
struct ReverseConversionFunction{T<:AbstractConversionFunction} <:
       AbstractConversionFunction
    f::T

    function ReverseConversionFunction(f::AbstractConversionFunction)
        if f isa ReverseConversionFunction
            # If we're trying to reverse a reverse, return the original
            return f.f
        else
            return new{typeof(f)}(f)
        end
    end
end

# Forward conversion uses the wrapped function's reverse conversion
function convert(r::ReverseConversionFunction, amount::Float64)::Float64
    return rev_convert(r.f, amount)
end

# Reverse conversion uses the wrapped function's forward conversion
function rev_convert(r::ReverseConversionFunction, amount::Float64)::Float64
    return convert(r.f, amount)
end
