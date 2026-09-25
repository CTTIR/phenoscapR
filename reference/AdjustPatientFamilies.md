# Adjust Explicitly Declared Patient-Test Families

Computes finite-only BH for historical comparison and declared-family
BH/BY using every registered hypothesis as the adjustment count.
Unavailable p values remain NA. Family IDs define the entire correction
scope: include setting and contrast in the ID only when separate
families are intended. A retrospective family registry is not
prospective registration, and neither adjustment establishes biological
validity or study-wide error control.

## Usage

``` r
AdjustPatientFamilies(tests, policy, method = c("BH", "BY"))
```

## Arguments

- tests:

  Data frame containing character `hypothesis_id`, `family_id`, and
  numeric `p_value`. All declared hypotheses must be present exactly
  once.

- policy:

  Explicit adjustment policy, `"declared"` or `"finite_only"`.

- method:

  Selected correction, `"BH"` or `"BY"`.

## Value

A list with `tests` (input columns plus all adjustment variants,
selected `p_adjusted`, policy and method) and `families` (declared,
testable and unavailable counts). Every NA is retained in the original
row order.

## Examples

``` r
x <- data.frame(hypothesis_id = c("h1", "h2"), family_id = "f",
                p_value = c(0.03, NA))
AdjustPatientFamilies(x, policy = "declared")
#> $tests
#>   hypothesis_id family_id p_value q_bh_finite q_by_finite q_bh_declared
#> 1            h1         f    0.03        0.03        0.03          0.06
#> 2            h2         f      NA          NA          NA            NA
#>   q_by_declared p_adjusted adjustment_policy adjustment_method
#> 1          0.09       0.06          declared                BH
#> 2            NA         NA          declared                BH
#> 
#> $families
#>   family_id n_declared n_testable n_unavailable
#> 1         f          2          1             1
#> 
```
