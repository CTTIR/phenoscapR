# Spatial Cell Clustering

Clusters cells based on their spatial coordinates using k-means or
hierarchical clustering. All rows are clustered together, whatever their
`sample_id`: cluster one sample at a time when samples have separate
coordinate frames. k-means starts from random centres, so call
[`set.seed()`](https://rdrr.io/r/base/Random.html) first for
reproducible labels.

## Usage

``` r
spatial_clusters(dt, k, method = c("kmeans", "hierarchical"))
```

## Arguments

- dt:

  A `data.table` with finite numeric columns `x` and `y`.

- k:

  Integer. Number of clusters, between 1 and the number of cells;
  k-means needs fewer clusters than cells.

- method:

  Character string. Clustering method: `"kmeans"` (default) or
  `"hierarchical"`.

## Value

The input `data.table` with an added `cluster` column.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:50,
  x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
  y = c(rnorm(25, 0, 5), rnorm(25, 50, 5))
)
result <- spatial_clusters(dt, k = 2)
table(result$cluster)
#> 
#>  1  2 
#> 25 25 
```
