# Get Expression Data

Retrieve raw counts or normalised data from a SpatialCellData object.

## Usage

``` r
GetData(object, slot = "data")

# S4 method for class 'SpatialCellData'
GetData(object, slot = "data")
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- slot:

  Character. `"counts"` for raw data or `"data"` (default) for
  normalised data.

## Value

A numeric matrix (cells x markers).

## Examples

``` r
data(phenoscapR_example)
GetData(phenoscapR_example, slot = "counts")[1:3, ]
#>            CD3      CD4       CD8       CD20      CD68     PanCK     FoxP3
#> [1,]  1.232687 1.929555  1.886467 12.8077449 0.9628334  1.030865 0.9204028
#> [2,] 29.873100 2.292387 23.131630  1.4714869 0.9444263  1.081335 1.4091575
#> [3,]  1.076436 1.117645  1.282085  0.7691188 0.8374219 16.982042 0.8732379
#>          Ki67
#> [1,] 2.443624
#> [2,] 1.486877
#> [3,] 5.307441
```
