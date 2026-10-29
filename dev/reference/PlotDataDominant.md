# Order Groups by Their Dominant Category

For each row group of a share table (from
[`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCrossShares.md)),
finds the category with the largest share (ties go to the earlier
category in `columns`) and orders the groups by the position of that
category in `priority`, then by the group value. Categories missing from
`priority` take position zero, before all listed ones. A group without
any share among `columns` has a missing `dominant` category and also
takes position zero.

## Usage

``` r
PlotDataDominant(
  data,
  row,
  column,
  value = "share",
  columns = NULL,
  priority = NULL
)
```

## Arguments

- data:

  Long share table.

- row, column, value:

  Column names.

- columns:

  Category order used to break ties.

- priority:

  Category order defining the group order.

## Value

A data frame with the group, `dominant`, `dominant_share` and `rank`,
sorted by rank.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md),
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataConstant.md),
[`PlotDataCount()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCount.md),
[`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCrossShares.md),
[`PlotDataDirection()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDirection.md),
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
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
s <- PlotDataCrossShares(data.frame(cl = c(1, 1, 2, 3), type = c("b", "b", "a", "b")), "cl", "type")
PlotDataDominant(s, "cl", "type", "share", columns = c("a", "b"), priority = c("a", "b"))
#>   cl dominant dominant_share rank
#> 1  2        a            100    1
#> 2  1        b            100    2
#> 3  3        b            100    3
```
