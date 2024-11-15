"""
    AbstractPrice

Base type for all price representations.
"""
abstract type AbstractPrice end

"""
    from_asset(x::AbstractPrice)::String

Get the base currency of a price.
"""
function from_asset(x::AbstractPrice)::String
    throw(ErrorException("not implemented for $(typeof(x))"))
end

"""
    to_asset(x::AbstractPrice)::String

Get the quote currency of a price.
"""
function to_asset(x::AbstractPrice)::String
    throw(ErrorException("not implemented for $(typeof(x))"))
end

"""
    price(x::AbstractPrice)::Float64

Get the conversion rate of a price.
"""
function price(x::AbstractPrice)::Float64
    throw(ErrorException("not implemented for $(typeof(x))"))
end