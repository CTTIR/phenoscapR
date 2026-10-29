# Build Explicitly Ordered Delaunay Graphs

Constructs each complete declared geometry before selecting edges whose
two endpoints are eligible. Uses
[`deldir::deldir()`](https://rdrr.io/pkg/deldir/man/deldir.html) with no
fallback, coordinate rounding, jitter or population inference.

## Usage

``` r
BuildExactDelaunayEdges(
  nodes,
  frames,
  groups,
  frame,
  id,
  x,
  y,
  point_order,
  orientation_rank,
  geometry,
  eligible,
  unit_column,
  coordinate_unit,
  edge_order,
  window_policy,
  cap_policy,
  backend_contract = NULL,
  eps,
  mode,
  caps = numeric(),
  initial_madj = 64L,
  max_retries = 32L
)
```

## Arguments

- nodes:

  Data frame of keys, coordinates, orders and memberships.

- frames:

  Data frame of unique complete group/frame keys and units.

- groups:

  Nonempty character vector of distinct grouping column names.

- frame:

  Character name of the coordinate-frame key in both tables.

- id:

  Character name of the node ID column. IDs are unique within frames.

- x, y:

  Character names of finite coordinate columns in `nodes`.

- point_order:

  Character name of unique positive whole within-frame ranks defining
  geometry input order, independently of table row order.

- orientation_rank:

  Character name of unique positive whole within-frame ranks defining
  undirected endpoint orientation, independently of input order.

- geometry, eligible:

  Character names of nonmissing logical memberships. Eligibility implies
  geometry membership. Nodes outside geometry remain in the node map;
  isolated eligible nodes are retained.

- unit_column:

  Character name of the units column in `frames`.

- coordinate_unit:

  One of `"nm"`, `"um"`, `"mm"`, `"cm"`, `"m"`. All frames must declare
  this unit; no conversion occurs.

- edge_order:

  Required string `"orientation_rank"`. Output edges sort by UTF-8
  group/frame keys, then numeric endpoint orientation ranks.

- window_policy:

  Required string `"span_padding_v1"`. Bounds extend the coordinate
  ranges by `max(1e-6, max(x_span, y_span) * 1e-10)` on each side.

- cap_policy:

  Required string `"distance_leq"`. Named caps use inclusive comparisons
  with `sqrt(dx^2 + dy^2)`, without a tolerance.

- backend_contract:

  Deprecated and ignored. Construction uses the public
  [`deldir::deldir()`](https://rdrr.io/pkg/deldir/man/deldir.html)
  interface, so there are no private functions or native routines to
  pin. Kept so that existing calls keep working.

- eps:

  Explicit positive finite scalar tolerance passed to the engine.

- mode:

  Explicit `"stock"`, `"bounded"` or `"auto"` workspace mode, validated
  with
  [`PlanExactDelaunayWorkspace()`](https://cttir.github.io/phenoscapR/dev/reference/PlanExactDelaunayWorkspace.md)
  and recorded in the provenance. Every mode runs
  [`deldir::deldir()`](https://rdrr.io/pkg/deldir/man/deldir.html),
  which sizes its own workspace and enlarges it when needed; frames
  whose stock workspace would exceed the integer limit
  (`bounded_required`) are refused.

- caps:

  Named positive finite numeric thresholds in `coordinate_unit`. An
  empty numeric vector requests no cap columns.

- initial_madj, max_retries:

  Validated as in
  [`PlanExactDelaunayWorkspace()`](https://cttir.github.io/phenoscapR/dev/reference/PlanExactDelaunayWorkspace.md);
  they no longer change the construction.

## Value

A list with `schema_version = "0.1.0"`, `nodes` (including input
`source_row` and ordered `geometry_index`), `full_edges`,
`analysis_edge_rows`, `cap_flags`, `caps`, `frames` and `provenance`.
`full_edges` contains keys, endpoint IDs/geometry indices/orientation
ranks, coordinates, distance, `analysis_edge` and `edge_row`. Frame
counts distinguish all nodes, geometry, eligible nodes, full edges and
induced edges. `frame_construction` contains keyed per-frame
engine/workspace receipts in input registry order; output tables sort
independently. No input is modified.

## Details

Supported columns are dimensionless, unclassed base character,
integer/double or logical vectors as appropriate. Names are allowed.
Factors, `integer64` and arbitrary classed columns are rejected without
coercion. Data frames and data.tables are supported containers. Keys
must be nonmissing and nonblank. Selected roles are distinct within each
table. Node roles cannot be named `source_row` or `geometry_index`;
group/frame keys cannot collide with output edge or frame-summary
fields. Duplicate IDs across different frames are valid.

Every frame is preflighted before construction begins. A declared frame
needs at least three distinct noncollinear geometry points; a declared
empty frame fails. A completely empty registry and empty node table
return typed empty outputs without loading or executing the backend.
Integer workspace and conservative combined edge/cap bounds are checked
before allocation; they do not certify available memory. A finite
direct-determinant guard is deliberately conservative for extreme or
nearly collinear coordinates. Unsupported geometry fails rather than
being perturbed. Distances must be finite and positive.

Complete edges are checked for whole in-range nonself indices, exact
endpoint coordinate reconciliation, duplicate unordered pairs,
connectedness and planar cardinality bounds before eligibility
induction. These necessary invariants alone are not an independent proof
of Delaunay geometry. Co-circular choices depend on the `deldir` version
and explicit point order. Numeric orientation ranks and UTF-8 output
ordering do not infer a historical locale or ordering policy.

`deldir` is optional: a missing installation fails clearly for nonempty
construction. Each frame calls
`deldir::deldir(x, y, rw, eps, sort = TRUE, round = FALSE)` on the
geometry points in `point_order`. Warnings and unexpected messages fail
closed; messages announcing that `deldir` enlarged its workspace are
counted in the frame provenance (`workspace_growth`). No incomplete
tessellation is returned. The frame provenance records the `deldir`
version.

## Examples

``` r
PlanExactDelaunayWorkspace(100, mode = "stock")$native_buffer_bytes
#> [1] 84708
if (requireNamespace("deldir", quietly = TRUE)) {
  nodes <- data.frame(
    sample = "one", frame = "image", id = c("a", "b", "c", "d"),
    x = c(0, 4, 0, 3), y = c(0, 0, 3, 4), input = 1:4, orientation = 1:4,
    geometry = TRUE, eligible = c(TRUE, TRUE, TRUE, FALSE)
  )
  frames <- data.frame(sample = "one", frame = "image", unit = "um")
  graph <- BuildExactDelaunayEdges(nodes, frames, "sample", "frame", "id",
    "x", "y", "input", "orientation", "geometry", "eligible", "unit", "um",
    "orientation_rank", "span_padding_v1", "distance_leq",
    eps = 1e-9, mode = "stock", caps = c(short = 3, long = 5)
  )
  graph$full_edges
}
#>   sample frame from_id to_id from_geometry_index to_geometry_index
#> 1    one image       a     b                   1                 2
#> 2    one image       a     c                   1                 3
#> 3    one image       b     c                   2                 3
#> 4    one image       b     d                   2                 4
#> 5    one image       c     d                   3                 4
#>   from_orientation_rank to_orientation_rank x1 y1 x2 y2 distance analysis_edge
#> 1                     1                   2  0  0  4  0 4.000000          TRUE
#> 2                     1                   3  0  0  0  3 3.000000          TRUE
#> 3                     2                   3  4  0  0  3 5.000000          TRUE
#> 4                     2                   4  4  0  3  4 4.123106         FALSE
#> 5                     3                   4  0  3  3  4 3.162278         FALSE
#>   edge_row
#> 1        1
#> 2        2
#> 3        3
#> 4        4
#> 5        5
```
