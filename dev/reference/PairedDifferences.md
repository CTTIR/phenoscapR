# Build Paired Differences from Wide Subject Tables

Turns pairs of columns of one or several subject tables (one row per
subject) into long paired differences `x - y`, ready for
[`ExactPairedTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPairedTests.md).

## Usage

``` r
PairedDifferences(data, id, pairs, name = "endpoint")
```

## Arguments

- data:

  A data frame, or a named list of data frames (for example several
  summary tables of the same subjects).

- id:

  Subject column, unique within each table.

- pairs:

  List of pair specifications, each a list with `name` (label of the
  difference), `x` and `y` (column names; `y = NULL` keeps `x`
  unchanged) and, when `data` is a list, `table` (element name). Further
  scalar fields (for example `expected = "less"`) become columns.

- name:

  Name of the output label column.

## Value

A data frame with `name`, the subject column, `x`, `y`, `difference` and
any extra fields, pairs in the given order and subjects in table order.

## Examples

``` r
d <- data.frame(subject = c("s1", "s2", "s3"), a = c(5, 7, 9), b = c(6, 6, 10))
PairedDifferences(d, "subject", list(list(name = "a - b", x = "a", y = "b",
                                          expected = "less")))
#>   endpoint subject x  y difference expected
#> 1    a - b      s1 5  6         -1     less
#> 2    a - b      s2 7  6          1     less
#> 3    a - b      s3 9 10         -1     less
```
