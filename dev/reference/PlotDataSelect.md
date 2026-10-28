# Select Rows and Columns of Plot Data

Keeps rows whose columns take given values (`filter`) and that meet
comparison conditions (`where`), optionally orders rows by a given order
of one column, and keeps or renames columns.

## Usage

``` r
PlotDataSelect(
  data,
  filter = list(),
  where = list(),
  columns = NULL,
  rename = NULL,
  order_by = NULL,
  order = NULL
)
```

## Arguments

- data:

  A data frame.

- filter:

  Named list: column name to the values to keep. Logical values are
  compared as logical, all others as text.

- where:

  Conditions, each a list with `column`, `op` and (except for `is_na`,
  `not_na`) `value`. Operators: `<`, `<=`, `>`, `>=`, `==`, `!=`, `in`,
  `not_in`, `is_na`, `not_na`, `matches`, `not_matches` (regular
  expression). Conditions are combined with AND; comparisons with
  missing values are false.

- columns:

  Columns to keep (all if `NULL`).

- rename:

  Named character vector or list, new name to old name.

- order_by:

  Optional column whose values follow `order`.

- order:

  Value order for `order_by`; rows with other values are dropped.

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
[`PlotDataShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataShares.md),
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
d <- data.frame(type = c("x", "y", "x"), v = 1:3, n = c(1, 12, NA))
PlotDataSelect(d, filter = list(type = "x"), rename = c(value = "v"))
#>   type value  n
#> 1    x     1  1
#> 2    x     3 NA
PlotDataSelect(d, where = list(list(column = "n", op = ">=", value = 10)))
#>   type v  n
#> 1    y 2 12
```
