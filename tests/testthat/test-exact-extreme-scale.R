exact_scaled_fixture <- function(values) {
  n <- length(values)
  list(endpoints = data.frame(endpoint_id = "e", patient_id = letters[seq_len(n)],
                              value = values, eligible = TRUE),
       design = data.frame(contrast_id = "c", patient_id = letters[seq_len(n)],
                           group = rep(c("A", "B"), each = n / 2)),
       hypotheses = data.frame(hypothesis_id = "h", endpoint_id = "e",
                               contrast_id = "c", family_id = "f"))
}

test_that("finite exact allocation p values retain their value after large rescaling", {
  # For ordered four/six-patient endpoints with equally sized groups, only the
  # two endpoint allocations attain the largest absolute mean difference.
  for (n in c(4L, 6L)) {
    expected <- 2 / choose(n, n / 2)
    for (direction in c(-1, 1)) {
      ordinary <- direction * (seq_len(n) - 1)
      baseline <- do.call(ExactPatientTests, exact_scaled_fixture(ordinary))
      large <- do.call(ExactPatientTests, exact_scaled_fixture(ordinary * 1e307))
      expect_equal(baseline$p_value, expected)
      expect_identical(large$p_value, baseline$p_value)
      expect_identical(large$allocations, baseline$allocations)
      expect_identical(large$status, "EXACT")
      expect_true(is.finite(large$mean_difference))
      expect_equal(large$mean_difference / 1e307, baseline$mean_difference)
    }
  }
})

test_that("ordinary exact allocation counts agree with independent integer sums", {
  fixtures <- list(c(0, 1, 2, 3), c(0, 1, 1, 2), c(-3, -1, 0, 4),
                   c(-4, -1, 0, 1, 3, 8))
  for (values in fixtures) {
    n <- length(values)
    k <- n / 2
    # Equal group sizes cancel the denominator: integer selected sums compare
    # exactly through 2*sum(selected)-sum(all), without floating means/tolerance.
    selected <- utils::combn(values, k, FUN = sum)
    statistics <- 2 * selected - sum(values)
    observed <- 2 * sum(values[seq_len(k)]) - sum(values)
    expected <- sum(abs(statistics) >= abs(observed)) / length(statistics)
    result <- do.call(ExactPatientTests, exact_scaled_fixture(values))
    expect_equal(result$p_value, expected)
    expect_identical(result$status, "EXACT")
  }
})
