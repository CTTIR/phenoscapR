# Summarize Cell Annotations Within Fixed Grids

Joins annotations by sample and cell key, never by row position or
coordinates. Counts only supplied memberships, retaining each sample
separately. Unobserved grid bins and unobserved categories are not
manufactured as zeros. Additional annotation rows outside the membership
are allowed and ignored.

## Usage

``` r
SummarizeFixedGrid(
  membership,
  annotations,
  settings,
  categories = character(),
  indicators = character()
)
```

## Arguments

- membership:

  Data frame returned by
  [`AssignFixedGrid()`](https://cttir.github.io/phenoscapR/reference/AssignFixedGrid.md).
  Each cell occurs at most once per setting and sample. Bin geometry and
  sample frames must be internally consistent. No coordinate
  transformation is performed.

- annotations:

  Data frame with unique character `sample_id`, `cell_id` keys and
  requested category/indicator columns. Every membership must match.

- settings:

  The explicit grid settings supplied to
  [`AssignFixedGrid()`](https://cttir.github.io/phenoscapR/reference/AssignFixedGrid.md).
  Size and all bounds must exactly match these settings and grid
  indices.

- categories:

  Character vector of unique category column names. Values must be
  character vectors; NA is permitted, but empty values are rejected.

- indicators:

  Character vector of unique logical indicator column names. NA is
  permitted. Names must be disjoint from categories and key columns.

## Value

List of data frames: `bins` with geometry and `n_cells`, `categories`
with bin keys, category column, value, count, fraction and
known/unavailable status, and `indicators` with bin keys, indicator
column, TRUE/FALSE/NA counts, fraction and COMPLETE/PARTIAL/UNAVAILABLE
status. Results have deterministic ordering. Empty inputs return empty
typed tables.

## Details

Logical indicators retain counts of TRUE, FALSE and unavailable (NA).
Their fraction is returned only for complete bins: any unavailable value
makes the fraction NA. Category NA is an explicit unavailable bucket,
whose fraction is the fraction of memberships with unknown category, not
biological absence. These are cell fractions, not tissue densities or
patient-level replicates. Supplied annotations do not establish
biological identity or review authority.

## Examples

``` r
cells <- data.frame(cell_id = c("a", "b"), sample_id = "s",
  frame_id = "physical", x = c(1, 2), y = 0)
settings <- data.frame(setting_id = "g", size_um = 10,
  offset_x_um = 0, offset_y_um = 0)
frames <- data.frame(sample_id = "s", frame_id = "physical", unit = "um")
membership <- AssignFixedGrid(cells, settings, frames)
annotations <- data.frame(sample_id = "s", cell_id = c("a", "b"),
  type = c("A", "B"), signal = c(TRUE, NA))
SummarizeFixedGrid(membership, annotations, settings, "type", "signal")
#> $bins
#>   setting_id sample_id grid_x grid_y frame_id size_um xmin_um xmax_um ymin_um
#> 1          g         s      0      0 physical      10       0      10       0
#>   ymax_um n_cells
#> 1      10       2
#> 
#> $categories
#>   setting_id sample_id grid_x grid_y category value n_cells fraction status
#> 1          g         s      0      0     type     A       1      0.5  KNOWN
#> 2          g         s      0      0     type     B       1      0.5  KNOWN
#> 
#> $indicators
#>   setting_id sample_id grid_x grid_y indicator n_true n_false n_unavailable
#> 1          g         s      0      0    signal      1       0             1
#>   fraction_true  status
#> 1            NA PARTIAL
#> 
```
