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
