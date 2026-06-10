# Advanced Spatial Analysis

![phenoscapR hex logo](../reference/figures/logo.svg)

## Overview

phenoscapR provides a rich set of spatial statistics beyond basic
nearest neighbours and density estimation. This vignette demonstrates:

- **Neighbourhood Enrichment** — permutation test for phenotype
  co-localisation
- **Ripley’s K** — global clustering / dispersion measure
- **Moran’s I** — spatial autocorrelation of a continuous variable
- **Quadrat Analysis** — complete spatial randomness test
- **Pair Correlation Function** — scale-dependent g(r)
- **Cross Nearest-Neighbour Distance** — inter-phenotype proximity
- **Delaunay Network** — cell contact graph
- **Expression Clustering** — marker-expression-based cell clusters

## Setup: Simulated Tissue Data

``` r

library(phenoscapR)

set.seed(42)
n <- 600

# Two spatially segregated populations
coords <- data.frame(
  x = c(rnorm(300, 250, 80), rnorm(300, 750, 80)),
  y = c(rnorm(300, 400, 80), rnorm(300, 400, 80))
)

counts <- matrix(
  c(
    c(rnorm(300, 900, 150), rnorm(300, 200, 100)),  # CD3 high in pop 1
    c(rnorm(300, 200, 100), rnorm(300, 800, 130)),  # CD8 high in pop 2
    abs(rnorm(600, 600, 150)),                       # PanCK background
    abs(rnorm(600, 400, 100))                        # DAPI
  ),
  nrow = n,
  dimnames = list(NULL, c("CD3", "CD8", "PanCK", "DAPI"))
)

obj <- CreateSpatialObject(counts, coords, project = "spatial-demo")
obj <- NormaliseData(obj, method = "zscore")
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0,
                                              PanCK = 0, DAPI = -99))
table(Idents(obj))
#> 
#> CD3+/CD8+/PanCK+/DAPI+             CD3+/DAPI+      CD3+/PanCK+/DAPI+ 
#>                      1                    126                    170 
#>             CD8+/DAPI+      CD8+/PanCK+/DAPI+                  DAPI+ 
#>                    159                    137                      4 
#>           PanCK+/DAPI+ 
#>                      3
```

## Neighbourhood Enrichment

Tests whether phenotype pairs co-localise more (or less) than expected
by random chance using a permutation approach:

``` r

# Run with n_perm = 100 or more for reliable p-values
ne <- NeighbourhoodEnrichment(obj, radius = 80, n_perm = 20)
ne
```

## Ripley’s K

Assesses global spatial clustering across a range of radii. Values above
the theoretical CSR line indicate clustering:

``` r

rk <- RipleysK(obj)
rk
```

## Moran’s I

Quantifies the spatial autocorrelation of a continuous variable (e.g. a
marker intensity). Values near +1 indicate strong spatial clustering of
high/low values; values near −1 indicate regular spatial dispersion:

``` r

mi <- MoransI(obj, feature = "CD3", radius = 100)
mi
```

## Quadrat Analysis

Divides the tissue into a regular grid and tests for Complete Spatial
Randomness (CSR) using a chi-squared test. Significant results indicate
non-random spatial distribution:

``` r

qa <- QuadratAnalysis(obj, nx = 4, ny = 4)
qa
```

## Pair Correlation Function

The pair correlation function g(r) is the derivative of Ripley’s K and
measures clustering or inhibition at a specific distance r. g(r) \> 1
indicates clustering; g(r) \< 1 indicates inhibition:

``` r

pcf <- PairCorrelation(obj)
pcf
```

## Cross Nearest-Neighbour Distance

Measures the distance from each cell of phenotype A to the nearest cell
of phenotype B, providing a directed measure of inter-phenotype
proximity:

``` r

cn <- CrossNNDistance(obj, from = "CD3+CD8-", to = "CD3-CD8+")
summary(cn$cross_nn_distance)
```

## Delaunay Triangulation Network

Constructs a cell contact graph based on Delaunay triangulation. Useful
for cell-cell interaction analyses:

``` r

obj <- DelaunayNetwork(obj)
SpatialNetworkPlot(obj)
```

## Expression Clustering

Cluster cells by their normalised marker expression profiles (k-means or
hierarchical). Useful for discovering marker co-expression communities
independently of spatial position:

``` r

obj <- ExpressionClusters(obj, k = 4)
table(obj$expr_cluster)
CellMap(obj, colour_by = "expr_cluster")
```

## Summary

| Function | What it tests | Key parameter |
|----|----|----|
| [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/reference/NeighbourhoodEnrichment.md) | Co-localisation vs random | `radius`, `n_perm` |
| [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md) | Global clustering at multiple radii | `r_max`, `n_r` |
| [`MoransI()`](https://cttir.github.io/phenoscapR/reference/MoransI.md) | Spatial autocorrelation of a feature | `feature`, `radius` |
| [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/reference/QuadratAnalysis.md) | CSR via chi-squared | `nx`, `ny` |
| [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md) | Scale-dependent g(r) | `r_max`, `n_r` |
| [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/reference/CrossNNDistance.md) | Inter-phenotype proximity | `from`, `to` |
| [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/reference/DelaunayNetwork.md) | Cell contact graph | — |
| [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/reference/ExpressionClusters.md) | Marker expression communities | `k`, `method` |

## Next Steps

- See
  [`?NeighbourhoodEnrichment`](https://cttir.github.io/phenoscapR/reference/NeighbourhoodEnrichment.md),
  [`?RipleysK`](https://cttir.github.io/phenoscapR/reference/RipleysK.md),
  etc. for full parameter documentation.
- Combine spatial statistics with
  [`InteractionMatrix()`](https://cttir.github.io/phenoscapR/reference/InteractionMatrix.md)
  and
  [`InteractionPlot()`](https://cttir.github.io/phenoscapR/reference/InteractionPlot.md)
  for a complete co-localisation picture.
