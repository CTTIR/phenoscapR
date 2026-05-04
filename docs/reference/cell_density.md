# Compute Cell Density

Estimates the local cell density around each cell using a circular
neighbourhood of a given radius.

## Usage

``` r
cell_density(dt, radius, target_phenotype = NULL)
```

## Arguments

- dt:

  A `data.table` with columns `x` and `y`.

- radius:

  Numeric. Radius of the neighbourhood (in coordinate units).

- target_phenotype:

  Character string or `NULL`. If provided, only cells of this phenotype
  are counted in the neighbourhood.

## Value

The input `data.table` with an added `density` column representing the
number of neighbours within the specified radius.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:50,
  x = runif(50, 0, 100), y = runif(50, 0, 100)
)
result <- cell_density(dt, radius = 20)
head(result[, .(cell_id, density)])
#>    cell_id density
#>      <int>   <num>
#> 1:       1       6
#> 2:       2       3
#> 3:       3       7
#> 4:       4       6
#> 5:       5       1
#> 6:       6       4
```
