# Compare Two Distributions Within Explicit Groups

Computes descriptive Cliff's delta as the number of A-greater-than-B
pairs minus A-less-than-B pairs, divided by all available cross-arm
pairs. Ties contribute zero. No inferential p value or independence
claim is supplied. Pair counts use sorted value frequencies without a
cross-product matrix or value subtraction. Every registered group is
retained, including empty arms.

## Usage

``` r
ContrastGroupedRanks(
  data,
  registry,
  groups,
  id,
  arm,
  value,
  missing = c("propagate", "available")
)
```

## Arguments

- data:

  Data frame with group keys, observation IDs, arms and values.

- registry:

  Data frame containing every allowed group key exactly once.

- groups:

  Nonempty character vector naming distinct group columns.

- id:

  Character name of the observation ID column; IDs are unique within
  each complete group key.

- arm:

  Character name of the arm column, containing exactly `"A"` or `"B"`.

- value:

  Character name of a numeric column containing finite values or
  explicit NA. NaN and infinities are rejected. Convert nonfinite input
  values to NA only through an explicit upstream policy.

- missing:

  `"propagate"` suppresses delta if any supplied value is NA;
  `"available"` explicitly uses available values independently in each
  arm.

## Value

Data frame sorted by group keys, preserving original key values.
Supplied, available and unavailable counts are returned for each arm,
together with available cross-pair, greater, less and tied counts,
delta, missingness policy and status. Empty available arms yield
UNAVAILABLE; otherwise propagation with missing values yields
MISSING_VALUES, followed by PARTIAL or COMPLETE. Pair counts always
describe available values even when delta is suppressed. Counts
exceeding exact binary64 integer capacity are rejected before
multiplication. An empty registry returns typed output.

## Details

Group keys and observation IDs must be dimensionless, nonmissing,
nonblank character vectors. Factors and numeric IDs are not coerced. The
reserved ASCII 28 separator (`intToUtf8(28)`) is rejected in keys.
Column selections must be distinct, and group columns must not collide
with output names. Registry keys must be unique. Every observation must
belong to a registered group and have a unique ID within that complete
group, including across arms. The same ID may occur in different groups.
Arm values must be exactly `"A"` or `"B"`; no labels or population
policy are inferred.

Delta is positive when A tends to exceed B and negative when B tends to
exceed A. It equals the proportion of available cross-arm pairs with A
greater than B minus the proportion with A less than B. Equal values,
including signed zeros, are ties. Comparisons use represented numeric
values without a tolerance. No value subtraction, cross-pair matrix,
rank test or resampling is performed. Pair counts above `2^53 - 1` are
rejected before multiplication rather than rounded. Sorting distinct
values and counting frequencies avoids allocating a Cartesian product,
but input and distinct values must still fit in memory.

Available-case analysis filters missing values separately within each
arm; it is not paired-observation deletion. Propagation suppresses delta
when either supplied arm contains missing values, while still reporting
the available pair counts. If an available arm is empty, status is
`UNAVAILABLE` under either policy. A declared group without observations
is retained. Group membership and missingness policies do not establish
independence or exchangeability. This function computes a descriptive
effect only.

## Examples

``` r
d <- data.frame(
  g = "one", id = letters[1:4],
  arm = c("A", "A", "B", "B"), value = c(2, 4, 1, 2)
)
ContrastGroupedRanks(d, data.frame(g = "one"), "g", "id", "arm", "value")
#>     g n_a_supplied n_b_supplied n_a_available n_b_available n_a_unavailable
#> 1 one            2            2             2             2               0
#>   n_b_unavailable n_pairs n_a_greater n_a_less n_tied delta_a_vs_b   status
#> 1               0       4           3        0      1         0.75 COMPLETE
#>   missing_policy
#> 1      propagate
```
