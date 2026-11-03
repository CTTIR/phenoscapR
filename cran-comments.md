# Development qualification for version 0.2.0.9001

Checked locally on 2026-11-03 with R 4.6.1 on macOS 27.0.1 (ARM64).
The exact source archive has SHA-256
`8542c3991e4157fe1741d6cb904f3d9c864fe1e426fc6cc9b098f38125d3e944`.
These are local development checks, not a CRAN submission or acceptance.
Hosted checks for the forthcoming source commit remain pending.

## Current exact-archive results

- Full `R CMD check --as-cran`: **0 errors, 0 warnings, 1 NOTE**.
  Tests: **8,045 passing assertions, 0 failures or test warnings, 2 skips**.
  The skips are the private-term check without its environment value and the
  opt-in live SONG embedding. Vignettes and PDF/HTML manuals were rebuilt and
  checked with the full dependency set.
- Genuine required/test-only library: **0 errors, 1 warning, 3 NOTEs**.
  Tests: **7,186 passing assertions, 0 failures or test warnings, 62 optional
  skips**. User/site libraries and profiles were excluded; optional packages
  were not admitted to make this check pass.
- Exact-archive source coverage: **94.88058%**, above the existing 90% gate.
- Fresh isolated package-library installation: **19 first-use checks passed**,
  including file import, QC, normalization, exact inference, native object
  roundtrip, actual PDF/PNG export and failure preservation, empty imports,
  metadata-only cells and zero-marker nearest-neighbor geometry. Existing
  dependencies were reused; this is not a fresh-operating-system qualification.

## Current NOTE and warning details

The full incoming NOTE records a new submission, the development version's
large component (`0.2.0.9001`), and optional `cellspecR`/`songR` outside mainstream
repositories. Both were available from the declared
`https://cttir.r-universe.dev` repository during the checks.

The required/test-only warning lists unavailable suggested packages and the
missing optional `knitr` vignette builder. Its additional NOTEs report that
vignettes cannot be processed in that closure and HTML math checking is skipped
because `V8` is unavailable. The incoming NOTE is the same class as above.
The full dependency check qualifies documentation; the reduced closure warning
is retained rather than hidden or reported as a clean documentation check.

Independent manual inspection found 40 stale printed contents page numbers in
the stock R check PDF, although hyperlink destinations are correct. The stock
output is preserved; a separate complete manual generated from the exact archive
and converged with two additional TeX/index passes has correct contents and links.
This required no package-source pagination changes.

Repository and shared lint remain report-only (570 and 334 findings respectively);
no rules were disabled. Actionlint reports no findings. The detailed source,
artifact, first-use, site and manual evidence is summarized in
`planning/maintenance-2026-11-03.md` and the isolated audit evidence directory.

---

# Historical checks for version 0.2.0

These results describe source d5959bd from 31 October 2026, not the current
0.2.0.9001 development candidate. Current qualification will be recorded in
planning/maintenance-2026-11-03.md; no new CRAN submission is claimed.

## Test environments

Checked on 2026-10-31:

* Local: R 4.6.1 on macOS 27.0.1 (aarch64-apple-darwin27.0.0), with all
  suggested packages available, vignettes rebuilt, and PDF and HTML manuals
  checked.
* Local: the same environment with `_R_CHECK_DEPENDS_ONLY_=true`.
* GitHub Actions: ubuntu-latest (R devel, oldrel-1, oldrel-3), macOS-latest
  and windows-latest (R release).

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

* The suggested packages 'cellspecR' and 'songR' are not on CRAN or
  Bioconductor. They are declared in `Additional_repositories`
  (<https://cttir.r-universe.dev>) and are used only conditionally: examples,
  tests and vignettes check for them with `requireNamespace()` or
  `skip_if_not_installed()`, and the package works without them.

The example of `RunSONG()` is in `\dontrun{}`: it needs the optional 'songR'
package, whose compiled code does not run on every platform.

Both local `R CMD check --as-cran` runs give the result above. Tests that need
unavailable optional packages are skipped in the dependencies-only run.
