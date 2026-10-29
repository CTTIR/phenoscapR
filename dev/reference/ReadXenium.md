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
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMatrixCoords.md).

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
object.

## Examples

``` r
cells <- tempfile(fileext = ".csv")
write.csv(data.frame(cell_id = c("aaa-1", "aab-1", "aac-1"),
                     x_centroid = c(10.5, 42, 77.25), y_centroid = c(5, 18.5, 33)),
          cells, row.names = FALSE)
counts <- data.frame(cell_id = c("aac-1", "aaa-1", "aab-1"),
                     CD3E = c(0, 4, 1), MS4A1 = c(7, 0, 2))
obj <- ReadXenium(expression = counts, cells = cells)
obj
#> A SpatialCellData object
#>   3 cells across 1 sample
#>   Markers: CD3E, MS4A1 
#>   Normalised: FALSE 
#>   Project: Xenium 
unlink(cells)
```
