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
  `Image` column, the scan identity is parsed automatically.

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
#>           sample_id cell_id         x        y cell_area     DAPI      CD3
#>              <char>   <int>     <num>    <num>     <num>    <num>    <num>
#> 1: file24eb65a5b0cb       1 547.88770  31.0337  174.3390 583.8669 380.0891
#> 2: file24eb65a5b0cb       2 304.46452 652.2918  141.1577 434.5385 359.7962
#> 3: file24eb65a5b0cb       3 402.30483 596.8411   70.7169 595.3961 249.8740
#> 4: file24eb65a5b0cb       4  27.59579 312.6110  180.6391 535.2951 331.6179
#> 5: file24eb65a5b0cb       5 848.99369 986.9101  136.5632 520.6599 228.6266
unlink(tmp)
```
