# Build Explicitly Ordered Delaunay Graphs with a Pinned Backend

Constructs each complete declared geometry before selecting edges whose
two endpoints are eligible. Uses a caller-pinned `deldir` engine with no
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
  backend_contract,
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

  Named list of exactly the 13 fields described below. Pins identify the
  expected current runtime; their origin is not authenticated.

- eps:

  Explicit positive finite scalar tolerance passed to the engine.

- mode:

  Explicit `"stock"`, `"bounded"` or `"auto"` workspace path.
  `"bounded"` forces the registered-master edge-only path. `"auto"`
  selects it when stock adjacency lacks a complete spare row below the
  integer limit.

- caps:

  Named positive finite numeric thresholds in `coordinate_unit`. An
  empty numeric vector requests no cap columns.

- initial_madj, max_retries:

  Initial bounded adjacency capacity and retry ceiling; see
  [`PlanExactDelaunayWorkspace()`](https://cttir.github.io/phenoscapR/reference/PlanExactDelaunayWorkspace.md).

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
of Delaunay geometry. Co-circular choices depend on the pinned engine
and explicit point order. Numeric orientation ranks and UTF-8 output
ordering do not infer a historical locale or ordering policy.

The only supported backend profile is `deldir` version `"2.0-4"`, with
registered Fortran arities 9 (`binsrt`) and 16 (`master`). `deldir` is
optional: missing or unsupported installations fail clearly for nonempty
construction. The contract fields are:

- `package_version`, `binsrt_num_parameters`, `master_num_parameters`;

- `description_sha256`, `native_library_sha256`;

- `binsrtR_body_serialized_sha256`, `binsrtR_body_deparse_sha256`;

- `wrapper_body_serialized_sha256`, `wrapper_body_deparse_sha256`;

- `digOutxy_body_serialized_sha256`, `digOutxy_body_deparse_sha256`;

- `digOutz_body_serialized_sha256`, `digOutz_body_deparse_sha256`.

Digests use `digest::digest(..., algo = "sha256")`; file/text digests
set `serialize = FALSE`. Body text is
`paste(deparse(body(f), width.cutoff = 500L), collapse = "\n")`. Builds,
operating systems and R serialization may produce different pins:
approve each intended runtime explicitly. No local digest is embedded
here. Matching supplied pins does not authenticate their source,
historical results or the entire R process.

Registered symbols are freshly looked up and validated. Detached
wrapper, sorter and lexical-helper closures preserve original functions
while routing native calls through registered symbols. Warnings,
unexpected messages, invalid native lengths/flags and exhausted
workspaces fail closed. Segment exhaustion is not silently retried with
an incomplete result. No incomplete tessellation is returned. The
bounded path changes workspace allocation, not the selected
triangulation engine; large-input qualification is separate from
small-fixture parity.

## Examples

``` r
PlanExactDelaunayWorkspace(100, mode = "stock")$native_buffer_bytes
#> [1] 84708
if (FALSE) { # \dontrun{
# Observe this runtime for an explicit local experiment. Observation is not
# historical authentication; independently approve pins for reproducible use.
stopifnot(requireNamespace("deldir", quietly = TRUE))
ns <- asNamespace("deldir")
dll <- getLoadedDLLs()[["deldir"]]
wrapper <- get("deldir", ns)
functions <- list(
  binsrtR = get("binsrtR", ns), wrapper = wrapper,
  digOutxy = get("digOutxy", environment(wrapper)),
  digOutz = get("digOutz", environment(wrapper))
)
hash_file <- function(path) {
  digest::digest(
    file = path, algo = "sha256",
    serialize = FALSE
  )
}
contract <- list(
  package_version = read.dcf(
    file.path(getNamespaceInfo(ns, "path"), "DESCRIPTION"),
    fields = "Version"
  )[[1L]],
  description_sha256 = hash_file(file.path(
    getNamespaceInfo(ns, "path"),
    "DESCRIPTION"
  )), native_library_sha256 = hash_file(dll[["path"]]),
  binsrt_num_parameters = 9L, master_num_parameters = 16L
)
for (name in names(functions)) {
  f <- functions[[name]]
  contract[[paste0(name, "_body_serialized_sha256")]] <-
    digest::digest(body(f), algo = "sha256")
  contract[[paste0(name, "_body_deparse_sha256")]] <- digest::digest(
    paste(deparse(body(f), width.cutoff = 500L), collapse = "\n"),
    algo = "sha256", serialize = FALSE
  )
}
nodes <- data.frame(
  sample = "one", frame = "image", id = c("a", "b", "c"),
  x = c(0, 4, 0), y = c(0, 0, 3), input = 1:3, orientation = 1:3,
  geometry = TRUE, eligible = TRUE
)
frames <- data.frame(sample = "one", frame = "image", unit = "um")
graph <- BuildExactDelaunayEdges(nodes, frames, "sample", "frame", "id",
  "x", "y", "input", "orientation", "geometry", "eligible", "unit", "um",
  "orientation_rank", "span_padding_v1", "distance_leq", contract,
  eps = 1e-9, mode = "stock", caps = c(short = 3, long = 5)
)
graph$full_edges
} # }
```
