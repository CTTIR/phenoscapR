exhaustive_p <- function(v, a) {
  na <- sum(a)
  obs <- mean(v[a]) - mean(v[!a])
  null <- apply(utils::combn(length(v), na), 2, function(i) mean(v[i]) - mean(v[-i]))
  mean(abs(null) >= abs(obs) - 1e-12)
}

patients <- data.frame(
  patient = paste0("p", 1:7), arm = c("x", "x", "x", "y", "y", "z", "z"),
  e1 = c(1.5, 2, 3, 6, 7.25, NA, 4), e2 = c(5, 4, 6, 1, 2, 3, 3.5),
  e3 = c(NA, NA, NA, 1, 2, 3, 4)
)
registry <- data.frame(
  family = c("f1", "f1", "f2", "f2", "f1"),
  endpoint = c("e1", "e2", "e1", "e2", "e3"),
  contrast = c("x vs y", "x vs y", "xy vs z", "xy vs z", "x vs y")
)
contrasts <- list("x vs y" = list(A = "x", B = "y"),
                  "xy vs z" = list(A = c("x", "y"), B = "z"))

test_that("complete-case contrasts equal direct exhaustive tests", {
  out <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm")
  expect_identical(out$hypothesis_id, paste0("h", 1:5))
  expect_identical(out$family_id, paste(registry$family, registry$contrast, sep = " :: "))
  # e1, x vs y: all finite
  v <- patients$e1[1:5]
  a <- patients$arm[1:5] == "x"
  expect_equal(out$p_value[1], exhaustive_p(v, a), tolerance = 0)
  expect_equal(out$mean_difference[1], mean(v[a]) - mean(v[!a]))
  # e1, xy vs z: p6 missing, dropped
  keep <- c(1:5, 7)
  v <- patients$e1[keep]
  a <- patients$arm[keep] %in% c("x", "y")
  expect_equal(out$p_value[3], exhaustive_p(v, a), tolerance = 0)
  expect_identical(out$n_b_evaluable[3], 1L)
  expect_identical(out$n_b_expected[3], 2L)
  # e3, x vs y: arm x has no finite value
  expect_identical(out$status[5], "UNAVAILABLE_EMPTY_ARM")
  expect_true(is.na(out$p_value[5]))
})

test_that("require_complete leaves incomplete hypotheses unavailable", {
  out <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm",
                                  missingness = "require_complete")
  expect_identical(out$status[3], "UNAVAILABLE_INCOMPLETE")
  expect_true(is.na(out$p_value[3]))
  cc <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm")
  expect_identical(out$p_value[c(1, 2, 4)], cc$p_value[c(1, 2, 4)])
  adjusted <- AdjustPatientFamilies(out, policy = "declared")
  expect_identical(nrow(adjusted$tests), 5L)
  expect_identical(adjusted$families$n_declared, c(3L, 2L))
})

test_that("invalid declarations fail", {
  expect_error(ContrastPatientEndpoints(patients, registry,
    list("x vs y" = list(A = "x", B = "x"), "xy vs z" = contrasts[[2]]), "patient", "arm"),
    "disjoint")
  bad <- registry
  bad$endpoint[1] <- "missing"
  expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
               "Unknown endpoint")
  bad <- registry
  bad$contrast[1] <- "other"
  expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
               "Unknown contrast")
})

test_that("distinct declared families cannot merge through label separators", {
  d <- data.frame(patient = letters[1:4], arm = c("x", "x", "y", "y"),
                   e1 = c(1, 2, 9, 10), e2 = c(1, 9, 2, 10))
  reg <- data.frame(endpoint = c("e1", "e2"), contrast = c("c", "b :: c"),
                     family = c("a :: b", "a"))
  ctr <- list(c = list(A = "x", B = "y"), "b :: c" = list(A = "x", B = "y"))
  # Previously both rows became family_id "a :: b :: c", so the second
  # hypothesis changed the first one's multiplicity-adjusted p value.
  expect_error(ContrastPatientEndpoints(d, reg, ctr, "patient", "arm"),
               "reserved separator")
  # A separator on either side alone must also be refused, even when the
  # registry currently contains no colliding partner.
  for (i in 1:2) {
    expect_error(ContrastPatientEndpoints(d, reg[i, ], ctr, "patient", "arm"),
                 "reserved separator")
  }
  # The spaced separator also overlaps its own boundary. Neither component
  # below contains " :: ", but concatenation would still merge the two pairs.
  overlap <- reg
  overlap$family <- c("a ::", "a")
  overlap$contrast <- c("b", ":: b")
  names(ctr) <- overlap$contrast
  expect_error(ContrastPatientEndpoints(d, overlap, ctr, "patient", "arm"),
               "reserved separator")
  reg$family <- c("a:b", "a")
  reg$contrast <- c("c", "b:c")
  names(ctr) <- reg$contrast
  out <- ContrastPatientEndpoints(d, reg, ctr, "patient", "arm")
  expect_identical(out$family_id, c("a:b :: c", "a :: b:c"))
  adjusted <- AdjustPatientFamilies(out, policy = "declared")
  expect_identical(adjusted$families$n_declared, c(1L, 1L))
  expect_equal(adjusted$tests$p_adjusted, out$p_value)
})

test_that("family and contrast labels cannot be missing or blank", {
  for (column in c("family", "contrast")) {
    for (invalid in c(NA_character_, "", "   ")) {
      bad <- registry
      bad[[column]][1] <- invalid
      expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
                   "nonmissing, nonblank")
    }
  }
  factored <- registry
  factored$family <- factor(factored$family)
  factored$contrast <- factor(factored$contrast)
  expect_identical(
    ContrastPatientEndpoints(patients, factored, contrasts, "patient", "arm")$family_id,
    ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm")$family_id)
})

test_that("matrix patient identifiers cannot manufacture independent patients", {
  d <- data.frame(patient = letters[1:4], arm = c("x", "x", "y", "y"), e1 = 1:4)
  reg <- data.frame(endpoint = "e1", contrast = "c", family = "f")
  ctr <- list(c = list(A = "x", B = "y"))
  baseline <- ContrastPatientEndpoints(d, reg, ctr, "patient", "arm")
  expect_equal(baseline$p_value, 1 / 3)
  # Previously the second ID column doubled each measurement under a new ID,
  # changing six allocations into 70 and p = 1/3 into p = 2/70.
  bad <- d
  bad$patient <- I(matrix(letters[1:8], nrow = 4L))
  expect_error(ContrastPatientEndpoints(bad, reg, ctr, "patient", "arm"),
               "dimensionless atomic vectors")
  for (column in c("patient", "arm")) {
    for (shape in list(c(4L, 1L), c(4L, 2L), c(4L, 1L, 2L))) {
      bad <- d
      bad[[column]] <- I(array(rep(d[[column]], length.out = prod(shape)), dim = shape))
      expect_error(ContrastPatientEndpoints(bad, reg, ctr, "patient", "arm"),
                   "dimensionless atomic vectors")
    }
  }
  for (shape in list(c(4L, 1L), c(4L, 2L), c(4L, 1L, 2L))) {
    bad <- d
    bad$e1 <- I(array(rep(d$e1, length.out = prod(shape)), dim = shape))
    expect_error(ContrastPatientEndpoints(bad, reg, ctr, "patient", "arm"),
                 "dimensionless numeric vector")
  }
  d$patient <- factor(d$patient)
  d$arm <- factor(d$arm)
  expect_identical(ContrastPatientEndpoints(d, reg, ctr, "patient", "arm"), baseline)
})

test_that("registry columns cannot silently hide additional hypotheses", {
  for (column in c("endpoint", "contrast", "family")) {
    for (shape in list(c(nrow(registry), 1L), c(nrow(registry), 2L),
                       c(nrow(registry), 1L, 2L))) {
      bad <- registry
      bad[[column]] <- I(array(rep(registry[[column]], length.out = prod(shape)), dim = shape))
      expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
                   "dimensionless atomic vectors")
    }
  }
})
