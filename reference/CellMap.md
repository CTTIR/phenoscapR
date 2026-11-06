# Plot Cell Map

Scatter plot of cell positions coloured by phenotype, cluster, or any
metadata column. Analogous to Seurat's `DimPlot` but in tissue space.

## Usage

``` r
CellMap(
  object,
  colour_by = "phenotype",
  colours = NULL,
  pt_size = 0.5,
  title = NULL,
  dark_theme = FALSE,
  y_down = TRUE
)
```

## Arguments

- object:

  An
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- colour_by:

  Character. Column name in `meta_data` to colour by. Default
  `"phenotype"`. Numeric columns get a continuous colour scale.

- colours:

  Named character vector or `NULL` for automatic colours via the global
  palette.

- pt_size:

  Numeric. Point size. Default `0.5`.

- title:

  Character or `NULL`. Plot title.

- dark_theme:

  Logical. Use a dark background (useful for tissue images). Default
  `FALSE`.

- y_down:

  Logical. If `TRUE` (default), y increases downward, as in image
  coordinates (origin at the top left; QuPath, cellspecR), so the map
  has the orientation of the tissue image. Use `FALSE` for coordinates
  whose y axis points up.

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
obj <- CreateSpatialObject(counts, coords)
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
CellMap(obj)

```
