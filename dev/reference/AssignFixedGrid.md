# Assign Physical Cell Coordinates to Fixed Square Grids

Assigns every supplied cell independently in each setting. Bins are
half-open intervals: an exact boundary belongs to the bin on its
positive side. Negative coordinates use floor division. No rounding or
tolerance is applied. Samples remain separate even when coordinates
overlap. Select eligible cells explicitly before calling; this function
does not filter, classify, or infer review status.

## Usage

``` r
AssignFixedGrid(cells, settings, frames)
```

## Arguments

- cells:

  Data frame with character `cell_id`, `sample_id`, `frame_id` and
  finite numeric `x`, `y` coordinates in micrometres. Keys are unique
  within each sample. An empty, correctly typed table is supported.

- settings:

  Nonempty data frame with unique character `setting_id`, positive
  finite numeric `size_um`, and finite numeric `offset_x_um`,
  `offset_y_um`. Each setting applies separately to every sample.

- frames:

  Data frame with unique character `sample_id`, character `frame_id` and
  character `unit`, which must be `"um"`. Each cell must match its
  sample's frame exactly. Extra frame rows are permitted.

## Value

Data frame ordered by setting, sample and cell ID (radix order), with
those keys, frame ID, integer grid indices, physical bounds and grid
size. Bins are keyed by `(setting_id, sample_id, grid_x, grid_y)`, never
coordinates alone. Unrepresentable bounds and indices outside the R
integer range fail. Floating-point cancellation that produces bounds
excluding an assigned cell also fails; no tolerance or silent coordinate
correction is introduced. Extra input columns are ignored; inputs are
not modified.

## Details

The result describes detection locations, not tissue regions. Square bin
area is not observed tissue area and must not be used as an inferred
tissue-density denominator. Frame identifiers bind already calibrated
coordinates; no unit, origin, axis, crop or registration conversion is
performed.

## Examples

``` r
cells <- data.frame(cell_id = c("a", "b"), sample_id = "s",
  frame_id = "physical", x = c(-1, 10), y = c(0, 0))
settings <- data.frame(setting_id = "g", size_um = 10,
  offset_x_um = 0, offset_y_um = 0)
frames <- data.frame(sample_id = "s", frame_id = "physical", unit = "um")
AssignFixedGrid(cells, settings, frames)
#>   setting_id sample_id cell_id frame_id grid_x grid_y size_um xmin_um xmax_um
#> 1          g         s       a physical     -1      0      10     -10       0
#> 2          g         s       b physical      1      0      10      10      20
#>   ymin_um ymax_um
#> 1       0      10
#> 2       0      10
```
