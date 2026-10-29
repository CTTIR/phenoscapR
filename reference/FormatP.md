# Format P Values for Figures

Two significant digits from 0.001 upwards, scientific notation below
(\\4.9 \times 10^{-4}\\ after
[`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md))
and `"n.e."` (not evaluable) for missing or non-finite values. This is
the C format `%.2g` / `%.1e` of common figure code.

## Usage

``` r
FormatP(p)
```

## Arguments

- p:

  Numeric vector of P values.

## Value

Character vector; values below 0.001 use the plain form `"4.9e-04"`,
which
[`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md)
turns into a power of ten.

## Examples

``` r
FormatP(c(0.0039, 0.055, 0.5, 4.9e-4, NA))
#> [1] "0.0039"  "0.055"   "0.5"     "4.9e-04" "n.e."   
```
