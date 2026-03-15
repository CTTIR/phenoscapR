\name{SpatialClusters}
\alias{SpatialClusters}
\title{Spatial Cell Clustering}
\description{
Clusters cells based on their spatial coordinates using k-means or
hierarchical clustering.
}
\usage{
SpatialClusters(object, k, method = c("kmeans", "hierarchical"))
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
  \item{k}{Integer. Number of clusters.}
  \item{method}{Character. \code{"kmeans"} (default) or
    \code{"hierarchical"}.}
}
\value{
An \code{\link{AkoyaExperiment}} with a \code{cluster} column
  added to \code{meta_data}.
}
\examples{
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(
  x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
  y = c(rnorm(25, 0, 5), rnorm(25, 50, 5))
)
obj <- CreateAkoyaObject(counts, coords)
obj <- SpatialClusters(obj, k = 2)
table(Meta(obj)$cluster)
}
