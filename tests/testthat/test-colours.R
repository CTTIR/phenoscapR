# Guard the global palette system. A stray or unsupported palette name must
# never crash a plot: every advertised viridis-family palette has to resolve,
# and anything unrecognised falls back to the default instead of erroring.

test_that("every advertised viridis palette resolves to n colours", {
  for (p in c("viridis", "inferno", "plasma", "cividis", "rocket", "mako")) {
    cols <- PaletteDiscrete(8L, palette = p)
    expect_length(cols, 8L)
    expect_true(all(grepl("^#", cols)))
  }
})

test_that("unsupported or invalid palette names fall back without error", {
  # These used to be advertised but are not provided by hcl.colors().
  expect_silent(PaletteContinuous(16L, palette = "turbo"))
  expect_silent(PaletteContinuous(16L, palette = "magma"))
  expect_silent(PaletteDiscrete(4L, palette = "not-a-real-palette"))
  expect_length(PaletteDiscrete(4L, palette = "turbo"), 4L)
})

test_that("single colour names and hex codes make a gradient", {
  expect_length(PaletteContinuous(10L, palette = "firebrick"), 10L)
  expect_length(PaletteContinuous(10L, palette = "#3366cc"), 10L)
})

test_that("SetPalette round-trips and drives PaletteDiscrete", {
  old <- SetPalette("rocket")
  on.exit(SetPalette(old), add = TRUE)
  expect_equal(GetPalette(), "rocket")
  expect_length(PaletteDiscrete(5L), 5L)

  # A bad global palette still must not break colour resolution.
  SetPalette("turbo")
  expect_silent(PaletteDiscrete(5L))
})

test_that("CustomGradient builds a working ramp", {
  pal <- CustomGradient(c("navy", "white", "firebrick"))
  expect_type(pal, "closure")
  expect_length(pal(20L), 20L)
  expect_error(CustomGradient("navy"), "2 or 3")
})
