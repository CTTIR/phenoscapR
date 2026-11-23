# Access Metadata Columns with \$

Access Metadata Columns with \$

## Usage

``` r
# S4 method for class 'SpatialCellData'
x$name
```

## Arguments

- x:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- name:

  Column name.

## Value

The requested metadata column.

## Examples

``` r
data(phenoscapR_example)
table(phenoscapR_example$sample_id)
#> 
#> tonsil_A tonsil_B 
#>      320      320 
```
