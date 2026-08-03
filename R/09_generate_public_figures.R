# =============================================================================
# Generate public figures
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("path_data_public", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

if (!exists("path_figures", inherits = TRUE)) {
  path_figures <- here::here(
    "figures"
  )
}

check_project_packages("core")


# Public input files ------------------------------------------------------------

public_figure_input_files <- c(
  annual_registrations =
    "annual_registrations.csv",
  monthly_registrations =
    "monthly_registrations.csv",
  propulsion_evolution =
    "propulsion_evolution.csv",
  municipal_ranking =
    "municipal_ranking.csv",
  famd_eigenvalues =
    "famd_eigenvalues.csv",
  cluster_profiles =
    "cluster_profiles.csv"
)


# Public output files -----------------------------------------------------------

public_figure_output_files <- c(
  annual_registrations =
    "annual_registrations.png",
  monthly_registrations =
    "monthly_registrations.png",
  propulsion_evolution =
    "propulsion_evolution.png",
  municipal_ranking =
    "municipal_ranking.png",
  famd_inertia =
    "famd_inertia.png",
  cluster_profiles =
    "cluster_profiles.png"
)


# Read and validate one public CSV ---------------------------------------------

read_public_result <- function(
    file_name,
    required_columns
) {

  file_path <- file.path(
    path_data_public,
    file_name
  )

  if (!file.exists(file_path)) {
    stop(
      "Public result file not found: ",
      file_path,
      call. = FALSE
    )
  }

  data <- readr::read_csv(
    file_path,
    show_col_types = FALSE
  )

  missing_columns <- setdiff(
    required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The file ",
      file_name,
      " is missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  data
}


# Load all public results -------------------------------------------------------

load_public_figure_data <- function() {

  annual_registrations <- read_public_result(
    public_figure_input_files[["annual_registrations"]],
    c(
      "year",
      "registrations"
    )
  )

  monthly_registrations <- read_public_result(
    public_figure_input_files[["monthly_registrations"]],
    c(
      "month",
      "registrations"
    )
  ) |>
    dplyr::mutate(
      month = as.Date(
        .data$month
      )
    )

  propulsion_evolution <- read_public_result(
    public_figure_input_files[["propulsion_evolution"]],
    c(
      "year",
      "propulsion_type",
      "registrations",
      "annual_share"
    )
  )

  municipal_ranking <- read_public_result(
    public_figure_input_files[["municipal_ranking"]],
    c(
      "position",
      "municipality_name",
      "registrations",
      "share_of_total"
    )
  )

  famd_eigenvalues <- read_public_result(
    public_figure_input_files[["famd_eigenvalues"]],
    c(
      "dimension",
      "eigenvalue",
      "variance.percent",
      "cumulative.variance.percent"
    )
  )

  cluster_profiles <- read_public_result(
    public_figure_input_files[["cluster_profiles"]],
    c(
      "cluster",
      "cluster_label",
      "observations",
      "cluster_share"
    )
  )

  list(
    annual_registrations =
      annual_registrations,
    monthly_registrations =
      monthly_registrations,
    propulsion_evolution =
      propulsion_evolution,
    municipal_ranking =
      municipal_ranking,
    famd_eigenvalues =
      famd_eigenvalues,
    cluster_profiles =
      cluster_profiles
  )
}


# Annual registrations ---------------------------------------------------------

plot_public_annual_registrations <- function(
    annual_registrations
) {

  plot_data <- annual_registrations |>
    dplyr::arrange(
      .data$year
    ) |>
    dplyr::mutate(
      year_label = factor(
        .data$year,
        levels = .data$year
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$year_label,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_col(
      width = 0.75
    ) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = scales::label_number(
          scale = 0.001,
          suffix = "k",
          accuracy = 1
        )(
          .data$registrations
        )
      ),
      vjust = -0.35,
      size = 3.2
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma(),
      expand = ggplot2::expansion(
        mult = c(0, 0.1)
      )
    ) +
    ggplot2::labs(
      title = "Annual passenger car registrations",
      subtitle = "Community of Madrid, 2015–2025",
      x = NULL,
      y = "Registrations",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      )
    )
}


# Monthly registrations --------------------------------------------------------

plot_public_monthly_registrations <- function(
    monthly_registrations
) {

  ggplot2::ggplot(
    monthly_registrations,
    ggplot2::aes(
      x = .data$month,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.75
    ) +
    ggplot2::geom_vline(
      xintercept = as.Date(
        "2020-03-01"
      ),
      linetype = "dashed",
      linewidth = 0.7
    ) +
    ggplot2::annotate(
      geom = "text",
      x = as.Date(
        "2020-04-01"
      ),
      y = max(
        monthly_registrations$registrations,
        na.rm = TRUE
      ),
      label = "COVID-19 disruption",
      hjust = 0,
      vjust = 1,
      size = 3.3
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Monthly passenger car registrations",
      subtitle = "Community of Madrid, January 2015–December 2025",
      x = NULL,
      y = "Registrations",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      )
    )
}


# Propulsion evolution ---------------------------------------------------------

plot_public_propulsion_evolution <- function(
    propulsion_evolution
) {

  plot_data <- propulsion_evolution |>
    dplyr::mutate(
      propulsion_type = factor(
        .data$propulsion_type,
        levels = c(
          "Petrol",
          "Diesel",
          "Hybrid",
          "Electric"
        )
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$year,
      y = .data$annual_share,
      group = .data$propulsion_type,
      colour = .data$propulsion_type
    )
  ) +
    ggplot2::geom_line(
      linewidth = 1
    ) +
    ggplot2::geom_point(
      size = 2
    ) +
    ggplot2::scale_x_continuous(
      breaks = sort(
        unique(
          plot_data$year
        )
      )
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent(
        accuracy = 1
      )
    ) +
    ggplot2::labs(
      title = "Evolution of propulsion technologies",
      subtitle = "Annual share of passenger car registrations",
      x = "Year",
      y = "Share of annual registrations",
      colour = "Propulsion",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      legend.position = "bottom"
    )
}


# Municipal ranking ------------------------------------------------------------

plot_public_municipal_ranking <- function(
    municipal_ranking,
    number_of_municipalities = 20L
) {

  plot_data <- municipal_ranking |>
    dplyr::slice_min(
      order_by = .data$position,
      n = number_of_municipalities,
      with_ties = FALSE
    ) |>
    dplyr::arrange(
      .data$registrations
    ) |>
    dplyr::mutate(
      municipality_name = factor(
        .data$municipality_name,
        levels = .data$municipality_name
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$municipality_name,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_col(
      width = 0.75
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Municipal registration ranking",
      subtitle = paste(
        "Twenty municipalities with the highest registration volume,"
      ),
      x = NULL,
      y = "Registrations",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )
}


# FAMD inertia -----------------------------------------------------------------

plot_public_famd_inertia <- function(
    famd_eigenvalues
) {

  plot_data <- famd_eigenvalues |>
    dplyr::mutate(
      dimension = factor(
        .data$dimension,
        levels = .data$dimension
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$dimension
    )
  ) +
    ggplot2::geom_col(
      ggplot2::aes(
        y = .data[["variance.percent"]]
      ),
      width = 0.7
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        y = .data[["cumulative.variance.percent"]],
        group = 1
      ),
      linewidth = 1
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        y = .data[["cumulative.variance.percent"]]
      ),
      size = 2
    ) +
    ggplot2::geom_hline(
      yintercept = 60,
      linetype = "dashed",
      linewidth = 0.6
    ) +
    ggplot2::scale_y_continuous(
      labels = function(x) {
        paste0(
          x,
          "%"
        )
      }
    ) +
    ggplot2::labs(
      title = "FAMD explained inertia",
      subtitle = "Bars show individual inertia; the line shows cumulative inertia",
      x = "Factorial dimension",
      y = "Explained inertia",
      caption = "The first three dimensions explain approximately 64.8% of total inertia"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )
}


# Cluster profile heatmap -------------------------------------------------------

plot_public_cluster_profiles <- function(
    cluster_profiles
) {

  candidate_profile_columns <- c(
    "propulsion_share_petrol",
    "propulsion_share_diesel",
    "propulsion_share_hybrid",
    "propulsion_share_electric",
    "ownership_share_individual",
    "ownership_share_legal_entity",
    "renting_share_no",
    "renting_share_yes"
  )

  available_profile_columns <- intersect(
    candidate_profile_columns,
    names(cluster_profiles)
  )

  if (length(available_profile_columns) == 0L) {
    stop(
      "The cluster profile file does not contain any public share variables.",
      call. = FALSE
    )
  }

  indicator_labels <- c(
    propulsion_share_petrol = "Petrol",
    propulsion_share_diesel = "Diesel",
    propulsion_share_hybrid = "Hybrid",
    propulsion_share_electric = "Electric",
    ownership_share_individual = "Individual ownership",
    ownership_share_legal_entity = "Legal-entity ownership",
    renting_share_no = "Non-renting",
    renting_share_yes = "Renting"
  )

  cluster_order <- cluster_profiles |>
    dplyr::arrange(
      as.integer(
        .data$cluster
      )
    ) |>
    dplyr::transmute(
      cluster_display = paste0(
        "Cluster ",
        .data$cluster,
        ": ",
        .data$cluster_label
      )
    ) |>
    dplyr::pull(
      "cluster_display"
    )

  plot_data <- cluster_profiles |>
    dplyr::mutate(
      cluster_display = paste0(
        "Cluster ",
        .data$cluster,
        ": ",
        .data$cluster_label
      )
    ) |>
    dplyr::select(
      dplyr::all_of(
        c(
          "cluster_display",
          available_profile_columns
        )
      )
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(
        available_profile_columns
      ),
      names_to = "indicator",
      values_to = "share"
    ) |>
    dplyr::mutate(
      cluster_display = factor(
        .data$cluster_display,
        levels = rev(
          cluster_order
        )
      ),
      indicator = factor(
        unname(
          indicator_labels[
            .data$indicator
          ]
        ),
        levels = unname(
          indicator_labels[
            available_profile_columns
          ]
        )
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$indicator,
      y = .data$cluster_display,
      fill = .data$share
    )
  ) +
    ggplot2::geom_tile(
      colour = "white",
      linewidth = 0.5
    ) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = scales::label_percent(
          accuracy = 1
        )(
          .data$share
        )
      ),
      size = 3
    ) +
    ggplot2::scale_fill_gradient(
      low = "white",
      high = "grey30",
      labels = scales::label_percent(),
      limits = c(
        0,
        1
      ),
      name = "Within-cluster share"
    ) +
    ggplot2::labs(
      title = "Final cluster profiles",
      subtitle = "Propulsion, ownership and renting composition",
      x = NULL,
      y = NULL,
      caption = "K-means clustering on the first three FAMD dimensions"
    ) +
    ggplot2::theme_minimal(
      base_size = 11
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      panel.grid = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}


# Save one figure --------------------------------------------------------------

save_public_figure <- function(
    plot,
    file_name,
    width,
    height
) {

  output_path <- file.path(
    path_figures,
    file_name
  )

  ggplot2::ggsave(
    filename = output_path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )

  message(
    "Public figure saved: ",
    output_path
  )

  invisible(output_path)
}


# Generate all public figures --------------------------------------------------

run_public_figure_generation <- function() {

  dir.create(
    path_figures,
    recursive = TRUE,
    showWarnings = FALSE
  )

  public_data <- load_public_figure_data()

  figures <- list(
    annual_registrations =
      plot_public_annual_registrations(
        public_data[["annual_registrations"]]
      ),
    monthly_registrations =
      plot_public_monthly_registrations(
        public_data[["monthly_registrations"]]
      ),
    propulsion_evolution =
      plot_public_propulsion_evolution(
        public_data[["propulsion_evolution"]]
      ),
    municipal_ranking =
      plot_public_municipal_ranking(
        public_data[["municipal_ranking"]]
      ),
    famd_inertia =
      plot_public_famd_inertia(
        public_data[["famd_eigenvalues"]]
      ),
    cluster_profiles =
      plot_public_cluster_profiles(
        public_data[["cluster_profiles"]]
      )
  )

  figure_dimensions <- list(
    annual_registrations = c(
      9,
      5.5
    ),
    monthly_registrations = c(
      10,
      5.5
    ),
    propulsion_evolution = c(
      9,
      5.5
    ),
    municipal_ranking = c(
      9,
      7
    ),
    famd_inertia = c(
      8,
      5.5
    ),
    cluster_profiles = c(
      11,
      6
    )
  )

  purrr::iwalk(
    figures,
    function(figure, figure_name) {

      dimensions <- figure_dimensions[[figure_name]]

      save_public_figure(
        plot = figure,
        file_name =
          public_figure_output_files[[figure_name]],
        width = dimensions[[1]],
        height = dimensions[[2]]
      )
    }
  )

  message(
    "Public figure generation completed."
  )

  invisible(figures)
}


# Usage example ----------------------------------------------------------------

# public_figures <- run_public_figure_generation()
#
# public_figures$annual_registrations
# public_figures$monthly_registrations
# public_figures$propulsion_evolution
# public_figures$municipal_ranking
# public_figures$famd_inertia
# public_figures$cluster_profiles