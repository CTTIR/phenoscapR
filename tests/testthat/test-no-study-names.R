# Package code, tests, documentation and bundled files must be study-neutral:
# study names, private sample identifiers, people and local paths live in
# study configuration, never in phenoscapR.

test_that("no study-specific names occur in package code, tests or documentation", {
  # The terms (a regular expression) come from the environment, never from
  # this file.
  private <- Sys.getenv("CTTIR_PRIVATE_TERMS")
  skip_if(!nzchar(private), "CTTIR_PRIVATE_TERMS is not set")
  pkg_root <- testthat::test_path("..", "..")
  skip_if_not(dir.exists(file.path(pkg_root, "R")), "package sources not available (installed test run)")
  dirs <- c("R", "tests", "man", "vignettes", "inst", "data-raw")
  files <- unlist(lapply(dirs, function(d) {
    list.files(file.path(pkg_root, d), recursive = TRUE, full.names = TRUE,
               pattern = "\\.(R|r|Rd|Rmd|md|json|txt|yml|yaml|csv|tsv)$")
  }))
  top <- file.path(pkg_root, c("DESCRIPTION", "NEWS.md", "README.md", "README.Rmd", "_pkgdown.yml"))
  files <- c(files, top[file.exists(top)])
  hits <- unlist(lapply(files, function(f) {
    lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
    which_hit <- grep(private, lines, perl = TRUE)
    if (length(which_hit)) paste0(sub(paste0("^", pkg_root, "/?"), "", f), ":", which_hit) else character()
  }), use.names = FALSE)
  if (is.null(hits)) hits <- character()
  expect_identical(hits, character())
})
