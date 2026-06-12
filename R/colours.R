#' Set or Get the Default Colour Palette
#'
#' Sets a global colour palette used by all plotting functions in phenoscapR.
#' The palette can be a viridis option, a custom gradient defined by 2-3
#' anchor colours, or a named vector of discrete colours.
#'
#' @param palette Character or named character vector. Either:
#'   \itemize{
#'     \item A viridis-family palette name: \code{"viridis"} (default),
#'       \code{"inferno"}, \code{"plasma"}, \code{"cividis"},
#'       \code{"rocket"}, or \code{"mako"}.
#'     \item A character vector of 2-3 hex colours for a custom gradient
#'       (e.g. \code{c("#440154", "#21918c", "#fde725")}).
#'     \item \code{NULL} to return the current palette without changing it.
#'   }
#'   An unrecognised name falls back to \code{"viridis"} rather than erroring.
#'
#' @return Invisibly returns the previous palette setting.
#'
#' @examples
#' SetPalette("inferno")
#' GetPalette()
#'
#' # Custom 3-colour gradient
#' SetPalette(c("navy", "white", "firebrick"))
#' GetPalette()
#'
#' # Reset to default
#' SetPalette("viridis")
#'
#' @export
SetPalette <- function(palette) {
  old <- getOption("phenoscapR.palette", default = "viridis")
  options(phenoscapR.palette = palette)
  invisible(old)
}

#' @rdname SetPalette
#' @export
GetPalette <- function() {
  getOption("phenoscapR.palette", default = "viridis")
}

#' Generate a Continuous Colour Palette Function
#'
#' Returns a function that maps numeric values to colours based on the
#' current or specified palette. Works with \code{ggplot2} via
#' \code{scale_colour_gradientn} / \code{scale_fill_gradientn}.
#'
#' @param n Integer. Number of colours to generate. Default \code{256}.
#' @param palette Character or character vector. Palette specification
#'   (see \code{\link{SetPalette}}). If \code{NULL}, uses the global palette.
#'
#' @return A character vector of \code{n} hex colours.
#'
#' @examples
#' cols <- PaletteContinuous(10)
#' plot(1:10, col = cols, pch = 19, cex = 3)
#'
#' cols <- PaletteContinuous(10, palette = c("blue", "white", "red"))
#' plot(1:10, col = cols, pch = 19, cex = 3)
#'
#' @export
#' @importFrom grDevices colorRampPalette
PaletteContinuous <- function(n = 256L, palette = NULL) {
  if (is.null(palette)) palette <- GetPalette()
  .make_continuous_colours(palette, n)
}

#' Generate Discrete Colours
#'
#' Generates \code{n} evenly spaced colours from the current or specified
#' palette. Useful for colouring phenotypes, clusters, or samples.
#'
#' @param n Integer. Number of distinct colours needed.
#' @param palette Character or character vector. Palette specification
#'   (see \code{\link{SetPalette}}). If \code{NULL}, uses the global palette.
#'
#' @return A character vector of \code{n} hex colours.
#'
#' @examples
#' cols <- PaletteDiscrete(5)
#' barplot(rep(1, 5), col = cols)
#'
#' cols <- PaletteDiscrete(8, palette = c("#1b9e77", "#ffffff", "#d95f02"))
#' barplot(rep(1, 8), col = cols)
#'
#' @export
PaletteDiscrete <- function(n, palette = NULL) {
  if (is.null(palette)) palette <- GetPalette()
  .make_continuous_colours(palette, n)
}

#' Create a Custom Gradient Palette from Anchor Colours
#'
#' Creates a gradient palette function from 2 or 3 anchor colours. The
#' returned function takes an integer \code{n} and returns \code{n} colours.
#'
#' @param colours Character vector of 2-3 colours (names or hex codes).
#'
#' @return A function that takes integer \code{n} and returns \code{n}
#'   hex colour codes.
#'
#' @examples
#' pal <- CustomGradient(c("navy", "white", "firebrick"))
#' cols <- pal(100)
#' image(matrix(1:100, ncol = 1), col = cols)
#'
#' @export
CustomGradient <- function(colours) {
  if (length(colours) < 2L || length(colours) > 3L) {
    stop("colours must be a vector of 2 or 3 colours.", call. = FALSE)
  }
  grDevices::colorRampPalette(colours)
}

# --- Internal helpers --------------------------------------------------------

#' Resolve palette to a vector of n colours
#' @noRd
.make_continuous_colours <- function(palette, n) {
  if (length(palette) == 1L && is.character(palette)) {
    if (tolower(palette) %in% .viridis_palettes()) {
      return(.viridis_colours(n, tolower(palette)))
    }
    # Single colour name or hex code — create a white -> colour gradient.
    if (palette %in% grDevices::colours() || grepl("^#", palette)) {
      return(grDevices::colorRampPalette(c("white", palette))(n))
    }
    # Unrecognised palette: fall back to the default rather than erroring, so a
    # stray SetPalette() can never crash a plot.
    return(.viridis_colours(n, "viridis"))
  }
  # Vector of 2-3 colours: custom gradient
  if (is.character(palette) && length(palette) >= 2L && length(palette) <= 3L) {
    return(grDevices::colorRampPalette(palette)(n))
  }
  # Named vector of colours (discrete) — just return as-is or cycle
  if (length(palette) >= n) {
    return(palette[seq_len(n)])
  }
  rep_len(palette, n)
}

#' Names of the supported viridis-family palettes
#'
#' Only the palettes that `grDevices::hcl.colors()` actually provides are
#' advertised, so every name here is guaranteed to resolve.
#' @noRd
.viridis_palettes <- function() {
  c("viridis", "inferno", "plasma", "cividis", "rocket", "mako")
}

#' Generate viridis-family colours using base R
#'
#' Self-contained colour generation via `grDevices::hcl.colors()` (available
#' since R 3.6.0), with no external dependency. Any unrecognised option falls
#' back to Viridis rather than erroring.
#'
#' @noRd
.viridis_colours <- function(n, option = "viridis") {
  palette_name <- switch(tolower(option),
    viridis = "Viridis",
    inferno = "Inferno",
    plasma  = "Plasma",
    cividis = "Cividis",
    rocket  = "Rocket",
    mako    = "Mako",
    "Viridis"
  )
  if (!palette_name %in% grDevices::hcl.pals()) palette_name <- "Viridis"
  grDevices::hcl.colors(n, palette = palette_name)
}

#' Get ggplot2 continuous colour scale using current palette
#' @noRd
#' @importFrom ggplot2 scale_colour_gradientn scale_fill_gradientn
.gg_continuous_scale <- function(aesthetic = "colour", palette = NULL, ...) {
  cols <- PaletteContinuous(256L, palette)
  if (aesthetic == "fill") {
    ggplot2::scale_fill_gradientn(colours = cols, ...)
  } else {
    ggplot2::scale_colour_gradientn(colours = cols, ...)
  }
}

#' Get ggplot2 discrete colour scale using current palette
#' @noRd
#' @importFrom ggplot2 scale_colour_manual scale_fill_manual
.gg_discrete_scale <- function(aesthetic = "colour", n, palette = NULL, ...) {
  cols <- PaletteDiscrete(n, palette)
  if (aesthetic == "fill") {
    ggplot2::scale_fill_manual(values = cols, ...)
  } else {
    ggplot2::scale_colour_manual(values = cols, ...)
  }
}
