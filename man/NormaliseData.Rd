\name{NormaliseData}
\alias{NormaliseData}
\title{Normalise Marker Intensities}
\description{
Normalises marker intensity values and stores the result in the
\code{data} slot of the object. The raw counts remain unchanged.
}
\usage{
NormaliseData(object, method = c("zscore", "minmax", "quantile"),
             markers = NULL)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{method}{Character. Normalisation method: \code{"zscore"} (default),
    \code{"minmax"}, or \code{"quantile"}.}
  \item{markers}{Character vector or \code{NULL}. Markers to normalise. If
    \code{NULL}, all markers are normalised.}
}
\value{
An \code{\link{AkoyaExperiment}} with updated \code{data} slot.
}
\examples{
counts <- matrix(rnorm(100, 500, 100), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
coords <- data.frame(x = runif(20), y = runif(20))
obj <- CreateAkoyaObject(counts, coords)
obj <- NormaliseData(obj, method = "zscore")
head(GetData(obj))
}
