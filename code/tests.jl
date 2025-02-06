using SpeciesDistributionToolkit
using CairoMakie

place = SpeciesDistributionToolkit.gadm("ARG")

tx = taxon("Hydrochoerus hydrochaeris")
occ = occurrences(tx, "country" => "ARG", "occurrenceStatus" => "PRESENCE", "hasCoordinate" => true, "limit" => 300)

provider = RasterData{CHELSA2, BioClim}

temp = SDMLayer(provider; layer=1, SpeciesDistributionToolkit.bbox(place)...)

# Initial map
f = Figure()
ax = Axis(f[1,1])
heatmap!(ax, temp, color=:matter)
scatter!(ax, occ, color=:white, strokecolor=:black, strokewidth=4)
f

