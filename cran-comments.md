## Test environments

* Local: R 4.6.1 on Ubuntu 26.04 LTS (x86_64-pc-linux-gnu), with the PDF
  manual built by LaTeX.
* GitHub Actions: ubuntu-latest (R release, devel, oldrel-1), macOS-latest
  and windows-latest (R release).

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission. The development version number 0.1.1.9000 will
  be replaced by a release version before submission.

* The suggested packages 'cellspecR' and 'songR' are not on CRAN or
  Bioconductor. They are declared in `Additional_repositories`
  (<https://cttir.r-universe.dev>) and are used only conditionally: examples,
  tests and vignettes check for them with `requireNamespace()` or
  `skip_if_not_installed()`, and the package works without them.

A check with `_R_CHECK_DEPENDS_ONLY_=true` (no suggested packages available)
also passes.
