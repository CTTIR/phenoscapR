# Look Up Values Stored on Nested Row Subsets

Per-cell results are often stored only for a subset of a subset of the
rows of a sample (for example neighbourhood labels for the defined cells
among the counted cells). For records that refer to rows of the full
sample table, this returns the stored value, or `missing` where the row
lies outside the subsets.

## Usage

``` r
LookupNestedRows(
  data,
  sample = "sample",
  row = "row",
  outer,
  inner,
  values = NULL,
  samples,
  outer_name = "counted",
  inner_name = "defined_rows",
  value_name = "cn",
  missing = -1L,
  base = 0L,
  to = "value"
)
```

## Arguments

- data:

  Data frame of records with a sample and a row column.

- sample, row:

  Column names; rows are counted from `base`.

- outer:

  List (one entry per sample, in the order of `samples`) of logical
  vectors over all rows, or lists holding such a vector named
  `outer_name`.

- inner:

  List of logical vectors over the outer rows, or lists holding one
  named `inner_name` together with the values `value_name`.

- values:

  Optional list of value vectors over the inner rows (default taken from
  `inner`).

- samples:

  Sample names matching the entries of the lists.

- outer_name, inner_name, value_name:

  Element names inside list entries.

- missing:

  Value for rows outside the subsets.

- base:

  Index of the first row (0 for arrays from Python).

- to:

  Name of the new column.

## Value

`data` with the new column.

## Examples

``` r
d <- data.frame(s = c("a", "a", "b"), r = c(0, 2, 1))
LookupNestedRows(d, "s", "r", outer = list(c(TRUE, FALSE, TRUE), c(TRUE, TRUE)),
                 inner = list(c(TRUE, TRUE), c(FALSE, TRUE)),
                 values = list(c(5L, 6L), 7L), samples = c("a", "b"))
#>   s r value
#> 1 a 0     5
#> 2 a 2     6
#> 3 b 1     7
```
