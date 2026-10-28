# Annotation tracks and alteration classes for annotated matrices.

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
