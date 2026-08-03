# =============================================================================
# Export public aggregated results
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("path_data_public", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

check_project_packages("core")


# Load analytical functions ----------------------------------------------------

source_project_script <- function(
    file_name,
    required_function
) {

  if (
    exists(
      required_function,
      inherits = TRUE
    )
  ) {
    return(
      invisible(TRUE)
    )
  }

  script_path <- here::here(
    "R",
    file_name
  )

  if (!file.exists(script_path)) {
    stop(
      "Required project script not found: ",
      script_path,
      call. = FALSE
    )
  }

  source(
    script_path,
    local = .GlobalEnv
  )

  if (
    !exists(
      required_function,
      inherits = TRUE
    )
  ) {
    stop(
      "The script did not define the expected function: ",
      required_function,
      call. = FALSE
    )
  }

  invisible(TRUE)
}


source_project_script(
  "04_territorial_analysis.R",
  "prepare_territorial_data"
)

source_project_script(
  "05_famd_analysis.R",
  "derive_famd_propulsion"
)

source_project_script(
  "06_cluster_analysis.R",
  "final_cluster_labels"
)
source_project_script(
  "07_time_series_analysis.R",
  "prepare_monthly_registration_series"
)


# Output file names ------------------------------------------------------------

public_result_files <- c(
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


# Load master dataset ----------------------------------------------------------

load_public_results_master_data <- function(
    file_path = file.path(
      path_data_processed,
      master_dataset_filename
    )
) {

  if (!file.exists(file_path)) {
    stop(
      "The processed master dataset does not exist: ",
      file_path,
      call. = FALSE
    )
  }

  data <- readRDS(
    file_path
  )

  if (!is.data.frame(data)) {
    stop(
      "The processed master dataset must be a data frame.",
      call. = FALSE
    )
  }

  data
}


# Validate required input files ------------------------------------------------

validate_public_result_inputs <- function() {

  required_files <- c(
    master_dataset = file.path(
      path_data_processed,
      master_dataset_filename
    ),
    famd_results = file.path(
      path_data_processed,
      famd_cluster_input_filename
    ),
    cluster_results = file.path(
      path_data_processed,
      cluster_results_filename
    ),
    municipal_shapefile =
      municipal_shapefile_path
  )

  missing_files <- required_files[
    !file.exists(
      required_files
    )
  ]

  if (length(missing_files) > 0L) {
    stop(
      "The following required files are missing:\n",
      paste(
        missing_files,
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  invisible(required_files)
}


# Monthly and annual registrations --------------------------------------------

create_public_monthly_registrations <- function(
    data
) {

  prepare_monthly_registration_series(
    data
  ) |>
    dplyr::select(
      dplyr::all_of(
        c(
          "month",
          "year",
          "month_number",
          "month_name",
          "registrations"
        )
      )
    )
}


create_public_annual_registrations <- function(
    monthly_registrations
) {

  summarise_annual_time_series(
    monthly_registrations
  )
}


# Propulsion evolution ---------------------------------------------------------

create_public_propulsion_evolution <- function(
    data
) {

  required_columns <- c(
    "FEC_MATRICULA",
    "COD_PROPULSION_ITV",
    "CATEGORIA_VEHICULO_ELECTRICO"
  )

  missing_columns <- setdiff(
    required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "Missing propulsion columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  data |>
    dplyr::transmute(
      year = lubridate::year(
        as.Date(
          .data$FEC_MATRICULA
        )
      ),
      propulsion_type =
        derive_famd_propulsion(
          .data$COD_PROPULSION_ITV,
          .data$CATEGORIA_VEHICULO_ELECTRICO
        )
    ) |>
    dplyr::filter(
      !is.na(.data$year),
      !is.na(.data$propulsion_type)
    ) |>
    dplyr::count(
      .data$year,
      .data$propulsion_type,
      name = "registrations"
    ) |>
    dplyr::group_by(
      .data$year
    ) |>
    dplyr::mutate(
      annual_total = sum(
        .data$registrations
      ),
      annual_share =
        .data$registrations /
        .data$annual_total
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$year,
      .data$propulsion_type
    )
}


# Municipal ranking ------------------------------------------------------------

create_public_municipal_ranking <- function(
    data,
    shapefile_path =
      municipal_shapefile_path
) {

  municipal_boundaries <-
    load_madrid_municipal_boundaries(
      shapefile_path
    )

  territorial_data <-
    prepare_territorial_data(
      data,
      municipal_boundaries
    )

  unmatched <-
    identify_unmatched_municipalities(
      territorial_data,
      municipal_boundaries
    )

  if (nrow(unmatched) > 0L) {
    stop(
      "Public municipal results cannot be exported because ",
      nrow(unmatched),
      " municipality names remain unmatched.",
      call. = FALSE
    )
  }

  summarise_municipal_ranking(
    territorial_data
  ) |>
    dplyr::select(
      dplyr::all_of(
        c(
          "position",
          "municipality_name",
          "registrations",
          "share_of_total",
          "cumulative_share"
        )
      )
    )
}


# FAMD eigenvalues -------------------------------------------------------------

create_public_famd_eigenvalues <- function(
    file_path = file.path(
      path_data_processed,
      famd_cluster_input_filename
    )
) {

  famd_object <- readRDS(
    file_path
  )

  if (
    !is.list(famd_object) ||
      is.null(
        famd_object[["eig_val"]]
      )
  ) {
    stop(
      "The saved FAMD object does not contain eig_val.",
      call. = FALSE
    )
  }

  tibble::as_tibble(
    famd_object[["eig_val"]]
  )
}


# Cluster profile helpers ------------------------------------------------------

normalise_public_column_name <- function(x) {

  x |>
    as.character() |>
    iconv(
      from = "",
      to = "ASCII//TRANSLIT"
    ) |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(
      "[^a-z0-9]+",
      "_"
    ) |>
    stringr::str_replace_all(
      "^_|_$",
      ""
    )
}


create_wide_cluster_shares <- function(
    profile,
    prefix
) {

  profile |>
    dplyr::mutate(
      cluster = as.character(
        .data$cluster
      ),
      category_name =
        normalise_public_column_name(
          .data$category
        ),
      output_column = paste0(
        prefix,
        "_share_",
        .data$category_name
      )
    ) |>
    dplyr::select(
      dplyr::all_of(
        c(
          "cluster",
          "output_column",
          "share"
        )
      )
    ) |>
    tidyr::pivot_wider(
      names_from = "output_column",
      values_from = "share",
      values_fill = 0
    )
}


# Combined cluster profiles ----------------------------------------------------

create_public_cluster_profiles <- function(
    file_path = file.path(
      path_data_processed,
      cluster_results_filename
    )
) {

  cluster_results <- readRDS(
    file_path
  )

  required_tables <- c(
    "numeric_profile",
    "propulsion_profile",
    "ownership_profile",
    "renting_profile"
  )

  if (
    !is.list(cluster_results) ||
      is.null(
        cluster_results[["tables"]]
      )
  ) {
    stop(
      "The saved clustering object does not contain result tables.",
      call. = FALSE
    )
  }

  missing_tables <- setdiff(
    required_tables,
    names(
      cluster_results[["tables"]]
    )
  )

  if (length(missing_tables) > 0L) {
    stop(
      "Missing clustering result tables: ",
      paste(
        missing_tables,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  numeric_profile <-
    cluster_results[["tables"]][["numeric_profile"]] |>
    dplyr::mutate(
      cluster = as.character(
        .data$cluster
      ),
      cluster_label = unname(
        final_cluster_labels[
          .data$cluster
        ]
      ),
      cluster_share =
        .data$share
    ) |>
    dplyr::select(
      -dplyr::all_of(
        "share"
      )
    )

  propulsion_profile <-
    create_wide_cluster_shares(
      cluster_results[["tables"]][["propulsion_profile"]],
      "propulsion"
    )

  ownership_profile <-
    create_wide_cluster_shares(
      cluster_results[["tables"]][["ownership_profile"]],
      "ownership"
    )

  renting_profile <-
    create_wide_cluster_shares(
      cluster_results[["tables"]][["renting_profile"]],
      "renting"
    )

  numeric_profile |>
    dplyr::left_join(
      propulsion_profile,
      by = "cluster"
    ) |>
    dplyr::left_join(
      ownership_profile,
      by = "cluster"
    ) |>
    dplyr::left_join(
      renting_profile,
      by = "cluster"
    ) |>
    dplyr::arrange(
      as.integer(
        .data$cluster
      )
    )
}


# Write one public CSV ----------------------------------------------------------

write_public_result <- function(
    data,
    file_name
) {

  output_path <- file.path(
    path_data_public,
    file_name
  )

  readr::write_csv(
    data,
    output_path,
    na = ""
  )

  message(
    "Public result saved: ",
    output_path,
    " | Rows: ",
    format(
      nrow(data),
      big.mark = ",",
      scientific = FALSE
    )
  )

  invisible(output_path)
}


# Export complete public-results package ---------------------------------------

run_public_results_export <- function(
    data =
      load_public_results_master_data()
) {

  validate_public_result_inputs()

  dir.create(
    path_data_public,
    recursive = TRUE,
    showWarnings = FALSE
  )

  message(
    "Creating public aggregated results."
  )

  monthly_registrations <-
    create_public_monthly_registrations(
      data
    )

  annual_registrations <-
    create_public_annual_registrations(
      monthly_registrations
    )

  propulsion_evolution <-
    create_public_propulsion_evolution(
      data
    )

  municipal_ranking <-
    create_public_municipal_ranking(
      data
    )

  famd_eigenvalues <-
    create_public_famd_eigenvalues()

  cluster_profiles <-
    create_public_cluster_profiles()

  results <- list(
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

  purrr::iwalk(
    results,
    function(result, result_name) {
      write_public_result(
        result,
        public_result_files[[result_name]]
      )
    }
  )

  message(
    "Public-results export completed."
  )

  invisible(results)
}


# Usage example ----------------------------------------------------------------

# public_results <- run_public_results_export()
#
# public_results$annual_registrations
# public_results$monthly_registrations
# public_results$propulsion_evolution
# public_results$municipal_ranking
# public_results$famd_eigenvalues
# public_results$cluster_profiles