# Apply Supplied Group Thresholds to Observations

Looks up one supplied threshold per composite group and tests strictly
greater than. Thresholds are not estimated; equality is FALSE.
Eligibility and numeric availability remain explicit. No labels, units
or observation universe are inferred. Unknown groups fail, including
groups of ineligible observations.

## Usage

``` r
ApplyGroupedThresholds(
  data,
  thresholds,
  groups,
  id,
  value,
  threshold,
  eligible
)
```

## Arguments

- data:

  Data frame of observations. Original columns, metadata and row order
  are preserved; inputs are not mutated.

- thresholds:

  Data frame with one threshold per unique group. Extra groups are
  permitted. Supply an explicit NA threshold for an unavailable group.

- groups:

  Nonempty plain character vector of distinct group column names.

- id:

  Plain character scalar naming the observation ID column. Identity is
  unique within groups; IDs may recur across different groups.

- value:

  Plain character scalar naming the observation value column.

- threshold:

  Plain character scalar naming the supplied threshold column. Selected
  numeric columns must be plain integer/double, finite or NA; classed,
  dimensional, complex, NaN and infinite values fail even when
  ineligible.

- eligible:

  Plain character scalar naming a plain logical eligibility column.
  TRUE, FALSE and NA are distinct. Data roles must not overlap;
  threshold must not overlap groups. Keys are plain nonblank character
  values without NA or ASCII 28. Selectors are dimensionless and
  nonblank.

## Value

A data frame with all original observation columns unchanged, followed
by threshold_value (double), threshold_available and value_available
(logical), above_threshold (logical or NA), and threshold_status
(character). Original columns with these reserved names fail. Status
precedence is INELIGIBLE, UNKNOWN_ELIGIBILITY,
MISSING_VALUE_AND_THRESHOLD, MISSING_THRESHOLD, MISSING_VALUE, COMPLETE.
Availability flags retain numeric missingness independently of
eligibility. Only eligible observations with both numbers known receive
a comparison. Empty inputs retain typed outputs; nonempty observations
require complete group-reference coverage. Metadata classes and the
original value storage type are preserved. Units must agree upstream; no
conversion is performed.

## Examples

``` r
d <- data.frame(group = "a", id = c("x", "y"), value = c(1, 2), eligible = TRUE)
r <- data.frame(group = "a", cutoff = 1)
ApplyGroupedThresholds(d, r, "group", "id", "value", "cutoff", "eligible")
#>   group id value eligible threshold_value threshold_available value_available
#> 1     a  x     1     TRUE               1                TRUE            TRUE
#> 2     a  y     2     TRUE               1                TRUE            TRUE
#>   above_threshold threshold_status
#> 1           FALSE         COMPLETE
#> 2            TRUE         COMPLETE
```
