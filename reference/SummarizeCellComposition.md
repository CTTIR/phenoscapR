# Cell-Type Composition, Densities and Declared State Fractions of a Section

Counts cells per registered type, expresses them as fractions of all
cells and as densities per unit area, and adds declared subset fractions
such as "marker-positive cells among cells of some types". Fractions are
computed from exact counts with
[`SummarizeGroupedCountFractions()`](https://cttir.github.io/phenoscapR/reference/SummarizeGroupedCountFractions.md).

## Usage

``` r
SummarizeCellComposition(
  cells,
  type,
  levels,
  area = NULL,
  area_divisor = 1,
  fractions = NULL,
  percent = TRUE,
  prefix = c(fraction = "fraction|", density = "density|"),
  totals = c(cells = "cells", area = "area")
)
```

## Arguments

- cells:

  Cell table (one section).

- type:

  Cell-type column; every value must be in `levels`.

- levels:

  Character vector: the complete type registry (zero counts are
  reported).

- area:

  Optional column summed over all cells into the section area; adds
  density rows.

- area_divisor:

  Divisor applied to the summed area.

- fractions:

  Optional named list of subset fractions. Each element is a list with
  `numerator` (types), `denominator` (types) and optional `flag` (name
  of a logical or 0/1 column that numerator cells must have set).

- percent:

  Express fractions in percent.

- prefix:

  Named character vector with prefixes of the `fraction` and `density`
  endpoint names (followed by the type).

- totals:

  Named character vector: endpoint names of the `cells` and `area`
  totals.

## Value

A data frame with `endpoint`, `measure` (`"fraction"`, `"density"`,
`"subset_fraction"` or `"total"`), `type` (for per-type rows),
`numerator`, `denominator` and `value`.

## Examples

``` r
cells <- data.frame(type = c("t", "t", "a", "b", "t"), pos = c(1, 0, 0, 1, 1),
                    area = c(10, 12, 9, 11, 8))
SummarizeCellComposition(cells, "type", c("t", "a", "b", "c"), area = "area",
  fractions = list("pos % t" = list(numerator = "t", denominator = "t",
                                    flag = "pos")))
#>      endpoint         measure type numerator denominator    value
#> 1  fraction|t        fraction    t         3           5 60.00000
#> 2  fraction|a        fraction    a         1           5 20.00000
#> 3  fraction|b        fraction    b         1           5 20.00000
#> 4  fraction|c        fraction    c         0           5  0.00000
#> 5     pos % t subset_fraction <NA>         2           3 66.66667
#> 6   density|t         density    t         3          50  0.06000
#> 7   density|a         density    a         1          50  0.02000
#> 8   density|b         density    b         1          50  0.02000
#> 9   density|c         density    c         0          50  0.00000
#> 10      cells           total <NA>         5          NA  5.00000
#> 11       area           total <NA>        NA          NA 50.00000
```
