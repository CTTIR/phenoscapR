# Count Reference Sets Within Explicit Euclidean Radii

Counts reference neighbours and overlapping reference sets for each
query ID within an explicitly declared coordinate frame. Query batching
always searches the complete reference population of that frame. No
population, coordinate transformation, graph, tissue area or scientific
threshold is inferred.

## Usage

``` r
CountRadiusSets(
  nodes,
  frames,
  groups,
  frame,
  id,
  x,
  y,
  query,
  reference,
  sets,
  unit_column,
  radius_unit,
  radii,
  search_radius,
  chunk_size = 1000L
)
```

## Arguments

- nodes:

  Data frame containing node keys, coordinates and memberships.

- frames:

  Data frame declaring unique group/frame keys and coordinate units,
  including desired empty frames.

- groups:

  Nonempty character vector naming distinct group columns shared by both
  tables. Include independent sample keys as appropriate.

- frame:

  Character name of the shared coordinate-frame column.

- id:

  Character name of the node ID column in `nodes`.

- x, y:

  Character names of finite numeric coordinate columns in `nodes`.

- query, reference:

  Character names of nonmissing logical query and reference memberships
  in `nodes`. Memberships may overlap.

- sets:

  Nonempty character vector naming distinct nonmissing logical
  reference-set columns in `nodes`. Sets may overlap. Membership outside
  `reference` does not expand the reference population.

- unit_column:

  Character name of the units column in `frames`.

- radius_unit:

  One of `"nm"`, `"um"`, `"mm"`, `"cm"`, or `"m"`. Every declared frame
  must use this unit; no unit conversion is performed.

- radii:

  Distinct positive finite numeric output radii in `radius_unit`.

- search_radius:

  Required finite numeric search envelope, at least every requested
  radius. This is part of the numerical contract, not a default.

- chunk_size:

  Positive integer number of queries per native search batch.

## Value

A list with `schema_version = "1.0.0"` and:

- `frame_summary`: one row per declared frame, coordinate units,
  `n_nodes`, `n_queries`, `n_references`, and `status` (`NO_QUERIES`,
  `EMPTY_REFERENCE`, or `DEFINED`).

- `query_counts`: every query by requested radius, including zero
  neighbours, with `n_reference_neighbors` and `status`
  (`EMPTY_REFERENCE` or `DEFINED`). A nonempty reference universe
  containing only the query itself has status `DEFINED` and zero
  eligible neighbours.

- `set_counts`: every query by radius by set, with integer-valued double
  `count` and matching status. Overlapping sets need not partition
  neighbours.

- `backend`: installed version, search settings and radius/unit,
  DESCRIPTION, R-wrapper and native-library SHA-256 fingerprints. These
  identify the current runtime and do not authenticate a historical
  backend.

Keys and IDs are retained. Tables are sorted by keys, IDs, radii and set
names as applicable. Empty inputs return typed empty tables; inputs are
not modified.

## Details

Keys and IDs must be dimensionless, nonmissing, nonblank character
vectors. IDs must be unique within the complete group/frame key, but may
repeat across independent frames. Factors and numeric IDs are not
coerced. Selected roles within each input table must be distinct.
Unknown frames, duplicate keys, missing memberships and malformed inputs
raise errors. Extra node columns are ignored; a tile column does not
partition a frame unless selected as a key.

Searches use
[`dbscan::frNN()`](https://michael.hahsler.net/dbscan/reference/frNN.html)
with explicit query mode, `search = "kdtree"`, `approx = 0` and
`sort = FALSE`, without a fallback. Returned distances are filtered
inclusively using `distance <= radius`. Self exclusion compares IDs
within the complete frame key. Distinct coincident IDs remain
neighbours.

Exact search mode does not imply arbitrary-precision real-number
geometry. Binary64 boundary decisions can depend on `search_radius`: the
distance from `(0, 0)` to `(3 + 2 * .Machine$double.eps, 4)` is excluded
by a native search at 5, but a search at 6 returns a distance rounded to
5, which passes the output-radius filter at 5. Keep the search envelope
fixed when requesting different subsets of radii or comparing runs. No
padding, recentring, coordinate rounding or squared-distance replacement
is applied.

Squared output and search radii must be finite and at least
`.Machine$double.xmin`. Absolute coordinates must not exceed
`sqrt(.Machine$double.xmax) / 4`; frame spans must support finite
squared arithmetic. Unsupported extreme inputs and integer
indexing/output sizes raise errors. These conservative guards do not
remove ordinary rounding. Chunking bounds each native query batch, not
dense-neighbourhood memory within a batch or total output size. This
function does not authenticate input coordinates or historical geometry
and does not infer fractions or weights.

## Examples

``` r
nodes <- data.frame(
  sample = "sample-1", frame = "image-1", id = c("a", "b", "c"),
  x = c(0, 0, 3), y = c(0, 0, 4),
  query = c(TRUE, FALSE, FALSE), reference = TRUE,
  set_a = c(FALSE, TRUE, TRUE), set_b = c(FALSE, TRUE, FALSE)
)
frames <- data.frame(sample = "sample-1", frame = "image-1", unit = "um")
CountRadiusSets(nodes, frames, "sample", "frame", "id", "x", "y",
  "query", "reference", c("set_a", "set_b"), "unit", "um",
  radii = c(1, 5), search_radius = 5
)
#> $schema_version
#> [1] "1.0.0"
#> 
#> $frame_summary
#>     sample   frame coordinate_unit n_nodes n_queries n_references  status
#> 1 sample-1 image-1              um       3         1            3 DEFINED
#> 
#> $query_counts
#>     sample   frame id radius n_reference_neighbors  status
#> 1 sample-1 image-1  a      1                     1 DEFINED
#> 2 sample-1 image-1  a      5                     2 DEFINED
#> 
#> $set_counts
#>     sample   frame id radius   set count  status
#> 1 sample-1 image-1  a      1 set_a     1 DEFINED
#> 2 sample-1 image-1  a      1 set_b     1 DEFINED
#> 3 sample-1 image-1  a      5 set_a     2 DEFINED
#> 4 sample-1 image-1  a      5 set_b     1 DEFINED
#> 
#> $backend
#> $backend$name
#> [1] "dbscan::frNN"
#> 
#> $backend$version
#> [1] "1.2.7"
#> 
#> $backend$search
#> [1] "kdtree"
#> 
#> $backend$approx
#> [1] 0
#> 
#> $backend$search_radius
#> [1] 5
#> 
#> $backend$radius_unit
#> [1] "um"
#> 
#> $backend$description_sha256
#> [1] "bdbfb6af0d1e05ba8c4de649e3aa0089d199f26672621187e7c4ea9b3d9f25a3"
#> 
#> $backend$function_sha256
#> [1] "0a22705eae7c642abb21d9bf95a1d1e18767d73d86f058014a4c9a6495547b94"
#> 
#> $backend$native_sha256
#>                                                          dbscan.so 
#> "74f880d06549071ce25b244a1dcea31217828f062778d665ba3072e4a6d484b3" 
#> 
#> $backend$authority
#> [1] "CURRENT_INSTALLED_BACKEND_NOT_HISTORICAL_AUTHENTICATION"
#> 
#> 
```
