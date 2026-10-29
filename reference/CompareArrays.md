# Compare Table Columns or Arrays with Arrays of a NumPy Archive

Compares observed vectors or matrices (taken from columns of a table or
elements of a list) with reference arrays, read from an `.npz` archive
with
[`cellspecR::cs_read_npz()`](https://cttir.github.io/cellspecR/reference/cs_read_npy.html)
or given as a list. Shapes must agree; values are compared exactly or
within an absolute tolerance.

## Usage

``` r
CompareArrays(observed, reference, arrays, tolerance = 0, check = "arrays")
```

## Arguments

- observed:

  A data frame or named list.

- reference:

  Path to an `.npz` archive, or a named list of arrays.

- arrays:

  Named list: reference array name to the observed column(s) or element.
  Several columns are bound into a matrix in the given order.

- tolerance:

  Absolute tolerance (numbers).

- check:

  Label stored in column `check`.

## Value

A data frame with one row per array: `check`, `row_key` (array name),
`array`, `observed_dim`, `reference_dim`, `reference_type`, `n_values`,
`n_different`, `max_difference`, `tolerance`, `matches` and `status`
(`MATCH`, `MISMATCH`, `SHAPE_MISMATCH`).

## Examples

``` r
obs <- data.frame(a = 1:3, b = c(0, 1, 0), z = c(0.5, 1.5, 2.5))
ref <- list(counts = cbind(1:3, c(0, 1, 0)), z = c(0.5, 1.5, 2.5))
CompareArrays(obs, ref, list(counts = c("a", "b"), z = "z"))
#>    check row_key  array observed_dim reference_dim reference_type n_values
#> 1 arrays  counts counts          3x2           3x2         double        6
#> 2 arrays       z      z            3             3         double        3
#>   n_different max_difference tolerance matches status
#> 1           0              0         0    TRUE  MATCH
#> 2           0              0         0    TRUE  MATCH
```
