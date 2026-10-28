# Changelog

## phenoscapR (development version)

- Patient-level and cell-level analysis exports:
  [`ExactPairedTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPairedTests.md)
  (exact signed-rank test over all sign flips with midranks, exact sign
  test, direction interval and leave-one-out rows),
  [`PairedDifferences()`](https://cttir.github.io/phenoscapR/dev/reference/PairedDifferences.md),
  [`ContrastPatientEndpoints()`](https://cttir.github.io/phenoscapR/dev/reference/ContrastPatientEndpoints.md),
  [`BootstrapMedianInterval()`](https://cttir.github.io/phenoscapR/dev/reference/BootstrapMedianInterval.md),
  [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/dev/reference/PermutationCorrelation.md),
  [`NeighbourTypeCounts()`](https://cttir.github.io/phenoscapR/dev/reference/NeighbourTypeCounts.md)
  (Delaunay neighbours within a maximum edge length, GEOS or deldir),
  [`SummarizeNearestDistances()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeNearestDistances.md),
  [`SummarizeCellComposition()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeCellComposition.md),
  `ReadCellArrays()` and keyed comparisons with
  [`CompareTables()`](https://cttir.github.io/phenoscapR/dev/reference/CompareTables.md),
  [`CompareArrays()`](https://cttir.github.io/phenoscapR/dev/reference/CompareArrays.md)
  and
  [`SummarizeComparisons()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeComparisons.md).
- Manuscript figures: a figure style, page composition in millimetres
  and figures rendered from declarative specifications through
  registered plot grammars, with plot-data builders for patient-level,
  matrix, embedding and image panels.
- One set of generic plot-data helpers named `PlotData*()` (select,
  reshape, join, bind, recode, summarise, count, rank, compute and write
  text), with `filter` and `into` as common argument names, and one
  template syntax in
  [`FormatTemplate()`](https://cttir.github.io/phenoscapR/dev/reference/FormatTemplate.md).
- Tick placement of common plotting code as
  [`NiceBreaks()`](https://cttir.github.io/phenoscapR/dev/reference/NiceBreaks.md)
  (also with intervals that follow the axis length);
  [`LegendKeys()`](https://cttir.github.io/phenoscapR/dev/reference/LegendKeys.md)
  gains marker sizes, spacings, column-major filling and diamond and
  patch keys; figure texts can sit on their baseline; typesetting can be
  switched off per figure, panel, text or legend, or for single rules;
  straight quotes stay straight.
- Exact paired tests, contrasts of patient endpoints, bootstrap median
  intervals, permutation correlations, section summaries, Delaunay
  neighbour type counts and keyed parity checks of recomputed tables and
  arrays.
- [`SaveFigure()`](https://cttir.github.io/phenoscapR/dev/reference/SaveFigure.md)
  and
  [`WriteFigure()`](https://cttir.github.io/phenoscapR/dev/reference/WriteFigure.md)
  give the same files whatever was saved before in the session: rich
  text is measured afresh for every figure, not taken from gridtext’s
  session-wide cache.

## phenoscapR 0.1.1

- Standardize the named v5 package logo across README, documentation
  pages and available application headers, with matching light and dark
  artwork.

- Prepare a release with explicit patient-level inference, grouped
  summaries, spatial-table projection, and the existing single-cell
  spatial analysis APIs.

- Document GitHub access for the optional cellspecR and songR packages
  and correct the SONG installation hint. Conditional dependency checks
  remain in place; no analytical algorithms or public function
  signatures change.

- Align package and citation metadata, retain release notes in source
  archives, and distinguish current release information from earlier
  development labels.

### Historical development notes

The entries below retain the earlier development record. Their original
version labels are historical project labels, not a sequence of CRAN
releases. The package version for this release is 0.1.1.

#### Original development label: phenoscapR development

- Project explicit spatial-table rows and columns while retaining column
  metadata, repeated-row order and typed empty results without changing
  inputs.

- Apply supplied group thresholds with strict comparisons, validated
  reference coverage and separate eligibility and missing-value
  provenance.

- Complete scalar observations against an explicit registry and
  absent-value policy while preserving observed missingness, metadata
  and row provenance.

- Summarize grouped subset counts with exact bounded count totals,
  propagated missingness and explicit zero-denominator status before
  fraction division.

- Assemble explicitly registered paired summaries with missing-side,
  count and value availability retained separately from descriptive
  contrasts.

- Normalize backend DLL paths consistently on Windows while preserving
  strict package-library containment and native provenance checks.

- Build complete explicitly ordered Delaunay geometries with
  caller-pinned native contracts, full-graph validation before
  eligibility induction, and pure integer workspace preflight.
  Unsupported backends or geometry fail without fallback.

- [`LeaveOnePatientOut()`](https://cttir.github.io/phenoscapR/dev/reference/LeaveOnePatientOut.md)
  evaluates explicitly registered patient omissions using the existing
  exhaustive exact test, retaining incomplete-full and empty-arm
  outcomes, availability counts and effect-direction diagnostics.

- Contrast explicit groups within finite-metric overlap strata while
  retaining policy, evaluable and matched denominators, per-observation
  weights, stable effective control counts and separately requested
  quality criteria.

- Count supplied undirected edges between explicit disjoint node sets
  using complete group/frame registries, stable IDs, isolated-node
  denominators and separate zero-denominator statuses without claiming
  geometry reconstruction.

- Explicit grouped rank correlations retain paired availability counts,
  ties and constant-value statuses without manufacturing absent groups.

- Grouped summaries expose the available weight total as an explicit
  denominator, retaining unknown and observed-zero weight totals
  separately.

- Add explicit grouped continuous summaries with separate value/weight
  availability and caller-declared missingness and minimum-count
  policies.

- Add keyed fixed-grid annotation summaries with explicit unknown
  category and indicator counts, preserving sample boundaries and
  incomplete fractions.

- Add explicit physical fixed-grid membership with sample/frame
  validation, deterministic keys, and fail-closed numerical containment
  checks.

- [`ExactPatientTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPatientTests.md)
  enumerates declared independent-patient contrasts with
  complete-patient missingness and explicit allocation resolution.
  [`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/dev/reference/AdjustPatientFamilies.md)
  retains unavailable hypotheses and reports both finite-only and
  declared-family BH/BY adjustments. Existing differential abundance
  methods are unchanged.

- [`FromCellspec()`](https://cttir.github.io/phenoscapR/dev/reference/FromCellspec.md)
  preserves canonical feature dictionaries, missing features, cell keys,
  physical coordinates and original-import provenance. Independent
  images become separate spatial samples even when biological sample IDs
  match.

- Delaunay networks now triangulate each sample independently and
  preserve full-object row indices. Missing sample IDs and groups with
  fewer than three cells fail explicitly instead of allowing
  cross-sample edges.

- Cell subsetting clears cached spatial results and neighbour
  distance/density columns, preventing stale edges and summaries after
  filtering or reordering. Cluster, neighbourhood and domain labels
  remain frozen annotations from the original fit for plotting;
  recompute them to describe the new neighbourhoods. Marker-only
  subsetting retains spatial results.

- Differential abundance rejects missing/empty conditions or sample IDs
  and conflicting conditions within a sample before aggregating
  proportions.

#### Original development label: phenoscapR 2.1.0

- Added an interactive **Shiny app**, styled 1:1 to the Hugo Coder theme
  via `bslib` / Bootstrap 5 and a `_brand.yml`, launched with
  [`run_app()`](https://cttir.github.io/phenoscapR/dev/reference/run_app.md).
  It covers the core workflow, spatial statistics, cellular
  neighbourhoods, spatial domains, dimensionality reductions, and
  differential abundance, with a light/dark colour-mode toggle. The
  Shiny stack is optional (Suggests), so the core package stays
  lightweight;
  [`run_app()`](https://cttir.github.io/phenoscapR/dev/reference/run_app.md)
  reports any missing app packages.
- The app ships in `inst/app` as composable Shiny modules over the
  package’s exported functions, with a `shinytest2` smoke test (light
  and dark).
- Hanno Witte is credited as co-author throughout (README, citation,
  site).

#### Original development label: phenoscapR 2.0.0

Major feature release: higher-order spatial structure, unsupervised
phenotyping, differential testing, platform readers, and ecosystem
interop.

- **Cellular neighbourhoods / niches**
  ([`CellularNeighbourhoods()`](https://cttir.github.io/phenoscapR/dev/reference/CellularNeighbourhoods.md)):
  cluster cells by the phenotype composition of their local
  neighbourhood.
- **Spatial domains**
  ([`SpatialDomains()`](https://cttir.github.io/phenoscapR/dev/reference/SpatialDomains.md)):
  partition tissue into regions of coherent, spatially smoothed
  expression.
- **Unsupervised phenotyping**:
  [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/dev/reference/ExpressionClusters.md)
  gains a Gaussian mixture-model option (`method = "gmm"`, via mclust),
  and
  [`AnnotateClusters()`](https://cttir.github.io/phenoscapR/dev/reference/AnnotateClusters.md)
  names clusters by their most enriched markers.
- **Differential abundance**
  ([`DifferentialAbundance()`](https://cttir.github.io/phenoscapR/dev/reference/DifferentialAbundance.md)):
  per-sample phenotype proportions compared across conditions (Wilcoxon
  / t / Kruskal-Wallis), with BH-adjusted p-values.
- **Platform readers**:
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMatrixCoords.md)
  for the general expression-plus- coordinates layout, with
  [`ReadXenium()`](https://cttir.github.io/phenoscapR/dev/reference/ReadXenium.md),
  [`ReadCosMx()`](https://cttir.github.io/phenoscapR/dev/reference/ReadCosMx.md),
  and
  [`ReadMERSCOPE()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMERSCOPE.md)
  presetting each vendor’s cell-level column names.
- **Ecosystem interop**:
  [`as_Seurat()`](https://cttir.github.io/phenoscapR/dev/reference/as_Seurat.md),
  [`as_SpatialExperiment()`](https://cttir.github.io/phenoscapR/dev/reference/as_SpatialExperiment.md),
  and
  [`as_SpatialCellData()`](https://cttir.github.io/phenoscapR/dev/reference/as_SpatialCellData.md)
  convert to and from Seurat / SpatialExperiment.

#### Original development label: phenoscapR 1.2.0

Deeper, more rigorous statistics.

- [`RipleysK()`](https://cttir.github.io/phenoscapR/dev/reference/RipleysK.md)
  gains a `"translation"` edge correction (each pair weighted by the
  inverse window/translate overlap) – the rigorous estimator for
  rectangular windows, alongside the existing `"none"` and
  reduced-sample `"border"`.
- [`MoransI()`](https://cttir.github.io/phenoscapR/dev/reference/MoransI.md)
  gains weight schemes (`weights = "binary"`, `"row"`-standardised, or
  `"idw"` inverse-distance) and a permutation p-value (`n_perm`),
  reported via a `method` field. Non-binary weights use the permutation
  test automatically.
- [`InteractionMatrix()`](https://cttir.github.io/phenoscapR/dev/reference/InteractionMatrix.md)
  gains a permutation null (`method = "permutation"`, `n_perm`) that
  shuffles phenotype labels within each sample and adds `z_score` and
  `p_value` columns.
- PCA now retains variance and loadings:
  [`VarianceExplained()`](https://cttir.github.io/phenoscapR/dev/reference/VarianceExplained.md)
  returns the percent variance per component and
  [`ScreePlot()`](https://cttir.github.io/phenoscapR/dev/reference/ScreePlot.md)
  visualises it.
- The translation sweep and Moran weighting are exercised against direct
  references in the test suite.

#### Original development label: phenoscapR 1.1.0

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

#### Original development label: phenoscapR 1.0.1

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
  [`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/dev/reference/CreateSpatialObject.md)
  robustness: unnamed marker matrices get stable default names and
  all-NA marker columns are dropped with a warning;
  [`ReadSpatial()`](https://cttir.github.io/phenoscapR/dev/reference/ReadSpatial.md)
  now shares this handling. Duplicate marker names remain a hard error
  (renaming them would mask a labelling mistake).
- Added large-n and backend-equivalence regression tests.

#### Original development label: phenoscapR 1.0.0

First stable release. This version consolidates the package onto a
single compute engine, hardens the spatial statistics, and ships a
reproducible example dataset and comprehensive vignettes.

##### New features

- Bundled synthetic example dataset `phenoscapR_example` (two samples,
  eight markers, planted spatial niches) used across all examples,
  tests, and vignettes — `data(phenoscapR_example)`.
- Dimensionality reduction:
  [`RunPCA()`](https://cttir.github.io/phenoscapR/dev/reference/RunPCA.md),
  [`RunUMAP()`](https://cttir.github.io/phenoscapR/dev/reference/RunUMAP.md),
  [`RunTSNE()`](https://cttir.github.io/phenoscapR/dev/reference/RunTSNE.md),
  [`RunSONG()`](https://cttir.github.io/phenoscapR/dev/reference/RunSONG.md)
  with
  [`DimPlot()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingPlot.md)
  /
  [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingPlot.md)
  and an
  [`Embeddings()`](https://cttir.github.io/phenoscapR/dev/reference/Embeddings.md)
  /
  [`Reductions()`](https://cttir.github.io/phenoscapR/dev/reference/Reductions.md)
  accessor pair.
- New Visualisation Gallery vignette demonstrating every plotting
  function, and a “choosing a spatial statistic” guide in the
  spatial-analysis vignette.

##### Correctness and robustness

- Spatial statistics are now **sample-aware**:
  [`interaction_matrix()`](https://cttir.github.io/phenoscapR/dev/reference/interaction_matrix.md)
  and friends never count neighbours across samples, and the
  single-window statistics
  ([`RipleysK()`](https://cttir.github.io/phenoscapR/dev/reference/RipleysK.md),
  [`MoransI()`](https://cttir.github.io/phenoscapR/dev/reference/MoransI.md),
  [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/dev/reference/QuadratAnalysis.md),
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/dev/reference/PairCorrelation.md),
  [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/dev/reference/NeighbourhoodEnrichment.md),
  [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/dev/reference/CrossNNDistance.md))
  refuse multi-sample objects with an informative error.
- [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/dev/reference/DelaunayNetwork.md)
  builds a real Delaunay triangulation via `deldir` (Suggests) instead
  of an all-pairs placeholder, with a `max_edge` cap.
- Ripley’s K gains a reduced-sample border correction.
- Added input validation and friendly errors throughout (NA coordinates,
  degenerate samples, missing phenotype/marker columns).
- Fixed the colour palette system: unsupported palette names now fall
  back to the default instead of erroring; advertised palettes are
  limited to those the backend actually provides.

##### Performance

- All neighbour queries route through a shared kd-tree search engine
  (`RANN`, Suggests) with an exact, memory-bounded base-R fallback,
  replacing the per-function O(n^2) distance matrices. Interaction and
  enrichment counting are vectorised and the enrichment permutation
  graph is computed once. Large sections (10^(4–10)5 cells) that
  previously needed multi-gigabyte distance matrices now run in seconds.

##### Infrastructure

- Consolidated the snake_case and `SpatialCellData` APIs onto one
  internal compute core so both faces stay in sync.
- Added `inst/CITATION`, expanded the test suite, and raised coverage to
  ~83%.

#### Original development label: phenoscapR 0.1.0

- Fixed selected key names such as `collapse`, `sep` and `...` in
  grouped summaries and rank correlations, retaining duplicate-ID
  validation. Shared key validation now rejects matrix-valued keys
  across its public consumers.

- Added
  [`ContrastGroupedRanks()`](https://cttir.github.io/phenoscapR/dev/reference/ContrastGroupedRanks.md)
  for descriptive grouped Cliff deltas with explicit arm and missingness
  policies, complete registries and exact available pair counts without
  allocating cross-pair matrices.

- Fixed sorting of native-encoded non-ASCII keys in disjoint edge
  counts, grouped overlap contrasts and exact patient tests while
  preserving returned keys and numerical results.

- Added
  [`CountRadiusSets()`](https://cttir.github.io/phenoscapR/dev/reference/CountRadiusSets.md)
  for ID-keyed full-frame radius counts of explicit reference sets, with
  complete query outputs, a required numerical search envelope, and
  installed backend fingerprints.

- Initial release.

- Read single-cell spatial biology data with
  [`read_spatial()`](https://cttir.github.io/phenoscapR/dev/reference/read_spatial.md).

- Quality control with
  [`qc_filter()`](https://cttir.github.io/phenoscapR/dev/reference/qc_filter.md).

- Marker normalisation with
  [`normalise_markers()`](https://cttir.github.io/phenoscapR/dev/reference/normalise_markers.md).

- Cell phenotyping with
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/dev/reference/phenotype_cells.md)
  and
  [`summarise_phenotypes()`](https://cttir.github.io/phenoscapR/dev/reference/summarise_phenotypes.md).

- Spatial analysis:
  [`nearest_neighbours()`](https://cttir.github.io/phenoscapR/dev/reference/nearest_neighbours.md),
  [`cell_density()`](https://cttir.github.io/phenoscapR/dev/reference/cell_density.md),
  [`interaction_matrix()`](https://cttir.github.io/phenoscapR/dev/reference/interaction_matrix.md),
  [`spatial_clusters()`](https://cttir.github.io/phenoscapR/dev/reference/spatial_clusters.md).

- Visualisation:
  [`plot_cell_map()`](https://cttir.github.io/phenoscapR/dev/reference/plot_cell_map.md),
  [`plot_density()`](https://cttir.github.io/phenoscapR/dev/reference/plot_density.md),
  [`plot_heatmap()`](https://cttir.github.io/phenoscapR/dev/reference/plot_heatmap.md),
  [`plot_interactions()`](https://cttir.github.io/phenoscapR/dev/reference/plot_interactions.md).
