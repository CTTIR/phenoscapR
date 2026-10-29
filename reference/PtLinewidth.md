# Convert Points to a 'ggplot2' Line Width

'ggplot2' draws a line width of 1 as 0.75 mm (R's line width unit is
1/96 inch); this converts a width given in typographic points.

## Usage

``` r
PtLinewidth(pt)
```

## Arguments

- pt:

  Numeric line width in points.

## Value

Numeric 'ggplot2' `linewidth`.

## Examples

``` r
PtLinewidth(0.5)
#> [1] 0.2343065
```
