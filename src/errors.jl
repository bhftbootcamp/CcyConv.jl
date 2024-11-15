"""
    CcyConvError <: Exception

Base error type for all CcyConv errors.
"""
abstract type CcyConvError <: Exception end

"""
    UnknownCurrencyError <: CcyConvError

Error thrown when a currency or currency ID is not found.

## Fields
- `message::String`: Error description
- `currency::Union{String,UInt64}`: The currency or ID that wasn't found
"""
struct UnknownCurrencyError <: CcyConvError
    message::String
    currency::Union{String,UInt64}
end

# Custom show method for better error messages
function Base.showerror(io::IO, e::UnknownCurrencyError)
    return print(io, "UnknownCurrencyError: ", e.message)
end

"""
    InvalidConversionError <: CcyConvError

Error thrown when a conversion is invalid.

## Fields
- `message::String`: Error description
- `from_asset::String`: Source currency
- `to_asset::String`: Target currency
- `details::Union{Nothing,String}`: Optional additional details
"""
struct InvalidConversionError <: CcyConvError
    message::String
    from_asset::String
    to_asset::String
    details::Union{Nothing,String}
end

function InvalidConversionError(msg::String, from::String, to::String)
    return InvalidConversionError(msg, from, to, nothing)
end

function Base.showerror(io::IO, e::InvalidConversionError)
    print(
        io,
        "InvalidConversionError: ",
        e.message,
        " (",
        e.from_asset,
        " -> ",
        e.to_asset,
        ")",
    )
    if !isnothing(e.details)
        print(io, "\nDetails: ", e.details)
    end
end

"""
    InvalidGraphError <: CcyConvError

Error thrown when graph operations are invalid.

## Fields
- `message::String`: Error description
- `details::Union{Nothing,Dict{Symbol,Any}}`: Optional additional context
"""
struct InvalidGraphError <: CcyConvError
    message::String
    details::Union{Nothing,Dict{Symbol,Any}}
end

InvalidGraphError(msg::String) = InvalidGraphError(msg, nothing)

function Base.showerror(io::IO, e::InvalidGraphError)
    print(io, "InvalidGraphError: ", e.message)
    if !isnothing(e.details)
        print(io, "\nDetails:")
        for (key, value) in e.details
            print(io, "\n  ", key, ": ", value)
        end
    end
end
