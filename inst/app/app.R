# ============================================================================
# app.R -- Top-level assembly of the phenoscapR Shiny app.
# Feature logic lives in the mod_* modules (auto-sourced from ./R); this file
# only wires the Hugo Coder theme, the navbar, and the colour-mode toggle.
# ============================================================================

# ggplot/plotly output adopts the active bslib theme automatically.
thematic::thematic_shiny(font = "auto")

# Hugo Coder theme: brand tokens from _brand.yml + the flat SCSS overrides.
coder_theme <- function() {
  bslib::bs_add_rules(
    bslib::bs_theme(version = 5, brand = "_brand.yml"),
    sass::sass_file("www/custom.scss")
  )
}

ui <- bslib::page_navbar(
  title = "phenoscapR",
  id = "nav",
  theme = coder_theme(),
  fillable = TRUE,
  bslib::nav_panel("Data & maps", icon = bsicons::bs_icon("grid-3x3"),
                   mod_data_ui("data")),
  bslib::nav_panel("Spatial statistics", icon = bsicons::bs_icon("bezier2"),
                   mod_spatial_ui("spatial")),
  bslib::nav_panel("Niches & domains", icon = bsicons::bs_icon("diagram-3"),
                   mod_niches_ui("niches")),
  bslib::nav_panel("Reductions & differential",
                   icon = bsicons::bs_icon("bar-chart"),
                   mod_reductions_ui("reductions")),
  bslib::nav_spacer(),
  bslib::nav_item(
    shiny::tags$a(bsicons::bs_icon("github"), class = "nav-link",
                  href = "https://github.com/cttir/phenoscapR", target = "_blank")
  ),
  bslib::nav_item(bslib::input_dark_mode(id = "color_mode"))
)

server <- function(input, output, session) {
  # The data module builds the analysed object; every other module reads it.
  obj <- mod_data_server("data")
  mod_spatial_server("spatial", obj)
  mod_niches_server("niches", obj)
  mod_reductions_server("reductions", obj)
}

shiny::shinyApp(ui, server)
