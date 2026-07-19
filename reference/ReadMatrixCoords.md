# Read an Expression Matrix and a Coordinate/Metadata Table

General-purpose reader for the common spatial layout of one
cell-by-feature expression table plus one cell-metadata table holding
coordinates. Each argument may be a file path (read with
[`data.table::fread`](https://rdrr.io/pkg/data.table/man/fread.html)), a
matrix, or a data frame.

## Usage

``` r
ReadMatrixCoords(
  expression,
  metadata,
  x_col = "x",
  y_col = "y",
  cell_id_col = NULL,
  id_cols = character(0),
  sample_id = "sample1",
  transpose = FALSE,
  project = "SpatialProject"
)
```

## Arguments

- expression:

  Cells-by-markers expression (matrix, data frame, or CSV path).
  Non-numeric and `id_cols` columns are dropped.

- metadata:

  Cell metadata containing the coordinate columns (data frame or CSV
  path).

- x_col, y_col:

  Character. Coordinate column names in `metadata`.

- cell_id_col:

  Character or `NULL`. Shared cell-id column; if present in both tables,
  rows are matched on it, otherwise row order is assumed.

- id_cols:

  Character vector. Non-marker id columns to drop from `expression`
  (e.g. `"fov"`, `"cell_ID"`).

- sample_id:

  Character. Sample identifier. Default `"sample1"`.

- transpose:

  Logical. Set `TRUE` if `expression` is markers-by-cells. Default
  `FALSE`.

- project:

  Character. Project name.

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
expr <- matrix(rpois(40, 5), nrow = 10,
               dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
meta <- data.frame(x = runif(10, 0, 100), y = runif(10, 0, 100))
obj <- ReadMatrixCoords(expr, meta)
obj
#> A SpatialCellData object
#>   10 cells across 1 sample
#>   Markers: CD3, CD8, CD20, PanCK 
#>   Normalised: FALSE 
#>   Project: SpatialProject 
```
