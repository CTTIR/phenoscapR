# Summarize Continuous Observations in Explicit Groups

Computes arithmetic means, medians and optional threshold fractions or
weighted means over supplied observations. No unobserved groups or zeros
are manufactured. Observation IDs must be unique within the complete
group key. Include the independent sampling unit in `groups` when
required; this function does not establish independence, eligibility,
review authority or tissue area.

## Usage

``` r
SummarizeGroupedValues(
  data,
  groups,
  id,
  value,
  weight = NULL,
  threshold = NULL,
  min_available = 1L,
  missing = c("propagate", "available")
)
```

## Arguments

- data:

  Data frame containing group/observation keys and numeric values.

- groups:

  Nonempty character vector of distinct group columns. Their values must
  be dimensionless, nonblank character vectors without NA.

- id:

  Character name of the observation ID column. IDs must be
  dimensionless, nonblank character values without NA, unique within
  each complete group key. The reserved ASCII 28 separator is rejected
  in keys.

- value:

  Character column containing finite numeric values or NA.

- weight:

  Optional character column with finite nonnegative weights or NA.

- threshold:

  Optional finite numeric scalar. Reports the fraction of available
  values greater than or equal to this fixed threshold.

- min_available:

  Positive integer minimum number of available observations.

- missing:

  Missingness policy: `"propagate"` or explicit `"available"`.

## Value

Data frame sorted by group keys with supplied/available counts, mean,
median, threshold fraction, weighted mean, total available weight, and
separate availability statuses and the missingness policy. Status is
COMPLETE, PARTIAL, INSUFFICIENT or UNAVAILABLE; optional weighted status
also uses NOT_REQUESTED and NO_POSITIVE_WEIGHT. Empty input returns a
typed empty table. Numerical overflow or product underflow fails rather
than producing a misleading summary. `weight_sum` counts only pairs with
both value and weight available; it is zero for observed zero weights,
and NA when policy suppresses a weighted summary or weights were not
requested.

## Details

Missing observations remain counted. The default suppresses summaries
when any required value is unavailable. `missing = "available"`
explicitly selects available-case summaries, still labelled PARTIAL.
Weighted summaries require both a value and its nonnegative weight, and
positive total weight. A weight of zero is an observed zero
contribution, not unavailable. `min_available` applies separately to
unweighted and weighted available observations.

## Examples

``` r
d <- data.frame(sample = c("one", "one"), cell = c("a", "b"),
  score = c(1, 3), area = c(1, 3))
SummarizeGroupedValues(d, "sample", "cell", "score", "area", threshold = 2)
#>   sample n_supplied n_available n_unavailable mean median fraction_at_least
#> 1    one          2           2             0    2      2               0.5
#>     status n_weighted_available weighted_mean weighted_status weight_sum
#> 1 COMPLETE                    2           2.5        COMPLETE          4
#>   missing_policy
#> 1      propagate
```
