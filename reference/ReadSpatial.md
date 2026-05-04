# Read Cell Segmentation Data into a SpatialCellData Object

Reads cell segmentation CSV files and returns a
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
object. This is the recommended high-level entry point.

## Usage

``` r
ReadSpatial(
  path,
  sample_id = NULL,
  markers = NULL,
  filter = "DAPI|Blank|Empty",
  compartment = "Cell",
  statistic = "mean",
  sep = "auto",
  project = "SpatialProject"
)
```

## Arguments

- path:

  Character. Path to a CSV file or a directory containing CSV files.

- sample_id:

  Character or `NULL`. An identifier for the sample.

- markers:

  Character vector or `NULL`. If provided, only these marker columns are
  retained.

- filter:

  Character or `NA`. Regex pattern for marker names to exclude. Default
  `"DAPI|Blank|Empty"`.

- compartment:

  Character. Compartment for intensity extraction (QuPath full format).
  Default `"Cell"`.

- statistic:

  Character. Summary statistic to extract (QuPath full format). Default
  `"mean"`.

- sep:

  Character or `"auto"`. Column delimiter. Default `"auto"`.

- project:

  Character. Project name. Default `"SpatialProject"`.

## Value

A
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
write.csv(data.frame(
  `Cell ID` = 1:5,
  `Cell X Position` = runif(5, 0, 1000),
  `Cell Y Position` = runif(5, 0, 1000),
  CD3 = rnorm(5, 300, 80),
  CD8 = rnorm(5, 200, 60),
  check.names = FALSE
), tmp, row.names = FALSE)
obj <- ReadSpatial(tmp, filter = NA)
obj
#> A SpatialCellData object
#>   5 cells across 1 sample
#>   Markers: CD3, CD8 
#>   Normalised: FALSE 
#>   Project: SpatialProject 
unlink(tmp)
```
