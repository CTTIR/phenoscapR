# Neighbourhood Enrichment Analysis

Tests whether specific phenotype pairs are spatially enriched or
depleted relative to a random permutation baseline. Phenotype labels are
permuted over the fixed neighbour graph; the z-score compares the
observed pair count with the mean and standard deviation of the permuted
counts, and the p-value is the two-sided normal approximation of that
z-score (it is not a permutation tail probability).

## Usage

``` r
NeighbourhoodEnrichment(
  object,
  radius,
  n_perm = 100L,
  seed = NULL,
  by_sample = FALSE
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object. Every cell needs a complete, nonblank `phenotype` label.

- radius:

  Numeric. Neighbourhood radius: one finite nonnegative number in
  coordinate units.

- n_perm:

  Integer. Number of permutations, at least `2` (the permutation
  standard deviation is undefined otherwise). Default `100`.

- seed:

  Integer or `NULL`. Random seed.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list. Default `FALSE`;
  otherwise a single sample is required.

## Value

A data frame with columns `from`, `to`, `observed`, `mean_expected`,
`z_score`, and `p_value`. When the permuted counts of a pair do not
vary, the z-score and p-value are `0` and `1` if the observed count
equals the permuted count and `NA` otherwise, as for
`InteractionMatrix(method = "permutation")`.

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
#> <phenoscapR> Neighbourhood enrichment (label permutation)
#>   z-scores against permuted labels; p-values from the normal approximation
#>   top co-localised pairs (by z-score):
#>  from to    z_score   p_value
#>     B  B  0.5196665 0.6032960
#>     B  A  0.1268387 0.8990681
#>     A  B  0.1268387 0.8990681
#>     A  A -0.9977852 0.3183835
```
