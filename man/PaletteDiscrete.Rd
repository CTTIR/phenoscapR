\name{PaletteDiscrete}
\alias{PaletteDiscrete}
\title{Generate Discrete Colours}
\description{
Generates \code{n} evenly spaced colours from the current or specified
palette. Useful for colouring phenotypes, clusters, or samples.
}
\usage{
PaletteDiscrete(n, palette = NULL)
}
\arguments{
  \item{n}{Integer. Number of distinct colours needed.}
  \item{palette}{Character or character vector. Palette specification
    (see \code{\link{SetPalette}}). If \code{NULL}, uses the global palette.}
}
\value{
A character vector of \code{n} hex colours.
}
\examples{
cols <- PaletteDiscrete(5)
barplot(rep(1, 5), col = cols)

cols <- PaletteDiscrete(8, palette = c("#1b9e77", "#ffffff", "#d95f02"))
barplot(rep(1, 8), col = cols)
}
