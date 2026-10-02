# Preflight Integer Workspace Bounds for Exact Delaunay Construction

Computes buffer lengths and routing without loading a backend,
constructing a graph or allocating the planned native vectors.

## Usage

``` r
PlanExactDelaunayWorkspace(
  n_points,
  mode = c("auto", "stock", "bounded"),
  initial_madj = 64L,
  max_retries = 32L,
  retain_tessellation = FALSE
)
```

## Arguments

- n_points:

  Whole scalar point count, at least three.

- mode:

  `"auto"`, `"stock"` or `"bounded"` workspace route.

- initial_madj:

  Whole bounded adjacency capacity, at least 20. The request is clipped
  to the largest safe capacity; no unsafe integer coercion occurs.

- max_retries:

  Nonnegative whole adjacency-growth retry ceiling.

- retain_tessellation:

  Logical scalar. `TRUE` is rejected for a bounded plan, which is
  edge-only and cannot retain an incomplete tessellation.

## Value

A list containing requested/selected route, stock and selected adjacency
capacity, segment capacity, named native lengths, integer headroom,
retry ceiling and `native_buffer_bytes`. `native_execution` is always
`FALSE`.

## Details

All values must be dimensionless unclassed base vectors. Every native
argument length is checked against signed integer capacity, with one
complete spare adjacency row. The byte estimate includes native buffers
only, not R objects, copies or runtime overhead, and is not an
available-memory check. Successful arithmetic preflight does not qualify
a large native execution.

## See also

[`BuildExactDelaunayEdges()`](https://cttir.github.io/phenoscapR/reference/BuildExactDelaunayEdges.md)

## Examples

``` r
PlanExactDelaunayWorkspace(100)
#> $schema_version
#> [1] "0.1.0"
#> 
#> $n_points
#> [1] 100
#> 
#> $requested_mode
#> [1] "auto"
#> 
#> $execution_path
#> [1] "STOCK_WRAPPER"
#> 
#> $bounded_required
#> [1] FALSE
#> 
#> $bounded_planned
#> [1] FALSE
#> 
#> $stock_madj
#> [1] 31
#> 
#> $stock_adjacency_length
#> [1] 3456
#> 
#> $initial_madj_requested
#> [1] 64
#> 
#> $initial_madj_used
#> [1] 31
#> 
#> $max_madj
#> [1] 19884105
#> 
#> $max_retries
#> [1] 32
#> 
#> $segment_capacity
#> [1] 496
#> 
#> $native_lengths
#>      x      y     rw     nn   ntot   nadj   madj    eps delsgs   ndel delsum 
#>    108    108      4      1      1   3456      1      1   2976      1    400 
#> dirsgs   ndir dirsum incAdj incSeg 
#>   4960      1    300      1      1 
#> 
#> $adjacency_headroom_rows
#> [1] 19884075
#> 
#> $native_buffer_bytes
#> [1] 84708
#> 
#> $native_execution
#> [1] FALSE
#> 
#> $memory_limit_claim
#> [1] "BUFFER_SUM_ONLY_EXCLUDES_COPIES_AND_RUNTIME_OVERHEAD"
#> 
# Pure arithmetic at the stock spare-row boundary; no large allocation:
PlanExactDelaunayWorkspace(799800)$bounded_required
#> [1] TRUE
```
