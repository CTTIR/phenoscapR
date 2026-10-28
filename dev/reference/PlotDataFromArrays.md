# Table from a List of Arrays

Turns a named list of equally long arrays, for example the arrays of a
NumPy `.npz` archive, into a data frame. Given a file path instead of a
list, only the arrays needed are read with
[`cellspecR::cs_read_npz()`](https://cttir.github.io/cellspecR/reference/cs_read_npy.html)
(pure R). One-dimensional arrays become columns, the columns of matrices
become further columns, arrays defined only for some rows (`masked`) are
expanded with `NA`, and rows can be restricted to a logical array.

## Usage

``` r
PlotDataFromArrays(
  arrays,
  columns = NULL,
  matrices = NULL,
  masked = NULL,
  keep = NULL,
  row_id = NULL,
  row_base = 0L,
  row_first = FALSE
)
```

## Arguments

- arrays:

  Named list of vectors and matrices with one row per record, or the
  path of an `.npz` archive.

- columns:

  Names of one-dimensional arrays to keep; a named vector or list
  renames them (new name = array name). Default all vectors of the
  record length.

- matrices:

  Named list: for each matrix, either the new column names or
  `list(names_from = "<array>", prefix = "")` taking the names from a
  character array.

- masked:

  Named list: output column (as named in `columns`) to the name of the
  logical array marking the rows its values belong to.

- keep:

  Optional name of a logical array; only rows where it is `TRUE` are
  returned.

- row_id:

  Optional name of a column holding the position of each row in the
  arrays (before `keep`).

- row_base:

  Position of the first row (0 or 1).

- row_first:

  Put the `row_id` column first instead of last.

## Value

A data frame.

## See also

Other plot-data builders:
[`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md),
[`PlotDataConstant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataConstant.md),
[`PlotDataCount()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCount.md),
[`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCrossShares.md),
[`PlotDataDirection()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDirection.md),
[`PlotDataDominant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDominant.md),
[`PlotDataJoin()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataJoin.md),
[`PlotDataKeyColours()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataKeyColours.md),
[`PlotDataLabels()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLabels.md),
[`PlotDataLonger()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLonger.md),
[`PlotDataMembership()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataMembership.md),
[`PlotDataPairRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataPairRatio.md),
[`PlotDataProduct()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataProduct.md),
[`PlotDataQuantiles()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataQuantiles.md),
[`PlotDataRankRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRankRows.md),
[`PlotDataRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRatio.md),
[`PlotDataRecode()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRecode.md),
[`PlotDataRelative()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRelative.md),
[`PlotDataSelect()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSelect.md),
[`PlotDataShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataShares.md),
[`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md),
[`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)

## Examples

``` r
a <- list(xy = matrix(1:6, 3), label = c("a", "b", "a"), names = c("u", "v"),
          feat = matrix(c(0.1, 0.2, 0.3, 1, 2, 3), 3), kept = c(TRUE, FALSE, TRUE),
          cls = c(7L, 8L), has_cls = c(TRUE, FALSE, TRUE))
PlotDataFromArrays(a, columns = "label",
                   matrices = list(xy = c("x", "y"), feat = list(names_from = "names")))
#>   label x y   u v
#> 1     a 1 4 0.1 1
#> 2     b 2 5 0.2 2
#> 3     a 3 6 0.3 3
PlotDataFromArrays(a, c(type = "label", cls = "cls"), masked = list(cls = "has_cls"),
                   keep = "kept", row_id = "row")
#>   type cls row
#> 1    a   7   0
#> 2    a   8   2
```
