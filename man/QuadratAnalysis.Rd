\name{QuadratAnalysis}
\alias{QuadratAnalysis}
\title{Quadrat Analysis}
\description{
Divides the tissue area into a grid of quadrats and counts cells
per quadrat. Tests for Complete Spatial Randomness (CSR) using a
chi-squared test.
}
\usage{
QuadratAnalysis(object, nx = 5L, ny = 5L, target = NULL)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{nx}{Integer. Number of quadrats along x. Default \code{5}.}
  \item{ny}{Integer. Number of quadrats along y. Default \code{5}.}
  \item{target}{Character or \code{NULL}. If set, only count cells of
    this phenotype.}
}
\value{
A list with \code{counts} (matrix of counts per quadrat),
\code{chi_sq} (chi-squared statistic), \code{p_value}, and
\code{VMR} (variance-to-mean ratio; >1 = clustered, <1 = regular).
}
\examples{
set.seed(1)
counts <- matrix(rnorm(200), nrow = 100,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
obj <- CreateAkoyaObject(counts, coords)
qa <- QuadratAnalysis(obj, nx = 4, ny = 4)
qa$VMR
}
