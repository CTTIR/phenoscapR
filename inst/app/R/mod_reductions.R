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
      reactable::reactableOutput(ns("diff"))
    )
  )
}

mod_reductions_server <- function(id, obj) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      meta <- phenoscapR::Meta(obj())
      cat_cols <- names(meta)[vapply(meta, function(x)
        is.character(x) || is.factor(x), logical(1L))]
      cat_cols <- setdiff(cat_cols, "cell_id")
      shiny::updateSelectInput(session, "colour", choices = cat_cols,
                               selected = "phenotype")
    })

    reduced <- shiny::reactive({
      o <- phenoscapR::RunPCA(obj(), n_pcs = input$npcs)
      if (input$reduction == "umap" &&
          requireNamespace("uwot", quietly = TRUE)) {
        o <- phenoscapR::RunUMAP(o, dims = input$npcs, n_neighbors = 15,
                                 seed = 1)
      }
      o
    })

    output$dimplot <- shiny::renderPlot({
      shiny::req(input$colour)
      o <- reduced()
      red <- if (input$reduction == "umap" &&
                 "umap" %in% phenoscapR::Reductions(o)) "umap" else "pca"
      phenoscapR::DimPlot(o, reduction = red, colour_by = input$colour,
                          pt_size = 0.6)
    })
    output$scree <- shiny::renderPlot({
      phenoscapR::ScreePlot(reduced())
    })
    output$diff <- reactable::renderReactable({
      o <- obj()
      sections <- unique(o$sample_id)
      o@meta_data$section <- o$sample_id
      da <- suppressWarnings(
        phenoscapR::DifferentialAbundance(o, condition = "section"))
      df <- as.data.frame(da)
      num <- vapply(df, is.numeric, logical(1L))
      df[num] <- lapply(df[num], function(x) round(x, 4))
      reactable::reactable(df, compact = TRUE, defaultPageSize = 8)
    })
  })
}
