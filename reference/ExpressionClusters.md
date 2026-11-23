# Expression-Based Cell Clustering

Clusters cells based on marker expression profiles. k-means and Gaussian
mixtures start from random or data-dependent initial values, so call
[`set.seed()`](https://rdrr.io/r/base/Random.html) first for
reproducible labels.

## Usage

``` r
ExpressionClusters(
  object,
  k,
  method = c("kmeans", "hierarchical", "gmm"),
  slot = "data",
  markers = NULL
)
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

  Character. `"kmeans"` (default), `"hierarchical"` (Ward linkage on
  Euclidean distances) or `"gmm"` (a Gaussian mixture with `k`
  components; requires the mclust package).

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`. Markers to use. Names not found in the
  object are ignored with a warning. For `"kmeans"` and `"gmm"` the
  selected values must not contain missing intensities. `"hierarchical"`
  accepts them as long as every pair of cells shares at least one
  measured marker: [`dist()`](https://rdrr.io/r/stats/dist.html) then
  leaves out the markers missing in either cell and rescales the sum to
  the number of markers, so the dissimilarities are only approximately
  Euclidean and the Ward clusters of incomplete data should be read with
  that in mind.

## Value

An
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
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
#> 31 19 
```
