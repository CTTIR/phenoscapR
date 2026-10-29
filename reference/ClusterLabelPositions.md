# Label Positions of Clusters on an Embedding

The median position of the points of each cluster with at least
`min_points` points, for numbering clusters on the embedding.

## Usage

``` r
ClusterLabelPositions(
  data,
  x = "x",
  y = "y",
  cluster = "cluster",
  filter = NULL,
  min_points = 150
)
```

## Arguments

- data:

  Data frame with coordinates and a cluster column.

- x, y, cluster:

  Column names.

- filter:

  Optional named list of columns and values selecting the points used.

- min_points:

  Smallest cluster that gets a label.

## Value

A data frame with `label`, `x`, `y` and `n`, ordered by cluster.

## Examples

``` r
d <- data.frame(x = c(1, 2, 3, 10), y = c(1, 1, 2, 5), cl = c(1, 1, 1, 2))
ClusterLabelPositions(d, cluster = "cl", min_points = 2)
#>   label x y n
#> 1     1 2 1 3
```
