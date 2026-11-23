# Spatial Clusters (SpatialCellData)

Clusters cells based on spatial coordinates. The cells of all samples
are clustered together: subset to one sample first when samples have
separate coordinate frames. k-means starts from random centres, so call
[`set.seed()`](https://rdrr.io/r/base/Random.html) first for
reproducible labels.

## Usage

``` r
SpatialClusters(object, k, method = c("kmeans", "hierarchical"))
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- k:

  Integer. Number of clusters, between 1 and the number of cells;
  k-means needs fewer clusters than cells.

- method:

  Character. `"kmeans"` (default) or `"hierarchical"`.

## Value

An
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
with a `cluster` column in `meta_data`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(
  x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
  y = c(rnorm(25, 0, 5), rnorm(25, 50, 5)))
obj <- CreateSpatialObject(counts, coords)
obj <- SpatialClusters(obj, k = 2)
table(Meta(obj)$cluster)
#> 
#>  1  2 
#> 25 25 
```
