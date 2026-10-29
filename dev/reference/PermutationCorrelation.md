# Permutation Test of a Rank or Linear Correlation

Computes Spearman's rho (Pearson correlation of midranks) or Pearson's r
for the complete pairs of each group, with a two-sided permutation p
value: Monte Carlo with a declared R seed, `(b + 1) / (B + 1)` where `b`
counts permuted absolute correlations at least the observed one, or
exact enumeration of all `n!` orderings (`mean` of the same indicator).

## Usage

``` r
PermutationCorrelation(
  data,
  x,
  y,
  groups = NULL,
  method = c("spearman", "pearson"),
  permutations = c("monte_carlo", "exact"),
  n_perm = 99999L,
  seed = NULL,
  min_n = 4L,
  max_exact_n = 9L,
  tolerance = 1e-12
)
```

## Arguments

- data:

  Data frame.

- x, y:

  Numeric columns.

- groups:

  Optional group columns.

- method:

  `"spearman"` or `"pearson"`.

- permutations:

  `"monte_carlo"` or `"exact"`.

- n_perm:

  Number of Monte Carlo permutations.

- seed:

  Optional whole-number seed for Monte Carlo draws; every group starts
  from it. The caller's random stream is restored.

- min_n:

  Smallest number of complete pairs tested (at least 2).

- max_exact_n:

  Largest `n` accepted for exact enumeration.

- tolerance:

  Absolute tolerance in the comparison with the observed correlation.

## Value

A data frame with the group columns, `n`, `estimate`, `p_value`,
`method`, `permutations`, `n_perm` (number of orderings used), `seed`
and `status`.

## Examples

``` r
d <- data.frame(x = c(1, 2, 3, 4, 5, 6), y = c(2, 1, 4, 3, 6, 5))
PermutationCorrelation(d, "x", "y", permutations = "exact")
#>   n  estimate    p_value   method permutations n_perm seed status
#> 1 6 0.8285714 0.05833333 spearman        exact    720   NA TESTED
PermutationCorrelation(d, "x", "y", n_perm = 999, seed = 1)
#>   n  estimate p_value   method permutations n_perm seed status
#> 1 6 0.8285714   0.054 spearman  monte_carlo    999    1 TESTED
```
