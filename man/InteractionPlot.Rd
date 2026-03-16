\name{InteractionPlot}
\alias{InteractionPlot}
\title{Plot Spatial Interaction Heatmap}
\description{
Heatmap of pairwise spatial interaction scores between phenotypes.
}
\usage{
InteractionPlot(interactions, title = NULL)
}
\arguments{
  \item{interactions}{Data frame as returned by
    \code{\link{InteractionMatrix}}.}
  \item{title}{Character or \code{NULL}.}
}
\value{
A \code{ggplot} object.
}
\examples{
interactions <- data.frame(
  from = rep(c("CD3+", "CD8+"), each = 2),
  to = rep(c("CD3+", "CD8+"), 2),
  observed = c(50, 30, 25, 40),
  expected = rep(35, 4),
  interaction_score = log2(c(50, 30, 25, 40) / 35)
)
InteractionPlot(interactions)
}
