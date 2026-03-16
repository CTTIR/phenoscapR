\name{CrossNNDistance}
\alias{CrossNNDistance}
\title{Cross-type Nearest Neighbour Distance}
\description{
Computes the nearest neighbour distance from each cell of one
phenotype to cells of another phenotype.
}
\usage{
CrossNNDistance(object, from, to)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object with a
    \code{phenotype} column.}
  \item{from}{Character. Source phenotype.}
  \item{to}{Character. Target phenotype.}
}
\value{
A numeric vector of distances (one per cell of the \code{from}
phenotype).
}
\examples{
set.seed(1)
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
meta <- data.frame(cell_id = 1:50, sample_id = "s1",
                   phenotype = sample(c("A", "B"), 50, TRUE))
obj <- CreateAkoyaObject(counts, coords, meta)
dists <- CrossNNDistance(obj, from = "A", to = "B")
summary(dists)
}
