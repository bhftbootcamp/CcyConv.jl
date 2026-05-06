# example

using CcyConv

# Create a new graph
crypto = FXGraph()

# Add exchange rates
push!(crypto, Price("ADA", "USDT", 0.4037))
push!(crypto, Price("USDT", "BTC", 2.373717628722553e-5))
push!(crypto, Price("BTC", "ETH", 18.80891065680265))
push!(crypto, Price("ETH", "ALGO", 14735.46052631579))

# Convert ADA to USDT
conv(crypto, "ADA", "USDT") |> conv_safe_value

# Convert ADA to BTC
conv(crypto, "ADA", "BTC") |> conv_value

# Convert ADA to ETH through BTC
conv(crypto, "ADA", "ETH") |> conv_value

#__

using CcyConv

# Create a new graph
crypto = FXGraph()

# Custom Price
struct MyPrice <: CcyConv.AbstractPrice
    exchange::String
    from_asset::String
    to_asset::String
    price::Float64
end

CcyConv.from_asset(x::MyPrice) = x.from_asset
CcyConv.to_asset(x::MyPrice) = x.to_asset
CcyConv.price(x::MyPrice) = x.price

# Add exchange rates
push!(crypto, MyPrice("Binance", "ADA", "USDT", 0.4037))
push!(crypto, MyPrice("Huobi", "USDT", "BTC", 2.373717628722553e-5))
push!(crypto, MyPrice("Okex", "BTC", "ETH", 18.80891065680265))
push!(crypto, MyPrice("Gateio", "ETH", "ALGO", 14735.46052631579))

# Convert ADA to USDT
conv(crypto, "ADA", "USDT")

# Convert ADA to BTC
conv(crypto, "ADA", "BTC")

# Convert ADA to ETH through BTC
conv(crypto, "ADA", "ETH")

#__

using CcyConv
using EasyCurl
using Serde

struct BinanceCtx <: CcyConv.AbstractCtx
    prices::Dict{String,Float64}

    BinanceCtx() = new(Dict{String,Float64}())
end

struct BinancePair <: CcyConv.AbstractPrice
    base_asset::String
    quote_asset::String
    symbol::String
end

CcyConv.from_asset(x::BinancePair) = x.base_asset
CcyConv.to_asset(x::BinancePair) = x.quote_asset

function CcyConv.price(ctx::BinanceCtx, x::BinancePair)::Float64
    return get!(ctx.prices, x.symbol) do
        try
            resp = http_get("https://api.binance.com/api/v3/avgPrice?symbol=$(x.symbol)")
            data = Serde.parse_json(http_body(resp))
            parse(Float64, data["price"])
        catch
            NaN
        end
    end
end

fx = FXGraph()
ctx = BinanceCtx()

push!(fx, BinancePair("ADA", "BTC", "ADABTC"))
push!(fx, BinancePair("BTC", "USDT", "BTCUSDT"))
push!(fx, BinancePair("PEPE", "USDT", "PEPEUSDT"))
push!(fx, BinancePair("EOS", "USDT", "EOSUSDT"))

@time conv(fx, "ADA", "EOS"; ctx = ctx)
