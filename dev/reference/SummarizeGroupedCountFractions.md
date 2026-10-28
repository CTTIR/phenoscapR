# Summarize Grouped Subset Counts as Fractions

Computes sum(numerator) / sum(denominator) from supplied subset counts,
without averaging observation fractions or manufacturing absent groups.
Eligibility and the independent sampling unit must be chosen upstream.
IDs must be unique within the complete group key.

## Usage

``` r
SummarizeGroupedCountFractions(data, groups, id, numerator, denominator)
```

## Arguments

- data:

  Data frame of observation keys and subset counts.

- groups:

  Nonempty character vector of distinct group column names.

- id:

  Name of the observation ID column. Group and ID keys must be
  dimensionless nonblank character vectors without NA or ASCII 28
  separators.

- numerator:

  Name of the subset-count column, allowing NA.

- denominator:

  Name of the total-count column, allowing NA.

## Value

Data frame sorted by group keys with integer n_supplied, n_available and
n_unavailable; double numerator_total, denominator_total and fraction;
character status and missing_policy. Status precedence is UNAVAILABLE
(no complete count pairs), PARTIAL (some missing counts),
ZERO_DENOMINATOR, COMPLETE. missing_policy is always "propagate". Empty
input returns a typed empty table. Count totals outside the exact
integer range fail. Fractions use ordinary double division after exact
count accumulation.

## Details

Counts must be plain integer/double vectors (names are permitted), with
no classes or dimensions. Known counts must be finite nonnegative whole
numbers at most 2^53 - 1. Numerators cannot exceed their corresponding
denominators where both are known. NaN is rejected; NA is explicitly
unavailable. Both known-count totals are checked incrementally against
2^53 - 1 before each addition, even when missingness will suppress the
reported totals.

Missingness is always propagated: any missing count suppresses both
totals and the fraction. n_available counts rows with both counts known,
including observed zero counts. A zero denominator total leaves the
fraction unavailable; a zero numerator and positive denominator gives an
observed zero fraction.

## Examples

``` r
d <- data.frame(sample = c("one", "one"), bin = c("a", "b"),
                positive = c(1, 2), total = c(3, 7))
SummarizeGroupedCountFractions(d, "sample", "bin", "positive", "total")
#>   sample n_supplied n_available n_unavailable numerator_total denominator_total
#> 1    one          2           2             0               3                10
#>   fraction   status missing_policy
#> 1      0.3 COMPLETE      propagate
```
