# Text Labels from Table Rows

`PlotDataLabels()` writes one text per row with
[`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md)
(for example titles such as `"{cells:%.0f}k cells; {area:%.0f} mm2"`),
after optional per-column scaling. `PlotDataCollapse()` writes every row
and joins the results into one text, for example to list patients with
their cell counts in a figure note.

## Usage

``` r
PlotDataLabels(data, template, id = NULL, scales = NULL, into = "text")

PlotDataCollapse(
  data,
  template,
  sep = "; ",
  order_by = NULL,
  decreasing = FALSE,
  into = "text",
  n_name = "rows"
)
```

## Arguments

- data:

  A data frame.

- template:

  Template (see
  [`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md)).

- id:

  Optional columns of `data` kept in the output of `PlotDataLabels()`.

- scales:

  Named list: column to a multiplier applied before formatting.

- into:

  Name of the text column.

- sep:

  Separator of the collapsed rows.

- order_by:

  Optional column to sort by before collapsing (stable, increasing).

- decreasing:

  Sort decreasing.

- n_name:

  Name of a column with the number of rows collapsed.

## Value

`PlotDataLabels()`: a data frame with the `id` columns and `into`;
`PlotDataCollapse()`: a one-row data frame.

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
d <- data.frame(p = c("p3", "p1"), n = c(27081, 1450), g = c("A", "B"))
PlotDataLabels(d, "{n:%.0f}k cells, {g}", id = "p", scales = list(n = 0.001))
#>    p         text
#> 1 p3 27k cells, A
#> 2 p1  1k cells, B
PlotDataCollapse(d, "{p}, {n|comma}", order_by = "n")
#>                    text rows
#> 1 p1, 1,450; p3, 27,081    2
```
