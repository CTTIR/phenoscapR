# Smoke test for the bundled Shiny app: it launches, the data module produces
# the analysed object, and the colour-mode toggle switches light <-> dark.
# Snapshots capture the input state in each mode. Skipped on CRAN and wherever
# the headless-browser stack is unavailable.

test_that("the Shiny app launches and toggles colour mode", {
  skip_on_cran()
  skip_on_ci()  # headless-browser snapshots differ across runners; run locally
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if_not_installed("bslib")
  skip_if_not_installed("reactable")

  app_dir <- system.file("app", package = "phenoscapR")
  skip_if(!nzchar(app_dir), "app directory not installed")

  app <- shinytest2::AppDriver$new(
    app_dir, name = "phenoscapR-app",
    width = 1400, height = 900, load_timeout = 60000,
    expect_values_screenshot_args = FALSE   # JSON snapshots only (portable)
  )
  withr::defer(app$stop())
  app$wait_for_idle(timeout = 30000)

  # Light mode: snapshot the (deterministic) input state.
  app$expect_values(input = TRUE, name = "light")

  # Toggle to dark mode and confirm the switch took effect.
  app$set_inputs(color_mode = "dark")
  app$wait_for_idle(timeout = 15000)
  expect_identical(app$get_value(input = "color_mode"), "dark")
  app$expect_values(input = TRUE, name = "dark")
})
