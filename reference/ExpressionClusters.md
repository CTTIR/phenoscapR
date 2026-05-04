# Expression-Based Cell Clustering

Clusters cells based on marker expression profiles.

## Usage

``` r
ExpressionClusters(
  object,
  k,
  method = c("kmeans", "hierarchical"),
  slot = "data",
  markers = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- k:

  Integer. Number of clusters.

- method:

  Character. `"kmeans"` (default) or `"hierarchical"`.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`. Markers to use.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with an `expr_cluster` column in `meta_data`.

## Examples

``` r
counts <- matrix(c(rnorm(50, 10), rnorm(50, 0)), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50), y = runif(50))
obj <- CreateSpatialObject(counts, coords)
obj <- ExpressionClusters(obj, k = 2)
table(Meta(obj)$expr_cluster)
#> 
#>  1  2 
#> 25 25 
```
