# Format a Patient-Level Statistic Line

Builds the short statistic text placed above a panel, for example
`"11/12 patients; p = 0.0015"` or `"+3.4; p = 0.021; q = 0.18"`, before
typesetting.

## Usage

``` r
FormatStatistic(
  p,
  k = NULL,
  n = NULL,
  q = NULL,
  estimate = NULL,
  digits = 1,
  unit = "patients"
)
```

## Arguments

- p:

  P value.

- k, n:

  Patients in the expected direction and evaluable patients; omit both
  for a contrast line.

- q:

  Optional adjusted P value.

- estimate:

  Optional signed effect shown first, with `digits` decimals and a true
  minus sign.

- digits:

  Decimals of `estimate`.

- unit:

  Optional text after the patient count, default `"patients"`.

## Value

Character vector.

## Examples

``` r
FormatStatistic(0.0015, k = 11, n = 12)
#> [1] "11/12 patients; p = 0.0015"
FormatStatistic(0.021, q = 0.18, estimate = -3.42)
#> [1] "−3.4; p = 0.021; q = 0.18"
```
