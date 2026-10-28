# Compute Nearest Neighbour Distances

For each cell, computes the distance to the nearest neighbouring cell,
optionally restricted to specific phenotypes.

## Usage

``` r
nearest_neighbours(dt, target_phenotype = NULL, k = 1L)
```

## Arguments

- dt:

  A `data.table` with columns `x` and `y`.

- target_phenotype:

  Character string or `NULL`. If provided, distances are computed only
  to cells of this phenotype. Requires a `phenotype` column.

- k:

  Integer. Number of nearest neighbours to consider. Default `1`.

## Value

The input `data.table` with an added `nn_distance` column (mean distance
to the `k` nearest neighbours).

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:20,
  x = runif(20, 0, 100), y = runif(20, 0, 100)
)
result <- nearest_neighbours(dt, k = 3)
head(result[, .(cell_id, nn_distance)])
#>    cell_id nn_distance
#>      <int>       <num>
#> 1:       1   12.937976
#> 2:       2   11.203918
#> 3:       3   13.765183
#> 4:       4   20.192255
#> 5:       5   14.425834
#> 6:       6    7.784847
```
