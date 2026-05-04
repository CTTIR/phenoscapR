# Phenotype Cells (SpatialCellData)

Assigns phenotype labels to cells based on marker intensity thresholds.
Uses the normalised `data` slot.

## Usage

``` r
PhenotypeCells(object, thresholds, labels = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- thresholds:

  Named list of thresholds (marker name = value).

- labels:

  Named character vector mapping signatures to labels, or `NULL` for
  automatic labelling.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with a `phenotype` column in `meta_data`.

## Examples

``` r
counts <- matrix(c(rnorm(10, 5), rnorm(10, 1)), ncol = 2,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateSpatialObject(counts, coords)
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 3, CD8 = 3))
table(Meta(obj)$phenotype)
#> 
#> CD3+ 
#>   10 
```
