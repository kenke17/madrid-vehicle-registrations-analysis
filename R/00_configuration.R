# =============================================================================
# Project configuration
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# General options --------------------------------------------------------------

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)


# Package groups ---------------------------------------------------------------

project_packages <- list(
  core = c(
    "here",
    "dplyr",
    "tidyr",
    "readr",
    "stringr",
    "purrr",
    "tibble",
    "lubridate",
    "ggplot2",
    "scales"
  ),
  territorial = c(
    "sf",
    "stringi"
  ),
  multivariate = c(
    "FactoMineR",
    "factoextra",
    "cluster"
  ),
  time_series = c(
    "forecast",
    "zoo"
  ),
  reporting = c(
    "knitr",
    "flextable",
    "officer",
    "patchwork"
  )
)


# Package validation -----------------------------------------------------------

check_project_packages <- function(groups = names(project_packages)) {

  unknown_groups <- setdiff(groups, names(project_packages))

  if (length(unknown_groups) > 0) {
    stop(
      "Unknown package group: ",
      paste(unknown_groups, collapse = ", "),
      call. = FALSE
    )
  }

  packages <- unique(
    unlist(
      project_packages[groups],
      use.names = FALSE
    )
  )

  missing_packages <- packages[
    !vapply(
      packages,
      requireNamespace,
      quietly = TRUE,
      FUN.VALUE = logical(1)
    )
  ]

  if (length(missing_packages) > 0) {
    stop(
      paste0(
        "The following packages are required but not installed: ",
        paste(missing_packages, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  invisible(packages)
}


# Validate the packages required by all scripts --------------------------------

check_project_packages("core")


# Project paths ----------------------------------------------------------------

path_data_raw <- here::here("data", "raw")
path_data_sample <- here::here("data", "sample")
path_data_processed <- here::here("data", "processed")

path_scripts <- here::here("R")
path_notebooks <- here::here("notebooks")
path_figures <- here::here("figures")
path_reports <- here::here("reports")
path_docs <- here::here("docs")


# Create output directories if necessary --------------------------------------

output_directories <- c(
  path_data_sample,
  path_data_processed,
  path_figures,
  path_reports
)

invisible(
  lapply(
    output_directories,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)


# Study scope ------------------------------------------------------------------

analysis_start_date <- as.Date("2015-01-01")
analysis_end_date <- as.Date("2025-12-31")

analysis_start_year <- 2015L
analysis_end_year <- 2025L

expected_number_of_months <- 132L
expected_master_observations <- 3115063L

madrid_province_code <- "M"
madrid_city_name <- "Madrid"


# Source-file configuration ----------------------------------------------------

source_file_pattern <- "^export_mensual_mat_\\d{6}\\.txt$"
source_period_pattern <- "\\d{6}"

master_dataset_filename <- "passenger_car_registrations_madrid.rds"


# Final filtering rules --------------------------------------------------------

valid_registration_classes <- c(
  "0",
  "1",
  "3",
  "8"
)

valid_vehicle_types <- c(
  "24",
  "25",
  "40"
)

new_vehicle_code <- "N"

excluded_service_codes <- sprintf(
  "A%02d",
  1:20
)

withdrawal_variables <- c(
  "IND_BAJA_DEF",
  "IND_BAJA_TEMP",
  "BAJA_TELEMATICA"
)


# Propulsion codes -------------------------------------------------------------

propulsion_code_petrol <- "0"
propulsion_code_diesel <- "1"
propulsion_code_electric <- "2"

hybrid_vehicle_categories <- c(
  "PHEV",
  "HEV",
  "REEV"
)


# FAMD configuration -----------------------------------------------------------

famd_number_of_components <- 8L

famd_minimum_power_kw <- 10
famd_minimum_wheelbase_mm <- 1000
famd_maximum_wheelbase_mm <- 6000

nedc_end_year <- 2020L
wltp_start_year <- 2021L


# Clustering configuration -----------------------------------------------------

cluster_seed <- 123L

cluster_final_k <- 5L
cluster_nstart <- 50L
cluster_max_iterations <- 100L

cluster_inertia_threshold <- 0.60
cluster_minimum_dimensions <- 3L
cluster_maximum_dimensions <- 6L

cluster_candidate_values <- 2:10
cluster_detailed_candidate_values <- 4:8

cluster_validation_sample_size <- 2000L


# Time-series configuration ----------------------------------------------------

time_series_frequency <- 12L
stl_seasonal_window <- "periodic"


# Confirmation message ---------------------------------------------------------

message(
  paste0(
    "Project configuration loaded: ",
    analysis_start_year,
    "-",
    analysis_end_year,
    " | Expected observations: ",
    format(
      expected_master_observations,
      big.mark = ",",
      scientific = FALSE
    )
  )
)