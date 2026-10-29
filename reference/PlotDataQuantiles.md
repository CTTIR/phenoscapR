# Quantile Summaries of Plot Data

Summarises a value column by groups (for example a distance curve across
patients) into lower, middle and upper quantiles and the number of
non-missing values. Quantiles use R's default (type 7) interpolation,
which equals the linear rule of common numerical libraries.

## Usage

``` r
PlotDataQuantiles(
  data,
  by,
  value,
  probs = c(0.25, 0.5, 0.75),
  names = c("lower", "median", "upper"),
  n_name = "n"
)
```

## Arguments

- data:

  A data frame.

- by:

  Grouping columns; groups keep their order of first appearance.

- value:

  Value column.

- probs:

  Three probabilities.

- names:

  Names of the three quantile columns.

- n_name:

  Name of the count column.

## Value

A data frame with the `by` columns, the quantile columns and the count
column.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/reference/PlotDataBindRows.md),
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
d <- data.frame(type = rep(c("a", "b"), each = 6), x = rep(1:2, 6), v = 1:12)
PlotDataQuantiles(d, by = c("type", "x"), value = "v")
#>   type x lower median upper n
#> 1    a 1     2      3     4 3
#> 2    a 2     3      4     5 3
#> 3    b 1     8      9    10 3
#> 4    b 2     9     10    11 3
```
