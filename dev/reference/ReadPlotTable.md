# Read a Plot Data Table

Reads a tab-separated (optionally gzipped), comma-separated or RDS table
as a plain data frame with the column names unchanged, using one thread.
Empty strings and `NA` are missing values.

## Usage

``` r
ReadPlotTable(path)
```

## Arguments

- path:

  File path.

## Value

A data frame (or the RDS object).

## Examples

``` r
f <- tempfile(fileext = ".tsv")
writeLines(c("patient\tvalue", "p1\t2.5"), f)
ReadPlotTable(f)
#>   patient value
#> 1      p1   2.5
```
