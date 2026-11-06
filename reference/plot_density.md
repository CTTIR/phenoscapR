# Plot Density Map

Creates a scatter plot with point size or colour scaled by local cell
density.

## Usage

``` r
plot_density(dt, point_size = 1, title = NULL, y_down = TRUE)
```

## Arguments

- dt:

  A `data.table` with columns `x`, `y`, and `density` (as returned by
  [`cell_density()`](https://cttir.github.io/phenoscapR/reference/cell_density.md)).

- point_size:

  Numeric. Base point size. Default `1`.

- title:

  Character string or `NULL`. Plot title.

- y_down:

  Logical. If `TRUE` (default), y increases downward, as in image
  coordinates (origin at the top left; QuPath, cellspecR), so the map
  has the orientation of the tissue image. Use `FALSE` for coordinates
  whose y axis points up.

## Value

A `ggplot` object.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:50,
  x = runif(50, 0, 100), y = runif(50, 0, 100),
  density = rpois(50, 5)
)
plot_density(dt)

```
