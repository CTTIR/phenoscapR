# Read 10x Xenium Cell Output

Convenience wrapper for Xenium: a `cells` table with
`x_centroid`/`y_centroid` coordinates plus a cell-by-gene `expression`
matrix (load the feature matrix yourself, e.g. via Matrix, and pass it
here).

## Usage

``` r
ReadXenium(expression, cells, sample_id = "sample1", project = "Xenium")
```

## Arguments

- expression:

  Cells-by-genes matrix / data frame / CSV path.

- cells:

  The Xenium `cells.csv(.gz)` metadata (path or data frame).

- sample_id, project:

  Passed to
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/reference/ReadMatrixCoords.md).

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
obj <- ReadXenium(expression = counts_matrix, cells = "cells.csv.gz")
} # }
```
