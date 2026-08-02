# =============================================================================
# Factor Analysis of Mixed Data
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("famd_number_of_components", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

check_project_packages(
  c("core", "multivariate")
)


# Required variables -----------------------------------------------------------

famd_required_columns <- c(
  "FEC_MATRICULA",
  "CILINDRADA_ITV",
  "KW_ITV",
  "CO2_ITV",
  "CONSUMO_WH_KM_ITV",
  "DISTANCIA_EJES_12_ITV",
  "COD_PROPULSION_ITV",
  "CATEGORIA_VEHICULO_ELECTRICO",
  "RENTING",
  "PERSONA_FISICA_JURIDICA"
)

famd_quantitative_variables <- c(
  "CILINDRADA_ITV",
  "KW_ITV",
  "CO2_norm",
  "CONSUMO_WH_KM_ITV",
  "DISTANCIA_EJES_12_ITV"
)

famd_qualitative_variables <- c(
  "propulsion_type",
  "renting_status",
  "ownership_type"
)

famd_active_variables <- c(
  famd_quantitative_variables,
  famd_qualitative_variables
)


# Variable documentation -------------------------------------------------------

create_famd_variable_dictionary <- function() {

  tibble::tibble(
    variable = famd_active_variables,
    type = c(
      rep("Quantitative", 5),
      rep("Qualitative", 3)
    ),
    description = c(
      "Engine displacement, assigning zero to electric vehicles.",
      "Maximum net vehicle power in kilowatts.",
      "CO2 emissions standardised separately for NEDC and WLTP.",
      "Electric consumption in Wh/km, assigning zero to petrol and diesel vehicles.",
      "Distance between the first and second axles.",
      "Propulsion technology: petrol, diesel, hybrid or electric.",
      "Indicator identifying whether the registration is associated with renting.",
      "Indicator identifying individual or legal-entity ownership."
    )
  )
}


# Load master dataset ----------------------------------------------------------

load_famd_master_dataset <- function(
    file_path = file.path(
      path_data_processed,
      master_dataset_filename
    )
) {

  if (!file.exists(file_path)) {
    stop(
      "The master dataset does not exist: ",
      file_path,
      call. = FALSE
    )
  }

  data <- readRDS(file_path)

  if (!is.data.frame(data)) {
    stop(
      "The master dataset must be a data frame.",
      call. = FALSE
    )
  }

  data
}


# Validate input ---------------------------------------------------------------

validate_famd_input <- function(data) {

  missing_columns <- setdiff(
    famd_required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The FAMD dataset is missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Recoding functions -----------------------------------------------------------

derive_famd_propulsion <- function(
    propulsion_code,
    electric_vehicle_category
) {

  propulsion_code <- stringr::str_trim(
    as.character(propulsion_code)
  )

  electric_vehicle_category <- stringr::str_to_upper(
    stringr::str_trim(
      as.character(electric_vehicle_category)
    )
  )

  # Hybrid categories are evaluated first, reproducing AnalisisFact.qmd.
  dplyr::case_when(
    electric_vehicle_category %in%
      hybrid_vehicle_categories ~ "Hybrid",

    propulsion_code ==
      propulsion_code_electric ~ "Electric",

    propulsion_code ==
      propulsion_code_petrol ~ "Petrol",

    propulsion_code ==
      propulsion_code_diesel ~ "Diesel",

    TRUE ~ NA_character_
  )
}


derive_famd_renting <- function(x) {

  x <- stringr::str_to_upper(
    stringr::str_trim(
      as.character(x)
    )
  )

  dplyr::case_when(
    x == "S" ~ "Yes",
    x == "N" ~ "No",
    TRUE ~ NA_character_
  )
}


derive_famd_ownership <- function(x) {

  x <- stringr::str_to_upper(
    stringr::str_trim(
      as.character(x)
    )
  )

  dplyr::case_when(
    x %in% c(
      "D",
      "FISICA",
      "FÍSICA"
    ) ~ "Individual",

    x %in% c(
      "X",
      "JURIDICA",
      "JURÍDICA"
    ) ~ "Legal entity",

    TRUE ~ NA_character_
  )
}


# Standardise CO2 within each measurement framework ----------------------------

standardise_co2 <- function(x) {

  valid_values <- x[
    !is.na(x)
  ]

  if (length(valid_values) < 2L) {
    return(
      rep(
        NA_real_,
        length(x)
      )
    )
  }

  standard_deviation <- stats::sd(
    valid_values
  )

  if (
    is.na(standard_deviation) ||
    standard_deviation == 0
  ) {
    result <- rep(
      NA_real_,
      length(x)
    )

    result[!is.na(x)] <- 0

    return(result)
  }

  as.numeric(
    scale(x)[, 1]
  )
}


# Prepare the FAMD analytical dataset ------------------------------------------

prepare_famd_data <- function(data) {

  validate_famd_input(data)

  prepared_data <- data |>
    dplyr::mutate(
      id = dplyr::row_number(),
      FEC_MATRICULA = as.Date(
        .data$FEC_MATRICULA
      ),
      periodo = lubridate::floor_date(
        .data$FEC_MATRICULA,
        unit = "month"
      ),
      anio = lubridate::year(
        .data$FEC_MATRICULA
      ),
      propulsion_type = derive_famd_propulsion(
        .data$COD_PROPULSION_ITV,
        .data$CATEGORIA_VEHICULO_ELECTRICO
      ),
      renting_status = derive_famd_renting(
        .data$RENTING
      ),
      ownership_type = derive_famd_ownership(
        .data$PERSONA_FISICA_JURIDICA
      ),
      CILINDRADA_ITV = suppressWarnings(
        as.numeric(
          .data$CILINDRADA_ITV
        )
      ),
      KW_ITV = suppressWarnings(
        as.numeric(
          .data$KW_ITV
        )
      ),
      CO2_ITV = suppressWarnings(
        as.numeric(
          .data$CO2_ITV
        )
      ),
      CONSUMO_WH_KM_ITV = suppressWarnings(
        as.numeric(
          .data$CONSUMO_WH_KM_ITV
        )
      ),
      DISTANCIA_EJES_12_ITV = suppressWarnings(
        as.numeric(
          .data$DISTANCIA_EJES_12_ITV
        )
      )
    ) |>
    dplyr::filter(
      !is.na(.data$periodo),
      !is.na(.data$propulsion_type),
      .data$KW_ITV >= famd_minimum_power_kw,
      .data$DISTANCIA_EJES_12_ITV >=
        famd_minimum_wheelbase_mm,
      .data$DISTANCIA_EJES_12_ITV <=
        famd_maximum_wheelbase_mm
    ) |>
    dplyr::mutate(
      CILINDRADA_ITV = dplyr::case_when(
        .data$propulsion_type == "Electric" ~ 0,
        .data$CILINDRADA_ITV <= 0 ~ NA_real_,
        TRUE ~ .data$CILINDRADA_ITV
      ),
      KW_ITV = dplyr::case_when(
        .data$KW_ITV <= 0 ~ NA_real_,
        TRUE ~ .data$KW_ITV
      ),
      CONSUMO_WH_KM_ITV = dplyr::case_when(
        .data$propulsion_type %in%
          c("Petrol", "Diesel") ~ 0,

        .data$CONSUMO_WH_KM_ITV < 0 ~
          NA_real_,

        TRUE ~ .data$CONSUMO_WH_KM_ITV
      ),
      DISTANCIA_EJES_12_ITV = dplyr::case_when(
        .data$DISTANCIA_EJES_12_ITV <= 0 ~
          NA_real_,

        .data$DISTANCIA_EJES_12_ITV == 9999 ~
          NA_real_,

        TRUE ~ .data$DISTANCIA_EJES_12_ITV
      ),
      CO2_ITV = dplyr::case_when(
        .data$CO2_ITV <= 0 ~ NA_real_,
        TRUE ~ .data$CO2_ITV
      ),
      CO2_ITV = dplyr::case_when(
        .data$propulsion_type == "Electric" ~ 0,
        TRUE ~ .data$CO2_ITV
      ),
      emissions_framework = dplyr::if_else(
        .data$anio < wltp_start_year,
        "NEDC",
        "WLTP"
      )
    ) |>
    dplyr::group_by(
      .data$emissions_framework
    ) |>
    dplyr::mutate(
      CO2_norm = standardise_co2(
        .data$CO2_ITV
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      propulsion_type = factor(
        .data$propulsion_type,
        levels = c(
          "Petrol",
          "Diesel",
          "Hybrid",
          "Electric"
        )
      ),
      renting_status = factor(
        .data$renting_status,
        levels = c(
          "No",
          "Yes"
        )
      ),
      ownership_type = factor(
        .data$ownership_type,
        levels = c(
          "Individual",
          "Legal entity"
        )
      )
    )

  prepared_data
}


# Missing-value summary --------------------------------------------------------

summarise_famd_missing_values <- function(
    prepared_data
) {

  prepared_data |>
    dplyr::summarise(
      observations = dplyr::n(),
      missing_displacement = sum(
        is.na(.data$CILINDRADA_ITV)
      ),
      missing_power = sum(
        is.na(.data$KW_ITV)
      ),
      missing_co2 = sum(
        is.na(.data$CO2_norm)
      ),
      missing_electric_consumption = sum(
        is.na(.data$CONSUMO_WH_KM_ITV)
      ),
      missing_wheelbase = sum(
        is.na(.data$DISTANCIA_EJES_12_ITV)
      ),
      missing_propulsion = sum(
        is.na(.data$propulsion_type)
      ),
      missing_renting = sum(
        is.na(.data$renting_status)
      ),
      missing_ownership = sum(
        is.na(.data$ownership_type)
      )
    )
}


# Select complete observations -------------------------------------------------

create_famd_complete_case_data <- function(
    prepared_data,
    validate_expected_size = TRUE
) {

  complete_data <- prepared_data |>
    dplyr::filter(
      dplyr::if_all(
        dplyr::all_of(
          famd_active_variables
        ),
        ~ !is.na(.x)
      )
    ) |>
    dplyr::select(
      .data$id,
      .data$periodo,
      dplyr::all_of(
        famd_active_variables
      )
    )

  if (
    isTRUE(validate_expected_size) &&
      nrow(complete_data) !=
        expected_famd_observations
  ) {
    warning(
      "Expected ",
      expected_famd_observations,
      " complete FAMD observations but obtained ",
      nrow(complete_data),
      ".",
      call. = FALSE
    )
  }

  complete_data
}


# Create the active FAMD table -------------------------------------------------

create_famd_model_data <- function(
    complete_data
) {

  model_data <- complete_data |>
    dplyr::select(
      dplyr::all_of(
        famd_active_variables
      )
    )

  quantitative_classes <- vapply(
    model_data[
      famd_quantitative_variables
    ],
    is.numeric,
    FUN.VALUE = logical(1)
  )

  qualitative_classes <- vapply(
    model_data[
      famd_qualitative_variables
    ],
    is.factor,
    FUN.VALUE = logical(1)
  )

  if (!all(quantitative_classes)) {
    stop(
      "All quantitative FAMD variables must be numeric.",
      call. = FALSE
    )
  }

  if (!all(qualitative_classes)) {
    stop(
      "All qualitative FAMD variables must be factors.",
      call. = FALSE
    )
  }

  model_data
}


# Fit the main FAMD model ------------------------------------------------------

fit_famd_model <- function(
    model_data,
    number_of_components =
      famd_number_of_components
) {

  FactoMineR::FAMD(
    model_data,
    ncp = number_of_components,
    graph = FALSE
  )
}


# Extract eigenvalues ----------------------------------------------------------

extract_famd_eigenvalues <- function(
    famd_model
) {

  factoextra::get_eigenvalue(
    famd_model
  ) |>
    tibble::as_tibble(
      rownames = "dimension"
    )
}


# Extract variable contributions ----------------------------------------------

extract_famd_contributions <- function(
    famd_model
) {

  contribution_matrix <- famd_model$var$contrib

  if (is.null(contribution_matrix)) {
    stop(
      "Variable contributions are not available in the FAMD model.",
      call. = FALSE
    )
  }

  contribution_matrix |>
    as.data.frame() |>
    tibble::rownames_to_column(
      "variable"
    ) |>
    tibble::as_tibble()
}


# Extract individual factorial coordinates ------------------------------------

extract_famd_coordinates <- function(
    famd_model,
    complete_data
) {

  coordinates <- famd_model$ind$coord |>
    as.data.frame() |>
    tibble::as_tibble() |>
    dplyr::rename_with(
      ~ paste0(
        "Dim",
        seq_along(.x)
      )
    ) |>
    dplyr::mutate(
      id = complete_data$id,
      .before = 1
    )

  if (
    nrow(coordinates) !=
      nrow(complete_data)
  ) {
    stop(
      "The number of FAMD coordinates does not match the analytical dataset.",
      call. = FALSE
    )
  }

  if (!all(
    coordinates$id ==
      complete_data$id
  )) {
    stop(
      "The FAMD coordinates are not aligned with the analytical records.",
      call. = FALSE
    )
  }

  coordinates
}


# Top contributions by dimension ----------------------------------------------

summarise_top_famd_contributions <- function(
    contributions,
    dimensions = 1:3,
    number_of_variables = 8L
) {

  dimension_columns <- paste0(
    "Dim.",
    dimensions
  )

  missing_dimensions <- setdiff(
    dimension_columns,
    names(contributions)
  )

  if (length(missing_dimensions) > 0L) {
    stop(
      "The contribution table does not contain: ",
      paste(
        missing_dimensions,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  purrr::map_dfr(
    dimension_columns,
    function(dimension_column) {

      contributions |>
        dplyr::select(
          .data$variable,
          contribution =
            dplyr::all_of(
              dimension_column
            )
        ) |>
        dplyr::slice_max(
          order_by = .data$contribution,
          n = number_of_variables,
          with_ties = FALSE
        ) |>
        dplyr::mutate(
          dimension = dimension_column,
          .before = 1
        )
    }
  )
}


# Create compact clustering input ---------------------------------------------

create_famd_clustering_object <- function(
    complete_data,
    coordinates,
    eigenvalues,
    contributions
) {

  list(
    df_famd_clean = complete_data,
    coord_famd = coordinates,
    eig_val = eigenvalues,
    contrib_var = contributions,
    variables_famd =
      create_famd_variable_dictionary(),
    parameters = list(
      number_of_components =
        famd_number_of_components,
      seed = cluster_seed,
      expected_observations =
        expected_famd_observations,
      export_date = Sys.Date()
    )
  )
}


# Save FAMD outputs ------------------------------------------------------------

save_famd_outputs <- function(
    clustering_object,
    famd_model = NULL,
    clustering_output_path = file.path(
      path_data_processed,
      famd_cluster_input_filename
    ),
    full_model_output_path = file.path(
      path_data_processed,
      famd_full_model_filename
    ),
    save_full_model = FALSE
) {

  dir.create(
    dirname(clustering_output_path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  saveRDS(
    clustering_object,
    clustering_output_path
  )

  message(
    "Compact FAMD clustering input saved to: ",
    clustering_output_path
  )

  if (isTRUE(save_full_model)) {

    if (is.null(famd_model)) {
      stop(
        "A fitted FAMD model is required when save_full_model is TRUE.",
        call. = FALSE
      )
    }

    saveRDS(
      famd_model,
      full_model_output_path
    )

    message(
      "Complete FAMD model saved to: ",
      full_model_output_path
    )
  }

  invisible(
    list(
      clustering_output_path =
        clustering_output_path,
      full_model_output_path =
        if (isTRUE(save_full_model)) {
          full_model_output_path
        } else {
          NULL
        }
    )
  )
}


# Sensitivity model without renting -------------------------------------------

fit_famd_without_renting <- function(
    complete_data
) {

  sensitivity_variables <- setdiff(
    famd_active_variables,
    "renting_status"
  )

  sensitivity_data <- complete_data |>
    dplyr::select(
      dplyr::all_of(
        sensitivity_variables
      )
    )

  FactoMineR::FAMD(
    sensitivity_data,
    ncp = famd_number_of_components,
    graph = FALSE
  )
}


# Model with renting and ownership as supplementary variables -----------------

fit_famd_with_supplementary_ownership <- function(
    complete_data
) {

  supplementary_data <- complete_data |>
    dplyr::select(
      dplyr::all_of(
        famd_active_variables
      )
    )

  supplementary_positions <- match(
    c(
      "renting_status",
      "ownership_type"
    ),
    names(supplementary_data)
  )

  FactoMineR::FAMD(
    supplementary_data,
    ncp = famd_number_of_components,
    quali.sup = supplementary_positions,
    graph = FALSE
  )
}


# Visualisations ---------------------------------------------------------------

plot_famd_scree <- function(
    famd_model
) {

  factoextra::fviz_screeplot(
    famd_model,
    addlabels = TRUE
  ) +
    ggplot2::labs(
      title = "FAMD explained inertia",
      subtitle = "Eight retained factorial dimensions"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_famd_variables <- function(
    famd_model,
    axes = c(1, 2)
) {

  factoextra::fviz_famd_var(
    famd_model,
    axes = axes,
    repel = TRUE
  ) +
    ggplot2::labs(
      title = paste0(
        "FAMD variable map: dimensions ",
        axes[[1]],
        " and ",
        axes[[2]]
      )
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_famd_contributions <- function(
    famd_model,
    dimension = 1L,
    number_of_variables = 15L
) {

  factoextra::fviz_contrib(
    famd_model,
    choice = "var",
    axes = dimension,
    top = number_of_variables
  ) +
    ggplot2::labs(
      title = paste(
        "Variable contributions to dimension",
        dimension
      )
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


# Run the complete FAMD workflow ----------------------------------------------

run_famd_analysis <- function(
    data = load_famd_master_dataset(),
    save_output = TRUE,
    save_full_model = FALSE,
    validate_expected_size = TRUE
) {

  message(
    "Preparing the FAMD analytical dataset."
  )

  prepared_data <- prepare_famd_data(
    data
  )

  missing_summary <- summarise_famd_missing_values(
    prepared_data
  )

  complete_data <- create_famd_complete_case_data(
    prepared_data,
    validate_expected_size =
      validate_expected_size
  )

  retention_rate <- 100 *
    nrow(complete_data) /
    nrow(prepared_data)

  message(
    "FAMD complete observations: ",
    format(
      nrow(complete_data),
      big.mark = ",",
      scientific = FALSE
    ),
    " | Retained: ",
    round(retention_rate, 2),
    "%"
  )

  model_data <- create_famd_model_data(
    complete_data
  )

  message(
    "Fitting the FAMD model."
  )

  famd_model <- fit_famd_model(
    model_data
  )

  eigenvalues <- extract_famd_eigenvalues(
    famd_model
  )

  contributions <- extract_famd_contributions(
    famd_model
  )

  coordinates <- extract_famd_coordinates(
    famd_model,
    complete_data
  )

  top_contributions <-
    summarise_top_famd_contributions(
      contributions
    )

  clustering_object <-
    create_famd_clustering_object(
      complete_data,
      coordinates,
      eigenvalues,
      contributions
    )

  if (isTRUE(save_output)) {
    save_famd_outputs(
      clustering_object =
        clustering_object,
      famd_model = famd_model,
      save_full_model =
        save_full_model
    )
  }

  list(
    data = list(
      prepared = prepared_data,
      complete = complete_data,
      model = model_data
    ),
    model = famd_model,
    clustering_object =
      clustering_object,
    tables = list(
      missing_values = missing_summary,
      eigenvalues = eigenvalues,
      contributions = contributions,
      top_contributions =
        top_contributions
    ),
    figures = list(
      scree = plot_famd_scree(
        famd_model
      ),
      variables_dim_1_2 =
        plot_famd_variables(
          famd_model,
          axes = c(1, 2)
        ),
      variables_dim_1_3 =
        plot_famd_variables(
          famd_model,
          axes = c(1, 3)
        ),
      variables_dim_2_3 =
        plot_famd_variables(
          famd_model,
          axes = c(2, 3)
        ),
      contribution_dim_1 =
        plot_famd_contributions(
          famd_model,
          dimension = 1
        ),
      contribution_dim_2 =
        plot_famd_contributions(
          famd_model,
          dimension = 2
        ),
      contribution_dim_3 =
        plot_famd_contributions(
          famd_model,
          dimension = 3
        )
    )
  )
}


# Usage examples ---------------------------------------------------------------

# Run the complete analysis and save the compact clustering input:
#
# famd_results <- run_famd_analysis(
#   save_output = TRUE,
#   save_full_model = FALSE
# )
#
# Inspect the eigenvalues:
#
# famd_results$tables$eigenvalues
#
# Inspect the most important contributions:
#
# famd_results$tables$top_contributions
#
# Display the main variable map:
#
# famd_results$figures$variables_dim_1_2
#
# Optional sensitivity analysis:
#
# famd_without_renting <- fit_famd_without_renting(
#   famd_results$data$complete
# )
#
# famd_supplementary <- fit_famd_with_supplementary_ownership(
#   famd_results$data$complete
# )