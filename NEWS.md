# phenoscapR 1.2.0

Deeper, more rigorous statistics.

* `RipleysK()` gains a `"translation"` edge correction (each pair weighted by the
  inverse window/translate overlap) -- the rigorous estimator for rectangular
  windows, alongside the existing `"none"` and reduced-sample `"border"`.
* `MoransI()` gains weight schemes (`weights = "binary"`, `"row"`-standardised,
  or `"idw"` inverse-distance) and a permutation p-value (`n_perm`), reported via
  a `method` field. Non-binary weights use the permutation test automatically.
* `InteractionMatrix()` gains a permutation null (`method = "permutation"`,
  `n_perm`) that shuffles phenotype labels within each sample and adds
  `z_score` and `p_value` columns.
* PCA now retains variance and loadings: `VarianceExplained()` returns the
  percent variance per component and `ScreePlot()` visualises it.
* The translation sweep and Moran weighting are exercised against direct
  references in the test suite.

# phenoscapR 1.1.0

API coherence.

* The spatial statistics now return lightweight classed objects
  (`phenoscapR_ripley`, `_pcf`, `_moran`, `_quadrat`, `_enrichment`,
  `_interaction`, `_crossnn`) that still behave like their underlying
  data.frame / list / vector, with consistent `print` summaries and ggplot2
  `autoplot()` methods for one-line visualisation.
* All single-window statistics (`RipleysK`, `MoransI`, `QuadratAnalysis`,
  `PairCorrelation`, `NeighbourhoodEnrichment`, `CrossNNDistance`) gain a
  `by_sample` argument: with `by_sample = TRUE` a multi-sample object is
  analysed per section and returned as a named list (`phenoscapR_by_sample`).
* Added a project `.lintr` configuration (the package is lint-clean) and a
  `lint` GitHub Actions workflow running lintr and goodpractice.
* Hanno Witte added as a package author.

# phenoscapR 1.0.1

Robustness and scalability hardening.

* The Delaunay fallback (used when `deldir` is absent) no longer builds an
  O(n^2) distance matrix; it now uses the kd-tree k-nearest-neighbour engine.
* Ripley's K and the pair correlation function no longer materialise the full
  pairwise-distance set. Counting is streamed through the kd-tree in blocks and
  folded into a difference array over the radius grid — bounded memory, with the
  search cap seeded from the local density to avoid re-queries.
* Reader / `CreateSpatialObject()` robustness: unnamed marker matrices get
  stable default names and all-NA marker columns are dropped with a warning;
  `ReadSpatial()` now shares this handling. Duplicate marker names remain a hard
  error (renaming them would mask a labelling mistake).
* Added large-n and backend-equivalence regression tests.

# phenoscapR 1.0.0

First stable release. This version consolidates the package onto a single
compute engine, hardens the spatial statistics, and ships a reproducible
example dataset and comprehensive vignettes.

## New features

* Bundled synthetic example dataset `phenoscapR_example` (two samples, eight
  markers, planted spatial niches) used across all examples, tests, and
  vignettes — `data(phenoscapR_example)`.
* Dimensionality reduction: `RunPCA()`, `RunUMAP()`, `RunTSNE()`, `RunSONG()`
  with `DimPlot()` / `EmbeddingPlot()` and an `Embeddings()` / `Reductions()`
  accessor pair.
* New Visualisation Gallery vignette demonstrating every plotting function, and
  a "choosing a spatial statistic" guide in the spatial-analysis vignette.

## Correctness and robustness

* Spatial statistics are now **sample-aware**: `interaction_matrix()` and
  friends never count neighbours across samples, and the single-window
  statistics (`RipleysK()`, `MoransI()`, `QuadratAnalysis()`,
  `PairCorrelation()`, `NeighbourhoodEnrichment()`, `CrossNNDistance()`) refuse
  multi-sample objects with an informative error.
* `DelaunayNetwork()` builds a real Delaunay triangulation via `deldir`
  (Suggests) instead of an all-pairs placeholder, with a `max_edge` cap.
* Ripley's K gains a reduced-sample border correction.
* Added input validation and friendly errors throughout (NA coordinates,
  degenerate samples, missing phenotype/marker columns).
* Fixed the colour palette system: unsupported palette names now fall back to
  the default instead of erroring; advertised palettes are limited to those the
  backend actually provides.

## Performance

* All neighbour queries route through a shared kd-tree search engine (`RANN`,
  Suggests) with an exact, memory-bounded base-R fallback, replacing the
  per-function O(n^2) distance matrices. Interaction and enrichment counting are
  vectorised and the enrichment permutation graph is computed once. Large
  sections (10^4–10^5 cells) that previously needed multi-gigabyte distance
  matrices now run in seconds.

## Infrastructure

* Consolidated the snake_case and `SpatialCellData` APIs onto one internal
  compute core so both faces stay in sync.
* Added `inst/CITATION`, expanded the test suite, and raised coverage to ~83%.

# phenoscapR 0.1.0

* Initial release.
* Read single-cell spatial biology data with `read_spatial()`.
* Quality control with `qc_filter()`.
* Marker normalisation with `normalise_markers()`.
* Cell phenotyping with `phenotype_cells()` and `summarise_phenotypes()`.
* Spatial analysis: `nearest_neighbours()`, `cell_density()`,
  `interaction_matrix()`, `spatial_clusters()`.
* Visualisation: `plot_cell_map()`, `plot_density()`, `plot_heatmap()`,
  `plot_interactions()`.
