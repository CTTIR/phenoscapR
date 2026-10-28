# Assemble Registered Paired Summaries

Aligns already computed scalar summaries to an explicit expected group
registry. Computes the first side or first minus second side without
pooling observations or changing the supplied estimator. Choose the
value and count columns appropriate to the estimator, for example
weighted_mean and n_weighted_available from SummarizeGroupedValues().
This is descriptive assembly, not an independence assessment or
inferential test.

## Usage

``` r
AssemblePairedSummaries(
  data,
  registry,
  groups,
  side,
  value,
  count,
  weight_sum = NULL,
  sides = c("A", "B"),
  contrast = c("difference", "first"),
  min_count = 1L
)
```

## Arguments

- data:

  Data frame of precomputed summaries, at most one row per group and
  side. Extra columns are ignored.

- registry:

  Data frame with distinct expected group keys.

- groups:

  Nonempty character vector of distinct group columns. Keys must be
  nonblank character vectors without NA or the reserved ASCII 28
  separator.

- side:

  Name of the character side column.

- value:

  Name of the finite plain integer/double summary column, allowing NA.
  Classed vectors (including factors, dates and integer64) are rejected
  for values, counts, weight totals and min_count; names are permitted.

- count:

  Name of the nonnegative whole-number count column, allowing NA.

- weight_sum:

  Optional name of a nonnegative finite numeric denominator column,
  allowing NA. Missing-side totals remain NA, not an observed zero.

- sides:

  Two distinct nonblank side labels, in subtraction order.

- contrast:

  Either "difference" (first minus second) or "first".

- min_count:

  Positive whole-number minimum for each required side.

## Value

Data frame in registry order with keys, first/second presence, values,
counts and weight totals, value, status, contrast, side labels and
minimum. Status precedence is MISSING_SIDE, UNKNOWN_COUNT,
INSUFFICIENT_COUNT, UNAVAILABLE_VALUE, COMPLETE, considering required
sides only. An empty registry with empty data returns a typed empty
table. Unknown group/side keys, duplicates, malformed numbers and
arithmetic overflow fail.

## Details

Absent sides retain NA values, zero counts and a false presence flag.
Observed NA counts remain unknown. Optional weight totals are provenance
only and never used to reconstruct counts or recompute supplied values.
The registry defines output order; extra registry columns are ignored.

## Examples

``` r
d <- data.frame(sample = c("one", "one"), arm = c("A", "B"),
                average = c(4, 1), n = c(3, 2))
AssemblePairedSummaries(d, data.frame(sample = c("one", "two")),
                        "sample", "arm", "average", "n")
#>   sample first_present first_value first_count first_weight_sum second_present
#> 1    one          TRUE           4           3               NA           TRUE
#> 2    two         FALSE          NA           0               NA          FALSE
#>   second_value second_count second_weight_sum value       status   contrast
#> 1            1            2                NA     3     COMPLETE difference
#> 2           NA            0                NA    NA MISSING_SIDE difference
#>   first_side second_side min_count
#> 1          A           B         1
#> 2          A           B         1
```
