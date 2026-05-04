# Neighbourhood Enrichment Analysis

Tests whether specific phenotype pairs are spatially enriched or
depleted relative to a random permutation baseline.

## Usage

``` r
NeighbourhoodEnrichment(object, radius, n_perm = 100L, seed = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- radius:

  Numeric. Neighbourhood radius.

- n_perm:

  Integer. Number of permutations. Default `100`.

- seed:

  Integer or `NULL`. Random seed.

## Value

A data frame with columns `from`, `to`, `observed`, `mean_expected`,
`z_score`, and `p_value`.

## Examples

``` r
set.seed(1)
counts <- matrix(rnorm(200), nrow = 100,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
meta <- data.frame(cell_id = 1:100, sample_id = "s1",
  phenotype = sample(c("A", "B"), 100, replace = TRUE))
obj <- CreateSpatialObject(counts, coords, meta)
NeighbourhoodEnrichment(obj, radius = 50, n_perm = 10)
#>   from to observed mean_expected    z_score   p_value
#> 1    A  A       58          68.0 -0.9977852 0.3183835
#> 2    B  A       79          77.9  0.1268387 0.8990681
#> 3    A  B       79          77.9  0.1268387 0.8990681
#> 4    B  B       92          84.2  0.5196665 0.6032960
```
