# Exact Patient Omission Diagnostics for Declared Hypotheses

Computes full tests once through `ExactPatientTests`, then evaluates
explicitly declared patient omissions through the same API. An
incomplete full hypothesis cannot become testable by omitting a missing
or ineligible patient. No clinical groups, independence, omission set or
multiplicity policy is inferred.

## Usage

``` r
LeaveOnePatientOut(
  endpoints,
  design,
  hypotheses,
  omissions,
  missingness = "require_complete",
  max_allocations = 1000000L
)
```

## Arguments

- endpoints, design, hypotheses:

  Inputs with the `ExactPatientTests` schemas. Selected columns must be
  dimensionless vectors. Extra columns are ignored.

- omissions:

  Data frame with character `hypothesis_id` and `patient_id`. Each pair
  must be unique; the patient must belong to that hypothesis's contrast
  design. Zero rows are allowed with typed character columns.

- missingness:

  Only `"require_complete"` is supported.

- max_allocations:

  Allocation ceiling passed unchanged to full and reduced exact tests.
  No random approximation or changed numerical rule is used.

## Value

List with `full_tests` (the complete exact-test result) and `omissions`
(one row per supplied omission in its original order). Omission rows
retain hypothesis keys and full results, reduced
expected/supplied/evaluable counts, the omitted arm, an explicit
`empty_arm` flag, reduced results and effect direction diagnostics.
`reduced_status` is UNAVAILABLE_FULL_INCOMPLETE, UNAVAILABLE_EMPTY_ARM
or EXACT, in that priority order. Reduced allocations, grid step, effect
and p value are NA when no reduced test is performed. Supplied counts
include present endpoint rows regardless of eligibility; evaluable
counts require a finite value and nonmissing TRUE eligibility.
Full-incomplete omissions do not execute reduced tests. Zero effects
have direction ZERO; direction preservation is NA when either effect is
missing. Arithmetic overflow in an effect change fails rather than
returning Inf.
