# Embedding Scatter

Draws cells on two embedding coordinates (for example UMAP) as small
points without frame, coloured by a key (cell type, cluster,
neighbourhood). Points are drawn in layers in the order of the data
rows, as given by
[`EmbeddingLayers()`](https://cttir.github.io/phenoscapR/reference/EmbeddingLayers.md),
and rasterised at the style resolution so that vector output stays
small. Point sizes follow figure scatter areas (squared points);
individual keys can be drawn as diamonds with an outline. Optional
cluster labels with a white halo, arrow axes or plain axis titles, and
texts filled from plot data complete the panel.

## Usage

``` r
PlotEmbedding(
  data,
  x = "x",
  y = "y",
  key = "key",
  limits = NULL,
  subset = NULL,
  colours = NULL,
  default_colour = "#BBBBBB",
  sizes = 0.3,
  shapes = NULL,
  edge_colours = NULL,
  edge_widths = NULL,
  labels = NULL,
  label_size = 4.2,
  label_colour = "ink",
  halo = 0.6,
  axis_style = c("none", "arrows", "titles"),
  axis_titles = c("UMAP 1", "UMAP 2"),
  arrow_fraction = 0.16,
  arrow_text_size = 4,
  title_size = 4.6,
  title_pad = 1.5,
  raster = TRUE,
  legend = NULL,
  texts = NULL,
  values = NULL,
  style = ManuscriptStyle()
)
```

## Arguments

- data:

  Point data with coordinate and key columns.

- x, y, key:

  Column names.

- limits:

  Display limits `c(xmin, xmax, ymin, ymax)` or a one-row data frame
  with these columns (see
  [`EmbeddingLimits()`](https://cttir.github.io/phenoscapR/reference/EmbeddingLimits.md)).

- subset:

  Optional named list: keep rows whose columns take these values (for
  example one clinical group per panel).

- colours:

  Colours per key: named vector or list, or a data frame of key and
  colour.

- default_colour:

  Colour of keys without a colour.

- sizes:

  Scatter areas in squared points, one value or per key.

- shapes:

  Optional marker per key: `"o"` (circle) or `"D"` (diamond).

- edge_colours, edge_widths:

  Optional outline colour and width (points) per key.

- labels:

  Optional data frame of text labels (`label`, `x`, `y`), for example
  from
  [`ClusterLabelPositions()`](https://cttir.github.io/phenoscapR/reference/ClusterLabelPositions.md),
  drawn bold with a white halo.

- label_size, label_colour, halo:

  Label size, colour and halo width.

- axis_style:

  `"none"`, `"arrows"` (two arrows in the lower left corner) or
  `"titles"` (axis titles beside the panel).

- axis_titles:

  Titles of the two axes.

- arrow_fraction:

  Arrow length as a fraction of the x range.

- arrow_text_size, title_size, title_pad:

  Text sizes and the distance of axis titles from the panel (points).

- raster:

  Rasterise the points (default) or draw vectors.

- legend:

  Optional legend: list of `keys`, `labels`, `at` (upper left corner in
  panel fractions), `ncol`, `size`, `marker_size` (points),
  `label_spacing`, `column_spacing`, `handle_text_pad`, `handle_length`
  (in font sizes), `title`, `title_size`, `title_align`, and optional
  `colours` and `shapes` overriding those of the points. Columns are
  filled first.

- texts, values:

  Free texts and template values, as in
  [`PlotAnnotatedHeatmap()`](https://cttir.github.io/phenoscapR/reference/PlotAnnotatedHeatmap.md);
  templates are filled from `values` restricted to `subset`, or from the
  subset data.

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md)
  object.

## Value

A 'ggplot2' object.

## Examples

``` r
set.seed(1)
d <- data.frame(x = rnorm(500), y = rnorm(500), key = sample(c("a", "b"), 500, TRUE))
PlotEmbedding(d, limits = c(-4, 4, -4, 4), colours = c(a = "#e34948", b = "#2a78d6"),
              axis_style = "arrows", axis_titles = c("Dim 1", "Dim 2"))
```
