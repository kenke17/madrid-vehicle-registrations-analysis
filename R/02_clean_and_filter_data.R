# =============================================================================
# Clean, filter and integrate DGT registration data
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load import functions and configuration --------------------------------------

if (
  !exists(
    "read_dgt_fixed_width_file",
    mode = "function",
    inherits = TRUE
  )
) {
  source(
    here::here(
      "R",
      "01_import_fixed_width_data.R"
    )
  )
}


# Variables required during processing ----------------------------------------

dgt_processing_columns <- c(
  "source_file",
  "periodo",
  "FEC_MATRICULA",
  "COD_CLASE_MAT",
  "MARCA_ITV",
  "MODELO_ITV",
  "COD_TIPO",
  "COD_PROPULSION_ITV",
  "CILINDRADA_ITV",
  "POTENCIA_ITV",
  "TARA",
  "NUM_PLAZAS",
  "NUM_TITULARES",
  "COD_PROVINCIA_VEH",
  "IND_NUEVO_USADO",
  "PERSONA_FISICA_JURIDICA",
  "MUNICIPIO",
  "SERVICIO",
  "NUM_PLAZAS_MAX",
  "CO2_ITV",
  "RENTING",
  "IND_BAJA_DEF",
  "IND_BAJA_TEMP",
  "BAJA_TELEMATICA",
  "TIPO_ITV",
  "VARIANTE_ITV",
  "VERSION_ITV",
  "FABRICANTE_ITV",
  "CATEGORIA_HOMOLOGACION_EUROPEA_ITV",
  "CARROCERIA",
  "NIVEL_EMISIONES_EURO_ITV",
  "CONSUMO_WH_KM_ITV",
  "CATEGORIA_VEHICULO_ELECTRICO",
  "AUTONOMIA_VEHICULO_ELECTRICO",
  "DISTANCIA_EJES_12_ITV",
  "KW_ITV"
)


# Variables retained in the final master dataset -------------------------------

master_dataset_columns <- c(
  "FEC_MATRICULA",
  "MARCA_ITV",
  "MODELO_ITV",
  "COD_TIPO",
  "COD_PROPULSION_ITV",
  "IND_NUEVO_USADO",
  "PERSONA_FISICA_JURIDICA",
  "SERVICIO",
  "CILINDRADA_ITV",
  "POTENCIA_ITV",
  "TARA",
  "MUNICIPIO",
  "CO2_ITV",
  "RENTING",
  "CARROCERIA",
  "NIVEL_EMISIONES_EURO_ITV",
  "CONSUMO_WH_KM_ITV",
  "CATEGORIA_VEHICULO_ELECTRICO",
  "AUTONOMIA_VEHICULO_ELECTRICO",
  "DISTANCIA_EJES_12_ITV",
  "periodo",
  "KW_ITV"
)


# Variables converted during the original workflow ----------------------------

dgt_date_variables <- c(
  "FEC_MATRICULA",
  "FEC_TRAMITACION",
  "FEC_TRAMITE",
  "FEC_PRIM_MATRICULACION",
  "FEC_PROCESO"
)

dgt_integer_variables <- c(
  "CILINDRADA_ITV",
  "TARA",
  "PESO_MAX",
  "NUM_PLAZAS",
  "NUM_TRANSMISIONES",
  "NUM_TITULARES",
  "CODIGO_POSTAL",
  "COD_MUNICIPIO_INE_VEH",
  "NUM_PLAZAS_MAX",
  "CO2_ITV",
  "PLAZAS_PIE",
  "MASA_ORDEN_MARCHA_ITV",
  "MASA_MAXIMA_TECNICA_ADMISIBLE_ITV",
  "DISTANCIA_EJES_12_ITV",
  "VIA_ANTERIOR_ITV",
  "VIA_POSTERIOR_ITV",
  "AUTONOMIA_VEHICULO_ELECTRICO",
  "CONSUMO_WH_KM_ITV",
  "REDUCCION_ECO_ITV"
)

dgt_numeric_variables <- c(
  "POTENCIA_ITV",
  "KW_ITV"
)


# Clean fixed-width character fields ------------------------------------------

clean_dgt_text <- function(x) {

  x <- stringr::str_squish(x)

  x <- dplyr::na_if(
    x,
    ""
  )

  known_placeholders <- c(
    "*****",
    "******",
    "*******"
  )

  x[x %in% known_placeholders] <- NA_character_

  asterisk_only <- (
    !is.na(x) &
      stringr::str_detect(
        x,
        "^\\*+$"
      )
  )

  x[asterisk_only] <- NA_character_

  x
}


# Convert DGT values -----------------------------------------------------------

parse_dgt_date <- function(x) {

  as.Date(
    x,
    format = "%d%m%Y"
  )
}


parse_dgt_integer <- function(x) {

  suppressWarnings(
    as.integer(
      readr::parse_number(x)
    )
  )
}


parse_dgt_numeric <- function(x) {

  suppressWarnings(
    as.numeric(
      readr::parse_number(x)
    )
  )
}


# Validate columns before processing ------------------------------------------

validate_raw_dgt_columns <- function(data) {

  required_columns <- unique(
    c(
      dgt_processing_columns,
      dgt_date_variables,
      dgt_integer_variables,
      dgt_numeric_variables
    )
  )

  missing_columns <- setdiff(
    required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The imported DGT data are missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Clean and convert one imported monthly dataset -------------------------------

clean_dgt_monthly_data <- function(raw_data) {

  validate_raw_dgt_columns(raw_data)

  cleaned_data <- raw_data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character),
        clean_dgt_text
      )
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(dgt_date_variables),
        parse_dgt_date
      ),
      dplyr::across(
        dplyr::all_of(dgt_integer_variables),
        parse_dgt_integer
      ),
      dplyr::across(
        dplyr::all_of(dgt_numeric_variables),
        parse_dgt_numeric
      )
    )

  cleaned_data
}


# Apply the final thesis filters -----------------------------------------------

filter_passenger_car_registrations <- function(cleaned_data) {

  required_filter_columns <- c(
    "COD_CLASE_MAT",
    "COD_TIPO",
    "COD_PROVINCIA_VEH",
    "IND_NUEVO_USADO",
    "SERVICIO",
    withdrawal_variables
  )

  missing_columns <- setdiff(
    required_filter_columns,
    names(cleaned_data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "Filtering cannot be performed because these columns are missing: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  filtered_data <- cleaned_data |>
    dplyr::select(
      dplyr::any_of(dgt_processing_columns)
    ) |>
    dplyr::filter(
      is.na(.data$IND_BAJA_DEF),
      is.na(.data$IND_BAJA_TEMP),
      is.na(.data$BAJA_TELEMATICA),
      .data$COD_CLASE_MAT %in% valid_registration_classes,
      .data$COD_TIPO %in% valid_vehicle_types,
      .data$COD_PROVINCIA_VEH == madrid_province_code,
      .data$IND_NUEVO_USADO == new_vehicle_code,
      !(.data$SERVICIO %in% excluded_service_codes)
    ) |>
    dplyr::select(
      dplyr::all_of(master_dataset_columns)
    )

  filtered_data
}


# Process one complete monthly source file -------------------------------------

process_dgt_monthly_file <- function(
    file_path,
    progress = interactive()
) {

  source_period <- extract_dgt_period(file_path)

  message(
    "Processing DGT period: ",
    source_period
  )

  raw_data <- read_dgt_fixed_width_file(
    file_path = file_path,
    skip_header = TRUE,
    progress = progress
  )

  raw_data |>
    clean_dgt_monthly_data() |>
    filter_passenger_car_registrations()
}


# Validate the resulting master dataset ----------------------------------------

validate_master_dataset <- function(
    data,
    check_expected_observations = FALSE
) {

  if (!identical(
    names(data),
    master_dataset_columns
  )) {
    stop(
      "The final master dataset does not contain the expected columns or order.",
      call. = FALSE
    )
  }

  if (!inherits(
    data$FEC_MATRICULA,
    "Date"
  )) {
    stop(
      "FEC_MATRICULA must have Date format.",
      call. = FALSE
    )
  }

  observed_periods <- sort(
    unique(
      data$periodo[
        !is.na(data$periodo)
      ]
    )
  )

  expected_periods <- format(
    seq.Date(
      from = analysis_start_date,
      to = analysis_end_date,
      by = "month"
    ),
    "%Y%m"
  )

  missing_periods <- setdiff(
    expected_periods,
    observed_periods
  )

  unexpected_periods <- setdiff(
    observed_periods,
    expected_periods
  )

  if (length(missing_periods) > 0L) {
    warning(
      "The master dataset is missing these periods: ",
      paste(
        missing_periods,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  if (length(unexpected_periods) > 0L) {
    warning(
      "The master dataset contains periods outside the study window: ",
      paste(
        unexpected_periods,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  dates_outside_scope <- sum(
    !is.na(data$FEC_MATRICULA) &
      (
        data$FEC_MATRICULA < analysis_start_date |
          data$FEC_MATRICULA > analysis_end_date
      )
  )

  if (dates_outside_scope > 0L) {
    warning(
      dates_outside_scope,
      " registrations have dates outside the study period.",
      call. = FALSE
    )
  }

  if (
    isTRUE(check_expected_observations) &&
      nrow(data) != expected_master_observations
  ) {
    warning(
      "Expected ",
      expected_master_observations,
      " observations but obtained ",
      nrow(data),
      ".",
      call. = FALSE
    )
  }

  tibble::tibble(
    observations = nrow(data),
    variables = ncol(data),
    first_registration_date = min(
      data$FEC_MATRICULA,
      na.rm = TRUE
    ),
    last_registration_date = max(
      data$FEC_MATRICULA,
      na.rm = TRUE
    ),
    observed_periods = length(observed_periods),
    missing_periods = length(missing_periods),
    unexpected_periods = length(unexpected_periods),
    dates_outside_scope = dates_outside_scope
  )
}


# Build the complete master dataset --------------------------------------------

build_master_dataset <- function(
    files = list_dgt_source_files(),
    output_path = file.path(
      path_data_processed,
      master_dataset_filename
    ),
    save_output = TRUE,
    check_expected_observations = TRUE
) {

  if (length(files) == 0L) {
    stop(
      "No DGT monthly source files are available.",
      call. = FALSE
    )
  }

  validate_complete_source_period(files)

  message(
    "Starting integration of ",
    length(files),
    " monthly DGT files."
  )

  master_data <- purrr::map_dfr(
    files,
    process_dgt_monthly_file,
    progress = FALSE
  )

  validation_summary <- validate_master_dataset(
    master_data,
    check_expected_observations = check_expected_observations
  )

  print(validation_summary)

  if (isTRUE(save_output)) {

    dir.create(
      dirname(output_path),
      recursive = TRUE,
      showWarnings = FALSE
    )

    saveRDS(
      master_data,
      output_path
    )

    message(
      "Master dataset saved to: ",
      output_path
    )
  }

  master_data
}


# Usage examples ---------------------------------------------------------------

# List and validate the 132 monthly source files:
#
# dgt_files <- list_dgt_source_files()
# validate_complete_source_period(dgt_files)
#
# Process a single month without saving:
#
# monthly_data <- process_dgt_monthly_file(
#   dgt_files[[1]]
# )
#
# Build and save the complete master dataset:
#
# passenger_car_data <- build_master_dataset(
#   files = dgt_files,
#   save_output = TRUE,
#   check_expected_observations = TRUE
# )