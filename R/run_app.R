#' Launch the phenoscapR Shiny Application
#'
#' Opens an interactive, Hugo Coder-themed Shiny interface to the package's
#' analysis functions using the bundled synthetic teaching data:
#' run quality control, spatial statistics, cellular
#' neighbourhoods, spatial domains, dimensionality reductions, and differential
#' abundance, and explore the results with live plots and tables. Simulated
#' phenotypes are supplied with the example. This app does not import user
#' objects or export results; use the package functions for those workflows.
#' Each example section is one sample, so differential-abundance p-values
#' are not suitable for replicated group inference.
#'
#' The app ships in \code{inst/app}. It depends on optional packages (Shiny,
#' bslib, sass, thematic, reactable, bsicons); \code{run_app()} checks for them
#' and reports any that are missing. Branding requires bslib >= 0.9.0.
#' The optional UMAP view requires uwot; PCA remains available without it.
#' If QC removes every cell, widen or reset the cell-area filter.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}} (e.g.
#'   \code{launch.browser}, \code{port}, \code{host}).
#'
#' @return Called for its side effect of launching the app; returns the value of
#'   \code{\link[shiny]{runApp}} invisibly.
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }
#'
#' @export
run_app <- function(...) {
  needed <- c("shiny", "bslib", "sass", "thematic", "reactable", "bsicons",
              "brand.yml")
  missing <- needed[!vapply(needed, function(pkg)
    requireNamespace(pkg, quietly = TRUE), logical(1L))]
  if (length(missing) > 0L) {
    stop("run_app() needs these packages: ", paste(missing, collapse = ", "),
         ".\nInstall them with install.packages(c(",
         paste0("\"", missing, "\"", collapse = ", "), ")).", call. = FALSE)
  }
  if (.app_bslib_version() < "0.9.0") {
    stop('run_app() needs bslib >= 0.9.0; update with install.packages("bslib").',
         call. = FALSE)
  }
  app_dir <- system.file("app", package = "phenoscapR")
  if (!nzchar(app_dir)) {
    stop("Could not locate the app directory; try reinstalling phenoscapR.",
         call. = FALSE)
  }
  .run_shiny_app(app_dir, ...)
}

# shiny::runApp() behind a package function so tests can replace the launch.
.run_shiny_app <- function(app_dir, ...) shiny::runApp(app_dir, ...)

# Keep optional version detection testable without modifying another namespace.
.app_bslib_version <- function() utils::packageVersion("bslib")
