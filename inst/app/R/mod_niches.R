# Module: Niches & domains --------------------------------------------------
# Cellular neighbourhoods (niches) and spatial domains, with maps for a chosen
# section and the niche-composition heatmap. Reads the analysed object (`obj`).

mod_niches_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Niches & domains",
      shiny::selectInput(ns("section"), "Section", choices = NULL),
      shiny::sliderInput(ns("n_cn"), "Neighbourhoods", min = 3, max = 10,
                         value = 6),
      shiny::sliderInput(ns("k"), "Neighbours (k)", min = 5, max = 40,
                         value = 20, step = 5),
      shiny::sliderInput(ns("n_dom"), "Domains", min = 2, max = 8, value = 4)
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(bslib::card_header("Cellular neighbourhoods"),
                  shiny::plotOutput(ns("niche_map"), height = "340px")),
      bslib::card(bslib::card_header("Spatial domains"),
                  shiny::plotOutput(ns("domain_map"), height = "340px"))
    ),
    bslib::card(bslib::card_header("Neighbourhood composition"),
                shiny::plotOutput(ns("composition"), height = "300px"))
  )
}

mod_niches_server <- function(id, obj) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      o <- obj()
      shiny::updateSelectInput(session, "section",
                               choices = unique(o$sample_id))
    })

    cn <- shiny::reactive({
      o <- obj()
      phenoscapR::CellularNeighbourhoods(o, n_neighbourhoods = input$n_cn,
                                         k = input$k, seed = 1)
    })
    dom <- shiny::reactive({
      o <- obj()
      phenoscapR::SpatialDomains(o, n_domains = input$n_dom, k = input$k,
                                 seed = 1)
    })
    pick <- function(o) {
      shiny::req(input$section)
      selected <- o[o$sample_id == input$section, ]
      shiny::validate(shiny::need(nrow(phenoscapR::Meta(selected)) > 0L,
        "No cells remain in this section. Select another section or reset QC."))
      selected
    }

    output$niche_map <- shiny::renderPlot({
      o <- pick(cn())
      phenoscapR::CellMap(o, colour_by = "neighbourhood")
    }, alt = "Synthetic cell positions coloured by inferred cellular neighbourhood")
    output$domain_map <- shiny::renderPlot({
      o <- pick(dom())
      phenoscapR::CellMap(o, colour_by = "domain")
    }, alt = "Synthetic cell positions coloured by inferred spatial domain")
    output$composition <- shiny::renderPlot({
      cc <- cn()@spatial$neighbourhood_composition
      df <- data.frame(
        cn = rep(rownames(cc), ncol(cc)),
        phenotype = rep(colnames(cc), each = nrow(cc)),
        frac = as.vector(cc)
      )
      ggplot2::ggplot(df, ggplot2::aes(phenotype, cn, fill = frac)) +
        ggplot2::geom_tile(colour = "white") +
        ggplot2::scale_fill_gradientn(
          colours = phenoscapR::PaletteContinuous(256L)) +
        ggplot2::labs(x = NULL, y = NULL, fill = "fraction") +
        ggplot2::theme_bw(base_size = 11) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45,
                                                           hjust = 1))
    }, alt = "Simulated phenotype fractions within each inferred cellular neighbourhood")
  })
}
