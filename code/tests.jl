using SpeciesDistributionToolkit
using CairoMakie

place = SpeciesDistributionToolkit.gadm("ARG")

tx = taxon("Hydrochoerus hydrochaeris")
occ = occurrences(tx, "country" => "AR", "occurrenceStatus" => "PRESENT", "hasCoordinate" => true, "limit" => 300)

provider = RasterData(CHELSA2, BioClim)

temp = SDMLayer(provider; layer="BIO1", SpeciesDistributionToolkit.boundingbox(place)...)

# Initial map
f = Figure()
ax = Axis(f[1, 1])
heatmap!(ax, temp, color=:matter)
scatter!(ax, occ, color=:white, strokecolor=:black, strokewidth=4)
f

