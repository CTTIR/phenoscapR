test_that("array lists become tables with matrix columns", {
  a <- list(xy = matrix(c(1, 2, 3, 4, 5, 6), 3), label = c("a", "b", "a"), names = c("u", "v"),
            feat = matrix(c(0.5, 1, 2, 3, 4, 5), 3), keep = c(TRUE, FALSE, TRUE))
  t <- ArraysTable(a, columns = c(cls = "label", "keep"),
                   matrices = list(xy = c("x", "y"), feat = list(names_from = "names", prefix = "f_")))
  expect_identical(names(t), c("cls", "keep", "x", "y", "f_u", "f_v"))
  expect_identical(t$y, c(4, 5, 6))
  expect_identical(t$f_v, c(3, 4, 5))
  expect_identical(names(ArraysTable(a)), c("label", "keep"))
  expect_error(ArraysTable(a, columns = "zz"), "Unknown array")
  expect_error(ArraysTable(a, matrices = list(xy = "x")), "match")
  expect_error(ArraysTable(list(1, 2)), "named list")
})

test_that("display limits use type-7 quantiles and a margin", {
  d <- data.frame(x = 1:101, y = seq(0, 200, 2), keep = c(rep(TRUE, 100), FALSE))
  l <- EmbeddingLimits(d, keep = list(keep = TRUE), probs = c(0.1, 0.9), pad = 0.5)
  qx <- stats::quantile(1:100, c(0.1, 0.9), names = FALSE)
  expect_equal(l$xmin, qx[1] - 0.5 * diff(qx))
  expect_equal(l$xmax, qx[2] + 0.5 * diff(qx))
  expect_identical(names(l), c("xmin", "xmax", "ymin", "ymax"))
})

test_that("embedding layers keep drawing order and shuffle reproducibly", {
  d <- data.frame(u = 1:20, v = 20:1, type = rep(c("a", "b"), 10), kept = c(rep(TRUE, 15), rep(FALSE, 5)),
                  grp = rep(c("g1", "g2"), each = 10))
  set.seed(99)
  before <- .Random.seed
  l <- EmbeddingLayers(d, "u", "v", carry = "grp", seed = 4, layers = list(
    list(filter = list(kept = TRUE), key = "background"),
    list(filter = list(type = "a"), key_from = "type", shuffle = TRUE, recode = list(a = "A"))))
  expect_identical(.Random.seed, before)
  expect_identical(l$layer, c(rep(1L, 15), rep(2L, 10)))
  expect_identical(l$key[16:25], rep("A", 10))
  expect_setequal(l$x[16:25], d$u[d$type == "a"])
  l2 <- EmbeddingLayers(d, "u", "v", seed = 4, layers = list(list(filter = list(kept = TRUE), key = "background"),
                                                               list(filter = list(type = "a"), key_from = "type", shuffle = TRUE)))
  expect_identical(l$x, l2$x)
  expect_identical(l$grp, d$grp[match(l$x, d$u)])
  expect_error(EmbeddingLayers(d, "u", "v", layers = list(list(key = "x", shuffle = TRUE))), "seed")
})

test_that("cluster labels sit at the median of large clusters", {
  d <- data.frame(x = c(1, 2, 3, 10, 11), y = c(1, 1, 5, 5, 6), cl = c(1, 1, 1, 2, 2), f = TRUE)
  l <- ClusterLabelPositions(d, cluster = "cl", keep = list(f = TRUE), min_points = 3)
  expect_identical(l$label, "1")
  expect_equal(c(l$x, l$y, l$n), c(2, 1, 3))
})

test_that("Gaussian smoothing matches a mirrored direct convolution and keeps the mass", {
  set.seed(5)
  m <- matrix(rpois(30 * 25, 3), 30, 25)
  s <- .figb_gaussian_smooth(m, sigma = 2, truncate = 4)
  r <- 8L
  k <- exp(-0.5 * (-r:r)^2 / 4)
  k <- k / sum(k)
  mirror <- function(i, n) ifelse(i < 1, 1 - i, ifelse(i > n, 2 * n + 1 - i, i))
  pad <- m[mirror(seq(1 - r, 30 + r), 30), mirror(seq(1 - r, 25 + r), 25)]
  direct <- matrix(0, 30, 25)
  for (i in seq_len(30)) for (j in seq_len(25)) {
    direct[i, j] <- sum(outer(k, k) * pad[i:(i + 2 * r), j:(j + 2 * r)])
  }
  expect_equal(s, direct, tolerance = 1e-12)
  expect_equal(sum(s), sum(m), tolerance = 1e-12)
})

test_that("density levels enclose the requested share of the smoothed mass", {
  set.seed(6)
  d <- data.frame(x = c(rnorm(500), rnorm(400, 3)), y = c(rnorm(500), rnorm(400, 2)),
                  g = rep(c("p1", "p2"), c(500, 400)), cl = rep(c("A", "B"), c(500, 400)))
  lim <- data.frame(xmin = -4, xmax = 7, ymin = -4, ymax = 6)
  cont <- DensityLevelContour(d, group = "g", limits = lim, bins = 40, carry = "cl", slot_within = "cl",
                              label_from = "g", label_sub = c("^p", "#"))
  expect_true(all(c("g", "slot", "label", "cl", "kind", "piece", "x", "y", "level", "n") %in% names(cont)))
  expect_setequal(unique(cont$kind), c("band", "line"))
  expect_identical(unique(cont$label), c("#1", "#2"))
  expect_identical(unique(cont$slot), 1L)
  # brute force for one group
  m <- d$g == "p1"
  xe <- seq(-4, 7, length.out = 41)
  ye <- seq(-4, 6, length.out = 41)
  h <- table(factor(findInterval(d$x[m], xe, rightmost.closed = TRUE), levels = 1:40),
             factor(findInterval(d$y[m], ye, rightmost.closed = TRUE), levels = 1:40))
  z <- .figb_gaussian_smooth(unclass(h) * 1, 2, 4)
  v <- sort(as.vector(z), decreasing = TRUE)
  t <- v[which(cumsum(v) >= 0.9 * sum(v))[1]]
  expect_equal(unique(cont$level[cont$g == "p1"]), t)
  expect_gte(sum(z[z >= t]), 0.9 * sum(z))
  expect_lt(sum(z[z > t]), 0.9 * sum(z) + t + 1e-9)
  expect_identical(unique(cont$n[cont$g == "p2"]), 400L)
  expect_error(DensityLevelContour(d, group = "g", limits = lim, carry = "x"), "reuse")
})

test_that("values on nested row subsets are looked up per sample", {
  d <- data.frame(s = c("a", "a", "b", "b"), r = c(0, 2, 1, 0))
  out <- LookupNestedRows(d, "s", "r", samples = c("a", "b"),
                          outer = list(list(counted = c(TRUE, FALSE, TRUE)), c(TRUE, TRUE)),
                          inner = list(list(defined_rows = c(TRUE, TRUE), cn = c(5L, 6L)),
                                       list(defined_rows = c(FALSE, TRUE), cn = 7L)), to = "cn")
  expect_identical(out$cn, c(5L, 6L, 7L, -1L))
  expect_error(LookupNestedRows(d, "s", "r", samples = c("a", "b"), outer = list(TRUE), inner = list(TRUE)), "one entry")
  expect_error(LookupNestedRows(d[1, ], "s", "r", samples = "a", outer = list(c(TRUE, TRUE)), inner = list(TRUE),
                                values = list(1L)), "does not match")
})

test_that("shares, dominant order and column summaries", {
  d <- data.frame(cl = c(2, 2, 1, 1, 1, 3), type = c("b", "b", "a", "a", "c", "c"), v = 1:6, ok = TRUE)
  s <- CrossShares(d, "cl", "type", keep = list(ok = TRUE))
  expect_identical(nrow(s), 9L)
  expect_equal(s$share[s$cl == "1" & s$type == "a"], 200 / 3)
  expect_equal(s$total[s$cl == "2"], rep(2, 3))
  r <- RankByDominant(s, "cl", "type", columns = c("a", "b", "c"), priority = c("b", "a"))
  # cluster 3 is dominated by a type outside the priority list and comes first
  expect_identical(r$cl, c("3", "2", "1"))
  expect_identical(r$dominant, c("c", "b", "a"))
  tie <- CrossShares(data.frame(g = c(1, 1), t = c("x", "y")), "g", "t")
  expect_identical(RankByDominant(tie, "g", "t", columns = c("y", "x"))$dominant, "y")
  m <- SummariseColumns(d, "cl", c("v"), fun = "mean")
  expect_equal(m$value, c(4, 1.5, 6))
  m2 <- SummariseColumns(d, c("cl", "type"), "v", fun = "sum", values_to = "total")
  expect_equal(m2$total[m2$cl == 1 & m2$type == "a"], 7)
  expect_equal(SummariseColumns(d, columns = "v", fun = "sum")$value, 21)
})

test_that("recoding, joining, ranking and reshaping", {
  d <- data.frame(id = c("p1", "p2", "p3"), grp = c("TME-A x", "TME-B y", "other"), code = c(0, 2, -1),
                  "CN1 Tumour" = c(10, 50, 30), "CN2 Tumour mixed" = c(5, 0, 30), "CN3 Vessel" = c(85, 50, 40),
                  check.names = FALSE)
  r <- RecodeColumn(d, "grp", map = c(other = "O"), patterns = c("^TME-A" = "1"), default = "2", to = "g")
  expect_identical(r$g, c("1", "2", "O"))
  r2 <- RecodeColumn(d, "code", index = data.frame(n = c("first", "second", "third")), default = "none", to = "name")
  expect_identical(r2$name, c("first", "third", "none"))
  r3 <- RecodeColumn(d, "grp", extract = "^TME-(.) .*$", map = c(A = "alpha"), to = "x")
  expect_identical(r3$x, c("alpha", "TME-B y", "other"))
  j <- JoinColumns(data.frame(p = c("p3", "p1")), d, by = c(p = "id"), columns = c(area = "code"))
  expect_identical(j$area, c(-1, 0))
  k <- RankRows(d, "id", pattern = "^CN[0-9]+ Tumour")
  expect_identical(k$id, c("p3", "p2", "p1"))
  expect_identical(RankRows(d, "id", columns = "CN3 Vessel", decreasing = FALSE, keep = c("p1", "p2"))$id, c("p2", "p1"))
  l <- ColumnsToLong(d, c("id", "grp"), pattern = "^CN", names_to = "cn", values_to = "pct")
  expect_identical(unique(l$cn), c("CN1 Tumour", "CN2 Tumour mixed", "CN3 Vessel"))
  expect_identical(nrow(l), 9L)
  expect_error(ColumnsToLong(d, "id", pattern = "^zz"), "No value")
  p <- MultiplyColumns(data.frame(n = c(44, 5, 3), pct = c(50, 50, 50)), c("n", "pct"), divide = 100, round = TRUE)
  expect_identical(p$value, c(22, 2, 2))
  s <- ScaleToReference(data.frame(k = 4:6, v = c(50, 40, 25)), "v", to = "rel")
  expect_equal(s$rel, c(1, 0.8, 0.5))
  b <- BindTables(list(a = data.frame(k = 1, v = 2), b = data.frame(k = 3, v = 4, w = 0)), columns = c("k", "v"),
                  labels = c("first", "second"), origin = "set")
  expect_identical(b$set, c("first", "second"))
})

test_that("annotation tracks and alteration classes", {
  d <- data.frame(p = c("s1", "s2", "s3"), grp = c("g1", "g2", "g1"), mut = c("yes", "no", "yes"),
                  arch = c("A (x)", "B", "A"))
  t <- AnnotationTracks(d, "p", list(
    list(name = "Group", column = "grp", colours = c(g1 = "groups/group1", g2 = "#123456")),
    list(name = "Mutation", column = "mut", colours = c(yes = "#222222"), default = "#E0E0E0"),
    list(name = "Architecture", column = "arch", patterns = c("^A" = "#555555"), default = "#D0D0D0")))
  expect_identical(t$colour[t$track == "Group"], c("#009E73", "#123456", "#009E73"))
  expect_identical(t$colour[t$track == "Mutation"], c("#222222", "#E0E0E0", "#222222"))
  expect_identical(t$colour[t$track == "Architecture"], c("#555555", "#D0D0D0", "#555555"))
  expect_identical(unique(t$track_rank), 1:3)
  m <- data.frame(gene = c("G1", "G2", "G3", "G4"), D1 = c("Missense", "", "Nonsense|Splice", "Deletion"),
                  D2 = c("Frameshift|Missense", "Missense", NA, ""), D3 = c("", "Amplification", "Missense", "Deletion"))
  a <- AlterationMatrixData(m, ids = data.frame(p = c("s2", "s1", "s3"), rank = c(1, 2, 3)),
                            id_map = data.frame(pid = c("s1", "s2", "s3"), dna = c("D1", "D2", "D3")),
                            map_from = "pid", map_to = "dna", first = "G4", min_count = 2, last = "G9")
  expect_identical(unique(a$gene), c("G4", "G1", "G2", "G3", "G9"))
  expect_identical(a$class[a$gene == "G1"], c("Multiple", "Missense", NA))
  expect_identical(a$class[a$gene == "G3"], c(NA, "Truncating", "Missense"))
  expect_identical(unique(a$id), c("s2", "s1", "s3"))
  expect_equal(unique(a$percent[a$gene == "G1"]), 200 / 3)
  expect_true(all(is.na(a$class[a$gene == "G9"])))
  expect_error(AlterationMatrixData(m, ids = "s9"), "no column")
})

test_that("counts, key colours and templates", {
  d <- data.frame(g = c("a", "a", "b", "b", "b"), p = c("x", "y", "x", "x", "z"), t = c("T", "U", "T", "T", "U"),
                  f = c(TRUE, TRUE, TRUE, FALSE, TRUE))
  c1 <- CountBy(d, "g", keep = list(f = TRUE), distinct = "p", tally = list(n_t = list(column = "t", values = "T")))
  expect_identical(c1$n, c(2L, 2L))
  expect_identical(c1$n_distinct, c(2L, 2L))
  expect_identical(c1$n_per_distinct, c(1L, 1L))
  expect_identical(c1$n_t, c(1L, 1L))
  expect_equal(c1$share, c(50, 50))
  expect_identical(CountBy(d)$n, 5L)
  k <- KeyColours(data.frame(key = c(3, 1, 22, 0)), palettes = c("tab20", "tab20b"))
  expect_identical(k$key, c("0", "1", "3", "22"))
  expect_identical(k$colour[k$key == "1"], ManuscriptPalettes()$clusters[1])
  expect_identical(k$colour[k$key == "22"], "#5254a3")
  expect_error(KeyColours(1:3, palettes = "nothing"), "Unknown categorical")
  expect_identical(FillTemplate("{n} cells; {s:%.0f}% of {k~cell~cells}", list(n = 12345, s = 37.6, k = 1)),
                   "12,345 cells; 38% of cell")
  expect_identical(FillTemplate("{g} ({k~cell~cells})", data.frame(g = "x", k = 2)), "x (cells)")
  expect_error(FillTemplate("{zz}", list(a = 1)), "No value")
  expect_error(FillTemplate("{a}", list(a = 1:2)), "one distinct")
})
