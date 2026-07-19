# Get Active Cell Identities

Returns the phenotype labels if set, otherwise sample identities.

## Usage

``` r
Idents(object)

# S4 method for class 'SpatialCellData'
Idents(object)
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

A character vector.

## Examples

``` r
data(phenoscapR_example)
table(Idents(phenoscapR_example))
#> 
#> tonsil_A tonsil_B 
#>      320      320 
```
