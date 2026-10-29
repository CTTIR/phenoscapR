# Counts and Shares by Group

Counts rows per group (or overall), optionally the number of distinct
values of a column and the rows per distinct value, the share of all
counted rows, and counts of selected values of further columns.

## Usage

``` r
PlotDataCount(
  data,
  by = NULL,
  filter = NULL,
  distinct = NULL,
  tally = NULL,
  scale = 100
)
```

## Arguments

- data:

  A data frame.

- by:

  Grouping columns (none for one overall row).

- filter:

  Optional named list of columns and values selecting rows.

- distinct:

  Optional column whose distinct values are counted.

- tally:

  Optional named list of extra counts: each a list of `column` and
  `values`.

- scale:

  Multiplier of the share (100 for percentages).

## Value

A data frame with the groups, `n`, `share`, and if requested
`n_distinct`, `n_per_distinct` (integer division) and the tallies.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/reference/PlotDataBindRows.md),
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/reference/PlotDataConstant.md),
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
d <- data.frame(g = c("a", "a", "b"), p = c("x", "y", "x"), t = c("T", "U", "T"))
PlotDataCount(d, "g", distinct = "p", tally = list(n_t = list(column = "t", values = "T")))
#>   g n    share n_distinct n_per_distinct n_t
#> 1 a 2 66.66667          2              1   1
#> 2 b 1 33.33333          1              1   1
```
