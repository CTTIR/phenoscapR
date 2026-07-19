# List Available Reductions

List Available Reductions

## Usage

``` r
Reductions(object)

# S4 method for class 'SpatialCellData'
Reductions(object)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

Character vector of reduction names.

## Examples

``` r
data(phenoscapR_example)
Reductions(RunPCA(phenoscapR_example, n_pcs = 5))
#> [1] "pca"
```
