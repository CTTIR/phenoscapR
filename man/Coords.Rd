\name{Coords}
\alias{Coords}
\alias{Coords,AkoyaExperiment-method}
\title{Get Spatial Coordinates}
\description{
Returns the spatial coordinates from an \code{\link{AkoyaExperiment}} object.
}
\usage{
Coords(object)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
}
\value{
Data frame with columns \code{x} and \code{y}.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
Coords(obj)
}
