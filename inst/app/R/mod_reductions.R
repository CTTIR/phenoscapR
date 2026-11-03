# Module: Reductions & differential -----------------------------------------
# PCA / UMAP embeddings with a scree plot, and differential abundance of
# phenotypes across the sections. Reads the analysed object (`obj`).

mod_reductions_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Reductions & differential",
      shiny::radioButtons(ns("reduction"), "Embedding",
                          choices = c("PCA" = "pca", "UMAP" = "umap"),
                          selected = "pca"),
      shiny::selectInput(ns("colour"), "Colour by", choices = NULL),
      shiny::sliderInput(ns("npcs"), "Components", min = 2, max = 20,
                         value = 10)
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(bslib::card_header("Embedding"),
                  shiny::plotOutput(ns("dimplot"), height = "340px")),
      bslib::card(bslib::card_header("PCA scree"),
                  shiny::plotOutput(ns("scree"), height = "340px"))
    ),
    bslib::card(
      bslib::card_header("Differential abundance across sections"),
      shiny::uiOutput(ns("diff_warnings")),
      reactable::reactableOutput(ns("diff"))
    )
  )
}

mod_reductions_server <- function(id, obj) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      o <- obj()
      meta <- phenoscapR::Meta(o)
      is_cat <- function(x) is.character(x) || is.factor(x)
      cat_cols <- setdiff(names(meta)[vapply(meta, is_cat, logical(1L))],
                          "cell_id")
      shiny::updateSelectInput(session, "colour", choices = cat_cols,
                               selected = "phenotype")
    })

    pca <- shiny::reactive({
      shiny::req(input$npcs)
      o <- obj()
      phenoscapR::RunPCA(o, n_pcs = input$npcs)
    })
    reduced <- shiny::reactive({
      shiny::req(input$reduction)
      o <- pca()
      if (input$reduction == "umap") {
        shiny::validate(shiny::need(requireNamespace("uwot", quietly = TRUE),
          'UMAP requires uwot. Install it with install.packages("uwot") or select PCA.'))
        o <- phenoscapR::RunUMAP(o, dims = input$npcs, n_neighbors = 15,
                                 seed = 1)
      }
      o
    })

    output$dimplot <- shiny::renderPlot({
      shiny::req(input$colour)
      o <- reduced()
      phenoscapR::DimPlot(o, reduction = input$reduction, colour_by = input$colour,
                          pt_size = 0.6)
    }, alt = function() paste(toupper(input$reduction),
                             "embedding of synthetic cells coloured by", input$colour))
    output$scree <- shiny::renderPlot({
      o <- pca()
      phenoscapR::ScreePlot(o)
    }, alt = "Variance explained by each principal component of synthetic marker data")
    differential <- shiny::reactive({
      o <- obj()
      o@meta_data$section <- o$sample_id
      captured <- new.env(parent = emptyenv())
      captured$warnings <- character()
      da <- withCallingHandlers(
        phenoscapR::DifferentialAbundance(o, condition = "section"),
        warning = function(w) {
          captured$warnings <- c(captured$warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        })
      list(data = as.data.frame(da), warnings = unique(captured$warnings))
    })
    output$diff_warnings <- shiny::renderUI({
      shiny::tagList(
        shiny::tags$p("Synthetic demonstration: each section is one sample in ",
                      "its own condition; this is not replicated group inference."),
        lapply(differential()$warnings, function(w)
          shiny::tags$p(class = "alert alert-warning", role = "alert", w)))
    })
    output$diff <- reactable::renderReactable({
      df <- differential()$data
      num <- vapply(df, is.numeric, logical(1L))
      df[num] <- lapply(df[num], round, digits = 4)
      reactable::reactable(df, compact = TRUE, defaultPageSize = 8)
    })
  })
}
