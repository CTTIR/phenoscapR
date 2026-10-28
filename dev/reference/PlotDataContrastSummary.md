# Summary of a Family of Two-Group Tests

One row describing a set of exact two-group tests: the number of tests
with a finite P value, of nominal (`p < alpha`) and of adjusted
(`q < alpha`) results, the group sizes and
[`ExactPermutationBound()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPermutationBound.md).

## Usage

``` r
PlotDataContrastSummary(
  data,
  p = "p",
  q = "q",
  n_a = "n_a",
  n_b = "n_b",
  alpha = 0.05,
  label = NULL
)
```

## Arguments

- data:

  Test table, one row per endpoint.

- p, q:

  P value and adjusted P value columns.

- n_a, n_b:

  Group-size columns (the most frequent sizes are used).

- alpha:

  Significance level.

- label:

  Optional column whose distinct values are counted as `endpoints`.

## Value

A one-row data frame with `tests`, `nominal`, `adjusted`, `n_a`, `n_b`,
`p_bound` and `endpoints`.

## Examples

``` r
t <- data.frame(p = c(0.01, 0.2, NA), q = c(0.1, 0.4, NA), n_a = 4, n_b = 2)
PlotDataContrastSummary(t)
#>   tests nominal adjusted n_a n_b    p_bound endpoints
#> 1     2       1        0   4   2 0.06666667         2
```
