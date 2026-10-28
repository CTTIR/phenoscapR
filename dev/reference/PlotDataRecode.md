# Recode the Values of a Column

Maps the values of a column to new values. Each value is looked up, in
this order, in an exact `map`, in a list of regular expressions
(`patterns`, the first match wins) and by position in `index` (integer
codes counted from `index_base`); an optional `extract` expression first
picks the part of each value that is looked up. Unmatched values are
kept, or replaced by `default`. Finally `substitute` applies
regular-expression replacements to every value, in order (for example to
turn analysis names into display labels).

## Usage

``` r
PlotDataRecode(
  data,
  column,
  map = NULL,
  patterns = NULL,
  index = NULL,
  index_base = 0L,
  extract = NULL,
  default = NULL,
  keep_unmatched = is.null(default),
  substitute = NULL,
  into = column
)
```

## Arguments

- data:

  A data frame.

- column:

  Column to recode.

- map:

  Optional named vector or list: old value to new value.

- patterns:

  Optional named vector or list: regular expression to new value, tried
  in order for values not in `map`.

- index:

  Optional names for integer codes: a vector, or a data frame whose
  first column is used.

- index_base:

  Code of the first name of `index`.

- extract:

  Optional regular expression with one capture group; the group is
  looked up instead of the whole value.

- default:

  Value for unmatched entries; `NULL` keeps them.

- keep_unmatched:

  Keep unmatched values; with `FALSE` they become `default` (missing
  when `default` is `NULL`).

- substitute:

  Optional list of `c(pattern, replacement)` pairs (Perl regular
  expressions) applied to every value at the end, in order.

- into:

  Name of the result column; default `column`.

## Value

`data` with the recoded column.

## Details

The result is numeric when every replacement value is numeric and
unmatched values are not kept (for example ordinal codes for reported
categories); otherwise it is text.

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
[`PlotDataRelative()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRelative.md),
[`PlotDataSelect()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSelect.md),
[`PlotDataShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataShares.md),
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
d <- data.frame(e = c("pct|B cells", "density|B cells"), g = c("A-x", "B"), cn = c(0, 2))
PlotDataRecode(d, "e", substitute = list(c("^pct\\|(.*)$", "\\1 (% of cells)"),
                                         c("^density\\|(.*)$", "\\1 (per mm2)")))
#>                      e   g cn
#> 1 B cells (% of cells) A-x  0
#> 2    B cells (per mm2)   B  2
PlotDataRecode(d, "g", patterns = c("^A" = "first"), default = "other", into = "label")
#>                 e   g cn label
#> 1     pct|B cells A-x  0 first
#> 2 density|B cells   B  2 other
PlotDataRecode(d, "cn", index = c("zero", "one", "two"), into = "name")
#>                 e   g cn name
#> 1     pct|B cells A-x  0 zero
#> 2 density|B cells   B  2  two
PlotDataRecode(data.frame(tps = c("0", "<1", "8", "n.a.")), "tps",
               map = list("0" = 0, "<1" = 0.5, "8" = 8), keep_unmatched = FALSE, into = "score")
#>    tps score
#> 1    0   0.0
#> 2   <1   0.5
#> 3    8   8.0
#> 4 n.a.    NA
```
