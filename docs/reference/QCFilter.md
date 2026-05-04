# Quality Control Filter (SpatialCellData)

Removes cells that fail quality control criteria based on cell area
and/or total marker intensity.

## Usage

``` r
QCFilter(
  object,
  min_area = NULL,
  max_area = NULL,
  min_intensity = 0,
  max_intensity = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- min_area:

  Numeric or `NULL`. Minimum cell area.

- max_area:

  Numeric or `NULL`. Maximum cell area.

- min_intensity:

  Numeric. Minimum total marker intensity. Default `0`.

- max_intensity:

  Numeric or `NULL`. Maximum total marker intensity.

## Value

A filtered
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
counts <- matrix(rnorm(60, 5), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20")))
coords <- data.frame(x = runif(20), y = runif(20))
meta <- data.frame(cell_id = 1:20, sample_id = "s1",
                   cell_area = c(5, seq(50, 200, length.out = 18), 5000))
obj <- CreateSpatialObject(counts, coords, meta)
filtered <- QCFilter(obj, min_area = 10, max_area = 1000)
NCells(filtered)
#> [1] 18
```
