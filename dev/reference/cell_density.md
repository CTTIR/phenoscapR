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
#>      <int>   <int>
#> 1:       1       5
#> 2:       2       7
#> 3:       3       5
#> 4:       4       7
#> 5:       5       2
#> 6:       6       7
```
