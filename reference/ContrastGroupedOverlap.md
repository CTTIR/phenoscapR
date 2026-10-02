# Contrast Explicit Groups Within Finite-Metric Overlap Strata

Compares positive and control observations only within strata containing
both labels with finite metric values. The caller supplies the
policy-selected population, independent group keys, stratum assignments
and binary labels. This function does not select a population, construct
strata, establish independence, or infer a causal estimand or scientific
eligibility policy.

## Usage

``` r
ContrastGroupedOverlap(
  data,
  registry,
  groups,
  strata,
  id,
  positive,
  value,
  quality = NULL
)
```

## Arguments

- data:

  Data frame of policy-selected observations, including unavailable
  metric values. Rows are counted before filtering for finite metric
  values.

- registry:

  Data frame declaring every group, including empty groups. Extra
  registry columns are ignored.

- groups:

  Nonempty character vector of distinct group column names.

- strata:

  Nonempty character vector of distinct stratum column names. Strata are
  nested within the complete group key and are supplied explicitly.

- id:

  Character name of the observation ID column. IDs must be unique within
  a group, even when stratum assignments differ.

- positive:

  Character name of a dimensionless logical column without NA. TRUE
  denotes positive observations and FALSE denotes controls.

- value:

  Character name of a real numeric metric column. NA, NaN and infinite
  values count in policy totals but are not metric-evaluable.

- quality:

  Optional named list of explicit nonnegative finite criteria:
  `min_positive_policy`, `min_positive_evaluable`,
  `min_positive_overlap`, `min_policy_coverage`,
  `min_evaluable_coverage`, and `min_control_ess`. Count criteria must
  be integers; coverage criteria must lie between zero and one
  (inclusive). Each criterion is optional. NULL requests no quality
  assessment.

## Value

List with `schema_version` ("1.0.0"), `summary`, `strata`,
`observations`, and the canonical requested `quality` list. All tables
are sorted by explicit keys; empty registries return typed empty tables.
The summary contains policy/evaluable/overlap counts, stratum counts,
both positive coverage fractions, positive/control evaluable fractions,
`positive_mean`, `control_weighted_mean`, `contrast`,
`control_weight_sum` and `control_effective_n`. A zero weight total
denotes an empty matched control set; missing means and ESS remain NA,
never zero-imputed. Summary status is EMPTY_GROUP, NO_EVALUABLE_VALUES,
NO_OVERLAP or DEFINED; availability is UNAVAILABLE, PARTIAL or COMPLETE.
Quality is NOT_REQUESTED, PASS or FAIL with semicolon-separated failed
criterion names. The stratum table retains policy/evaluable counts and
overlap status. The observation table retains keys, `is_positive`,
`metric_value`, `metric_evaluable`, `overlap`, `weight`, and OVERLAP,
NONFINITE_VALUE or NO_OVERLAP_STRATUM status. Extra input columns are
not returned.

## Details

Group, stratum and observation keys must be nonblank, nonmissing
character vectors without dimensions. Factors and numeric IDs are not
coerced. All selected column roles must be distinct, and keys must not
collide with output column names. Unknown groups and duplicate registry
or observation keys are rejected. Row order does not define identity.

Overlap is determined separately within each group and stratum after
filtering for finite metric values. In an overlap stratum, positives
receive weight one and controls receive the finite positive count
divided by the finite control count. Observations with unavailable
values or outside overlap retain NA weights and explicit statuses. They
are not discarded from the returned observation and stratum audit
tables.

The contrast is the overlap-positive mean minus the weighted
overlap-control mean. Both policy-positive and metric-evaluable-positive
coverage denominators are reported. Effective control count is the
squared sum of control weights divided by their sum of squares, computed
after scaling weights to avoid avoidable overflow. Means similarly scale
values and weights. Unrepresentable results or scaling/product underflow
raise an error rather than silently dropping a nonzero contribution.
Exact cancellation to zero is valid. Ordinary floating-point rounding
still applies; this is not arbitrary-precision arithmetic.

All optional quality criteria are assessed separately. A failed
criterion never suppresses an otherwise finite contrast. A PASS means
only that the requested criteria passed, not that the contrast is
defined or scientifically eligible; inspect `status` and the explicit
denominators as well. Criteria using an unavailable denominator fail. No
count population or threshold is selected implicitly. Policy, evaluable
and overlap positive counts are distinct.

## Examples

``` r
d <- data.frame(sample = "one", block = c("a", "a", "a", "b"),
  cell = letters[1:4], positive = c(TRUE, FALSE, FALSE, TRUE),
  score = c(4, 1, 3, NA))
registry <- data.frame(sample = c("one", "empty"))
result <- ContrastGroupedOverlap(d, registry, groups = "sample", strata = "block",
  id = "cell", positive = "positive", value = "score")
result$summary
#>   sample n_policy n_positive_policy n_control_policy n_evaluable
#> 1  empty        0                 0                0           0
#> 2    one        4                 2                2           3
#>   n_positive_evaluable n_control_evaluable n_unavailable n_strata_policy
#> 1                    0                   0             0               0
#> 2                    1                   2             1               2
#>   n_strata_evaluable n_overlap_strata n_positive_overlap n_control_overlap
#> 1                  0                0                  0                 0
#> 2                  1                1                  1                 2
#>   positive_coverage_policy positive_coverage_evaluable
#> 1                       NA                          NA
#> 2                      0.5                           1
#>   positive_evaluable_fraction control_evaluable_fraction positive_mean
#> 1                          NA                         NA            NA
#> 2                         0.5                          1             4
#>   control_weighted_mean contrast control_weight_sum control_effective_n
#> 1                    NA       NA                  0                  NA
#> 2                     2        2                  1                   2
#>        status availability_status quality_status quality_reasons
#> 1 EMPTY_GROUP         UNAVAILABLE  NOT_REQUESTED                
#> 2     DEFINED             PARTIAL  NOT_REQUESTED                
```
