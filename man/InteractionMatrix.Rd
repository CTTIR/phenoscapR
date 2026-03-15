\name{InteractionMatrix}
\alias{InteractionMatrix}
\title{Spatial Interaction Matrix}
\description{
Computes pairwise spatial interaction scores between phenotypes by
comparing observed neighbour frequencies within a radius to those
expected under random mixing.
}
\usage{
InteractionMatrix(object, radius)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object with a
    \code{phenotype} column.}
  \item{radius}{Numeric. Neighbourhood radius.}
}
\value{
A data frame with columns \code{from}, \code{to},
  \code{observed}, \code{expected}, and \code{interaction_score}
  (\code{log2(observed / expected)}). Positive values indicate spatial
  attraction; negative values indicate avoidance.
}
\examples{
set.seed(42)
counts <- matrix(rnorm(200), nrow = 100,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
meta <- data.frame(cell_id = 1:100, sample_id = "s1")
obj <- CreateAkoyaObject(counts, coords, meta)
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
result <- InteractionMatrix(obj, radius = 80)
result
}
