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
      shiny::helpText("Synthetic teaching data with known simulated phenotypes. ",
                      "No patient data are loaded by this app."),
      shiny::selectInput(ns("sample"), "Section", choices = NULL),
      shiny::selectInput(ns("norm"), "Normalisation",
                         choices = c("z-score" = "zscore", "min-max" = "minmax",
                                     "quantile" = "quantile")),
      shiny::sliderInput(ns("area"), "Cell-area filter",
                         min = 0, max = 2000, value = c(20, 1000)),
      shiny::actionButton(ns("reset_qc"), "Reset cell-area filter"),
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

    shiny::observeEvent(input$reset_qc, {
      shiny::updateSliderInput(session, "area", value = c(20, 1000))
    })

    obj <- shiny::reactive({
      shiny::req(length(input$area) == 2L, input$norm)
      o <- phenoscapR::QCFilter(base, min_area = input$area[1],
                                max_area = input$area[2])
      shiny::validate(shiny::need(nrow(phenoscapR::Meta(o)) > 0L,
        "No cells pass the area filter. Widen it or reset the cell-area filter."))
      o <- phenoscapR::NormaliseData(o, method = input$norm)
      phenoscapR::CellDensity(o, radius = 40)
    })

    section <- shiny::reactive({
      shiny::req(input$sample)
      o <- obj()
      selected <- o[o$sample_id == input$sample, ]
      shiny::validate(shiny::need(nrow(phenoscapR::Meta(selected)) > 0L,
        "No cells remain in this section. Select another section or reset QC."))
      selected
    })

    output$cellmap <- shiny::renderPlot({
      shiny::req(input$colour)
      o <- section()
      phenoscapR::CellMap(o, colour_by = input$colour)
    }, alt = function() paste("Synthetic cell positions coloured by", input$colour))
    output$feature_plot <- shiny::renderPlot({
      shiny::req(input$feature)
      o <- section()
      phenoscapR::FeaturePlot(o, features = input$feature)
    }, alt = function() paste("Synthetic cell positions coloured by", input$feature,
                             "normalised marker intensity"))
    output$composition <- shiny::renderPlot({
      o <- obj()
      phenoscapR::CompositionPlot(o, group_by = "sample_id")
    }, alt = "Simulated phenotype composition in each synthetic section after QC")
    output$summary <- reactable::renderReactable({
      o <- obj()
      reactable::reactable(phenoscapR::PhenotypeSummary(o),
                           compact = TRUE, defaultPageSize = 8)
    })

    obj
  })
}
