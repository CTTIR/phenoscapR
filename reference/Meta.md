# Get or Set Cell Metadata

Get or Set Cell Metadata

## Usage

``` r
Meta(object)

# S4 method for class 'SpatialCellData'
Meta(object)
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

Data frame of cell metadata.

## Examples

``` r
data(phenoscapR_example)
head(Meta(phenoscapR_example))
#>      cell_id sample_id cell_area phenotype_true
#> 1 tonsil_A_1  tonsil_A       123         B cell
#> 2 tonsil_A_2  tonsil_A       115    T cytotoxic
#> 3 tonsil_A_3  tonsil_A       112     Epithelial
#> 4 tonsil_A_4  tonsil_A        63         B cell
#> 5 tonsil_A_5  tonsil_A       124    T cytotoxic
#> 6 tonsil_A_6  tonsil_A        86     Macrophage
```
