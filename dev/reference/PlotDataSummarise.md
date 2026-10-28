# Summarise Columns by Group

One summary per group (or one in total) of each selected column, in wide
form (one column per summarised column) or long form (one row per group
and column).

## Usage

``` r
PlotDataSummarise(
  data,
  columns = NULL,
  fun = "sum",
  by = NULL,
  into = NULL,
  filter = NULL,
  long = FALSE,
  names_to = "name",
  values_to = "value",
  sort = FALSE,
  na_rm = TRUE
)
```

## Arguments

- data:

  A data frame.

- columns:

  Columns to summarise (for `fun = "count"` only the first is used,
  default the first column of `data`).

- fun:

  One of `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`, `"count"`
  (rows) or `"n_distinct"`.

- by:

  Optional grouping columns.

- into:

  Names of the result columns in wide form; default `columns` (or `"n"`
  for counts).

- filter:

  Optional named list of columns and values selecting rows first.

- long:

  Return long form with `names_to` (column name) and `values_to`
  (summary).

- names_to, values_to:

  Names of the long-form columns.

- sort:

  Order groups by their values; by default groups keep the order of
  first appearance.

- na_rm:

  Ignore missing values.

## Value

A data frame.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md),
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataConstant.md),
[`PlotDataCount()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCount.md),
[`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCrossShares.md),
[`PlotDataDirection()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDirection.md),
[`PlotDataDominant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDominant.md),
[`PlotDataFromArrays()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataFromArrays.md),
[`PlotDataJoin()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataJoin.md),
[`PlotDataKeyColours()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataKeyColours.md),
[`PlotDataLabels()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLabels.md),
[`PlotDataLonger()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLonger.md),
[`PlotDataMembership()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataMembership.md),
[`PlotDataPairRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataPairRatio.md),
[`PlotDataProduct()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataProduct.md),
[`PlotDataQuantiles()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataQuantiles.md),
[`PlotDataRankRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRankRows.md),
[`PlotDataRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRatio.md),
[`PlotDataRecode()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRecode.md),
[`PlotDataRelative()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRelative.md),
[`PlotDataSelect()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSelect.md),
[`PlotDataShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataShares.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
d <- data.frame(g = c("b", "b", "a"), x = 1:3, y = c(2, 4, 6))
PlotDataSummarise(d, c("x", "y"), "sum")
#>   x  y
#> 1 6 12
PlotDataSummarise(d, fun = "count", by = "g")
#>   g n
#> 1 b 2
#> 2 a 1
PlotDataSummarise(d, c("x", "y"), "mean", by = "g", long = TRUE, sort = TRUE)
#>   g name value
#> 1 a    x   3.0
#> 2 b    x   1.5
#> 3 a    y   6.0
#> 4 b    y   3.0
```
