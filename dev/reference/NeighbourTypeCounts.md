# Count Neighbour Types over a Delaunay Graph with an Edge-Length Cut

Triangulates the cell centroids of one section (Delaunay), removes edges
longer than `max_edge`, and counts for every cell how many of its
remaining neighbours fall in each declared type group. This is the
per-cell neighbourhood composition input of cellular-neighbourhood
analyses.

## Usage

``` r
NeighbourTypeCounts(
  cells,
  x = "x",
  y = "y",
  type = "type",
  levels,
  max_edge = Inf,
  engine = c("geos", "deldir"),
  duplicates = c("error", "isolate"),
  backend_contract = NULL,
  eps = 1e-09,
  index_base = 1L
)
```

## Arguments

- cells:

  Cell table of one section.

- x, y, type:

  Column names of the coordinates and cell type.

- levels:

  Named list of type groups (group name to cell types) or a character
  vector (each type its own group). Every cell type must belong to
  exactly one group. The order defines the count columns.

- max_edge:

  Inclusive maximum edge length (same unit as `x`, `y`); `Inf` keeps all
  edges.

- engine:

  `"geos"` or `"deldir"`.

- duplicates:

  `"error"` or `"isolate"`.

- backend_contract:

  Deprecated and ignored (see
  [`BuildExactDelaunayEdges()`](https://cttir.github.io/phenoscapR/dev/reference/BuildExactDelaunayEdges.md)).

- eps:

  Tolerance passed to the `"deldir"` engine.

- index_base:

  Base of the integer `type_index` column (`1` or `0`).

## Value

A data frame with one row per cell, in input order: `type_group`,
`type_index`, `x`, `y`, `degree` and one integer count column per group.
Attributes `edges` (kept undirected edges), `full_edges` (all Delaunay
edges) and `engine`.

## Details

Edge length is computed with the C library `hypot()` (via
[`Mod()`](https://rdrr.io/r/base/complex.html)) on the double
coordinates and compared inclusively (`<= max_edge`), as `numpy.hypot`
does. In general position the Delaunay triangulation is unique, so every
correct engine gives the same edges; with four or more co-circular
points engines may choose different diagonals. Duplicate coordinates are
refused by default; `duplicates = "isolate"` keeps the first occurrence
as the graph vertex and gives later copies no neighbours (as Qhull's
coplanar-point handling does).

Engines: `"geos"` (default) uses GEOS through sf
(`st_triangulate(..., bOnlyEdges = TRUE)`); input coordinates are mapped
back to cells exactly. `"deldir"` uses
[`deldir::deldir()`](https://rdrr.io/pkg/deldir/man/deldir.html) as
[`BuildExactDelaunayEdges()`](https://cttir.github.io/phenoscapR/dev/reference/BuildExactDelaunayEdges.md)
does; its run time grows roughly quadratically with the number of cells,
so it is meant for cross-checks on small sections.

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  set.seed(1)
  cells <- data.frame(x = runif(60, 0, 100), y = runif(60, 0, 100),
                      type = sample(c("a", "b", "c"), 60, replace = TRUE))
  out <- NeighbourTypeCounts(cells, levels = list(A = "a", BC = c("b", "c")),
                             max_edge = 20)
  head(out)
  attr(out, "edges")
}
#> [1] 125
```
