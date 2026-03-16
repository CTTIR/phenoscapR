\name{DelaunayNetwork}
\alias{DelaunayNetwork}
\title{Delaunay Triangulation Network}
\description{
Computes a Delaunay triangulation of cell positions and stores edges
in the spatial slot. Used for spatial network visualisation and
neighbourhood analysis.
}
\usage{
DelaunayNetwork(object, max_edge = NULL)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{max_edge}{Numeric or \code{NULL}. Maximum edge length to retain.
    Removes very long edges that connect distant cells. Default
    \code{NULL} (keep all).}
}
\details{
Uses a sweep-line approach to compute Delaunay triangulation in pure
R. For very large datasets (>50k cells), consider subsetting first.
}
\value{
An \code{\link{AkoyaExperiment}} with \code{delaunay_edges}
(data frame with \code{from}, \code{to}, \code{distance}) stored in
the \code{spatial} slot.
}
\examples{
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
obj <- CreateAkoyaObject(counts, coords)
obj <- DelaunayNetwork(obj)
head(obj@spatial$delaunay_edges)
}
