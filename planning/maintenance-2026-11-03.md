# phenoscapR maintenance — 3 November 2026

## Purpose and acceptance criteria

phenoscapR imports single-cell spatial measurements, retains sample/cell/marker
identity through quality control and normalisation, performs explicitly scoped
spatial and patient-level inference, and produces reproducible figures. Its
bundled Shiny application is a synthetic-data demonstration. This source milestone
preserves the scientific definitions and the verified authors, initials, order,
Ulm affiliations, ORCIDs and copyright notices.

The baseline is public commit d5959bd538374648ddb4207f8c54171ac48ebc32.
The original clean working copy is preserved while an isolated maintenance
worktree is qualified. Earlier 31 October evidence is historical; current tests
and direct failure probes are recorded independently.

Acceptance requires exact numeric and identity preservation for supported input,
explicit refusal of unsupported or unrepresentable cases, recoverable app/export
failure paths, actual installed first-use workflows, full and required-dependency
archive checks, and independent review. Local qualification does not establish
scientific/clinical suitability, external CRAN acceptance or hosted operation.

## Strategy and confirmed findings

| Priority | Evidence and user impact | Outcome and validation |
| --- | --- | --- |
| Essential | R/classes.R accepts character measurements and inconsistent marker axes; numeric 10 can be classified lexicographically | Refuse malformed measurement/axis states while retaining supported missing values and empty schemas; regression fixtures and ordinary workflow checks |
| Essential | R/read.R selects a substring coordinate column, loses leading zeros in identifiers and can collapse distinct QuPath Image labels | Preserve declared/reserved identifiers before CSV type inference, prefer explicit coordinate names, reject nonnumeric coordinates and ambiguous sample collisions, retain unambiguous legacy IDs; import fixtures and caller-preservation checks |
| Essential | R/process.R normalisation loses large/small finite values; R/inference-exact.R tolerance overflows and changes p = 1/3 to 1 | Retain ordinary arithmetic and apply bounded fallback when intermediates degenerate; independent mathematical/unit-scaling oracles, fixed definitions and refusal of actual numerical loss |
| Essential | Interoperability roundtrips replace normalised assays with raw counts; Seurat can rewrite marker names | Preserve explicitly aligned assays; refuse feature-name rewriting with a lossless alternative documented; real optional-package roundtrips |
| Dependable use | SaveFigure overwrites an existing PDF before a later error and permits one destination for two formats | Validate paths, render both outputs before replacement, recover originals after reported publication failures, retain unrecoverable backups; actual graphics and injected filesystem/device failures |
| Dependable use | App empty filters disconnect sessions, unavailable UMAP silently returns PCA, and insufficient replication warnings disappear | Recoverable empty state, explicit optional-dependency errors and visible replication limits; focused server and real browser workflows |
| Dependable use | Declared bslib 0.6 minimum cannot interpret the brand configuration; dark tables have low contrast | Declare tested bslib 0.9/shiny 1.6 minima and scope readable table text to its actual surface; isolated compatibility and browser contrast checks |
| Dependable use | Four manual passages clip at the page edge; scientific images are inverted in the dark documentation theme and have generic alternatives | Reflow only documentation comments, retain scientific colours and provide accurate plot alternatives; R-expression identity, PDF structure and selected-page inspection, actual browser readback |
| Reproducibility | The source archive omits app JSON reference snapshots and a fallback test invents availability of optional backends | Include the existing portable references and delegate availability checks to the real dependency resolver; installed archive snapshot comparisons and a genuinely isolated required-only library |

The bounded repair does not add a new analysis engine, upload application,
scientific provenance schema, deployment service or retrospective study claims.
New features and broader method qualification remain outside this milestone.

## Verification evidence

The final development archive is 2,680,189 bytes, SHA-256
`8542c3991e4157fe1741d6cb904f3d9c864fe1e426fc6cc9b098f38125d3e944`.
All 366 source payload files match the frozen source. The archive contains no
Git metadata, unexpected links, traversal paths or audit/build scratch files.

| Observed check | Result |
| --- | --- |
| Full exact-archive `R CMD check --as-cran` | 0 errors, 0 warnings, 1 incoming NOTE; 8,045 assertions pass, no test warnings, 2 explicit opt-in/environment skips |
| Isolated required/test-only exact-archive check | 0 errors, 1 expected documentation warning, 3 NOTEs; 7,186 assertions pass, no test warnings, 62 optional-integration skips |
| Exact-archive source coverage | 94.88058%, above the unchanged 90% floor; all 148 instrumented source/test inputs remain unchanged |
| Fresh installed first use | 19 checks pass: numeric and spatial workflows, persistence, real PDF/PNG output, failure preservation, leading-zero IDs, empty imports and marker-free spatial analysis |
| Workflow syntax | Actionlint passes |
| Advisory style lint | 570 repository-style and 334 shared-style findings; existing report-only policy retained, no new suppression or weakened gate |
| Documentation site | 224 HTML pages, 11,547 local HTML references and 54 CSS references; no broken local targets |
| Scientific figures | All 33 vignette PNGs retain their bytes; 33 descriptive alternatives; 320 rendered source-pixel comparisons pass |
| Complete reader manual | 210 pages; 193 contents entries and 840 numeric links resolve correctly after bounded TeX/index convergence; no clipped words, replacement glyphs or unembedded fonts |

The full incoming NOTE records a new submission, the development version and
optional cellspecR/songR outside CRAN/Bioconductor; both were available from the
declared CTTIR R-universe. The required-only library deliberately lacks optional
documentation builders and integrations. Its warning concerns missing knitr;
the notes include incoming metadata, vignette processing without that builder,
and unavailable V8 math checking. Full qualification exercises those documents.
These conditions are retained and explained, not presented as a warning-free
minimal check or suppressed to obtain a pass.

Independent evidence includes 354 affected core/import assertions, 52 of them
covering empty/zero-marker boundaries; 159 figure-export assertions with real
graphics and injected failures; 32 exact-inference regressions; 31 additional
numerical checks; and reordered CSV identity/input-preservation probes. These
counts overlap the integrated suite and must not be added to it as separate test
totals. The fixtures reproduce baseline defects. A late empty-input probe also
caught a candidate compatibility regression before publication: constructors now
canonicalize logical placeholders only when there are no entries. Metadata-only
and fully filtered-marker imports explicitly retain their cell extent. Nonempty
logical measurements and factor coordinates remain refused; stored-object
validity remains strict.

The app has 33 focused and four actual browser-backed snapshot assertions, plus
37 direct browser checks for recovery, unavailable UMAP, separate sessions,
light/dark modes and mobile use. The missing-UMAP browser case changes only the
dependency-availability check in a disposable app copy. Ordinary normalization
retains identical 640-cell, eight-marker matrices for all three methods. Later
empty-placeholder and CSV identity repairs do not alter this synthetic app path;
source comparisons distinguish that evidence from a repeated browser run.

The site has 29 browser checks and 27 final targeted checks. Unchanged article,
image, CSS and JavaScript hashes support carrying forward relevant observations.
All 1,454 measured code text leaves per theme meet at least 5.18:1 in light and
5.33:1 in dark mode; linked keywords were also checked in normal/hover/focus
states. This is a bounded contrast review, not an accessibility certification.

The stock R-check PDF passes its automated check but retains 40 stale printed
contents references; its internal numeric destinations work. That artifact is
preserved. The complete `--internals` manual converges after two additional
TeX/index passes; only contents/index geometry changes. The qualified reader copy
has correct references. Fifty-two pages were visually reviewed directly or
carried forward through identical body geometry; every page was structurally
checked, not every page visually read. The exact recipe and both artifacts are
retained in the maintainer's audit evidence.

Baseline evidence is separate: 0 errors, 0 warnings, 1 incoming NOTE and 7,784
passing assertions, with two skips and two snapshot-creation test warnings.
Intermediate failing probes and superseded candidates remain available. The
original checkout's HEAD, clean status and all 433 files were unchanged through
qualification. Scholarly authors, affiliations, ORCIDs and copyright fields are
byte-preserved; citation/release metadata change only the version.

A bounded scan of the changed payload found no high-confidence private-key,
GitHub-token or AWS-access-key patterns. It is not a history-wide credential or
dependency-advisory certification. The normal hosted private-term gate remains
enabled. Current source publication and hosted CI must be verified separately;
no unobserved CI result is inferred from these local checks.

## Milestones and remaining scope

1. Essential repairs: numeric validity, exact cell/sample identity, assay
   preservation and finite-scale inference. Dependencies are existing data and
   optional-backend contracts. Completion requires failing baseline probes,
   independent numerical/identity oracles and affected integration tests.
2. Dependable daily use: recoverable exports and app failures, declared minimum
   versions, reproducible test packaging and accurate docs. Completion requires
   installed workflows, actual graphical/browser failures and source/doc agreement.
3. Source qualification: a frozen archive, full and genuinely required-only
   checks, meaningful coverage, independent review and authenticated normal main
   publication. Hosted results must be observed for the exact published commit.
4. Deferred opportunities: broader real-study validation, large-cohort performance
   benchmarking, a user-data app/import-export interface and additional UI layout
   refinements. These require separate evidence and product decisions; they are
   not prerequisites for this bounded experimental software milestone.

The package remains experimental. Synthetic tests and retrospective fixtures do
not establish clinical utility or biological validity for a particular study.
The existing general performance statement was not re-benchmarked across every
statistic at 20,000 cells. Dense category labels in two gallery plots remain a
layout limitation; legends are readable. The custom site navbar has no search
control, although its generated index is valid. A cosmetic license-page heading
is imperfect; the complete legal text is present. No CRAN/Zenodo submission or production
deployment is implied by a source publication.

## First use

Install R 4.1.0 or newer. A source installation may require the platform's R
build tools; the local qualification used R 4.6.1 on ARM macOS. From R:

```r
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("CTTIR/phenoscapR")
library(phenoscapR)
data(phenoscapR_example)
obj <- NormaliseData(phenoscapR_example, method = "zscore")
obj <- PhenotypeCells(obj, thresholds = list(CD20 = 1, CD3 = 1, CD8 = 1,
                                            CD68 = 1, PanCK = 1, FoxP3 = 1))
CellMap(obj[obj$sample_id == "tonsil_A", ])
```

The README contains the optional app dependency installation and complete
synthetic workflow. Real input starts with `ReadSpatial()` or
`ReadMatrixCoords()`; acquisition of user study data is outside the package.
Exact local archive installation and first-use evidence are separate from the
GitHub installation command above.

## Private-term configuration

The maintainer authorized removal of the now-public coauthor name from the
repository privacy filter. A manual maintenance workflow removed one exact
author-name alternative and preserved the other three alternatives verbatim.
The runner scan changed from 13 matching files to zero. The replacement and
rollback values were encrypted directly to GitHub's repository public key;
no plaintext filter was logged, stored in artifacts or committed. The secret
update timestamp was verified. The one-time workflow was then removed at
322b26ebd7d56f92c16cc2263ba1ca4e94eb3461, whose final source tree is identical
to the original baseline. The normal privacy check remains enabled. Scholarly
author metadata were not removed or modified. All four standard hosted workflows passed for that unchanged source tree.
Those results are separate from the current scientific-source qualification.


## Hosted warning-test follow-up

The scientific source milestone was published at `68359f2`. Its hosted lint,
coverage and documentation workflows passed, as did Windows, macOS and Ubuntu
release/devel R jobs. Ubuntu oldrel-1 and oldrel-3 retained an additional legitimate
Wilcoxon ties warning and exposed an overly broad test assertion: it required
every warning to contain the replication message. The application correctly
retained both warnings.

The test now requires the intended warning to be present and independently checks
that an additional backend warning survives in the reactive result and visible
UI. The actual abundance function still executes. Thirty affected recovery and
real browser assertions pass with no failures, warnings or skips. Restoring the
old assertion against the same fixture reproduces one failure. No runtime code
or warning handling changed. New-head hosted results remain to be observed; the
original failed run is retained as evidence.
