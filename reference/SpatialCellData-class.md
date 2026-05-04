# The SpatialCellData Class

Central S4 class for storing and analysing single-cell spatial biology
data. Inspired by the Seurat object design, it holds raw and normalised
marker intensities, spatial coordinates, cell-level metadata, and
results from spatial analyses in a single container.

## Slots

- `counts`:

  Numeric matrix of raw marker intensities (cells x markers).

- `data`:

  Numeric matrix of normalised marker intensities (cells x markers).
  Identical to `counts` until
  [`NormaliseData`](https://r-heller.github.io/phenoscapR/reference/NormaliseData.md)
  is called.

- `coords`:

  Data frame with columns `x` and `y` holding spatial coordinates for
  each cell.

- `meta_data`:

  Data frame of per-cell metadata. Always contains `cell_id` and
  `sample_id`. Additional columns such as `cell_area`, `phenotype`, or
  `cluster` are added by analysis functions.

- `project`:

  Character string. Project or experiment name.

- `spatial`:

  List for storing spatial analysis results (nearest-neighbour
  distances, density values, interaction matrices).
