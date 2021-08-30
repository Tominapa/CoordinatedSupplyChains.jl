using Documenter, CoordinatedSupplyChains

makedocs(sitename="CoordinatedSupplyChains.jl Documentation",
	pages = [
        	"Home" => "index.md",
        	"Tutorials" => "tutorial.md"
        	]
)

deploydocs(
    repo = "github.com/Tominapa/CoordinatedSupplyChains.jl.git",
)