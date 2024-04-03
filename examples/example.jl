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
conv_a_star(crypto, "ADA", "USDT") |> conv_safe_value

# Convert ADA to BTC
conv_a_star(crypto, "ADA", "BTC") |> conv_value

# Convert ADA to ETH through BTC
conv_a_star(crypto, "ADA", "ETH") |> conv_value

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
conv_a_star(crypto, "ADA", "USDT")

# Convert ADA to BTC
conv_a_star(crypto, "ADA", "BTC")

# Convert ADA to ETH through BTC
conv_a_star(crypto, "ADA", "ETH")

#__

using CcyConv
using CryptoAPIs

struct MyCtx <: CcyConv.AbstractCtx
    prices::Dict{String,Float64}

    MyCtx() = new(Dict{String,Float64}())
end

struct ExSymbol <: CcyConv.AbstractPrice
    base_asset::String
    quote_asset::String
    symbol::String
end

function CcyConv.from_asset(x::ExSymbol)::String
    return x.base_asset
end

function CcyConv.to_asset(x::ExSymbol)::String
    return x.quote_asset
end

function CcyConv.price(ctx::MyCtx, x::ExSymbol)::Float64
    return get!(ctx.prices, x.symbol) do
        return try
            CryptoAPIs.Binance.Spot.avg_price(; symbol = x.symbol).result.price
        catch
            NaN
        end
    end
end

my_graph = FXGraph()
my_ctx = MyCtx()

push!(my_graph, ExSymbol("ADA", "BTC", "ADABTC"))
push!(my_graph, ExSymbol("BTC", "USDT", "BTCUSDT"))
push!(my_graph, ExSymbol("PEPE", "USDT", "PEPEUSDT"))
push!(my_graph, ExSymbol("EOS", "USDT", "EOSUSDT"))

@time my_graph(my_ctx, CcyConv.a_star_alg, "ADA", "EOS")
