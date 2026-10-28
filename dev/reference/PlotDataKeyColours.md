# Key Colours from a Categorical Palette

Assigns colours to integer keys (for example cluster numbers) by cycling
through one or more categorical palettes: key `k` takes colour
`((k - first) mod n) + 1` of the joined palettes.

## Usage

``` r
PlotDataKeyColours(
  keys,
  column = "key",
  palettes = c("tab20", "tab20b"),
  first = 1
)
```

## Arguments

- keys:

  Keys: a vector, or a data frame whose `column` holds them.

- column:

  Key column when `keys` is a data frame.

- palettes:

  Palette names: `"tab20"`, `"tab20b"`, `"tab20c"` or `"clusters"` (the
  style's cluster palette), joined in order.

- first:

  Key that takes the first colour.

## Value

A data frame with `key` and `colour`, sorted by key.

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
PlotDataKeyColours(1:25)
#>    key  colour
#> 1    1 #1f77b4
#> 2    2 #aec7e8
#> 3    3 #ff7f0e
#> 4    4 #ffbb78
#> 5    5 #2ca02c
#> 6    6 #98df8a
#> 7    7 #d62728
#> 8    8 #ff9896
#> 9    9 #9467bd
#> 10  10 #c5b0d5
#> 11  11 #8c564b
#> 12  12 #c49c94
#> 13  13 #e377c2
#> 14  14 #f7b6d2
#> 15  15 #7f7f7f
#> 16  16 #c7c7c7
#> 17  17 #bcbd22
#> 18  18 #dbdb8d
#> 19  19 #17becf
#> 20  20 #9edae5
#> 21  21 #393b79
#> 22  22 #5254a3
#> 23  23 #6b6ecf
#> 24  24 #9c9ede
#> 25  25 #637939
```
