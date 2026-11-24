# Read Single-Cell Spatial Biology Data

Reads cell segmentation CSV files from spatial biology imaging platforms
or image analysis software. The function auto-detects the column naming
convention, delimiter, and BOM encoding.

## Usage

``` r
read_spatial(
  path,
  sample_id = NULL,
  markers = NULL,
  compartment = "Cell",
  statistic = "mean",
  sep = "auto"
)
```

## Arguments

- path:

  Character string. Path to a CSV file or a directory containing CSV
  files. When a directory is given, all `.csv` files are read and
  combined.

- sample_id:

  Character string or `NULL`. An identifier appended to each row. When
  `path` is a directory and `sample_id` is `NULL`, the file name
  (without extension) is used. For QuPath full-format files with an
  `Image` column, the scan identity is parsed automatically. This
  argument fills absent or blank identities; it does not overwrite a
  nonblank QuPath Image-derived identity. The original Image label is
  retained as `source_image`. Distinct Image labels that collapse to the
  same parsed identity are refused, including across files. Reserved
  cell/sample/Image identifier columns are read as text, retaining
  leading zeros; measurement and coordinate columns retain numeric
  inference.

- markers:

  Character vector or `NULL`. If provided, only these marker columns are
  retained. Matching is case-insensitive.

- compartment:

  Character. For QuPath full-format data, which compartment to extract
  intensities from. One of `"Cell"` (default), `"Nucleus"`, or
  `"Cytoplasm"`.

- statistic:

  Character. For QuPath full-format data, which summary statistic to
  extract. One of `"mean"` (default), `"sum"`, `"std dev"`, `"max"`,
  `"min"`, or `"range"`.

- sep:

  Character or `"auto"`. Column delimiter. Default `"auto"` detects
  comma vs. semicolon from the first line.

## Value

A `data.table` with standardised column names:

- sample_id:

  Sample identifier.

- cell_id:

  Unique cell identifier (per sample).

- x:

  Cell centroid x-coordinate.

- y:

  Cell centroid y-coordinate.

- cell_area:

  Cell area (if available).

- classification:

  Cell classification label (if available).

- source_image:

  Original QuPath Image label, when supplied.

Additional columns contain marker intensities (one per marker).

## Details

Three input formats are supported:

- QuPath Full:

  Contains `Object ID`, `Classification`, multi-compartment marker
  intensities (Compartment: Marker statistic).

- QuPath Minimal:

  Contains only spatial coordinates and Marker: Cell: Mean columns.

- Flat Format:

  Contains `Cell ID`, `Cell X Position`, `Cell Y Position`, and flat
  marker intensity columns.

## Examples

``` r
tmp <- tempfile(fileext = ".csv")
write.csv(data.frame(
  `Cell ID` = 1:5,
  `Cell X Position` = runif(5, 0, 1000),
  `Cell Y Position` = runif(5, 0, 1000),
  `Cell Area (px)` = runif(5, 50, 200),
  DAPI = rnorm(5, 500, 100),
  CD3 = rnorm(5, 300, 80),
  check.names = FALSE
), tmp, row.names = FALSE)
dat <- read_spatial(tmp)
head(dat)
#>          sample_id cell_id          x         y cell_area     DAPI      CD3
#>             <char>  <char>      <num>     <num>     <num>    <num>    <num>
#> 1: file215b3d87758       1 871.230944 767.45085  54.99984 485.1860 316.3510
#> 2: file215b3d87758       2 655.788006  33.28786 104.92274 402.8434 303.7254
#> 3: file215b3d87758       3 219.371878 774.95206  81.15327 461.0861 227.3405
#> 4: file215b3d87758       4   9.437143 393.95963 194.88688 373.6344 282.5053
#> 5: file215b3d87758       5  79.214495 784.81726 134.74490 372.1734 287.5764
unlink(tmp)
```
