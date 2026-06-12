# Module: Data & maps -------------------------------------------------------
# Builds the analysed SpatialCellData object from the bundled example data and
# the QC / normalisation controls, and returns it as a reactive for the other
# modules. Also renders the cell map, feature map, composition, and summary.

.app_example <- function() {
  e <- new.env()
  utils::data("phenoscapR_example", package = "phenoscapR", envir = e)
  obj <- e$phenoscapR_example
  obj@meta_data$phenotype <- obj@meta_data$phenotype_true
  obj
}

mod_data_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Data & QC",
      shiny::selectInput(ns("sample"), "Section", choices = NULL),
      shiny::selectInput(ns("norm"), "Normalisation",
                         choices = c("z-score" = "zscore", "min-max" = "minmax",
                                     "quantile" = "quantile")),
      shiny::sliderInput(ns("area"), "Cell-area filter",
                         min = 0, max = 2000, value = c(20, 1000)),
      shiny::selectInput(ns("colour"), "Colour map by", choices = NULL),
      shiny::selectInput(ns("feature"), "Feature", choices = NULL)
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(bslib::card_header("Phenotype map"),
                  shiny::plotOutput(ns("cellmap"), height = "360px")),
      bslib::card(bslib::card_header("Feature map"),
                  shiny::plotOutput(ns("feature_plot"), height = "360px"))
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(bslib::card_header("Phenotype composition"),
                  shiny::plotOutput(ns("composition"), height = "300px")),
      bslib::card(bslib::card_header("Phenotype summary"),
                  reactable::reactableOutput(ns("summary")))
    )
  )
}

mod_data_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    base <- .app_example()

    shiny::observe({
      meta <- phenoscapR::Meta(base)
      is_cat <- function(x) is.character(x) || is.factor(x)
      cat_cols <- setdiff(names(meta)[vapply(meta, is_cat, logical(1L))],
                          "cell_id")
      shiny::updateSelectInput(session, "sample",
                               choices = unique(base$sample_id))
      shiny::updateSelectInput(session, "colour", choices = cat_cols,
                               selected = "phenotype")
      shiny::updateSelectInput(session, "feature",
                               choices = phenoscapR::Markers(base),
                               selected = phenoscapR::Markers(base)[1])
    })

    obj <- shiny::reactive({
      o <- phenoscapR::QCFilter(base, min_area = input$area[1],
                                max_area = input$area[2])
      o <- phenoscapR::NormaliseData(o, method = input$norm)
      phenoscapR::CellDensity(o, radius = 40)
    })

    section <- shiny::reactive({
      shiny::req(input$sample)
      o <- obj()
      o[o$sample_id == input$sample, ]
    })

    output$cellmap <- shiny::renderPlot({
      shiny::req(input$colour)
      phenoscapR::CellMap(section(), colour_by = input$colour)
    })
    output$feature_plot <- shiny::renderPlot({
      shiny::req(input$feature)
      phenoscapR::FeaturePlot(section(), features = input$feature)
    })
    output$composition <- shiny::renderPlot({
      phenoscapR::CompositionPlot(obj(), group_by = "sample_id")
    })
    output$summary <- reactable::renderReactable({
      reactable::reactable(phenoscapR::PhenotypeSummary(obj()),
                           compact = TRUE, defaultPageSize = 8)
    })

    obj
  })
}
