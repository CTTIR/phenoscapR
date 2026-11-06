# The SpatialCellData Class

Central S4 class for storing and analysing single-cell spatial biology
data. Inspired by the Seurat object design, it holds raw and normalised
marker intensities, spatial coordinates, cell-level metadata, and
results from spatial analyses in a single container.

## Details

Raw and normalized matrices must have identical dimensions and
row/marker names. They contain real numeric values; `NA` and `NaN` are
allowed, infinity is not. Coordinates are finite real numeric vectors,
and coordinate/metadata row counts must agree even for empty objects.

## Slots

- `counts`:

  Numeric matrix of raw marker intensities (cells x markers).

- `data`:

  Numeric matrix of normalised marker intensities (cells x markers).
  Identical to `counts` until
  [`NormaliseData`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md)
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

- `reductions`:

  Named list of dimensionality-reduction embeddings. Each element is a
  numeric matrix with one row per cell (e.g. `"pca"`, `"umap"`,
  `"tsne"`, `"song"`), as produced by
  [`RunPCA`](https://cttir.github.io/phenoscapR/reference/RunPCA.md),
  [`RunUMAP`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md),
  [`RunTSNE`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md),
  or
  [`RunSONG`](https://cttir.github.io/phenoscapR/reference/RunSONG.md).
