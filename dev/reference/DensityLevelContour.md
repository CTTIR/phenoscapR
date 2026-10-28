# Density Level Region of Each Group on an Embedding

For each group (for example each patient), counts the points in a `bins`
x `bins` histogram over the display limits, smooths the counts with a
Gaussian kernel of `sigma` bins (mirror boundaries, kernel truncated at
`truncate` sigma), and finds the density level whose superlevel region
holds the fraction `level` of the smoothed mass: the smallest bin value
that is still needed when bins are added from the highest down until
their sum reaches `level` times the total. The region above that level
is returned as filled bands and outline paths on the bin centres.

## Usage

``` r
DensityLevelContour(
  data,
  x = "x",
  y = "y",
  group = "group",
  limits,
  filter = NULL,
  bins = 90,
  sigma = 2,
  level = 0.9,
  truncate = 4,
  groups = NULL,
  carry = NULL,
  slot_within = NULL,
  label_from = NULL,
  label_sub = NULL
)
```

## Arguments

- data:

  Data frame with coordinates and a group column.

- x, y, group:

  Column names.

- limits:

  Display limits `c(xmin, xmax, ymin, ymax)` or a data frame from
  [`EmbeddingLimits()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingLimits.md);
  the histogram spans them exactly.

- filter:

  Optional named list of columns and values selecting the points used.

- bins:

  Bins per axis.

- sigma:

  Kernel standard deviation in bins.

- level:

  Fraction of the smoothed mass inside the region.

- truncate:

  Kernel half-width in standard deviations.

- groups:

  Optional group order (also the order of slots).

- carry:

  Columns constant within a group copied to the output (for example the
  clinical group).

- slot_within:

  Optional carried column: slots count groups within each of its values
  (for example patients within a clinical group).

- label_from, label_sub:

  Column for the key label (default the group) and an optional regular
  expression replacement `c(pattern, replacement)` applied to it.

## Value

A data frame with the group column (named as in `data`), `slot`,
`label`, carried columns, `kind` (`"band"`, `"line"`), `piece`, `x`,
`y`, `level` (the density level) and `n` (points of the group).

## Examples

``` r
set.seed(3)
d <- data.frame(x = rnorm(400), y = rnorm(400), g = rep(c("a", "b"), 200))
head(DensityLevelContour(d, group = "g", limits = c(-4, 4, -4, 4), bins = 30))
#>   g slot label kind piece          x        y     level   n
#> 1 a    1     a band     1  0.4000000 2.393213 0.1904043 200
#> 2 a    1     a band     1  0.1333333 2.481399 0.1904043 200
#> 3 a    1     a band     1 -0.1333333 2.504117 0.1904043 200
#> 4 a    1     a band     1 -0.4000000 2.480293 0.1904043 200
#> 5 a    1     a band     1 -0.6666667 2.420837 0.1904043 200
#> 6 a    1     a band     1 -0.9333333 2.323576 0.1904043 200
```
