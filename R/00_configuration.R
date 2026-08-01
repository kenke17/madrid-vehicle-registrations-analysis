# =============================================================================
# Project configuration
# Vehicle Registrations in Madrid
# Author: Miguel Moscardó
# =============================================================================

# Global options ---------------------------------------------------------------

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

set.seed(2026)


# Required packages ------------------------------------------------------------

required_packages <- c(
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "lubridate",
  "ggplot2",
  "purrr",
  "tibble",
  "here"
)


# Package validation -----------------------------------------------------------

missing_packages <- required_packages[
  !vapply(
    required_packages,
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
      ". Install them before running the analysis."
    ),
    call. = FALSE
  )
}


# Load packages ----------------------------------------------------------------

invisible(
  lapply(
    required_packages,
    library,
    character.only = TRUE
  )
)


# Project paths ----------------------------------------------------------------

path_data_raw <- here::here("data", "raw")
path_data_sample <- here::here("data", "sample")
path_data_processed <- here::here("data", "processed")
path_figures <- here::here("figures")
path_reports <- here::here("reports")
path_docs <- here::here("docs")


# Create output directories if necessary --------------------------------------

output_directories <- c(
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


# Project constants ------------------------------------------------------------

analysis_start_year <- 2014
analysis_end_year <- 2025

madrid_city_name <- "Madrid"

valid_cod_clase_mat <- c(
  "0",
  "3",
  "6",
  "8"
)

valid_cod_tipo <- c(
  "0G",
  "20",
  "21",
  "24",
  "25",
  "50",
  "51",
  "54",
  "90",
  "91",
  "92"
)


# Confirmation message ---------------------------------------------------------

message(
  "Project configuration loaded successfully: ",
  analysis_start_year,
  "–",
  analysis_end_year
)