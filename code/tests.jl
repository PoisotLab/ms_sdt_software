using SpeciesDistributionToolkit
using CairoMakie

place = SpeciesDistributionToolkit.gadm("ARG")
extent = SpeciesDistributionToolkit.boundingbox(place)

tx = taxon("Hydrochoerus hydrochaeris")
occ = occurrences(tx, "country" => "AR", "occurrenceStatus" => "PRESENT", "hasCoordinate" => true, "limit" => 300)
occurrences!(occ)
occurrences!(occ)

provider = RasterData(WorldClim2, BioClim)

temp = SDMLayer(provider; layer="BIO1", extent...)
mask!(temp, place)

# Initial map
f = Figure()
ax = Axis(f[1, 1], aspect=DataAspect())
heatmap!(ax, temp, colormap=:thermal)
lines!(ax, place, color=:black)
scatter!(ax, mask(occ, place), color=:white, strokecolor=:black, strokewidth=2)
hidedecorations!(ax)
hidespines!(ax)
f

