# Changelog

## phenoscapR 0.2.0

- Normalisation preserves empty and all-missing markers without
  warnings. Quantile normalisation assigns a sole observed value 0.5,
  consistently with a constant marker, instead of producing `NaN`.
- Resampling functions reject non-numeric observation columns and
  non-finite draw counts.
  [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/reference/PermutationCorrelation.md)
  also validates its tolerance and exact-enumeration limit, preventing
  factor-code analyses, invalid exact p values from negative tolerances,
  and infinite permutation loops. Pearson permutation correlations are
  stable for finite observations at very large or small numeric scales.
- [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md)
  uses one worker thread by default; `n_threads` can be increased
  explicitly. The visualisation vignette uses a fixed seed and base SVD
  for PCA initialisation of disconnected groups, avoiding an older-R
  failure in the optional truncated-SVD solver.
- E. Chteinberg added as an author alongside R. Heller (author and
  maintainer) and H. Witte (author). All three authors are affiliated
  with Ulm University. Author names use initials throughout the package
  metadata, citation, and documentation.
- Patient-level and cell-level analysis exports:
  [`ExactPairedTests()`](https://cttir.github.io/phenoscapR/reference/ExactPairedTests.md)
  (exact signed-rank test over all sign flips with midranks, exact sign
  test, direction interval and leave-one-out rows),
  [`PairedDifferences()`](https://cttir.github.io/phenoscapR/reference/PairedDifferences.md),
  [`ContrastPatientEndpoints()`](https://cttir.github.io/phenoscapR/reference/ContrastPatientEndpoints.md),
  [`BootstrapMedianInterval()`](https://cttir.github.io/phenoscapR/reference/BootstrapMedianInterval.md),
  [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/reference/PermutationCorrelation.md),
  [`NeighbourTypeCounts()`](https://cttir.github.io/phenoscapR/reference/NeighbourTypeCounts.md)
  (Delaunay neighbours within a maximum edge length, GEOS or deldir),
  [`SummarizeNearestDistances()`](https://cttir.github.io/phenoscapR/reference/SummarizeNearestDistances.md),
  [`SummarizeCellComposition()`](https://cttir.github.io/phenoscapR/reference/SummarizeCellComposition.md),
  `ReadCellArrays()` and keyed comparisons with
  [`CompareTables()`](https://cttir.github.io/phenoscapR/reference/CompareTables.md),
  [`CompareArrays()`](https://cttir.github.io/phenoscapR/reference/CompareArrays.md)
  and
  [`SummarizeComparisons()`](https://cttir.github.io/phenoscapR/reference/SummarizeComparisons.md).
- Manuscript figures:
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md),
  page composition in millimetres
  ([`ComposeFigure()`](https://cttir.github.io/phenoscapR/reference/ComposeFigure.md),
  [`FigurePanel()`](https://cttir.github.io/phenoscapR/reference/FigurePanel.md),
  [`SaveFigure()`](https://cttir.github.io/phenoscapR/reference/SaveFigure.md))
  and figures rendered from declarative specifications
  ([`ReadFigureSpec()`](https://cttir.github.io/phenoscapR/reference/ReadFigureSpec.md),
  [`RenderFigure()`](https://cttir.github.io/phenoscapR/reference/RenderFigure.md),
  [`WriteFigure()`](https://cttir.github.io/phenoscapR/reference/WriteFigure.md))
  through registered plot grammars, with plot-data builders for
  patient-level, matrix, embedding and image panels.
- One set of generic plot-data helpers named `PlotData*()` (select,
  reshape, join, bind, recode, summarise, count, rank, compute and write
  text), with `filter` and `into` as common argument names, and one
  template syntax in
  [`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md).
- Tick placement of common plotting code as
  [`NiceBreaks()`](https://cttir.github.io/phenoscapR/reference/NiceBreaks.md)
  (also with intervals that follow the axis length);
  [`LegendKeys()`](https://cttir.github.io/phenoscapR/reference/LegendKeys.md)
  gains marker sizes, spacings, column-major filling and diamond and
  patch keys; figure texts can sit on their baseline; typesetting can be
  switched off per figure, panel, text or legend, or for single rules;
  straight quotes stay straight.
- [`SaveFigure()`](https://cttir.github.io/phenoscapR/reference/SaveFigure.md)
  and
  [`WriteFigure()`](https://cttir.github.io/phenoscapR/reference/WriteFigure.md)
  give the same files whatever was drawn before in the session: with
  ‘ragg’, every PNG is drawn on a new capture device, so rich text is
  measured afresh for every figure.
- [`ReadCosMx()`](https://cttir.github.io/phenoscapR/reference/ReadCosMx.md)
  matches cells on `fov` and `cell_ID`: CosMx numbers cells within each
  FOV, and cells of later FOVs used to receive the expression of the
  first.
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/reference/ReadMatrixCoords.md)
  takes further id columns in `cell_id_col` and refuses ids that are not
  unique.
- [`FindNeighbours()`](https://cttir.github.io/phenoscapR/reference/FindNeighbours.md),
  [`CellDensity()`](https://cttir.github.io/phenoscapR/reference/CellDensity.md),
  [`nearest_neighbours()`](https://cttir.github.io/phenoscapR/reference/nearest_neighbours.md)
  and
  [`cell_density()`](https://cttir.github.io/phenoscapR/reference/cell_density.md)
  return cells in input order; with interleaved samples, values used to
  be written to the wrong cells.
- [`BuildExactDelaunayEdges()`](https://cttir.github.io/phenoscapR/reference/BuildExactDelaunayEdges.md)
  and the `"deldir"` engine of
  [`NeighbourTypeCounts()`](https://cttir.github.io/phenoscapR/reference/NeighbourTypeCounts.md)
  triangulate through the public
  [`deldir::deldir()`](https://rdrr.io/pkg/deldir/man/deldir.html)
  instead of deldir’s internal routines, with the same edges. The deldir
  version pin is gone; `backend_contract` is no longer needed and is
  ignored, and `mode`, `initial_madj` and `max_retries` no longer change
  the construction. Frames that need deldir to enlarge its workspace now
  succeed in every mode; frames of 799,800 or more points are refused.
  Some degenerate frames that the bounded mode used to triangulate now
  fail with deldir’s own error (“Bailing out of adjchk.”), for example a
  centre with 40 points on a circle around it, a regular 150-gon, or 50
  collinear points with two points off the line.
- [`ExactPatientTests()`](https://cttir.github.io/phenoscapR/reference/ExactPatientTests.md)
  (and so
  [`ContrastPatientEndpoints()`](https://cttir.github.io/phenoscapR/reference/ContrastPatientEndpoints.md)
  and
  [`LeaveOnePatientOut()`](https://cttir.github.io/phenoscapR/reference/LeaveOnePatientOut.md))
  computes the observed and the allocated statistics with one formula on
  centred values and counts differences within the rounding of that
  arithmetic and of the stored values as ties. p values no longer change
  when values are rescaled, or shifted while the rounding of the shifted
  values stays below the spacing of distinct statistics (whole numbers
  keep their exact p values up to shifts of 1e13). Before, the observed
  statistic used a different formula and a fixed tolerance, so for
  values of about 10^3 and above with decimals the observed allocation
  or its mirror could be missed and p came out too small by
  1/allocations, down to 0; such p values now equal exact enumeration.
  Results for other inputs are unchanged.
- [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/reference/DelaunayNetwork.md)
  maps deldir’s points back to cell rows when coordinates repeat; edges
  used to point to the wrong cells after a duplicate.
- [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md)
  fills a blank QuPath `Image` value with the sample id; the blank used
  to stay.
- [`interaction_matrix()`](https://cttir.github.io/phenoscapR/reference/interaction_matrix.md)
  counts neighbours in a table without `sample_id` as one sample; it
  used to return zeros.
- [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/reference/CrossNNDistance.md)
  with `from` equal to `to` measures to the nearest other cell; every
  cell used to find itself at distance 0.
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md)
  and
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  treat a missing intensity as not positive; such cells used to get
  labels such as `"CD3+/NA+"`.
- Min-max scaling of a constant marker
  ([`NormaliseData()`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md),
  [`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md))
  keeps missing values instead of setting them to 0.
- The template format `{n|d}` writes every digit (`100000`, not
  `1e+05`). Plain placeholders and the `comma` format write whole
  numbers of magnitude 2^31 or more with every digit instead of `"NA"`
  and a warning.
- Heatmaps and dot matrices with zero-width colour limits (a constant
  matrix) take the first colour of the scale instead of missing fills.
- Horizontal
  [`PlotBars()`](https://cttir.github.io/phenoscapR/reference/PlotBars.md)
  and
  [`PlotStackedBars()`](https://cttir.github.io/phenoscapR/reference/PlotStackedBars.md)
  place the reference label and the top values on the value axis; their
  coordinates used to be swapped.
- [`AlterationMatrixData()`](https://cttir.github.io/phenoscapR/reference/AlterationMatrixData.md)
  puts the genes in `last` last also when they are altered in at least
  `min_count` samples.
- [`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/reference/PlotDataSummarise.md)
  with groups returns no rows when `filter` selects nothing, instead of
  one row with a missing group;
  [`PlotDataCount()`](https://cttir.github.io/phenoscapR/reference/PlotDataCount.md)
  without groups returns `n = 0` instead of failing.
- [`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/reference/PlotDataCrossShares.md)
  computes totals and shares for an empty-string level, which used to
  get missing values.
- Zero-row inputs give typed results without a phantom group in
  [`ExactPairedTests()`](https://cttir.github.io/phenoscapR/reference/ExactPairedTests.md),
  [`BootstrapMedianInterval()`](https://cttir.github.io/phenoscapR/reference/BootstrapMedianInterval.md),
  [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/reference/PermutationCorrelation.md),
  [`CompareTables()`](https://cttir.github.io/phenoscapR/reference/CompareTables.md)
  and
  [`SummarizeComparisons()`](https://cttir.github.io/phenoscapR/reference/SummarizeComparisons.md);
  without group columns they give one unavailable overall row.
- [`CellPositionsFor()`](https://cttir.github.io/phenoscapR/reference/CellPositionsFor.md)
  with zero references,
  [`SchematicShapes()`](https://cttir.github.io/phenoscapR/reference/SchematicShapes.md)
  without shapes and
  [`PlotDataQuantiles()`](https://cttir.github.io/phenoscapR/reference/PlotDataQuantiles.md)
  with zero rows give typed empty tables; they used to fail, warn or
  return `NULL`.
- [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/reference/PermutationCorrelation.md)
  refuses `min_n` below 2; a group with a single pair used to stop with
  an unhelpful error.
- [`PairedDifferences()`](https://cttir.github.io/phenoscapR/reference/PairedDifferences.md)
  refuses `id` or `name` columns called `x`, `y` or `difference`, which
  used to produce duplicated column names.
- [`PairedDifferences()`](https://cttir.github.io/phenoscapR/reference/PairedDifferences.md)
  gives zero rows for a zero-row table also for pairs without `y`, which
  used to fail.
- [`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md)
  writes infinite values of plain placeholders as `"n.e."` instead of
  failing.
- [`RenderFigure()`](https://cttir.github.io/phenoscapR/reference/RenderFigure.md)
  passes the colour keyword `"group"` (for example
  `label_colour = "group"`) on to the builder instead of rejecting it.
- [`PlotDataCount()`](https://cttir.github.io/phenoscapR/reference/PlotDataCount.md)
  and
  [`PlotDataRankRows()`](https://cttir.github.io/phenoscapR/reference/PlotDataRankRows.md)
  accept data.table input.
- [`PlotDataDominant()`](https://cttir.github.io/phenoscapR/reference/PlotDataDominant.md)
  gives a group without any share a missing dominant category instead of
  failing.
- [`SummarizeGroupedValues()`](https://cttir.github.io/phenoscapR/reference/SummarizeGroupedValues.md)
  accepts integer value and weight columns, which used to fail when
  groups gave different column types.
- [`AssignFixedGrid()`](https://cttir.github.io/phenoscapR/reference/AssignFixedGrid.md)
  corrects a bin index that the rounded division put one bin off, so
  coordinates on bin edges (for example `x = 10.7` with size 7 and
  offset 3.7) are assigned instead of failing.
- Nearest-neighbour distances of a cell without any other cell in its
  sample are `NA` instead of an error.
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md)
  and
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  phenotype a single cell on several markers instead of failing.
- [`QCFilter()`](https://cttir.github.io/phenoscapR/reference/QCFilter.md)
  removes cells with a missing area when an area threshold is set, as
  [`qc_filter()`](https://cttir.github.io/phenoscapR/reference/qc_filter.md)
  does; it used to fail.
- [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md),
  [`plot_cell_map()`](https://cttir.github.io/phenoscapR/reference/plot_cell_map.md)
  and
  [`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  colour by a numeric column with a continuous scale instead of failing.
- Moran’s I and quadrat results without a defined statistic (no
  neighbours within the radius, a single quadrat) print as not evaluable
  instead of failing.
- [`as_Seurat()`](https://cttir.github.io/phenoscapR/reference/as_Seurat.md)
  makes cell IDs that repeat across samples unique for the Seurat cell
  names instead of failing.
- ‘png’ moves from Suggests to Imports: image layers rasterise through
  [`png::readPNG()`](https://rdrr.io/pkg/png/man/readPNG.html) when
  ‘ragg’ is not installed.
- `ExpressionClusters(method = "gmm")` no longer attaches ‘mclust’ to
  the search path; the clusters are the same.
- `RunUMAP(densmap = TRUE)` uses the densMAP approximation of
  [`uwot::umap()`](https://jlmelville.github.io/uwot/reference/umap.html)
  (`dens_scale = 1`); it used to fail because ‘uwot’ has no `densmap()`.
- Reading `.npz` archives in
  [`CompareArrays()`](https://cttir.github.io/phenoscapR/reference/CompareArrays.md)
  and
  [`PlotDataFromArrays()`](https://cttir.github.io/phenoscapR/reference/PlotDataFromArrays.md)
  needs a ‘cellspecR’ newer than 1.0.0 (with `cs_read_npz()`); with
  ‘cellspecR’ 1.0.0 both functions now say so instead of failing on a
  missing function.
- [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md),
  [`RunTSNE()`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md)
  and
  [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  with `seed` restore the caller’s random number stream on exit instead
  of leaving it reseeded; the embeddings for a given seed are unchanged.
- The help pages, the README and the
  [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  error install ‘cellspecR’ and ‘songR’ from the CTTIR R-universe with
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html).
- The Shiny app takes its fonts (Inter, JetBrains Mono), the light
  border grey and the dark heading and border colours from the CTTIR
  design tokens.

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

- [`LeaveOnePatientOut()`](https://cttir.github.io/phenoscapR/reference/LeaveOnePatientOut.md)
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

- [`ExactPatientTests()`](https://cttir.github.io/phenoscapR/reference/ExactPatientTests.md)
  enumerates declared independent-patient contrasts with
  complete-patient missingness and explicit allocation resolution.
  [`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/reference/AdjustPatientFamilies.md)
  retains unavailable hypotheses and reports both finite-only and
  declared-family BH/BY adjustments. Existing differential abundance
  methods are unchanged.

- [`FromCellspec()`](https://cttir.github.io/phenoscapR/reference/FromCellspec.md)
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
- H. Witte is credited as co-author throughout (README, citation, site).

#### Original development label: phenoscapR 2.0.0

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

#### Original development label: phenoscapR 1.2.0

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
- H. Witte added as a package author.

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
  [`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/reference/CreateSpatialObject.md)
  robustness: unnamed marker matrices get stable default names and
  all-NA marker columns are dropped with a warning;
  [`ReadSpatial()`](https://cttir.github.io/phenoscapR/reference/ReadSpatial.md)
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

##### Correctness and robustness

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
  [`ContrastGroupedRanks()`](https://cttir.github.io/phenoscapR/reference/ContrastGroupedRanks.md)
  for descriptive grouped Cliff deltas with explicit arm and missingness
  policies, complete registries and exact available pair counts without
  allocating cross-pair matrices.

- Fixed sorting of native-encoded non-ASCII keys in disjoint edge
  counts, grouped overlap contrasts and exact patient tests while
  preserving returned keys and numerical results.

- Added
  [`CountRadiusSets()`](https://cttir.github.io/phenoscapR/reference/CountRadiusSets.md)
  for ID-keyed full-frame radius counts of explicit reference sets, with
  complete query outputs, a required numerical search envelope, and
  installed backend fingerprints.

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
