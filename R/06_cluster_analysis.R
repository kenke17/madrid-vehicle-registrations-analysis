# =============================================================================
# Cluster analysis on FAMD coordinates
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("cluster_final_k", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

check_project_packages(
  c("core", "multivariate")
)


# Final cluster labels ---------------------------------------------------------

final_cluster_labels <- c(
  "1" = "Business-oriented hybrid vehicles",
  "2" = "Company and renting vehicles",
  "3" = "Higher-power vehicles",
  "4" = "Privately owned conventional vehicles",
  "5" = "Electric vehicles"
)


# Load FAMD results ------------------------------------------------------------

load_famd_clustering_input <- function(
    file_path = file.path(
      path_data_processed,
      famd_cluster_input_filename
    )
) {

  if (!file.exists(file_path)) {
    stop(
      "The FAMD clustering input does not exist: ",
      file_path,
      call. = FALSE
    )
  }

  famd_object <- readRDS(file_path)

  required_elements <- c(
    "df_famd_clean",
    "coord_famd",
    "eig_val",
    "contrib_var"
  )

  missing_elements <- setdiff(
    required_elements,
    names(famd_object)
  )

  if (length(missing_elements) > 0L) {
    stop(
      "The FAMD object is missing: ",
      paste(
        missing_elements,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  famd_object
}


# Validate alignment -----------------------------------------------------------

validate_famd_clustering_input <- function(
    famd_object
) {

  analytical_data <- famd_object$df_famd_clean
  coordinates <- famd_object$coord_famd

  if (!is.data.frame(analytical_data)) {
    stop(
      "df_famd_clean must be a data frame.",
      call. = FALSE
    )
  }

  if (!is.data.frame(coordinates)) {
    stop(
      "coord_famd must be a data frame.",
      call. = FALSE
    )
  }

  if (!"id" %in% names(analytical_data)) {
    stop(
      "df_famd_clean does not contain the id variable.",
      call. = FALSE
    )
  }

  if (!"id" %in% names(coordinates)) {
    stop(
      "coord_famd does not contain the id variable.",
      call. = FALSE
    )
  }

  if (nrow(analytical_data) != nrow(coordinates)) {
    stop(
      "The FAMD data and coordinates have different numbers of rows.",
      call. = FALSE
    )
  }

  if (!all(analytical_data$id == coordinates$id)) {
    stop(
      "The FAMD records and coordinates are not aligned.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Extract cumulative explained inertia ----------------------------------------

extract_cumulative_inertia <- function(
    eigenvalues
) {

  eigenvalues <- as.data.frame(
    eigenvalues
  )

  possible_names <- c(
    "cumulative.variance.percent",
    "cumulative_variance_percent",
    "cumulative percentage of variance",
    "cumulative"
  )

  cumulative_column <- intersect(
    possible_names,
    names(eigenvalues)
  )

    if (length(cumulative_column) == 1L) {
        cumulative_inertia <- eigenvalues[[cumulative_column]]
  } else if (ncol(eigenvalues) >= 3L) {
    cumulative_inertia <- eigenvalues[[3]]
  } else {
    stop(
      "The cumulative explained inertia could not be identified.",
      call. = FALSE
    )
  }

  cumulative_inertia <- as.numeric(
    cumulative_inertia
  )

  if (
    all(
      cumulative_inertia <= 1,
      na.rm = TRUE
    )
  ) {
    cumulative_inertia <- 100 *
      cumulative_inertia
  }

  cumulative_inertia
}


# Select factorial dimensions --------------------------------------------------

select_clustering_dimensions <- function(
    eigenvalues,
    inertia_threshold =
      cluster_inertia_threshold,
    minimum_dimensions =
      cluster_minimum_dimensions,
    maximum_dimensions =
      cluster_maximum_dimensions
) {

  cumulative_inertia <- extract_cumulative_inertia(
    eigenvalues
  )

  threshold_percentage <- if (
    inertia_threshold <= 1
  ) {
    100 * inertia_threshold
  } else {
    inertia_threshold
  }

  matching_dimensions <- which(
    cumulative_inertia >= threshold_percentage
  )

  if (length(matching_dimensions) == 0L) {
    automatic_dimensions <- length(cumulative_inertia)
  } else {
    automatic_dimensions <- matching_dimensions[[1]]
  }

  selected_dimensions <- max(
    minimum_dimensions,
    min(
      automatic_dimensions,
      maximum_dimensions
    )
  )

  tibble::tibble(
    automatic_dimensions =
      automatic_dimensions,
    selected_dimensions =
      selected_dimensions,
    cumulative_inertia =
      cumulative_inertia[
        selected_dimensions
      ],
    threshold =
      threshold_percentage
  )
}


# Create clustering matrix -----------------------------------------------------

create_clustering_matrix <- function(
    coordinates,
    number_of_dimensions
) {

  dimension_columns <- names(
    coordinates
  )[
    stringr::str_detect(
      names(coordinates),
      "^Dim\\.?[0-9]+$"
    )
  ]

  if (
    length(dimension_columns) <
      number_of_dimensions
  ) {
    stop(
      "There are not enough factorial dimensions for clustering.",
      call. = FALSE
    )
  }

  clustering_data <- coordinates |>
    dplyr::select(
      dplyr::all_of(
        dimension_columns[
          seq_len(number_of_dimensions)
        ]
      )
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        as.numeric
      )
    )

  names(clustering_data) <- paste0(
    "Dim",
    seq_len(number_of_dimensions)
  )

  if (anyNA(clustering_data)) {
    stop(
      "The clustering coordinates contain missing values.",
      call. = FALSE
    )
  }

  clustering_data
}


# Create reproducible sample ---------------------------------------------------

sample_clustering_rows <- function(
    clustering_data,
    sample_size,
    seed = cluster_seed
) {

  set.seed(seed)

  selected_size <- min(
    sample_size,
    nrow(clustering_data)
  )

  selected_rows <- sample(
    seq_len(
      nrow(clustering_data)
    ),
    size = selected_size,
    replace = FALSE
  )

  list(
    rows = selected_rows,
    data = clustering_data[
      selected_rows,
      ,
      drop = FALSE
    ]
  )
}


# Elbow evaluation -------------------------------------------------------------

evaluate_elbow_method <- function(
    clustering_data,
    maximum_k = max(
      cluster_candidate_values
    ),
    sample_size =
      cluster_validation_sample_size
) {

  sampled_data <- sample_clustering_rows(
    clustering_data,
    sample_size
  )$data

  wss <- purrr::map_dbl(
    seq_len(maximum_k),
    function(k) {

      set.seed(cluster_seed)

      model <- stats::kmeans(
        sampled_data,
        centers = k,
        nstart =
          cluster_exploratory_nstart,
        iter.max =
          cluster_max_iterations
      )

      model$tot.withinss
    }
  )

  tibble::tibble(
    k = seq_len(maximum_k),
    total_withinss = wss
  )
}


# Silhouette evaluation --------------------------------------------------------

evaluate_silhouette_method <- function(
    clustering_data,
    candidate_values =
      cluster_candidate_values,
    sample_size =
      cluster_validation_sample_size
) {

  sampled_data <- sample_clustering_rows(
    clustering_data,
    sample_size
  )$data

  distance_matrix <- stats::dist(
    sampled_data
  )

  purrr::map_dfr(
    candidate_values,
    function(k) {

      set.seed(cluster_seed)

      model <- stats::kmeans(
        sampled_data,
        centers = k,
        nstart =
          cluster_exploratory_nstart,
        iter.max =
          cluster_max_iterations
      )

      silhouette_values <- cluster::silhouette(
        model$cluster,
        distance_matrix
      )

      tibble::tibble(
        k = k,
        mean_silhouette = mean(
          silhouette_values[, 3]
        )
      )
    }
  )
}


# Fit one K-means solution -----------------------------------------------------

fit_kmeans_solution <- function(
    clustering_data,
    number_of_clusters,
    nstart = cluster_candidate_nstart,
    seed = cluster_seed
) {

  set.seed(seed)

  stats::kmeans(
    clustering_data,
    centers = number_of_clusters,
    nstart = nstart,
    iter.max = cluster_max_iterations
  )
}


# Attach assignments safely ----------------------------------------------------

attach_cluster_assignments <- function(
    analytical_data,
    cluster_assignments,
    variable_name = "cluster"
) {

  if (
    length(cluster_assignments) !=
      nrow(analytical_data)
  ) {
    stop(
      "The cluster assignments do not match the analytical dataset.",
      call. = FALSE
    )
  }

  analytical_data[[variable_name]] <- factor(
    cluster_assignments
  )

  analytical_data
}


# Numerical cluster profile ----------------------------------------------------

summarise_cluster_numeric_profile <- function(
    clustered_data,
    cluster_variable = "cluster"
) {

  clustered_data |>
    dplyr::group_by(
      .data[[cluster_variable]]
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      share = .data$observations /
        nrow(clustered_data),
      mean_power_kw = mean(
        .data$KW_ITV,
        na.rm = TRUE
      ),
      mean_displacement_cc = mean(
        .data$CILINDRADA_ITV,
        na.rm = TRUE
      ),
      mean_normalised_co2 = mean(
        .data$CO2_norm,
        na.rm = TRUE
      ),
      mean_consumption_wh_km = mean(
        .data$CONSUMO_WH_KM_ITV,
        na.rm = TRUE
      ),
      mean_wheelbase_mm = mean(
        .data$DISTANCIA_EJES_12_ITV,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::rename(
      cluster =
        dplyr::all_of(
          cluster_variable
        )
    )
}


# Generic categorical profile -------------------------------------------------

summarise_cluster_categorical_profile <- function(
    clustered_data,
    category_variable,
    cluster_variable = "cluster"
) {

  clustered_data |>
    dplyr::count(
      .data[[cluster_variable]],
      .data[[category_variable]],
      name = "observations"
    ) |>
    dplyr::group_by(
      .data[[cluster_variable]]
    ) |>
    dplyr::mutate(
      share = .data$observations /
        sum(.data$observations)
    ) |>
    dplyr::ungroup() |>
    dplyr::rename(
      cluster =
        dplyr::all_of(
          cluster_variable
        ),
      category =
        dplyr::all_of(
          category_variable
        )
    )
}


# Compare candidate cluster solutions -----------------------------------------

compare_candidate_solutions <- function(
    clustering_data,
    analytical_data,
    candidate_values =
      cluster_detailed_candidate_values
) {

  purrr::map(
    candidate_values,
    function(k) {

      message(
        "Fitting candidate solution k = ",
        k
      )

      model <- fit_kmeans_solution(
        clustering_data,
        number_of_clusters = k,
        nstart =
          cluster_candidate_nstart
      )

      cluster_variable <- paste0(
        "cluster",
        k
      )

      candidate_data <- attach_cluster_assignments(
        analytical_data,
        model$cluster,
        variable_name =
          cluster_variable
      )

      list(
        k = k,
        model = model,
        numeric_profile =
          summarise_cluster_numeric_profile(
            candidate_data,
            cluster_variable
          ),
        propulsion_profile =
          summarise_cluster_categorical_profile(
            candidate_data,
            "propulsion_type",
            cluster_variable
          )
      )
    }
  ) |>
    rlang::set_names(
      paste0(
        "k",
        candidate_values
      )
    )
}


# Fit final cluster solution ---------------------------------------------------

fit_final_cluster_model <- function(
    clustering_data
) {

  fit_kmeans_solution(
    clustering_data,
    number_of_clusters =
      cluster_final_k,
    nstart = cluster_nstart,
    seed = cluster_seed
  )
}


# Add final labels -------------------------------------------------------------

add_final_cluster_labels <- function(
    clustered_data
) {

  clustered_data |>
    dplyr::mutate(
      cluster = factor(
        .data$cluster,
        levels = names(
          final_cluster_labels
        )
      ),
      cluster_label = factor(
        unname(
          final_cluster_labels[
            as.character(
              .data$cluster
            )
          ]
        ),
        levels = unname(
          final_cluster_labels
        )
      )
    )
}


# Cluster evolution ------------------------------------------------------------

summarise_cluster_evolution <- function(
    clustered_data
) {

  clustered_data |>
    dplyr::count(
      .data$periodo,
      .data$cluster,
      .data$cluster_label,
      name = "observations"
    ) |>
    dplyr::group_by(
      .data$periodo
    ) |>
    dplyr::mutate(
      share = .data$observations /
        sum(.data$observations)
    ) |>
    dplyr::ungroup()
}


summarise_cluster_evolution_by_category <- function(
    clustered_data,
    category_variable
) {

  clustered_data |>
    dplyr::count(
      .data$periodo,
      .data$cluster,
      .data$cluster_label,
      .data[[category_variable]],
      name = "observations"
    ) |>
    dplyr::group_by(
      .data$periodo,
      .data[[category_variable]]
    ) |>
    dplyr::mutate(
      share = .data$observations /
        sum(.data$observations)
    ) |>
    dplyr::ungroup()
}


# Stability across seeds -------------------------------------------------------

evaluate_cluster_stability <- function(
    clustering_data,
    seeds =
      cluster_stability_seeds
) {

  purrr::map_dfr(
    seeds,
    function(seed) {

      model <- fit_kmeans_solution(
        clustering_data,
        number_of_clusters =
          cluster_final_k,
        nstart =
          cluster_nstart,
        seed = seed
      )

      tibble::tibble(
        seed = seed,
        total_withinss =
          model$tot.withinss,
        between_ss =
          model$betweenss,
        total_ss =
          model$totss,
        explained_variation =
          model$betweenss /
            model$totss
      )
    }
  )
}


# Visualisations ---------------------------------------------------------------

plot_elbow_method <- function(
    elbow_results
) {

  ggplot2::ggplot(
    elbow_results,
    ggplot2::aes(
      x = .data$k,
      y = .data$total_withinss
    )
  ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_x_continuous(
      breaks = elbow_results$k
    ) +
    ggplot2::labs(
      title = "Elbow method",
      x = "Number of clusters",
      y = "Total within-cluster sum of squares"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_silhouette_method <- function(
    silhouette_results
) {

  ggplot2::ggplot(
    silhouette_results,
    ggplot2::aes(
      x = .data$k,
      y = .data$mean_silhouette
    )
  ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_x_continuous(
      breaks = silhouette_results$k
    ) +
    ggplot2::labs(
      title = "Mean silhouette width",
      x = "Number of clusters",
      y = "Mean silhouette"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_clusters_in_factorial_space <- function(
    clustering_data,
    clustered_data,
    dimensions = c(1L, 2L),
    sample_size =
      cluster_plot_sample_size
) {

  required_dimensions <- paste0(
    "Dim",
    dimensions
  )

  if (!all(
    required_dimensions %in%
      names(clustering_data)
  )) {
    stop(
      "The requested factorial dimensions are not available.",
      call. = FALSE
    )
  }

  plot_data <- clustering_data |>
    dplyr::mutate(
      cluster =
        clustered_data$cluster,
      cluster_label =
        clustered_data$cluster_label
    )

  sampled_rows <- sample_clustering_rows(
    plot_data,
    sample_size
  )$rows

  sampled_data <- plot_data[
    sampled_rows,
    ,
    drop = FALSE
  ]

  ggplot2::ggplot(
    sampled_data,
    ggplot2::aes(
      x = .data[[required_dimensions[[1]]]],
      y = .data[[required_dimensions[[2]]]],
      colour = .data$cluster_label
    )
  ) +
    ggplot2::geom_point(
      alpha = 0.35,
      size = 0.6
    ) +
    ggplot2::labs(
      title = paste(
        "Clusters in FAMD dimensions",
        dimensions[[1]],
        "and",
        dimensions[[2]]
      ),
      x = required_dimensions[[1]],
      y = required_dimensions[[2]],
      colour = "Cluster profile"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      legend.position = "right"
    )
}


plot_cluster_evolution <- function(
    evolution_data
) {

  ggplot2::ggplot(
    evolution_data,
    ggplot2::aes(
      x = .data$periodo,
      y = .data$share,
      colour = .data$cluster_label,
      group = .data$cluster_label
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.9
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent()
    ) +
    ggplot2::labs(
      title = "Temporal evolution of cluster profiles",
      x = NULL,
      y = "Monthly share",
      colour = "Cluster profile"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      legend.position = "bottom"
    )
}


# Save results -----------------------------------------------------------------

save_cluster_results <- function(
    cluster_results,
    clustered_data,
    results_path = file.path(
      path_data_processed,
      cluster_results_filename
    ),
    assignments_path = file.path(
      path_data_processed,
      cluster_assignments_filename
    )
) {

  compact_results <- cluster_results

  compact_results$models$candidate_models <-
    NULL

  saveRDS(
    compact_results,
    results_path
  )

  cluster_assignments <- clustered_data |>
    dplyr::select(
      .data$id,
      .data$periodo,
      .data$cluster,
      .data$cluster_label
    )

  saveRDS(
    cluster_assignments,
    assignments_path
  )

  message(
    "Cluster results saved to: ",
    results_path
  )

  message(
    "Cluster assignments saved to: ",
    assignments_path
  )

  invisible(
    list(
      results_path = results_path,
      assignments_path =
        assignments_path
    )
  )
}


# Run complete clustering workflow --------------------------------------------

run_cluster_analysis <- function(
    famd_object =
      load_famd_clustering_input(),
    compare_candidates = TRUE,
    save_output = TRUE
) {

  validate_famd_clustering_input(
    famd_object
  )

  analytical_data <-
    famd_object$df_famd_clean

  coordinates <-
    famd_object$coord_famd

  dimension_selection <-
    select_clustering_dimensions(
      famd_object$eig_val
    )

  number_of_dimensions <-
    dimension_selection$selected_dimensions[[1]]

  message(
    "Using ",
    number_of_dimensions,
    " FAMD dimensions for clustering."
  )

  clustering_data <-
    create_clustering_matrix(
      coordinates,
      number_of_dimensions
    )

  elbow_results <-
    evaluate_elbow_method(
      clustering_data
    )

  silhouette_results <-
    evaluate_silhouette_method(
      clustering_data
    )

  candidate_results <- NULL

  if (isTRUE(compare_candidates)) {
    candidate_results <-
      compare_candidate_solutions(
        clustering_data,
        analytical_data
      )
  }

  final_model <-
    fit_final_cluster_model(
      clustering_data
    )

  clustered_data <-
    attach_cluster_assignments(
      analytical_data,
      final_model$cluster
    ) |>
    add_final_cluster_labels()

  numeric_profile <-
    summarise_cluster_numeric_profile(
      clustered_data
    )

  propulsion_profile <-
    summarise_cluster_categorical_profile(
      clustered_data,
      "propulsion_type"
    )

  ownership_profile <-
    summarise_cluster_categorical_profile(
      clustered_data,
      "ownership_type"
    )

  renting_profile <-
    summarise_cluster_categorical_profile(
      clustered_data,
      "renting_status"
    )

  temporal_evolution <-
    summarise_cluster_evolution(
      clustered_data
    )

  ownership_evolution <-
    summarise_cluster_evolution_by_category(
      clustered_data,
      "ownership_type"
    )

  renting_evolution <-
    summarise_cluster_evolution_by_category(
      clustered_data,
      "renting_status"
    )

  stability_results <-
    evaluate_cluster_stability(
      clustering_data
    )

  results <- list(
    parameters = list(
      selected_dimensions =
        number_of_dimensions,
      final_k =
        cluster_final_k,
      seed =
        cluster_seed,
      nstart =
        cluster_nstart,
      maximum_iterations =
        cluster_max_iterations
    ),
    models = list(
      final_model =
        final_model,
      candidate_models =
        candidate_results
    ),
    tables = list(
      dimension_selection =
        dimension_selection,
      elbow =
        elbow_results,
      silhouette =
        silhouette_results,
      numeric_profile =
        numeric_profile,
      propulsion_profile =
        propulsion_profile,
      ownership_profile =
        ownership_profile,
      renting_profile =
        renting_profile,
      temporal_evolution =
        temporal_evolution,
      ownership_evolution =
        ownership_evolution,
      renting_evolution =
        renting_evolution,
      stability =
        stability_results
    ),
    figures = list(
      elbow =
        plot_elbow_method(
          elbow_results
        ),
      silhouette =
        plot_silhouette_method(
          silhouette_results
        ),
      dimensions_1_2 =
        plot_clusters_in_factorial_space(
          clustering_data,
          clustered_data,
          dimensions = c(1, 2)
        ),
      dimensions_1_3 =
        plot_clusters_in_factorial_space(
          clustering_data,
          clustered_data,
          dimensions = c(1, 3)
        ),
      temporal_evolution =
        plot_cluster_evolution(
          temporal_evolution
        )
    )
  )

  if (isTRUE(save_output)) {
    save_cluster_results(
      results,
      clustered_data
    )
  }

  list(
    clustered_data =
      clustered_data,
    results =
      results
  )
}


# Usage example ----------------------------------------------------------------

# cluster_analysis <- run_cluster_analysis(
#   compare_candidates = TRUE,
#   save_output = TRUE
# )
#
# cluster_analysis$results$tables$dimension_selection
# cluster_analysis$results$tables$silhouette
# cluster_analysis$results$tables$numeric_profile
# cluster_analysis$results$tables$propulsion_profile
# cluster_analysis$results$tables$ownership_profile
# cluster_analysis$results$tables$renting_profile
# cluster_analysis$results$tables$stability
#
# cluster_analysis$results$figures$elbow
# cluster_analysis$results$figures$silhouette
# cluster_analysis$results$figures$dimensions_1_2
# cluster_analysis$results$figures$temporal_evolution