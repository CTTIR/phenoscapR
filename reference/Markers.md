# Get Marker Names

Get Marker Names

## Usage

``` r
Markers(object)

# S4 method for class 'SpatialCellData'
Markers(object)
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

Character vector.

## Examples

``` r
data(phenoscapR_example)
Markers(phenoscapR_example)
#> [1] "CD3"   "CD4"   "CD8"   "CD20"  "CD68"  "PanCK" "FoxP3" "Ki67" 
```
