# Text-Table Cells from a Per-Unit Table

Transposes a table with one row per unit (patient, analysis) into the
cells of a small text table for
[`PlotTextBlock()`](https://cttir.github.io/phenoscapR/reference/PlotTextBlock.md):
a header row with the unit labels and one row per value column, each
with a row label in the first column. Values are written as numbers
(whole numbers without decimals, missing as `"NE"`), as text for text
columns, or from one template per table row (see
[`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md)).
Cells whose value lies below `highlight_below` are flagged.

## Usage

``` r
PlotDataTableCells(
  data,
  id,
  values = NULL,
  row_labels = values,
  header = "",
  key = NULL,
  highlight_below = NULL,
  zero_text = NULL,
  templates = NULL
)
```

## Arguments

- data:

  A data frame, one row per unit, in display order.

- id:

  Column with the unit labels shown in the header.

- values:

  Value columns, one table row each (optional with `templates`).

- row_labels:

  Labels of the value rows.

- header:

  Label of the header row.

- key:

  Optional column copied to the header cells as `key` (for example a
  group used to colour header text).

- highlight_below:

  Values below this are flagged (`highlight = TRUE`).

- zero_text:

  Optional text written instead of zero values.

- templates:

  Optional templates, one per table row, filled from each unit's row
  (for example `"p = {p|p}"`).

## Value

A data frame of cells with `row`, `column`, `label`, `header`,
`highlight` and `key`.

## Examples

``` r
d <- data.frame(id = c("1", "2"), a = c(3, 0), b = c(12, 40), g = c("x", "y"))
PlotDataTableCells(d, "id", c("a", "b"), c("First", "Second"), key = "g",
                   highlight_below = 10, zero_text = "0 (NE)")
#>   row column  label header highlight  key
#> 1   1      1          TRUE     FALSE <NA>
#> 2   1      2      1   TRUE     FALSE    x
#> 3   1      3      2   TRUE     FALSE    y
#> 4   2      1  First  FALSE     FALSE <NA>
#> 5   2      2      3  FALSE      TRUE <NA>
#> 6   2      3 0 (NE)  FALSE      TRUE <NA>
#> 7   3      1 Second  FALSE     FALSE <NA>
#> 8   3      2     12  FALSE     FALSE <NA>
#> 9   3      3     40  FALSE     FALSE <NA>
PlotDataTableCells(data.frame(id = c("A", "B"), p = c(0.018, 0.058)), "id",
                   row_labels = "Permutation test", templates = "p = {p|p}")
#>   row column            label header highlight key
#> 1   1      1                    TRUE     FALSE  NA
#> 2   1      2                A   TRUE     FALSE  NA
#> 3   1      3                B   TRUE     FALSE  NA
#> 4   2      1 Permutation test  FALSE     FALSE  NA
#> 5   2      2        p = 0.018  FALSE     FALSE  NA
#> 6   2      3        p = 0.058  FALSE     FALSE  NA
```
