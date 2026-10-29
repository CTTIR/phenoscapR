# Exact Allocation Tests of Independent Patient Endpoints

Enumerates every allocation with the declared group sizes. The statistic
is the mean in A minus the mean in B; the two-sided p value is the
fraction with absolute statistic at least the observed absolute
statistic. Observed and allocated statistics are computed alike from
values centred on their mean. Two statistics count as tied when they
differ by no more than the rounding of this arithmetic (relative to the
largest centred value) plus the rounding of the stored values (half a
unit in the last place of the largest absolute value), so p values do
not depend on the scale of the values. A shift leaves them unchanged
while the rounding of the shifted values stays below the spacing of
distinct statistics; for example, whole numbers from 0 to 20 for up to
12 patients keep their exact p values up to a shift of 1e13, while
larger shifts can merge distinct statistics into ties. This requires
exchangeability under the null. Observational confounding, paired
designs and stratified randomisation are not addressed by this test.
Repeated images must be aggregated to one endpoint per patient
beforehand.

## Usage

``` r
ExactPatientTests(
  endpoints,
  design,
  hypotheses,
  missingness = "require_complete",
  max_allocations = 1000000L
)
```

## Arguments

- endpoints:

  Data frame with character `endpoint_id`, `patient_id`, numeric
  `value`, and logical `eligible`. At most one row per endpoint and
  patient. NA values or eligibility mark unavailable observations; NaN
  and infinite values are rejected. Extra columns are ignored.

- design:

  Data frame with character `contrast_id`, `patient_id`, and `group`
  (exactly `"A"` or `"B"`). Each patient occurs once per contrast; both
  groups must be nonempty. Patients can belong to multiple contrasts.

- hypotheses:

  Data frame with unique character `hypothesis_id` and character
  `endpoint_id`, `contrast_id`, `family_id`. Every declared row,
  including unavailable tests, remains in the result and family count.

- missingness:

  Only `"require_complete"` is supported. All expected patients must
  have finite eligible endpoint values. No patient is dropped.

- max_allocations:

  Positive integer ceiling on exhaustive allocations, at most one
  million. Exceeding it fails rather than using an approximation.

## Value

A data frame with the registry, expected/evaluable group sizes,
`mean_difference`, `p_value`, allocation count, probability grid step,
and status. Grid step is a resolution bound, not a guaranteed attainable
minimum two-sided p value. Unavailable effects and p values remain NA.

## Examples

``` r
endpoints <- data.frame(endpoint_id = "e", patient_id = letters[1:4],
                        value = 1:4, eligible = TRUE)
design <- data.frame(contrast_id = "c", patient_id = letters[1:4],
                     group = c("A", "A", "B", "B"))
hypotheses <- data.frame(hypothesis_id = "h", endpoint_id = "e",
                         contrast_id = "c", family_id = "f")
ExactPatientTests(endpoints, design, hypotheses)
#>   hypothesis_id endpoint_id contrast_id family_id n_a_expected n_b_expected
#> 1             h           e           c         f            2            2
#>   n_a_evaluable n_b_evaluable mean_difference   p_value allocations
#> 1             2             2              -2 0.3333333           6
#>   probability_grid_step status missingness_policy inference_unit
#> 1             0.1666667  EXACT   require_complete        PATIENT
```
