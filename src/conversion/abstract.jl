"""
    AbstractConversionFunction

Base type for all conversion functions.
Must implement:
- convert(f::AbstractConversionFunction, amount::Float64)::Float64
- rev_convert(f::AbstractConversionFunction, amount::Float64)::Float64
"""
abstract type AbstractConversionFunction end

function convert(f::AbstractConversionFunction, amount::Float64)::Float64
    throw(ErrorException("not implemented for $(typeof(f))"))
end

function rev_convert(f::AbstractConversionFunction, amount::Float64)::Float64
    throw(ErrorException("not implemented for $(typeof(f))"))
end
