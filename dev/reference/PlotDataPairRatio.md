# Ratios Between Two Levels of a Key Column

For tables with one row per identifier and level (for example per
patient and cell set), divides the values of one level by those of a
reference level of the same identifier, for one or several value
columns, and returns one row per identifier and value column.

## Usage

``` r
PlotDataPairRatio(
  data,
  id,
  key,
  numerator,
  denominator,
  values,
  names = values,
  pseudocount = 0,
  log_base = NULL,
  names_to = "variable",
  values_to = "ratio"
)
```

## Arguments

- data:

  A data frame.

- id:

  Identifier columns that pair rows.

- key:

  Column holding the levels.

- numerator, denominator:

  Levels of `key`.

- values:

  Value columns.

- names:

  Names for `values` in the output; default `values`.

- pseudocount:

  Added to both values.

- log_base:

  Optional logarithm base.

- names_to, values_to:

  Names of the output columns.

## Value

A data frame with `id`, `names_to`, `values_to` and the two input values
(`numerator_value`, `denominator_value`). Identifiers lacking a level
give `NA`.

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
d <- data.frame(id = rep(c("p1", "p2"), each = 2), set = c("x", "ref", "x", "ref"),
                v = c(4, 2, 1, 2))
PlotDataPairRatio(d, "id", "set", "x", "ref", "v", log_base = 2)
#>   id variable ratio numerator_value denominator_value
#> 1 p1        v     1               4                 2
#> 2 p2        v    -1               1                 2
```
