# Compare a Recomputed Table with a Reference Table by Key

Joins two tables on declared key columns (which must be unique in both)
and compares declared value columns: numbers within an absolute
tolerance, everything else (text, logical) exactly. Missing values match
only missing values. Keys present in one table only are reported.

## Usage

``` r
CompareTables(
  observed,
  reference,
  keys,
  columns,
  tolerance = 0,
  observed_element = NULL,
  reference_element = NULL,
  observed_filter = NULL,
  reference_filter = NULL,
  reference_fill = NULL,
  check = "comparison"
)
```

## Arguments

- observed, reference:

  Data frames (or lists holding one, see `observed_element`,
  `reference_element`).

- keys:

  Key columns: a character vector of names shared by both tables, or a
  named vector/list `observed name = reference name`.

- columns:

  Value columns, given like `keys`.

- tolerance:

  Absolute tolerance for numeric columns: one number, or a named vector
  by observed column (unnamed columns use 0).

- observed_element, reference_element:

  Optional element names when an input is a list of tables (for example
  `"tests"` of
  [`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/reference/AdjustPatientFamilies.md)).

- observed_filter, reference_filter:

  Optional named lists of column values selecting rows before the join.

- reference_fill:

  Optional value used for every reference column when a key is absent
  from the reference (for registries that omit zero rows); such rows are
  flagged in `reference_filled`.

- check:

  Label stored in column `check`.

## Value

A data frame with one row per key and column: `check`, the key columns
(observed names), `row_key`, `column`, `reference_column`,
`observed_value`, `reference_value` (text, 17 significant digits for
numbers), `difference` (absolute, numeric pairs), `tolerance`,
`reference_filled`, `matches` and `status` (`MATCH`, `MISMATCH`,
`MISSING_OBSERVED`, `MISSING_REFERENCE`).

## See also

[`SummarizeComparisons()`](https://cttir.github.io/phenoscapR/reference/SummarizeComparisons.md)

## Examples

``` r
a <- data.frame(id = c("x", "y"), p = c(0.1, 0.2), s = c("ok", "ok"))
b <- data.frame(key = c("y", "x"), pv = c(0.2 + 1e-12, 0.1), s = c("ok", "no"))
CompareTables(a, b, keys = c(id = "key"), columns = c(p = "pv", s = "s"),
              tolerance = 1e-10)
#>        check id row_key column reference_column      observed_value
#> 1 comparison  x       x      p               pv 0.10000000000000001
#> 2 comparison  y       y      p               pv 0.20000000000000001
#> 3 comparison  x       x      s                s                  ok
#> 4 comparison  y       y      s                s                  ok
#>       reference_value   difference tolerance reference_filled matches   status
#> 1 0.10000000000000001 0.000000e+00     1e-10            FALSE    TRUE    MATCH
#> 2 0.20000000000100002 1.000006e-12     1e-10            FALSE    TRUE    MATCH
#> 3                  no           NA        NA            FALSE   FALSE MISMATCH
#> 4                  ok           NA        NA            FALSE    TRUE    MATCH
```
