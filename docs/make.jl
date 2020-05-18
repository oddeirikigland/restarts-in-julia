include("../src/Exceptional.jl")
using Documenter, .Exceptional

makedocs(sitename="Exceptional.jl Documentation", modules = [Exceptional])

deploydocs(
    repo = "github.com/oddeirikigland/Exceptional.jl.git",
)