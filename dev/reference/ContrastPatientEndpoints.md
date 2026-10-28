# Exact Two-Group Contrasts for a Registry of Patient Endpoints

Runs
[`ExactPatientTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPatientTests.md)
for every row of a hypothesis registry (endpoint, contrast, family) on a
wide patient table (one row per patient, one column per endpoint).
Contrast arms are declared as sets of patient groups. Two missingness
policies are offered:

## Usage

``` r
ContrastPatientEndpoints(
  data,
  registry,
  contrasts,
  id,
  group,
  endpoint = "endpoint",
  contrast = "contrast",
  family = "family",
  missingness = c("complete_case", "require_complete"),
  hypothesis_prefix = "h",
  max_allocations = 1000000L
)
```

## Arguments

- data:

  Wide patient table with the `id`, `group` and endpoint columns.

- registry:

  Data frame with one row per hypothesis and the `endpoint`, `contrast`
  and `family` columns. Extra columns are ignored.

- contrasts:

  Named list: contrast name to a list with character vectors `A` and `B`
  of patient groups (disjoint).

- id, group:

  Patient identifier and patient group columns of `data`.

- endpoint, contrast, family:

  Column names in `registry`.

- missingness:

  `"complete_case"` or `"require_complete"`.

- hypothesis_prefix:

  Prefix of the generated `hypothesis_id` (followed by the registry row
  number).

- max_allocations:

  Passed to
  [`ExactPatientTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPatientTests.md).

## Value

A data frame with the registry columns, `hypothesis_id`, `family_id`
(`family :: contrast`), expected and evaluable arm sizes,
`mean_difference`, `p_value`, `allocations`, `status` and `missingness`,
in registry order. Pass it to
[`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/dev/reference/AdjustPatientFamilies.md).

## Details

- `"complete_case"`: each hypothesis uses only patients with a finite
  value; a hypothesis whose arm has no such patient is unavailable. This
  reproduces tables that silently drop missing patients.

- `"require_complete"`: every patient of both arms must have a finite
  value, otherwise the hypothesis is unavailable (no patient is
  dropped).

Each hypothesis receives its own design, so a registry may repeat an
endpoint-contrast pair in different families. The effect is the mean of
arm A minus the mean of arm B.

## Examples

``` r
d <- data.frame(patient = paste0("p", 1:6), arm = rep(c("x", "y"), each = 3),
                e1 = c(1, 2, 3, 6, 7, NA), e2 = c(5, 4, 6, 1, 2, 3))
reg <- data.frame(endpoint = c("e1", "e2"), contrast = "x vs y", family = "f")
ctr <- list("x vs y" = list(A = "x", B = "y"))
ContrastPatientEndpoints(d, reg, ctr, "patient", "arm")
#>   endpoint contrast family hypothesis_id   family_id n_a_expected n_b_expected
#> 1       e1   x vs y      f            h1 f :: x vs y            3            3
#> 2       e2   x vs y      f            h2 f :: x vs y            3            3
#>   n_a_evaluable n_b_evaluable mean_difference p_value allocations status
#> 1             3             2            -4.5     0.1          10  EXACT
#> 2             3             3             3.0     0.1          20  EXACT
#>     missingness
#> 1 complete_case
#> 2 complete_case
ContrastPatientEndpoints(d, reg, ctr, "patient", "arm",
                         missingness = "require_complete")
#>   endpoint contrast family hypothesis_id   family_id n_a_expected n_b_expected
#> 1       e1   x vs y      f            h1 f :: x vs y            3            3
#> 2       e2   x vs y      f            h2 f :: x vs y            3            3
#>   n_a_evaluable n_b_evaluable mean_difference p_value allocations
#> 1             3             2              NA      NA          20
#> 2             3             3               3     0.1          20
#>                   status      missingness
#> 1 UNAVAILABLE_INCOMPLETE require_complete
#> 2                  EXACT require_complete
```
