# Lower Bound of an Exact Two-Sided Permutation P Value

For an exact permutation test of two groups of sizes `n_a` and `n_b`
(all allocations of the pooled values), the observed allocation always
reaches its own statistic; with equal group sizes its mirror allocation
reaches the same absolute difference. The smallest attainable two-sided
P is therefore at least `2 / choose(n_a + n_b, n_a)` for equal and
`1 / choose(n_a + n_b, n_a)` for unequal sizes.

## Usage

``` r
ExactPermutationBound(n_a, n_b)
```

## Arguments

- n_a, n_b:

  Group sizes.

## Value

Numeric lower bound.

## Examples

``` r
ExactPermutationBound(6, 6)
#> [1] 0.002164502
ExactPermutationBound(4, 2)
#> [1] 0.06666667
```
