# Count Undirected Edges Between Disjoint Node Sets

Counts an explicitly supplied edge set using stable node IDs within
complete group and frame keys. Isolated nodes and nodes in neither set
remain in the supplied graph totals. No graph is constructed, no
distance cap is applied, and no scientific population, radius or
eligibility policy is inferred.

## Usage

``` r
CountDisjointEdges(
  nodes,
  edges,
  registry,
  groups,
  frame,
  id,
  from,
  to,
  source,
  target
)
```

## Arguments

- nodes:

  Data frame containing every node, including isolated nodes.

- edges:

  Data frame with one row per undirected edge. Extra columns, including
  distances, are ignored; filtering is the caller's responsibility.

- registry:

  Data frame with unique group/frame keys, including desired empty
  frames, and character columns `geometry_source` and
  `geometry_reference`. The source is `"frozen_import"` or
  `"supplied_edges"`; the reference is a nonempty caller-declared
  artifact or provenance reference.

- groups:

  Nonempty character vector naming distinct group columns shared by all
  three tables. Include the independent sample key as appropriate.

- frame:

  Character name of the frame column shared by all three tables.

- id:

  Character name of the node ID column in `nodes`.

- from, to:

  Character names of endpoint ID columns in `edges`.

- source, target:

  Character names of logical membership columns in `nodes`. Missing
  membership and overlapping sets are rejected. Nodes in neither set are
  valid.

## Value

Data frame sorted by group/frame keys. Schema version `"1.0.0"` has
integer-valued numeric counts `n_nodes`, `n_edges`, `n_source`,
`n_target`, `n_cross_edges`, `n_interacting_source`, and
`n_interacting_target`; `source_neighbor_mean`, `target_neighbor_mean`,
`source_contact_fraction`, and `target_contact_fraction`; and their
corresponding `_status` columns. Supplied graph totals include all nodes
and edges, even those contributing no source-target contact. Geometry
provenance columns and `schema_version` are retained explicitly. Extra
input columns are not returned.

## Details

Keys and IDs must be dimensionless, nonmissing, nonblank character
vectors. IDs may repeat across different groups or frames, but must be
unique within the complete group/frame key. Factors and numeric IDs are
not coerced. Duplicate registry keys, unknown endpoints, self edges, and
duplicate undirected pairs (including reversed duplicates) raise errors.
Each edge declares one shared frame, so a cross-frame relationship
cannot be represented; an endpoint absent from the declared frame raises
an error. The function cannot detect incorrectly declared frames or
establish physical coordinate validity.

Each source-target edge contributes once regardless of orientation.
Conditional neighbor means divide cross-edge count by the number of
distinct interacting source or target nodes. Contact fractions divide
interacting nodes by the corresponding complete source or target
population. Thus isolated nodes enter contact-fraction denominators but
not conditional-neighbor denominators.

A population with no contacts has contact fraction zero (`DEFINED`) and
conditional mean `NA` (`NO_INTERACTING_SOURCE` or
`NO_INTERACTING_TARGET`). An absent population has contact fraction `NA`
(`NO_SOURCE` or `NO_TARGET`). Missing membership never becomes an
observed zero. Empty registries return the same typed zero-row schema.

Provenance is copied from the registry, not authenticated. In
particular, `frozen_import` does not mean geometry was regenerated or
its hashes verified. The result declares `geometry_recomputed = FALSE`
and `geometry_authentication = "CALLER_DECLARED_NOT_VERIFIED"`. This API
does not invoke or certify any triangulation, distance, review or
geometry backend.

## Examples

``` r
nodes <- data.frame(sample = rep("one", 3), frame = rep("image", 3),
  cell = c("a", "b", "isolated"), is_source = c(TRUE, FALSE, TRUE),
  is_target = c(FALSE, TRUE, FALSE))
edges <- data.frame(sample = "one", frame = "image", from = "b", to = "a")
registry <- data.frame(sample = c("one", "empty"), frame = "image",
  geometry_source = "supplied_edges", geometry_reference = "example-v1")
CountDisjointEdges(nodes, edges, registry, groups = "sample", frame = "frame",
  id = "cell", from = "from", to = "to", source = "is_source", target = "is_target")
#>   sample frame geometry_source geometry_reference n_nodes n_edges n_source
#> 1  empty image  supplied_edges         example-v1       0       0        0
#> 2    one image  supplied_edges         example-v1       3       1        2
#>   n_target n_cross_edges n_interacting_source n_interacting_target
#> 1        0             0                    0                    0
#> 2        1             1                    1                    1
#>   source_neighbor_mean target_neighbor_mean source_contact_fraction
#> 1                   NA                   NA                      NA
#> 2                    1                    1                     0.5
#>   target_contact_fraction source_neighbor_status target_neighbor_status
#> 1                      NA  NO_INTERACTING_SOURCE  NO_INTERACTING_TARGET
#> 2                       1                DEFINED                DEFINED
#>   source_contact_status target_contact_status geometry_recomputed
#> 1             NO_SOURCE             NO_TARGET               FALSE
#> 2               DEFINED               DEFINED               FALSE
#>        geometry_authentication schema_version
#> 1 CALLER_DECLARED_NOT_VERIFIED          1.0.0
#> 2 CALLER_DECLARED_NOT_VERIFIED          1.0.0
```
