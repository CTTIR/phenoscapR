#' Launch the phenoscapR Shiny Application
#'
#' Opens an interactive, Hugo Coder-themed Shiny interface to the package's
#' analysis functions: load the bundled example data (or your own object),
#' run quality control, phenotyping, spatial statistics, cellular
#' neighbourhoods, spatial domains, dimensionality reductions, and differential
#' abundance, and explore the results with live plots and tables.
#'
#' The app ships in \code{inst/app}. It depends on optional packages (Shiny,
#' bslib, sass, thematic, reactable, bsicons); \code{run_app()} checks for them
#' and reports any that are missing.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}} (e.g.
#'   \code{launch.browser}, \code{port}, \code{host}).
#'
#' @return Called for its side effect of launching the app; returns the value of
#'   \code{\link[shiny]{runApp}} invisibly.
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
#'
#' @export
run_app <- function(...) {
  needed <- c("shiny", "bslib", "sass", "thematic", "reactable", "bsicons",
              "brand.yml")
  missing <- needed[!vapply(needed, requireNamespace, logical(1L),
                            quietly = TRUE)]
  if (length(missing) > 0L) {
    stop("run_app() needs these packages: ", paste(missing, collapse = ", "),
         ".\nInstall them with install.packages(c(",
         paste0("\"", missing, "\"", collapse = ", "), ")).", call. = FALSE)
  }
  app_dir <- system.file("app", package = "phenoscapR")
  if (!nzchar(app_dir)) {
    stop("Could not locate the app directory; try reinstalling phenoscapR.",
         call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}
