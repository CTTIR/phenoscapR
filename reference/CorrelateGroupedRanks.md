# Correlate Paired Ranks Within Explicit Groups

Computes descriptive Spearman correlations over paired observations,
using average ranks for ties. Each observation must occur once per
complete group key. Include the independent sampling unit in `groups`;
no independence, eligibility, causal interpretation or inferential p
value is established. Missingness is paired: a row is available only
when both values are known. The default suppresses correlation when any
pair is unavailable. Explicit available-case analysis retains the
supplied and unavailable pair counts.

## Usage

``` r
CorrelateGroupedRanks(
  data,
  groups,
  id,
  x,
  y,
  min_pairs = 3L,
  missing = c("propagate", "available")
)
```

## Arguments

- data:

  Data frame with group keys, observation IDs and paired values.

- groups:

  Nonempty character vector of distinct group columns with nonempty
  character values and no missing keys.

- id:

  Character column naming observations within each group.

- x, y:

  Distinct numeric value columns. Finite numbers and NA are allowed; NaN
  and infinite values are rejected.

- min_pairs:

  Integer minimum available pair count, at least two.

- missing:

  Missingness policy: `"propagate"` or explicit `"available"`.

## Value

Data frame sorted by group keys with `n_supplied`, `n_available`,
`n_unavailable`, available-pair `n_unique_x` and `n_unique_y`, `rho`,
`status`, and `missing_policy`. Status precedence is UNAVAILABLE,
INSUFFICIENT, MISSING_PAIRS (propagation), CONSTANT_BOTH, CONSTANT_X,
CONSTANT_Y, then COMPLETE or PARTIAL. Suppressed correlations are NA.
Empty input returns a typed empty table; absent groups are not invented.

## Examples

``` r
d <- data.frame(sample = "one", cell = letters[1:4],
                a = c(1, 1, 3, 4), b = c(4, 3, 2, 1))
CorrelateGroupedRanks(d, "sample", "cell", "a", "b")
#>   sample n_supplied n_available n_unavailable n_unique_x n_unique_y        rho
#> 1    one          4           4             0          3          4 -0.9486833
#>     status missing_policy
#> 1 COMPLETE      propagate
```
