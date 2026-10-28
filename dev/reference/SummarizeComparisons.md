# Summarise Comparison Results into Pass/Fail Checks

Condenses outputs of
[`CompareTables()`](https://cttir.github.io/phenoscapR/dev/reference/CompareTables.md)
or
[`CompareArrays()`](https://cttir.github.io/phenoscapR/dev/reference/CompareArrays.md)
(one or a list of them) into one row per check: rows compared, rows
whose values all match, values compared and matching, the largest
difference and tolerance, and `PASS` when every value matches and the
declared number of rows (if any) was compared.

## Usage

``` r
SummarizeComparisons(
  comparisons,
  unit = "row_key",
  expected_rows = NULL,
  by = "check"
)
```

## Arguments

- comparisons:

  A comparison data frame or a list of them. When an element lacks the
  first `by` column, its list name is used.

- unit:

  Columns that identify one compared row (default `"row_key"`).

- expected_rows:

  Optional named list or vector: value of the first `by` column (the
  check label) to the number of rows that must be compared in each
  summary row of that check.

- by:

  Columns defining one summary row (default `"check"`), for example
  `c("check", "branch")`. Missing columns are treated as `NA`.

## Value

A data frame with the `by` columns, `rows`, `matching_rows`, `values`,
`matching_values`, `max_difference`, `tolerance`, `expected_rows` and
`status`.

## Examples

``` r
a <- data.frame(id = c("x", "y"), p = c(0.1, 0.2))
cmp <- CompareTables(a, a, "id", "p", check = "self")
SummarizeComparisons(cmp, expected_rows = c(self = 2))
#>   check rows matching_rows values matching_values max_difference tolerance
#> 1  self    2             2      2               2              0         0
#>   expected_rows status
#> 1             2   PASS
```
