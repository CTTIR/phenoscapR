# Bind Plot Data Tables

`PlotDataBindRows()` stacks tables by column name, filling columns
missing from some tables with `NA`. It can record the source of each row
(`names_to`, after the table columns) and add constant key columns per
table (`keys`, before the table columns). `PlotDataBindColumns()` places
one-row (or equally long) tables side by side.

## Usage

``` r
PlotDataBindRows(
  tables,
  names_to = NULL,
  labels = NULL,
  keys = NULL,
  columns = NULL,
  rename = NULL,
  element = NULL
)

PlotDataBindColumns(tables)
```

## Arguments

- tables:

  A list of data frames (named when `names_to` without `labels`, `keys`
  or `rename` are used), or a single data frame.

- names_to:

  Optional column recording the source of each row: the list name, the
  matching entry of `labels`, or the list position.

- labels:

  Optional source labels, one per table.

- keys:

  Optional named list: table name to a named list of scalar values added
  as leading columns. For a single data frame, `keys` is the named list
  of values itself.

- columns:

  Optional columns kept from every table.

- rename:

  Optional named list of renamings per table: table name to a named
  vector (new name = old name).

- element:

  Optional element name when the list items are lists that hold the
  tables.

## Value

A data frame.

## See also

Other plot-data builders:
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/reference/PlotDataConstant.md),
[`PlotDataCount()`](https://cttir.github.io/phenoscapR/reference/PlotDataCount.md),
[`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/reference/PlotDataCrossShares.md),
[`PlotDataDirection()`](https://cttir.github.io/phenoscapR/reference/PlotDataDirection.md),
[`PlotDataDominant()`](https://cttir.github.io/phenoscapR/reference/PlotDataDominant.md),
[`PlotDataFromArrays()`](https://cttir.github.io/phenoscapR/reference/PlotDataFromArrays.md),
[`PlotDataJoin()`](https://cttir.github.io/phenoscapR/reference/PlotDataJoin.md),
[`PlotDataKeyColours()`](https://cttir.github.io/phenoscapR/reference/PlotDataKeyColours.md),
[`PlotDataLabels()`](https://cttir.github.io/phenoscapR/reference/PlotDataLabels.md),
[`PlotDataLonger()`](https://cttir.github.io/phenoscapR/reference/PlotDataLonger.md),
[`PlotDataMembership()`](https://cttir.github.io/phenoscapR/reference/PlotDataMembership.md),
[`PlotDataPairRatio()`](https://cttir.github.io/phenoscapR/reference/PlotDataPairRatio.md),
[`PlotDataProduct()`](https://cttir.github.io/phenoscapR/reference/PlotDataProduct.md),
[`PlotDataQuantiles()`](https://cttir.github.io/phenoscapR/reference/PlotDataQuantiles.md),
[`PlotDataRankRows()`](https://cttir.github.io/phenoscapR/reference/PlotDataRankRows.md),
[`PlotDataRatio()`](https://cttir.github.io/phenoscapR/reference/PlotDataRatio.md),
[`PlotDataRecode()`](https://cttir.github.io/phenoscapR/reference/PlotDataRecode.md),
[`PlotDataRelative()`](https://cttir.github.io/phenoscapR/reference/PlotDataRelative.md),
[`PlotDataSelect()`](https://cttir.github.io/phenoscapR/reference/PlotDataSelect.md),
[`PlotDataShares()`](https://cttir.github.io/phenoscapR/reference/PlotDataShares.md),
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/reference/PlotDataUnite.md)

## Examples

``` r
PlotDataBindRows(list(a = data.frame(x = 1), b = data.frame(x = 2, y = 3)), names_to = "src")
#>   x src  y
#> 1 1   a NA
#> 2 2   b  3
PlotDataBindRows(list(a = data.frame(v = 1), b = data.frame(v = 2:3)),
                 keys = list(a = list(batch = "one"), b = list(batch = "two")))
#>   batch v
#> 1   one 1
#> 2   two 2
#> 3   two 3
PlotDataBindColumns(list(data.frame(n = 9), data.frame(text = "p1, 1")))
#>   n  text
#> 1 9 p1, 1
```
