# Read Akoya / QuPath Cell Segmentation Data

Reads cell segmentation CSV files produced by Akoya Biosciences
platforms (PhenoCycler, CODEX, PhenoImager) or QuPath. The function
auto-detects the column naming convention, delimiter, and BOM encoding.

## Usage

``` r
read_akoya(
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

  Cell centroid x-coordinate (micrometres for QuPath data).

- y:

  Cell centroid y-coordinate.

- cell_area:

  Cell area (if available).

- classification:

  QuPath classification label (if available).

Additional columns contain marker intensities (one per marker).

## Details

Three input formats are supported:

- QuPath Full:

  Contains `Object ID`, `Classification`, multi-compartment marker
  intensities (Compartment: Marker statistic).

- QuPath Minimal:

  Contains only spatial coordinates and Marker: Cell: Mean columns.

- Akoya Processor:

  Contains `Cell ID`, `Cell X Position`, `Cell Y Position`, and flat
  marker columns.

## Examples

``` r
# Akoya Processor format
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
dat <- read_akoya(tmp)
head(dat)
#>           sample_id cell_id        x         y cell_area     DAPI      CD3
#>              <char>   <int>    <num>     <num>     <num>    <num>    <num>
#> 1: file1ea946e80771       1 285.3411 816.47967  90.91971 365.2602 322.7216
#> 2: file1ea946e80771       2 340.3826 261.72111  80.41825 438.7820 243.4289
#> 3: file1ea946e80771       3 903.0621 584.18732  81.42481 547.5163 307.9512
#> 4: file1ea946e80771       4 877.5798  20.90613  67.53394 448.3067 320.8873
#> 5: file1ea946e80771       5 424.5403 396.09819  90.79981 570.3279 242.4990
unlink(tmp)
```
