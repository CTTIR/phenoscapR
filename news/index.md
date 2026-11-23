# Changelog

## phenoscapR 1.0.1

### Bug fixes

- [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/reference/NeighbourhoodEnrichment.md)
  validates the radius, the permutation count (at least two) and the
  seed before any random draw, and requires a complete, nonblank
  phenotype label for every cell; cells with a missing label used to be
  dropped from the counts while still being permuted. When the permuted
  counts of a phenotype pair do not vary, its z-score and p-value are
  now unavailable (`NA`) if the observed count differs from them,
  instead of the neutral `z = 0`, `p = 1`; a matching count stays
  neutral. This is the convention
  `InteractionMatrix(method = "permutation")` already follows. The help
  page, the printed summary and the spatial-analysis vignette state that
  the p-value is a normal approximation of the z-score.
- [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  and
  [`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  draw the second embedding axis increasing upward again. They share the
  drawing code of the tissue maps and had picked up its downward
  image-coordinate y axis, which mirrored every embedding vertically.
- [`AnnotateClusters()`](https://cttir.github.io/phenoscapR/reference/AnnotateClusters.md)
  writes every enriched marker with its own plus sign (`"CD3+CD8+"`). It
  used to join the marker names without a separator (`"CD3CD8+"`), which
  cannot be read back unambiguously and differed from the documented
  form.
- [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/reference/QuadratAnalysis.md)
  validates `nx` and `ny`, reports that no cell is retained (for example
  for an absent target phenotype) instead of failing in
  [`seq()`](https://rdrr.io/r/base/seq.html), and counts cells in one
  vectorised pass. Its summary no longer calls a variance-to-mean ratio
  of one “regular” because of rounding. Its
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  heatmap draws the rows downward, with the orientation of
  [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md)
  for the same cells; `autoplot(x, y_down = FALSE)` restores the upward
  rows.
- [`RidgePlot()`](https://cttir.github.io/phenoscapR/reference/RidgePlot.md)
  draws each density outline in the colour of its fill. Only the fill
  followed the package palette or the `colours` argument, so the
  outlines kept the default ‘ggplot2’ hues.
- [`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md)
  colours points with the package palette set by
  [`SetPalette()`](https://cttir.github.io/phenoscapR/reference/SetPalette.md),
  as the other plots do, instead of the default ‘ggplot2’ colours. This
  applies to numeric columns and to categories (character, factor,
  logical); other columns, such as dates, keep the scale ‘ggplot2’
  chooses for them.
- [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  divides each ring count by the exact area of the ring. A ring around a
  radius smaller than half the ring width is cut off at zero and is a
  disc; dividing it by `2 * pi * r * dr` inflated `g(r)` there. This
  affected the first radius of the automatic grid in every window whose
  shorter side exceeds about 400 coordinate units (a value near 1.8
  instead of 1 for a random pattern, reported as the peak in the printed
  summary), and user grids with `dr` larger than twice the smallest
  radius. All other values are unchanged.
- [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/reference/SpatialNetworkPlot.md)
  accepts a numeric `colour_by` column and draws it with the continuous
  palette, as
  [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md)
  does, instead of failing.
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md)
  and
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  use the labels of a factor passed as `labels`; its integer codes used
  to be written as the phenotype.
- [`InteractionPlot()`](https://cttir.github.io/phenoscapR/reference/InteractionPlot.md)
  rotates the phenotype labels on the x axis, as the other heatmaps do,
  so that long signatures no longer overlap.
- [`ViolinPlot()`](https://cttir.github.io/phenoscapR/reference/ViolinPlot.md)
  and
  [`BoxPlot()`](https://cttir.github.io/phenoscapR/reference/BoxPlot.md)
  rotate the group labels on the x axis as well; with more than a few
  phenotypes the labels of neighbouring groups ran into each other in
  every facet.
- [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md),
  [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md),
  [`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md),
  [`plot_cell_map()`](https://cttir.github.io/phenoscapR/reference/plot_cell_map.md),
  [`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md)
  and
  [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/reference/SpatialNetworkPlot.md)
  draw the legend keys of categories opaque and at a readable size. The
  keys used to copy the small, partly translucent map points, so that
  the colours of the categories could not be told apart in the legend.
- [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/reference/SpatialNetworkPlot.md)
  draws its edges visibly: the default `edge_alpha` is now `0.5`. The
  former default of `0.15` left the network almost invisible on the dark
  and on the light background. On the dark background
  (`dark_theme = TRUE`, also in
  [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md)
  and
  [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md))
  automatic colours that could not be seen against black are drawn
  lighter. Every category keeps its palette colour and hue, so that a
  dark and a light plot of the same object can be compared: only the
  colours below a lightness of CIE L\* = 40 differ between the two
  themes (with the default palette the first, dark purple one). Colours
  passed in `colours` and a vector of discrete colours set with
  [`SetPalette()`](https://cttir.github.io/phenoscapR/reference/SetPalette.md)
  are used as given.
- [`PlotAlterationMatrix()`](https://cttir.github.io/phenoscapR/reference/PlotAlterationMatrix.md)
  prints the row values of `right_text` right of the last tile. The
  default `right_offset` is now `tile_width / 2 + 0.1` column units; the
  former default of `0.2` put the text on the last tile, where it could
  not be read on a dark fill.
- The Shiny app shows axis tick labels again and draws plot text at its
  normal size. Automatic re-theming of the plots is no longer used,
  because it removed the tick labels of plots that set a complete
  ‘ggplot2’ theme; ‘thematic’ is no longer needed by
  [`run_app()`](https://cttir.github.io/phenoscapR/reference/run_app.md).
  The plots keep their light background in both colour modes and are
  rendered at 96 dpi, so that their text is no longer much smaller than
  the text of the page.
- The example of
  [`PlotTerritories()`](https://cttir.github.io/phenoscapR/reference/PlotTerritories.md)
  uses a scale bar that fits its field, and the help page of
  [`ThemeManuscript()`](https://cttir.github.io/phenoscapR/reference/ThemeManuscript.md)
  explains that panels printed outside
  [`ComposeFigure()`](https://cttir.github.io/phenoscapR/reference/ComposeFigure.md)
  need a margin for their outer labels.
- [`FeaturePlot()`](https://cttir.github.io/phenoscapR/reference/FeaturePlot.md),
  [`ViolinPlot()`](https://cttir.github.io/phenoscapR/reference/ViolinPlot.md),
  [`BoxPlot()`](https://cttir.github.io/phenoscapR/reference/BoxPlot.md),
  [`RidgePlot()`](https://cttir.github.io/phenoscapR/reference/RidgePlot.md)
  and
  [`DotPlot()`](https://cttir.github.io/phenoscapR/reference/DotPlot.md)
  build an empty plot for an object without cells instead of failing
  while assembling their data;
  [`MarkerHeatmap()`](https://cttir.github.io/phenoscapR/reference/MarkerHeatmap.md)
  reports that there is no phenotype to summarise.
- Summaries of Ripley’s K, the pair correlation function and cross
  nearest-neighbour distances print without warnings when values are
  unavailable, the per-sample summary accepts an empty result, and the
  enrichment heatmap keeps finite colour limits when z-scores are
  unavailable.

### Input validation

- Marker selections name the markers that do not exist.
  [`NormaliseData()`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md),
  [`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md),
  [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md),
  [`SpatialDomains()`](https://cttir.github.io/phenoscapR/reference/SpatialDomains.md),
  [`MarkerHeatmap()`](https://cttir.github.io/phenoscapR/reference/MarkerHeatmap.md)
  and
  [`plot_heatmap()`](https://cttir.github.io/phenoscapR/reference/plot_heatmap.md)
  used to drop a misspelt marker without any signal, so
  `NormaliseData(obj, markers = "typo")` returned the raw values
  silently. They now warn and continue with the markers that were found;
  [`SpatialDomains()`](https://cttir.github.io/phenoscapR/reference/SpatialDomains.md)
  stops when none remains.
  [`FeaturePlot()`](https://cttir.github.io/phenoscapR/reference/FeaturePlot.md),
  [`ViolinPlot()`](https://cttir.github.io/phenoscapR/reference/ViolinPlot.md),
  [`BoxPlot()`](https://cttir.github.io/phenoscapR/reference/BoxPlot.md),
  [`RidgePlot()`](https://cttir.github.io/phenoscapR/reference/RidgePlot.md)
  and
  [`DotPlot()`](https://cttir.github.io/phenoscapR/reference/DotPlot.md)
  warn in the same way about features that do not exist, and
  [`HistogramPlot()`](https://cttir.github.io/phenoscapR/reference/HistogramPlot.md)
  and
  [`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md)
  warn when the optional `group_by` or `colour_by` column does not exist
  instead of drawing an ungrouped plot silently.
- [`QCFilter()`](https://cttir.github.io/phenoscapR/reference/QCFilter.md)
  and
  [`qc_filter()`](https://cttir.github.io/phenoscapR/reference/qc_filter.md)
  require each threshold to be `NULL` or one non-missing number. A
  missing or non-numeric threshold used to remove every cell without a
  message. `min_intensity = NULL` now applies no lower limit, as for the
  other thresholds, instead of returning no cells.
- [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md)
  and
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  reject empty, missing, infinite and negative radii,
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  also a radius of zero, and
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  requires one positive ring width, instead of returning values for
  distances that do not exist. The automatic pair-correlation grid
  started at one coordinate unit even when a quarter of the shorter
  window side was not larger than that, which gave a descending grid
  beyond the supported radii; such windows now get an ascending grid
  scaled to the window. Larger windows keep their grid.
- [`SpatialClusters()`](https://cttir.github.io/phenoscapR/reference/SpatialClusters.md),
  [`spatial_clusters()`](https://cttir.github.io/phenoscapR/reference/spatial_clusters.md)
  and
  [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/reference/ExpressionClusters.md)
  require a whole cluster count between one and the number of cells;
  [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/reference/ExpressionClusters.md)
  names unknown markers, stops when no marker remains or when k-means or
  a Gaussian mixture meets a missing value, and documents
  `method = "gmm"`. k-means reports that it needs fewer clusters than
  cells, and Ward clustering reports cells that share no measured marker
  with another cell, instead of failing inside ‘stats’.
  [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/reference/DelaunayNetwork.md)
  requires `max_edge` to be `NULL` or one nonnegative number. The help
  pages state that spatial clustering pools the cells of all samples.
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md)
  and
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  require `labels` to carry unique, nonblank signature names. An unnamed
  label vector matched no signature and was ignored silently.
- [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md)
  rejects a component count below one or not finite, objects with fewer
  than two cells and missing marker values with a clear message.
  [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md),
  [`RunTSNE()`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md)
  and
  [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  warn about unknown markers in the same way as
  [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md).
- Cell subsetting (`object[i, ]`) rejects missing indices, which arise
  from comparing a column that holds `NA`, instead of failing in the
  validity check with a message about coordinates.
- [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md)
  and
  [`ReadSpatial()`](https://cttir.github.io/phenoscapR/reference/ReadSpatial.md)
  report an empty file and a path that is not one character string with
  a clear message.

### Documentation

- [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md)
  and
  [`MoransI()`](https://cttir.github.io/phenoscapR/reference/MoransI.md)
  cite their primary sources in the help pages, and
  [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md)
  and
  [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  state the estimators as implemented (intensity estimate, edge
  handling). The new help topic
  [`?"phenoscapR-results"`](https://cttir.github.io/phenoscapR/reference/phenoscapR-results.md)
  documents the result classes of the spatial statistics and their
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods.

### Packaging

- The minimum ‘ggplot2’ version is 3.5.0 rather than 3.0.0: the
  manuscript theme and the logarithmic axes use minor axis ticks, which
  older versions do not have, and plots and themes set line widths
  through the `linewidth` argument.

## phenoscapR 1.0.0

- Cap radius-search neighbour estimates before integer conversion so
  large valid radii remain usable. Ripley and pair-correlation
  calculations now reject undefined zero-area planar windows rather than
  report artificial dispersion; the existing target-filtered
  bounding-box window convention is documented.

- Treat machine-precision Moran permutation ties consistently,
  preserving two-sided theoretical-expectation centring and the Monte
  Carlo correction. Numerically constant sampled nulls no longer produce
  artificial z-scores or scale-dependent tail probabilities.

- Preserve extra Seurat coordinate annotations by cell-name mapping
  while exporting only named x/y to the spatial reduction; refuse
  conflicting metadata instead of overwriting it. SpatialExperiment
  retains named numeric dimensions across reordered columns and rejects
  ambiguous names or non-numeric coordinate annotations explicitly.

- Two-dimensional object analyses now project only the named x/y axes.
  Extra coordinate metadata and column order no longer alter neighbour
  geometry, weighting, clustering or graph calculations across native
  and fallback search engines; the original coordinate table remains
  stored unchanged.

- Differential abundance rejects incomplete or dimensioned labels
  instead of silently excluding unknown phenotypes from denominators.
  Its declared replication unit remains the sample; descriptive
  summaries retain unknown categories. Section composition rejects
  malformed cell/area/flag columns, invalid area divisors and undefined
  aggregate density areas, and enforces registered subset membership.
  Missing areas remain unsupported; no imputation is introduced.

- Singleton samples no longer contribute zero vectors to neighbourhood
  clustering. Their cells retain NA neighbourhood labels and explicit
  availability records; centres use only defined cell compositions.
  Empty/all-singleton inputs return zero-row centres without RNG use,
  and the app reports unavailable compositions explicitly.

- Phenotyping requires unique named, finite scalar thresholds. Reject
  recycled, missing, coerced and duplicate threshold definitions before
  assigning labels; selected marker columns must be unambiguous. Valid
  named numeric vectors and the existing empty-threshold behaviour
  remain supported.

- Neighbourhood and Moran analyses reject malformed sample/phenotype
  vectors and invalid integer controls before computation or RNG
  changes. Moran features must be finite real numeric vectors, and
  inverse-distance weighting explicitly rejects coincident neighbours
  rather than returning undefined values from infinite weights.

- Interaction tables reject missing phenotype labels and malformed
  coordinates before computing counts or changing RNG state. Previously,
  missing labels could disappear from observed counts while remaining in
  frequency denominators. Density and nearest-neighbour tables also
  reject complex coordinates.

- Permutation interaction results no longer report neutral z=0/p=1 when
  sampled null counts have zero variance but differ from the
  observation: those undefined normal-approximation statistics are now
  NA. Matching zero-variance sampled nulls and positive-variance
  formulas retain their existing behaviour.

- Interaction calculations now validate nonnegative finite radii before
  geometry shortcuts and validate permutation counts and signed integer
  seeds before coercion or RNG changes. At least two permutations are
  required for the reported variance; analytic methods continue to
  ignore unused permutation controls.

- Interaction scores now preserve complete avoidance as negative
  infinity when observed counts are zero and expected counts are
  positive, in both analytic and permutation methods. Present sample
  identifiers must be complete and nonblank; the optional missing-column
  single-sample convention is retained. Heatmaps identify infinite
  scores at colour scale endpoints while retaining the raw values.
  Permutation calculations now return zero counts for samples with no
  eligible neighbour edges.

- Stand-alone nearest-neighbour and density tables now require explicit
  complete sample identifiers and finite coordinates, rejecting
  malformed columns before any rows can disappear. Empty tables preserve
  their schema and receive typed empty results.

- Patient-level inference rejects matrix and array columns before
  indexing or coercion, preventing malformed patient identifiers from
  duplicating observations and malformed endpoints or p-values from
  being truncated. Ordinary vector inputs retain their existing
  numerical results.

- Contrast and family labels must be nonmissing and nonblank and cannot
  contain the reserved token `::`. This prevents distinct registry pairs
  from silently sharing a multiple-testing adjustment family.

- Spatial neighbours exclude the query cell by identity, including with
  tied coordinates and phenotype filters. Distinct cells at the same
  coordinates remain neighbours. Targeted nearest-neighbour distances no
  longer include the query cell itself; a sample with no other target
  cell returns `NA`. Neighbourhood composition, spatial-domain smoothing
  and the fallback Delaunay graph no longer retain self-neighbours when
  coordinates coincide.

- `SetPalette(NULL)` returns the current palette and leaves it
  unchanged, as documented. It previously cleared the setting, resetting
  the palette to `"viridis"`.

- Tissue maps
  ([`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md),
  [`FeaturePlot()`](https://cttir.github.io/phenoscapR/reference/FeaturePlot.md),
  [`DensityPlot()`](https://cttir.github.io/phenoscapR/reference/DensityPlot.md),
  [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/reference/SpatialNetworkPlot.md),
  [`plot_cell_map()`](https://cttir.github.io/phenoscapR/reference/plot_cell_map.md)
  and
  [`plot_density()`](https://cttir.github.io/phenoscapR/reference/plot_density.md))
  now draw the y axis increasing downward, as in image coordinates
  (origin at the top left; QuPath, cellspecR), so a map has the
  orientation of its tissue image. The new argument `y_down = FALSE`
  restores the previous upward axis.

- Column subsets of classed results (interaction matrices, neighbourhood
  enrichment, Ripley’s K, pair correlation and differential abundance)
  print as plain data frames. Previously the summary failed with an
  error or reported values from columns that were no longer present.

- Cell objects require aligned numeric raw and processed measurement
  matrices, finite numeric coordinates and complete empty-object
  schemas. Unsupported character measurements can no longer produce
  lexicographic phenotypes. Empty logical placeholders receive a numeric
  schema. Header-only imports remain valid, and removing every marker
  retains cell rows, IDs and coordinates.

- Normalisation conditions extreme finite inputs when variance or range
  arithmetic overflows or loses precision in the subnormal range. Exact
  patient tests compute an overflowing tie bound without changing its
  definition; ordinary well-scaled arithmetic and existing missingness
  rules are retained.

- CSV readers bind whole coordinate names and refuse factor-coordinate
  codes. Declared and reserved identifier columns retain leading zeros,
  so `001` and `1` remain distinct while measurement columns retain
  numeric parsing. QuPath retains original Image labels and refuses
  distinct images that would collapse to one parsed sample identity,
  including across files.

- SpatialExperiment and Seurat imports retain available normalized
  assays and all-missing features, with explicit axis validation. Seurat
  export refuses marker identifiers that its backend rewrites;
  SpatialExperiment preserves those names. No normalization method is
  inferred during conversion.

- Figure exports validate distinct destinations and render before
  replacing files. Reported render or publication failures preserve or
  restore previous outputs; unsuccessful restoration retains a
  recoverable backup. Failed graphics-device initialization cannot draw
  on or close a caller’s device.

- The synthetic-data app recovers from empty filters, reports
  unavailable UMAP and insufficient sample replication explicitly, and
  keeps tables readable in both themes. Its actual branding requires
  bslib 0.9.0; descriptive plot alternatives require shiny 1.6.0. These
  minimum versions are now declared.

- Vignette plots have descriptive text alternatives. The documentation
  site retains scientific plot colours and readable code text in both
  themes.

- The
  [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  example runs again (in `\donttest{}`, only when the optional songR
  package is installed), and the
  [`SetPalette()`](https://cttir.github.io/phenoscapR/reference/SetPalette.md)
  example restores the previous palette option.

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
  uses one worker thread and base SVD by default; `n_threads` and
  `pca_method` can be changed explicitly. Base SVD avoids an older-R
  failure in the optional truncated solver during PCA initialisation of
  disconnected groups. The visualisation vignette also uses a fixed
  seed.
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
