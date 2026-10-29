# Product of Columns

Multiplies columns row by row, divides by a constant and optionally
rounds (half to even), for example a count from a total and a
percentage.

## Usage

``` r
PlotDataProduct(data, columns, divide = 1, round = FALSE, into = "value")
```

## Arguments

- data:

  A data frame.

- columns:

  Columns to multiply, in order.

- divide:

  Divisor applied after the product.

- round:

  Round to whole numbers.

- into:

  Name of the new column.

## Value

`data` with the new column.

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
PlotDataProduct(data.frame(n = c(44, 2), pct = c(54.5454545, 50)), c("n", "pct"),
                divide = 100, round = TRUE, into = "k")
#>    n      pct  k
#> 1 44 54.54545 24
#> 2  2 50.00000  1
```
