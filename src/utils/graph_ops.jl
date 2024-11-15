"""
    get_currency(fx::FXGraph, id::UInt64)::String

Get currency name from node ID.
"""
function get_currency(fx::FXGraph, id::UInt64)::String
    for (currency, node_id) in fx.edge_encode
        if node_id == id
            return currency
        end
    end
    throw(UnknownCurrencyError("Currency not found", id))
end

"""
    get_currency_id(fx::FXGraph, currency::String)::UInt64

Get node ID from currency name.
"""
function get_currency_id(fx::FXGraph, currency::String)::UInt64
    get(fx.edge_encode, currency) do
        throw(UnknownCurrencyError("Currency not found", currency))
    end
end