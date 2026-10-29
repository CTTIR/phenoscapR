# Bootstrap Percentile Interval of a Median

Resamples the finite values of each group with replacement and reports
the percentile interval of the resampled medians (quantile type 7, which
is NumPy's default linear percentile). Draws come from R's
Mersenne-Twister generator with a declared seed, or from supplied
resampling indices (for example indices archived from another
implementation), so that the interval can be reproduced exactly.

## Usage

``` r
BootstrapMedianInterval(
  data,
  value,
  groups = NULL,
  n_boot = 10000L,
  conf_level = 0.95,
  seed = NULL,
  reseed = TRUE,
  indices = NULL,
  index_base = 1L
)
```

## Arguments

- data:

  Data frame in long form.

- value:

  Numeric value column.

- groups:

  Optional group columns; one interval per group.

- n_boot:

  Number of resamples.

- conf_level:

  Interval coverage.

- seed:

  Optional whole-number seed. With `reseed = TRUE` every group starts
  from this seed (as a per-call generator would); otherwise groups share
  one stream in output order. The caller's random stream is restored.

- reseed:

  See `seed`.

- indices:

  Optional supplied draws: an integer matrix with `n_boot` rows and one
  column per finite value (a single group), or a named list of such
  matrices keyed by `hypothesis_id`-style group labels (group values
  joined by `" :: "`). Each row is one resample.

- index_base:

  `1` (R) or `0` (zero-based archived indices).

## Value

A data frame with the group columns, `n`, `median`, `lower`, `upper`,
`conf_level`, `n_boot`, `seed` and `draws` (`"R_MERSENNE_TWISTER"` or
`"SUPPLIED"`).

## Examples

``` r
d <- data.frame(g = rep(c("a", "b"), each = 8), v = c(1:8, (1:8)^2))
BootstrapMedianInterval(d, "v", "g", n_boot = 2000, seed = 42)
#>   g n median lower upper conf_level n_boot seed              draws
#> 1 a 8    4.5     2   6.5       0.95   2000   42 R_MERSENNE_TWISTER
#> 2 b 8   20.5     4  42.5       0.95   2000   42 R_MERSENNE_TWISTER
```
