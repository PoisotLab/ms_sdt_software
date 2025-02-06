using SpeciesDistributionToolkit
using CairoMakie
using Distributions
using Statistics

provider = RasterData(CHELSA2, BioClim)

layers = [convert(SDMLayer{Float64}, SDMLayer(provider; layer=l, extent...)) for l in ["BIO1", "BIO12", "BIO3"]]
layers = [mask!(l, place) for l in layers]

logistic(x, α, β) = 1 / (1 + exp((x-β)/α))
logistic(α, β) = (x) -> logistic(x, α, β)

fs = [logistic(rand(), rand()) for _ in eachindex(layers)]

r = prod([fs[i].(rescale(l)) for (i,l) in enumerate(layers)])
heatmap(r)

thr = LinRange(extrema(r)..., 100)
prv = [count(nodata(r .>= t, false))/count(r) for t in thr]
cutoff = thr[findmin(abs.(prv .- 0.4))[2]]
distr = r .>= cutoff
heatmap(distr, colormap=[:lightgrey, :forestgreen])
presencelayer = backgroundpoints(distr, 300)

# Pseudo-absences
background = pseudoabsencemask(DistanceToEvent, presencelayer)
bgpoints = backgroundpoints(nodata(background, d -> d < 4), 800)

# Check
f = Figure(; size = (600, 300))
ax = Axis(f[1, 1]; aspect = DataAspect())
hm = heatmap!(ax,
    first(layers);
    colormap = :linear_bgyw_20_98_c66_n256,
)
scatter!(ax, presencelayer; color = :black)
scatter!(ax, bgpoints; color = :red, markersize = 4)
lines!(ax, place.geometry[1]; color = :black)
Colorbar(f[1, 2], hm)
hidedecorations!(ax)
hidespines!(ax)
current_figure()

# Test
sdm = SDM(ZScore, DecisionTree, layers, presencelayer, bgpoints)
ensemble = Bagging(sdm, 30)
bagfeatures!(ensemble)
folds = kfold(sdm);
cv = crossvalidate(sdm, folds; threshold = true);
mean(mcc.(cv.validation))

train!(ensemble)
prd = predict(ensemble, layers; threshold = true)
heatmap(distr, colormap=[:lightgrey, :forestgreen])
contour!(prd, color=:red)
lines!(place.geometry[1]; color = :black)
current_figure()
