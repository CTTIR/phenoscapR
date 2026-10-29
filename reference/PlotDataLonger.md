# Reshape Wide Columns into Long Plot Data

Stacks value columns of a summary table (one row per patient, say) into
one row per identifier and column, the form used by the plot builders.
The columns are given by name (`values`), by a regular expression
(`pattern`), or default to all columns other than `id` and `exclude`.

## Usage

``` r
PlotDataLonger(
  data,
  id,
  values = NULL,
  conditions = NULL,
  pattern = NULL,
  exclude = NULL,
  names_to = "condition",
  values_to = "value",
  drop_na = FALSE
)
```

## Arguments

- data:

  A data frame.

- id:

  Identifier columns kept on every row.

- values:

  Value columns to stack, in condition order.

- conditions:

  Condition names for the stacked columns; default the column names (or
  the pattern groups).

- pattern:

  Regular expression selecting the value columns when `values` is
  `NULL`.

- exclude:

  Columns never stacked when `values` is `NULL`.

- names_to, values_to:

  Names of the new condition and value columns.

- drop_na:

  Drop rows whose value is missing.

## Value

A data frame with `id` columns, `names_to` (character, in column order)
and `values_to` (numeric).

## Details

With `pattern`, the first capture group of the pattern becomes the
condition name (`"^log2\\|(.*)$"` turns `log2|p1` into `p1`); a pattern
without a group keeps the column names.

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
d <- data.frame(patient = c("p1", "p2"), a = 1:2, b = 3:4)
PlotDataLonger(d, "patient", c("a", "b"), conditions = c("A", "B"))
#>   patient condition value
#> 1      p1         A     1
#> 2      p2         A     2
#> 3      p1         B     3
#> 4      p2         B     4
w <- data.frame(type = c("a", "b"), `v|p1` = 1:2, `v|p2` = c(3, NA), check.names = FALSE)
PlotDataLonger(w, "type", pattern = "^v\\|(.*)$", names_to = "patient", drop_na = TRUE)
#>   type patient value
#> 1    a      p1     1
#> 2    b      p1     2
#> 3    a      p2     3
```
