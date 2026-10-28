brute_counts <- function(cells, edges, groups, max_edge) {
  map <- stats::setNames(rep(seq_along(groups), lengths(groups)), unlist(groups))
  t <- map[cells$type]
  d <- sqrt((cells$x[edges[, 1]] - cells$x[edges[, 2]])^2 +
              (cells$y[edges[, 1]] - cells$y[edges[, 2]])^2)
  edges <- edges[d <= max_edge, , drop = FALSE]
  m <- matrix(0L, nrow(cells), length(groups))
  for (e in seq_len(nrow(edges))) {
    i <- edges[e, 1]
    j <- edges[e, 2]
    m[i, t[j]] <- m[i, t[j]] + 1L
    m[j, t[i]] <- m[j, t[i]] + 1L
  }
  m
}

test_that("a square with a centre point has the known triangulation", {
  skip_if_not_installed("sf")
  cells <- data.frame(x = c(0, 10, 10, 0, 5), y = c(0, 0, 10, 10, 5.5),
                      type = c("a", "a", "b", "b", "c"))
  out <- NeighbourTypeCounts(cells, levels = list(A = "a", B = "b", C = "c"))
  # Hull: 4 sides; the centre connects to all corners: 8 edges.
  expect_identical(attr(out, "full_edges"), 8L)
  expect_identical(out$degree, c(3L, 3L, 3L, 3L, 4L))
  expect_identical(out$C, c(1L, 1L, 1L, 1L, 0L))
  expect_identical(unname(unlist(out[5, c("A", "B", "C")])), c(2L, 2L, 0L))
  cut <- NeighbourTypeCounts(cells, levels = list(A = "a", B = "b", C = "c"), max_edge = 9)
  expect_identical(attr(cut, "edges"), 4L)
  expect_identical(cut$degree, c(1L, 1L, 1L, 1L, 4L))
  zero <- NeighbourTypeCounts(cells, levels = list(A = "a", B = "b", C = "c"), index_base = 0)
  expect_identical(zero$type_index, c(0L, 0L, 1L, 1L, 2L))
})

test_that("GEOS counts equal brute-force counts over deldir edges", {
  skip_if_not_installed("sf")
  skip_if_not_installed("deldir")
  set.seed(4)
  cells <- data.frame(x = stats::runif(300, 0, 200), y = stats::runif(300, 0, 200),
                      type = sample(c("a", "b", "c", "d"), 300, replace = TRUE))
  groups <- list(A = "a", BC = c("b", "c"), D = "d")
  out <- NeighbourTypeCounts(cells, levels = groups, max_edge = 15)
  dd <- deldir::deldir(cells$x, cells$y)$delsgs
  edges <- cbind(dd$ind1, dd$ind2)
  ref <- brute_counts(cells, edges, groups, 15)
  expect_identical(unname(as.matrix(out[c("A", "BC", "D")])), ref)
  expect_identical(attr(out, "full_edges"), nrow(edges))
  expect_identical(sum(out$degree), 2L * attr(out, "edges"))
})

test_that("the deldir engine needs no backend contract and agrees with GEOS", {
  skip_if_not_installed("sf")
  skip_if_not_installed("deldir")
  set.seed(4)
  cells <- data.frame(x = stats::runif(300, 0, 200), y = stats::runif(300, 0, 200),
                      type = sample(c("a", "b", "c", "d"), 300, replace = TRUE))
  groups <- list(A = "a", BC = c("b", "c"), D = "d")
  geos <- NeighbourTypeCounts(cells, levels = groups, max_edge = 15)
  dd <- NeighbourTypeCounts(cells, levels = groups, max_edge = 15, engine = "deldir")
  expect_identical(attr(dd, "engine"), "deldir")
  old <- NeighbourTypeCounts(cells, levels = groups, max_edge = 15, engine = "deldir",
                             backend_contract = list(package_version = "2.0-4"))
  expect_identical(old, dd)
  attr(dd, "engine") <- attr(geos, "engine") <- NULL
  expect_identical(dd, geos)
})

test_that("duplicates and undeclared types are refused or isolated", {
  skip_if_not_installed("sf")
  cells <- data.frame(x = c(0, 10, 0, 10, 5, 0), y = c(0, 0, 10, 10, 4, 0),
                      type = c("a", "a", "b", "b", "b", "a"))
  expect_error(NeighbourTypeCounts(cells, levels = c("a", "b")), "Duplicate")
  iso <- NeighbourTypeCounts(cells, levels = c("a", "b"), duplicates = "isolate")
  expect_identical(iso$degree[6], 0L)
  expect_identical(iso$degree[1], 3L)
  expect_identical(iso$degree[5], 4L)
  expect_error(NeighbourTypeCounts(cells, levels = "a", duplicates = "isolate"), "outside")
  expect_error(NeighbourTypeCounts(cells, levels = list(x = "a", y = "b"),
                                   duplicates = "isolate"), "collide")
})
