# Changelog

## phenoscapR 2.1.0

- Added an interactive **Shiny app**, styled 1:1 to the Hugo Coder theme
  via `bslib` / Bootstrap 5 and a `_brand.yml`, launched with
  [`run_app()`](https://cttir.github.io/phenoscapR/reference/run_app.md).
  It covers the core workflow, spatial statistics, cellular
  neighbourhoods, spatial domains, dimensionality reductions, and
  differential abundance, with a light/dark colour-mode toggle. The
  Shiny stack is optional (Suggests), so the core package stays
  lightweight;
  [`run_app()`](https://cttir.github.io/phenoscapR/reference/run_app.md)
  reports any missing app packages.
- The app ships in `inst/app` as composable Shiny modules over the
  package’s exported functions, with a `shinytest2` smoke test (light
  and dark).
- Hanno Witte is credited as co-author throughout (README, citation,
  site).

## phenoscapR 2.0.0

Major feature release: higher-order spatial structure, unsupervised
phenotyping, differential testing, platform readers, and ecosystem
interop.

- **Cellular neighbourhoods / niches**
  ([`CellularNeighbourhoods()`](https://cttir.github.io/phenoscapR/reference/CellularNeighbourhoods.md)):
  cluster cells by the phenotype composition of their local
  neighbourhood.
- **Spatial domains**
  ([`SpatialDomains()`](https://cttir.github.io/phenoscapR/reference/SpatialDomains.md)):
  partition tissue into regions of coherent, spatially smoothed
  expression.
- **Unsupervised phenotyping**:
  [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/reference/ExpressionClusters.md)
  gains a Gaussian mixture-model option (`method = "gmm"`, via mclust),
  and
  [`AnnotateClusters()`](https://cttir.github.io/phenoscapR/reference/AnnotateClusters.md)
  names clusters by their most enriched markers.
- **Differential abundance**
  ([`DifferentialAbundance()`](https://cttir.github.io/phenoscapR/reference/DifferentialAbundance.md)):
  per-sample phenotype proportions compared across conditions (Wilcoxon
  / t / Kruskal-Wallis), with BH-adjusted p-values.
- **Platform readers**:
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/reference/ReadMatrixCoords.md)
  for the general expression-plus- coordinates layout, with
  [`ReadXenium()`](https://cttir.github.io/phenoscapR/reference/ReadXenium.md),
  [`ReadCosMx()`](https://cttir.github.io/phenoscapR/reference/ReadCosMx.md),
  and
  [`ReadMERSCOPE()`](https://cttir.github.io/phenoscapR/reference/ReadMERSCOPE.md)
  presetting each vendor’s cell-level column names.
- **Ecosystem interop**:
  [`as_Seurat()`](https://cttir.github.io/phenoscapR/reference/as_Seurat.md),
  [`as_SpatialExperiment()`](https://cttir.github.io/phenoscapR/reference/as_SpatialExperiment.md),
  and
  [`as_SpatialCellData()`](https://cttir.github.io/phenoscapR/reference/as_SpatialCellData.md)
  convert to and from Seurat / SpatialExperiment.

## phenoscapR 1.2.0

Deeper, more rigorous statistics.

- [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md)
  gains a `"translation"` edge correction (each pair weighted by the
  inverse window/translate overlap) – the rigorous estimator for
  rectangular windows, alongside the existing `"none"` and
  reduced-sample `"border"`.
- [`MoransI()`](https://cttir.github.io/phenoscapR/reference/MoransI.md)
  gains weight schemes (`weights = "binary"`, `"row"`-standardised, or
  `"idw"` inverse-distance) and a permutation p-value (`n_perm`),
  reported via a `method` field. Non-binary weights use the permutation
  test automatically.
- [`InteractionMatrix()`](https://cttir.github.io/phenoscapR/reference/InteractionMatrix.md)
  gains a permutation null (`method = "permutation"`, `n_perm`) that
  shuffles phenotype labels within each sample and adds `z_score` and
  `p_value` columns.
- PCA now retains variance and loadings:
  [`VarianceExplained()`](https://cttir.github.io/phenoscapR/reference/VarianceExplained.md)
  returns the percent variance per component and
  [`ScreePlot()`](https://cttir.github.io/phenoscapR/reference/ScreePlot.md)
  visualises it.
- The translation sweep and Moran weighting are exercised against direct
  references in the test suite.

## phenoscapR 1.1.0

API coherence.

- The spatial statistics now return lightweight classed objects
  (`phenoscapR_ripley`, `_pcf`, `_moran`, `_quadrat`, `_enrichment`,
  `_interaction`, `_crossnn`) that still behave like their underlying
  data.frame / list / vector, with consistent `print` summaries and
  ggplot2
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods for one-line visualisation.
- All single-window statistics (`RipleysK`, `MoransI`,
  `QuadratAnalysis`, `PairCorrelation`, `NeighbourhoodEnrichment`,
  `CrossNNDistance`) gain a `by_sample` argument: with
  `by_sample = TRUE` a multi-sample object is analysed per section and
  returned as a named list (`phenoscapR_by_sample`).
- Added a project `.lintr` configuration (the package is lint-clean) and
  a `lint` GitHub Actions workflow running lintr and goodpractice.
- Hanno Witte added as a package author.

## phenoscapR 1.0.1

Robustness and scalability hardening.

- The Delaunay fallback (used when `deldir` is absent) no longer builds
  an O(n^2) distance matrix; it now uses the kd-tree k-nearest-neighbour
  engine.
- Ripley’s K and the pair correlation function no longer materialise the
  full pairwise-distance set. Counting is streamed through the kd-tree
  in blocks and folded into a difference array over the radius grid —
  bounded memory, with the search cap seeded from the local density to
  avoid re-queries.
- Reader /
  [`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/reference/CreateSpatialObject.md)
  robustness: unnamed marker matrices get stable default names and
  all-NA marker columns are dropped with a warning;
  [`ReadSpatial()`](https://cttir.github.io/phenoscapR/reference/ReadSpatial.md)
  now shares this handling. Duplicate marker names remain a hard error
  (renaming them would mask a labelling mistake).
- Added large-n and backend-equivalence regression tests.

## phenoscapR 1.0.0

First stable release. This version consolidates the package onto a
single compute engine, hardens the spatial statistics, and ships a
reproducible example dataset and comprehensive vignettes.

### New features

- Bundled synthetic example dataset `phenoscapR_example` (two samples,
  eight markers, planted spatial niches) used across all examples,
  tests, and vignettes — `data(phenoscapR_example)`.
- Dimensionality reduction:
  [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md),
  [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md),
  [`RunTSNE()`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md),
  [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  with
  [`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  /
  [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  and an
  [`Embeddings()`](https://cttir.github.io/phenoscapR/reference/Embeddings.md)
  /
  [`Reductions()`](https://cttir.github.io/phenoscapR/reference/Reductions.md)
  accessor pair.
- New Visualisation Gallery vignette demonstrating every plotting
  function, and a “choosing a spatial statistic” guide in the
  spatial-analysis vignette.

### Correctness and robustness

- Spatial statistics are now **sample-aware**:
  [`interaction_matrix()`](https://cttir.github.io/phenoscapR/reference/interaction_matrix.md)
  and friends never count neighbours across samples, and the
  single-window statistics
  ([`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md),
  [`MoransI()`](https://cttir.github.io/phenoscapR/reference/MoransI.md),
  [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/reference/QuadratAnalysis.md),
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md),
  [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/reference/NeighbourhoodEnrichment.md),
  [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/reference/CrossNNDistance.md))
  refuse multi-sample objects with an informative error.
- [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/reference/DelaunayNetwork.md)
  builds a real Delaunay triangulation via `deldir` (Suggests) instead
  of an all-pairs placeholder, with a `max_edge` cap.
- Ripley’s K gains a reduced-sample border correction.
- Added input validation and friendly errors throughout (NA coordinates,
  degenerate samples, missing phenotype/marker columns).
- Fixed the colour palette system: unsupported palette names now fall
  back to the default instead of erroring; advertised palettes are
  limited to those the backend actually provides.

### Performance

- All neighbour queries route through a shared kd-tree search engine
  (`RANN`, Suggests) with an exact, memory-bounded base-R fallback,
  replacing the per-function O(n^2) distance matrices. Interaction and
  enrichment counting are vectorised and the enrichment permutation
  graph is computed once. Large sections (10^(4–10)5 cells) that
  previously needed multi-gigabyte distance matrices now run in seconds.

### Infrastructure

- Consolidated the snake_case and `SpatialCellData` APIs onto one
  internal compute core so both faces stay in sync.
- Added `inst/CITATION`, expanded the test suite, and raised coverage to
  ~83%.

## phenoscapR 0.1.0

- Initial release.
- Read single-cell spatial biology data with
  [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md).
- Quality control with
  [`qc_filter()`](https://cttir.github.io/phenoscapR/reference/qc_filter.md).
- Marker normalisation with
  [`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md).
- Cell phenotyping with
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  and
  [`summarise_phenotypes()`](https://cttir.github.io/phenoscapR/reference/summarise_phenotypes.md).
- Spatial analysis:
  [`nearest_neighbours()`](https://cttir.github.io/phenoscapR/reference/nearest_neighbours.md),
  [`cell_density()`](https://cttir.github.io/phenoscapR/reference/cell_density.md),
  [`interaction_matrix()`](https://cttir.github.io/phenoscapR/reference/interaction_matrix.md),
  [`spatial_clusters()`](https://cttir.github.io/phenoscapR/reference/spatial_clusters.md).
- Visualisation:
  [`plot_cell_map()`](https://cttir.github.io/phenoscapR/reference/plot_cell_map.md),
  [`plot_density()`](https://cttir.github.io/phenoscapR/reference/plot_density.md),
  [`plot_heatmap()`](https://cttir.github.io/phenoscapR/reference/plot_heatmap.md),
  [`plot_interactions()`](https://cttir.github.io/phenoscapR/reference/plot_interactions.md).
