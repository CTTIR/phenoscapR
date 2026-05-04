# Phenotype Summary (SpatialCellData)

Computes phenotype counts and proportions per sample.

## Usage

``` r
PhenotypeSummary(object)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

A data frame with columns `sample_id`, `phenotype`, `count`, and
`proportion`.

## Examples

``` r
counts <- matrix(c(rnorm(15, 5), rnorm(15, 1)), ncol = 2,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(15), y = runif(15))
obj <- CreateSpatialObject(counts, coords)
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 3, CD8 = 3))
PhenotypeSummary(obj)
#>   sample_id phenotype count proportion
#> 1   sample1      CD3+    15          1
```
