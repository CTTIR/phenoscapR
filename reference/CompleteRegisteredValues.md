# Complete Numeric Observations Against an Explicit Registry

Matches one numeric observation to each caller-supplied composite
registry key. The registry defines the entire row universe and its
order. No Cartesian product, observed group, eligibility rule or
biological absence is inferred. The required absent_value applies only
to absent rows, never to observed NA.

## Usage

``` r
CompleteRegisteredValues(data, registry, keys, value, absent_value)
```

## Arguments

- data:

  Data frame containing the selected keys and numeric value column.

- registry:

  Data frame with every expected composite key, in output order.
  Additional metadata columns retain their values and classes. It must
  not contain the selected value column or observed, status,
  absent_value columns.

- keys:

  Nonempty plain character vector of distinct key column names. Key
  columns must be plain dimensionless nonblank character vectors without
  NA or the reserved ASCII 28 separator.

- value:

  Plain character scalar naming the value column, distinct from keys and
  reserved output names. Values must be plain integer/double vectors,
  finite or NA. Complex, classed, dimensional, infinite and NaN values
  fail. Names on numeric vectors are permitted.

- absent_value:

  Required plain integer/double scalar, finite or NA_real\_. No default
  is supplied. Choosing zero explicitly does not impute observed NA.

## Value

A data frame with registry columns, the selected value (double),
observed (logical), status (character), and absent_value (double
policy). Status is OBSERVED for known matched values, OBSERVED_MISSING
for matched NA, ABSENT_FILLED for absent rows with finite fill, or
ABSENT_UNAVAILABLE for absent rows with NA fill. Row count and order
equal the registry. Empty registry requires empty data and returns a
typed empty result. Provenance distinguishes observed zero, filled zero,
observed NA and absent NA.

## Details

Both tables require unique composite keys. Unknown data keys fail rather
than being discarded. Registry metadata is authoritative and carried
unchanged; extra data columns are ignored. Inputs are not mutated.
Values are normalized to double; no arithmetic or aggregation is
performed.

## Examples

``` r
d <- data.frame(bin = c("a", "b"), fraction = c(0.5, NA_real_))
expected <- data.frame(bin = c("a", "b", "c"), sample = "one")
CompleteRegisteredValues(d, expected, "bin", "fraction", absent_value = 0)
#>   bin sample fraction observed           status absent_value
#> 1   a    one      0.5     TRUE         OBSERVED            0
#> 2   b    one       NA     TRUE OBSERVED_MISSING            0
#> 3   c    one      0.0    FALSE    ABSENT_FILLED            0
```
