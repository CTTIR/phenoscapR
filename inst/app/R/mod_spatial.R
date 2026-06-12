# Module: Spatial statistics ------------------------------------------------
# Single-window point-pattern statistics on a chosen section, plus the
# per-sample interaction matrix. Reads the analysed object reactive (`obj`).

mod_spatial_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Spatial statistics",
      shiny::selectInput(ns("section"), "Section", choices = NULL),
      shiny::sliderInput(ns("radius"), "Radius", min = 10, max = 120,
                         value = 40, step = 5),
      shiny::selectInput(ns("correction"), "Ripley correction",
                         choices = c("none", "border", "translation"),
                         selected = "border"),
      shiny::selectInput(ns("feature"), "Moran feature", choices = NULL),
      shiny::sliderInput(ns("nperm"), "Permutations", min = 49, max = 499,
                         value = 199, step = 50)
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(bslib::card_header("Ripley's L"),
                  shiny::plotOutput(ns("ripley"), height = "320px")),
      bslib::card(bslib::card_header("Neighbourhood enrichment"),
                  shiny::plotOutput(ns("enrich"), height = "320px"))
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(bslib::card_header("Phenotype interactions"),
                  shiny::plotOutput(ns("interaction"), height = "320px")),
      bslib::card(bslib::card_header("Moran's I"),
                  shiny::verbatimTextOutput(ns("moran")))
    )
  )
}

mod_spatial_server <- function(id, obj) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      o <- obj()
      markers <- phenoscapR::Markers(o)
      shiny::updateSelectInput(session, "section",
                               choices = unique(o$sample_id))
      shiny::updateSelectInput(session, "feature", choices = markers,
        selected = if ("CD20" %in% markers) "CD20" else markers[1])
    })

    section <- shiny::reactive({
      shiny::req(input$section)
      o <- obj()
      o[o$sample_id == input$section, ]
    })

    output$ripley <- shiny::renderPlot({
      rk <- phenoscapR::RipleysK(section(), correction = input$correction)
      ggplot2::autoplot(rk)
    })
    output$enrich <- shiny::renderPlot({
      ne <- phenoscapR::NeighbourhoodEnrichment(section(), radius = input$radius,
                                                n_perm = input$nperm, seed = 1)
      ggplot2::autoplot(ne)
    })
    output$interaction <- shiny::renderPlot({
      im <- phenoscapR::InteractionMatrix(obj(), radius = input$radius)
      phenoscapR::InteractionPlot(im)
    })
    output$moran <- shiny::renderPrint({
      shiny::req(input$feature)
      phenoscapR::MoransI(section(), feature = input$feature,
                          radius = input$radius)
    })
  })
}
