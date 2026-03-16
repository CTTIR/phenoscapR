\name{RipleysK}
\alias{RipleysK}
\title{Ripley's K Function}
\description{
Computes Ripley's K function to assess spatial clustering or
dispersion at multiple scales. The K function counts the average
number of points within distance \code{r} of each point, normalised
by the overall density.
}
\usage{
RipleysK(object, r_seq = NULL, target = NULL,
         correction = c("none", "border"))
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{r_seq}{Numeric vector. Distances at which to evaluate K. If
    \code{NULL}, 20 equally spaced values up to 1/4 of the bounding
    box diagonal are used.}
  \item{target}{Character or \code{NULL}. If set, compute K only for
    cells of this phenotype.}
  \item{correction}{Character. Edge correction: \code{"none"} (default)
    or \code{"border"}.}
}
\value{
A data frame with columns \code{r}, \code{K}, \code{L}
(Besag's L = sqrt(K/pi) - r), and \code{expected} (pi * r^2).
}
\examples{
set.seed(1)
counts <- matrix(rnorm(200), nrow = 100,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
obj <- CreateAkoyaObject(counts, coords)
kf <- RipleysK(obj)
head(kf)
}
