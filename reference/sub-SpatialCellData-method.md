# Subset a SpatialCellData Object

Subset a SpatialCellData Object

## Usage

``` r
# S4 method for class 'SpatialCellData'
x[i, j, drop = FALSE]
```

## Arguments

- x:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object. Supplying cell indices clears cached spatial results and the
  derived `nn_distance` and `density` metadata columns. Recompute these
  after filtering, reordering or duplicating cells. Marker-only
  subsetting preserves spatial results; dimensional reductions are
  subset by cell. Phenotype, cluster, neighbourhood and domain labels
  remain frozen annotations from the original fit for plotting and
  comparison; they do not describe a refit on the subset. Neither labels
  nor retained reductions are refitted. The metadata attribute
  `frozen_spatial_labels` records each retained spatial label's original
  fit row count; further subsetting preserves it. Recomputing an
  assignment clears its frozen-label record. Recompute spatial
  assignments to describe the new neighbourhoods. Marker-only subsetting
  does not revalidate expression-dependent cached analyses.

- i:

  Cell indices (integer or logical). Missing values are not allowed; use
  [`which()`](https://rdrr.io/r/base/which.html) or `%in%` to select
  cells from a column that holds `NA`.

- j:

  Marker indices (integer, logical, or character).

- drop:

  Ignored.

## Value

A subsetted `SpatialCellData` object.

## Examples

``` r
data(phenoscapR_example)
first <- phenoscapR_example[1:100, ]
dim(first)
#> [1] 100   8
one_sample <- phenoscapR_example[
  phenoscapR_example$sample_id == phenoscapR_example$sample_id[1], ]
NCells(one_sample)
#> [1] 320
two_markers <- phenoscapR_example[, Markers(phenoscapR_example)[1:2]]
Markers(two_markers)
#> [1] "CD3" "CD4"
```
