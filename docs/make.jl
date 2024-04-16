using CcyConv
using Documenter
using DocumenterMermaid

DocMeta.setdocmeta!(CcyConv, :DocTestSetup, :(using CcyConv); recursive = true)

makedocs(;
    modules = [CcyConv],
    sitename = "CcyConv.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/bhftbootcamp/CcyConv.jl",
        canonical = "https://bhftbootcamp.github.io/CcyConv.jl",
        edit_link = "master",
        assets = String["assets/favicon.ico"],
        sidebar_sitename = true,
    ),
    pages = [
        "Home" => "index.md",
        "pages/manual.md",
        "pages/api_reference.md",
    ],
    warnonly = [:doctest, :missing_docs],
)

deploydocs(;
    repo = "github.com/bhftbootcamp/CcyConv.jl",
    devbranch = "master",
    push_preview = true,
)
