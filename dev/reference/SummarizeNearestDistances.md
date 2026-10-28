# Nearest-Target Distances Summarised per Cell Set

For each declared source set of cell types, finds the Euclidean distance
from every source cell to its nearest target cell (via
[`CrossNNDistance()`](https://cttir.github.io/phenoscapR/dev/reference/CrossNNDistance.md))
and reports the number of source cells, the median distance and the
percentage (or fraction) within each radius (inclusive). Optionally adds
the summed area of all cells (for example Voronoi territories) as tissue
area.

## Usage

``` r
SummarizeNearestDistances(
  cells,
  from,
  to,
  x = "x",
  y = "y",
  type = "type",
  radius = NULL,
  percent = TRUE,
  area = NULL,
  area_divisor = 1
)
```

## Arguments

- cells:

  Cell table with coordinate and type columns.

- from:

  Named list (or named character vector) of source sets: output label to
  cell types. An unnamed character vector uses each type as its own set.
  Sets must be disjoint from each other and from `to`.

- to:

  Character vector of target cell types.

- x, y, type:

  Column names in `cells`.

- radius:

  Optional numeric radii; one output row per set and radius.

- percent:

  Report percentages (`TRUE`) or fractions.

- area:

  Optional column summed over all cells into `area`.

- area_divisor:

  Divisor applied to the summed area (e.g. `1e6` for square micrometres
  to square millimetres).

## Value

A data frame with `from`, `n`, `n_target`, `median_distance`, `radius`,
`within` and optionally `area`.

## Examples

``` r
set.seed(1)
cells <- data.frame(x = runif(200, 0, 100), y = runif(200, 0, 100),
                    type = sample(c("t", "a", "b"), 200, replace = TRUE))
SummarizeNearestDistances(cells, from = list(A = "a", B = "b"), to = "t",
                          radius = 10)
#>   from  n n_target median_distance radius   within
#> 1    A 61       75        5.009221     10 95.08197
#> 2    B 64       75        5.734158     10 89.06250
```
