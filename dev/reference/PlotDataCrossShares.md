# Shares of One Category within Another

Cross-tabulates two columns and returns every combination with its
count, the total of its row category and the share of the row total (for
example the cell-type composition of each cluster).

## Usage

``` r
PlotDataCrossShares(
  data,
  row,
  column,
  filter = NULL,
  rows = NULL,
  columns = NULL,
  scale = 100
)
```

## Arguments

- data:

  A data frame.

- row, column:

  Column names.

- filter:

  Optional named list of columns and values selecting rows.

- rows, columns:

  Optional level sets (and order); default the sorted values present.

- scale:

  Multiplier of the share (100 for percentages).

## Value

A data frame with `row`, `column` (named as the inputs), `n`, `total`
and `share`.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md),
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataConstant.md),
[`PlotDataCount()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCount.md),
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
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
d <- data.frame(cl = c(1, 1, 2, 2, 2), type = c("a", "b", "a", "a", "c"))
PlotDataCrossShares(d, "cl", "type")
#>   cl type n total    share
#> 1  1    a 1     2 50.00000
#> 2  1    b 1     2 50.00000
#> 3  1    c 0     2  0.00000
#> 4  2    a 2     3 66.66667
#> 5  2    b 0     3  0.00000
#> 6  2    c 1     3 33.33333
```
