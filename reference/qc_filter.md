# Quality Control Filter

Removes cells that fail quality control criteria based on marker
intensity ranges, cell area, or custom filters.

## Usage

``` r
qc_filter(
  dt,
  min_area = NULL,
  max_area = NULL,
  min_intensity = 0,
  max_intensity = NULL
)
```

## Arguments

- dt:

  A `data.table` as returned by
  [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md).

- min_area:

  Numeric or `NULL`. Minimum cell area. Cells below this threshold are
  removed.

- max_area:

  Numeric or `NULL`. Maximum cell area. Cells above this threshold are
  removed.

- min_intensity:

  Numeric. Minimum total marker intensity. Cells with total intensity
  below this value are removed. Default `0`.

- max_intensity:

  Numeric or `NULL`. Maximum total marker intensity.

## Value

A filtered `data.table`.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:10,
  x = runif(10), y = runif(10),
  cell_area = c(5, seq(50, 200, length.out = 8), 5000),
  CD3 = rnorm(10, 300, 50)
)
filtered <- qc_filter(dt, min_area = 10, max_area = 1000)
nrow(filtered)
#> [1] 8
```
