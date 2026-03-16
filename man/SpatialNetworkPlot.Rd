\name{SpatialNetworkPlot}
\alias{SpatialNetworkPlot}
\title{Plot Spatial Network}
\description{
Plots cells as circles connected by edges from Delaunay triangulation
or nearest-neighbour graph, coloured by phenotype. Matches the
network visualisation style with coloured nodes on dark background.
}
\usage{
SpatialNetworkPlot(object, edges = NULL, colour_by = "phenotype",
                   colours = NULL, pt_size = 2,
                   edge_alpha = 0.15, edge_colour = "grey60",
                   dark_theme = TRUE)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{edges}{Data frame with columns \code{from} and \code{to}
    (row indices), as returned by \code{\link{DelaunayNetwork}} or
    \code{\link{FindNeighbours}}. If \code{NULL} and the spatial slot
    contains \code{delaunay_edges}, those are used.}
  \item{colour_by}{Character. Metadata column for node colour. Default
    \code{"phenotype"}.}
  \item{colours}{Named character vector or \code{NULL}.}
  \item{pt_size}{Numeric. Node size. Default \code{2}.}
  \item{edge_alpha}{Numeric. Edge transparency. Default \code{0.15}.}
  \item{edge_colour}{Character. Edge colour. Default \code{"grey60"}.}
  \item{dark_theme}{Logical. Default \code{TRUE}.}
}
\value{
A \code{ggplot} object.
}
\examples{
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
meta <- data.frame(cell_id = 1:50, sample_id = "s1",
                   phenotype = sample(c("A", "B"), 50, TRUE))
obj <- CreateAkoyaObject(counts, coords, meta)
obj <- DelaunayNetwork(obj)
SpatialNetworkPlot(obj)
}
