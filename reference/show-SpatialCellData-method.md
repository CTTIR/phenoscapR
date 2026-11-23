# Show a SpatialCellData Object

Show a SpatialCellData Object

## Usage

``` r
# S4 method for class 'SpatialCellData'
show(object)
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

Invisibly `NULL`; called for printing a summary of the object.

## Examples

``` r
data(phenoscapR_example)
phenoscapR_example
#> A SpatialCellData object
#>   640 cells across 2 samples
#>   Markers: CD3, CD4, CD8, CD20, CD68, ... (8 total) 
#>   Normalised: FALSE 
#>   Project: phenoscapR example (tonsil, simulated) 
```
