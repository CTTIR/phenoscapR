# Exact Paired Sign-Flip Tests of Within-Subject Differences

For each declared group of rows, tests whether paired differences are
symmetric about zero with the exact Wilcoxon signed-rank test over all
\\2^n\\ sign assignments, together with the exact two-sided sign test
and, optionally, a Clopper-Pearson interval for the fraction of subjects
whose difference lies in an expected direction. Leave-one-subject-out
results can be requested instead of the full tests.

## Usage

``` r
ExactPairedTests(
  data,
  value,
  groups = NULL,
  id = NULL,
  expected = NULL,
  family = NULL,
  omit = c("none", "each"),
  conf_level = 0.95,
  max_n = 500L
)
```

## Arguments

- data:

  Data frame in long form: one row per subject and test.

- value:

  Name of the numeric difference column (for a one-sample test, the
  values themselves).

- groups:

  Optional names of columns that define separate tests. `NULL` treats
  all rows as one test. Output groups follow first appearance.

- id:

  Optional subject column; required for `omit = "each"`. Subjects must
  be unique within a group.

- expected:

  Optional expected direction: `"less"` or `"greater"` for every group,
  or the name of a column holding `"less"`/`"greater"` (constant within
  a group). Adds the number of subjects in that direction and its
  Clopper-Pearson interval.

- family:

  Optional columns defining multiplicity families; adds `family_id`
  (values joined by `" :: "`). `hypothesis_id` joins the group values
  the same way. Both are ready for
  [`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/dev/reference/AdjustPatientFamilies.md).

- omit:

  `"none"` (full tests) or `"each"`: one row per group and omitted
  subject (all subjects of the group, in data order), with the omitted
  subject in column `omitted`.

- conf_level:

  Confidence level of the direction interval.

- max_n:

  Largest number of nonzero differences accepted.

## Value

A data frame with the group columns, `n_available`, `n_nonzero`,
`n_zero`, `positive`, `negative`, `median_difference` and
`mean_difference` (of the nonzero differences), `signed_rank_sum`,
`p_value` (signed-rank), `sign_p_value`, `status`, optionally
`expected`, `expected_direction`, `direction_ci_low`,
`direction_ci_high`, `conf_level`, and `hypothesis_id` (plus
`family_id`).

## Details

Non-finite differences are unavailable; zero differences are excluded
from the signed-rank and sign tests (they still count as available
subjects and as not being in the expected direction). Ranks of absolute
differences use midranks for ties. The two-sided p value is the fraction
of sign assignments whose absolute signed-rank sum is at least the
observed one. It is computed by dynamic programming over twice the
midranks (integers), so it equals full enumeration exactly for up to 52
nonzero differences without enumerating them.

## See also

[`PairedDifferences()`](https://cttir.github.io/phenoscapR/dev/reference/PairedDifferences.md),
[`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/dev/reference/AdjustPatientFamilies.md)

## Examples

``` r
d <- data.frame(test = rep(c("a", "b"), each = 6), subject = rep(1:6, 2),
                difference = c(-3, -1, -2, -5, 1, -4, 2, -1, 3, 0, 1, 2))
ExactPairedTests(d, "difference", groups = "test", id = "subject",
                 expected = "less")
#>   test n_available n_nonzero n_zero positive negative median_difference
#> 1    a           6         6      0        1        5              -2.5
#> 2    b           6         5      1        4        1               2.0
#>   mean_difference signed_rank_sum p_value sign_p_value status expected
#> 1       -2.333333             -18 0.09375      0.21875  EXACT     less
#> 2        1.400000              12 0.18750      0.37500  EXACT     less
#>   expected_direction direction_ci_low direction_ci_high conf_level
#> 1                  5      0.358765421         0.9957893       0.95
#> 2                  1      0.004210745         0.6412346       0.95
#>   hypothesis_id
#> 1             a
#> 2             b
ExactPairedTests(d, "difference", groups = "test", id = "subject",
                 omit = "each")
#>    test omitted n_available n_nonzero n_zero positive negative
#> 1     a       1           5         5      0        1        4
#> 2     a       2           5         5      0        1        4
#> 3     a       3           5         5      0        1        4
#> 4     a       4           5         5      0        1        4
#> 5     a       5           5         5      0        0        5
#> 6     a       6           5         5      0        1        4
#> 7     b       1           5         4      1        3        1
#> 8     b       2           5         4      1        4        0
#> 9     b       3           5         4      1        3        1
#> 10    b       4           5         5      0        4        1
#> 11    b       5           5         4      1        3        1
#> 12    b       6           5         4      1        3        1
#>    median_difference mean_difference signed_rank_sum p_value sign_p_value
#> 1               -2.0           -2.20             -12  0.1875       0.3750
#> 2               -3.0           -2.60             -13  0.1250       0.3750
#> 3               -3.0           -2.40             -12  0.1875       0.3750
#> 4               -2.0           -1.80             -12  0.1875       0.3750
#> 5               -3.0           -3.00             -15  0.0625       0.0625
#> 6               -2.0           -2.00             -12  0.1875       0.3750
#> 7                1.5            1.25               7  0.3750       0.6250
#> 8                2.0            2.00              10  0.1250       0.1250
#> 9                1.5            1.00               7  0.3750       0.6250
#> 10               2.0            1.40              12  0.1875       0.3750
#> 11               2.0            1.50               8  0.2500       0.6250
#> 12               1.5            1.25               7  0.3750       0.6250
#>    status hypothesis_id
#> 1   EXACT        a :: 1
#> 2   EXACT        a :: 2
#> 3   EXACT        a :: 3
#> 4   EXACT        a :: 4
#> 5   EXACT        a :: 5
#> 6   EXACT        a :: 6
#> 7   EXACT        b :: 1
#> 8   EXACT        b :: 2
#> 9   EXACT        b :: 3
#> 10  EXACT        b :: 4
#> 11  EXACT        b :: 5
#> 12  EXACT        b :: 6
```
