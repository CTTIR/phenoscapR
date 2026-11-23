# Ripley's K Function

Computes Ripley's K function to assess spatial clustering or dispersion
at multiple scales. The observation window is inferred as the bounding
box of the retained points, after optional phenotype selection; it is
not an independently measured tissue frame. A positive finite
bounding-box area is required, including within each sample when
computing by sample.

## Usage

``` r
RipleysK(
  object,
  r_seq = NULL,
  target = NULL,
  correction = c("none", "border", "translation"),
  by_sample = FALSE
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- r_seq:

  Numeric vector of finite, nonnegative radii in coordinate units, or
  `NULL` for 50 radii from zero to a quarter of the shorter side of the
  bounding box.

- target:

  Character or `NULL`. Restrict to a phenotype.

- correction:

  Character. Edge correction: `"none"` (default), `"border"`
  (reduced-sample), or `"translation"` (each pair weighted by the
  inverse window/translate overlap; rigorous for rectangular windows).
  Pairs with zero overlap contribute zero to the translation estimate;
  radii with no eligible border centres return `NA`.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list (one entry per
  sample). Default `FALSE`; otherwise a single sample is required.

## Value

A data frame with columns `r`, `K`, `L`, and `expected`.

## Details

With `n` retained points in a window of area `A`, the uncorrected and
translation-corrected estimates scale the (weighted) count of ordered
point pairs within distance `r` by `A / n^2` and `A^2 / n^2`; the
squared intensity is thus estimated by `n^2 / A^2`, not by
`n (n - 1) / A^2`. The border estimate divides the pair count of the
centres at least `r` from the window edge by their number and by the
intensity `n / A`. Under complete spatial randomness `K` equals
`expected = pi r^2` and `L = sqrt(K / pi) - r` is zero.

## References

Ripley, B. D. (1977). Modelling spatial patterns. *Journal of the Royal
Statistical Society: Series B (Methodological)*, 39(2), 172-192.
[doi:10.1111/j.2517-6161.1977.tb01615.x](https://doi.org/10.1111/j.2517-6161.1977.tb01615.x)

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
obj <- CreateSpatialObject(counts, coords)
RipleysK(obj)
#> <phenoscapR> Ripley's K / none correction
#>   50 radii from 0 to 45.2
#>   L(r) range: [-5.17, 1.96]  (>0 clustered, <0 dispersed)
#>           r K          L  expected
#> 1 0.0000000 0  0.0000000  0.000000
#> 2 0.9232469 0 -0.9232469  2.677846
#> 3 1.8464938 0 -1.8464938 10.711384
#> 4 2.7697408 0 -2.7697408 24.100614
```
