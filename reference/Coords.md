# Get Spatial Coordinates

Get Spatial Coordinates

## Usage

``` r
Coords(object)

# S4 method for class 'SpatialCellData'
Coords(object)
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

Data frame with columns `x` and `y`.

## Examples

``` r
data(phenoscapR_example)
head(Coords(phenoscapR_example))
#>          x        y
#> 1 415.2129 760.4836
#> 2 674.0587 434.7913
#> 3 747.2101 353.3104
#> 4 379.1923 620.3793
#> 5 626.6378 308.7950
#> 6 223.4583 590.1055
```
