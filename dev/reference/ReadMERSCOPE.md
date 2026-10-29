# Read Vizgen MERSCOPE Cell Output

Convenience wrapper for MERSCOPE: `cell_by_gene.csv` (cell-by-gene,
first column the cell id) and `cell_metadata.csv` (with
`center_x`/`center_y`).

## Usage

``` r
ReadMERSCOPE(
  matrix_file,
  metadata_file,
  sample_id = "sample1",
  project = "MERSCOPE"
)
```

## Arguments

- matrix_file:

  Path/data frame of the cell-by-gene matrix.

- metadata_file:

  Path/data frame of the cell metadata.

- sample_id, project:

  Passed to
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMatrixCoords.md).

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
object.

## Examples

``` r
matrix_file <- tempfile(fileext = ".csv")
metadata_file <- tempfile(fileext = ".csv")
write.csv(data.frame(cell = c(101, 102, 103), CD3E = c(2, 0, 6), PTPRC = c(5, 1, 8)),
          matrix_file, row.names = FALSE)
write.csv(data.frame(cell = c(103, 101, 102), center_x = c(15, 210, 88),
                     center_y = c(40, 12, 160)),
          metadata_file, row.names = FALSE)
obj <- ReadMERSCOPE(matrix_file, metadata_file)
obj
#> A SpatialCellData object
#>   3 cells across 1 sample
#>   Markers: CD3E, PTPRC 
#>   Normalised: FALSE 
#>   Project: MERSCOPE 
unlink(c(matrix_file, metadata_file))
```
