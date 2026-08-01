# =============================================================================
# Import DGT fixed-width files
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("path_data_raw", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}


# DGT fixed-width layout -------------------------------------------------------

dgt_field_names <- c(
  "FEC_MATRICULA",
  "COD_CLASE_MAT",
  "FEC_TRAMITACION",
  "MARCA_ITV",
  "MODELO_ITV",
  "COD_PROCEDENCIA_ITV",
  "BASTIDOR_ITV",
  "COD_TIPO",
  "COD_PROPULSION_ITV",
  "CILINDRADA_ITV",
  "POTENCIA_ITV",
  "TARA",
  "PESO_MAX",
  "NUM_PLAZAS",
  "IND_PRECINTO",
  "IND_EMBARGO",
  "NUM_TRANSMISIONES",
  "NUM_TITULARES",
  "LOCALIDAD_VEHICULO",
  "COD_PROVINCIA_VEH",
  "COD_PROVINCIA_MAT",
  "CLAVE_TRAMITE",
  "FEC_TRAMITE",
  "CODIGO_POSTAL",
  "FEC_PRIM_MATRICULACION",
  "IND_NUEVO_USADO",
  "PERSONA_FISICA_JURIDICA",
  "CODIGO_ITV",
  "SERVICIO",
  "COD_MUNICIPIO_INE_VEH",
  "MUNICIPIO",
  "KW_ITV",
  "NUM_PLAZAS_MAX",
  "CO2_ITV",
  "RENTING",
  "COD_TUTELA",
  "COD_POSESION",
  "IND_BAJA_DEF",
  "IND_BAJA_TEMP",
  "IND_SUSTRACCION",
  "BAJA_TELEMATICA",
  "TIPO_ITV",
  "VARIANTE_ITV",
  "VERSION_ITV",
  "FABRICANTE_ITV",
  "MASA_ORDEN_MARCHA_ITV",
  "MASA_MAXIMA_TECNICA_ADMISIBLE_ITV",
  "CATEGORIA_HOMOLOGACION_EUROPEA_ITV",
  "CARROCERIA",
  "PLAZAS_PIE",
  "NIVEL_EMISIONES_EURO_ITV",
  "CONSUMO_WH_KM_ITV",
  "CLASIFICACION_REGLAMENTO_VEHICULOS_ITV",
  "CATEGORIA_VEHICULO_ELECTRICO",
  "AUTONOMIA_VEHICULO_ELECTRICO",
  "MARCA_VEHICULO_BASE",
  "FABRICANTE_VEHICULO_BASE",
  "TIPO_VEHICULO_BASE",
  "VARIANTE_VEHICULO_BASE",
  "VERSION_VEHICULO_BASE",
  "DISTANCIA_EJES_12_ITV",
  "VIA_ANTERIOR_ITV",
  "VIA_POSTERIOR_ITV",
  "TIPO_ALIMENTACION_ITV",
  "CONTRASENA_HOMOLOGACION_ITV",
  "ECO_INNOVACION_ITV",
  "REDUCCION_ECO_ITV",
  "CODIGO_ECO_ITV",
  "FEC_PROCESO"
)

dgt_field_widths <- c(
  8, 1, 8, 30, 22, 1, 21, 2, 1, 5,
  6, 6, 6, 3, 2, 2, 2, 2, 24, 2,
  2, 1, 8, 5, 8, 1, 1, 9, 3, 5,
  30, 7, 3, 5, 1, 1, 1, 1, 1, 1,
  11, 25, 25, 35, 70, 6, 6, 4, 4, 3,
  8, 4, 4, 4, 6, 30, 50, 35, 25, 35,
  4, 4, 4, 1, 25, 1, 4, 25, 8
)


# Validate the interface definition -------------------------------------------

validate_dgt_layout <- function(
    field_names = dgt_field_names,
    field_widths = dgt_field_widths
) {

  if (length(field_names) != length(field_widths)) {
    stop(
      "The number of DGT field names does not match the number of widths.",
      call. = FALSE
    )
  }

  if (length(field_names) != 69L) {
    stop(
      "The DGT interface must contain exactly 69 fields.",
      call. = FALSE
    )
  }

  if (
    anyDuplicated(field_names) > 0L ||
    any(is.na(field_names)) ||
    any(field_names == "")
  ) {
    stop(
      "The DGT field names must be unique and non-empty.",
      call. = FALSE
    )
  }

  if (
    any(is.na(field_widths)) ||
    any(field_widths <= 0)
  ) {
    stop(
      "All DGT field widths must be positive numbers.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Extract the source month from a filename -------------------------------------

extract_dgt_period <- function(file_path) {

  file_name <- basename(file_path)

  period <- stringr::str_extract(
    file_name,
    source_period_pattern
  )

  if (
    is.na(period) ||
    !grepl("^\\d{6}$", period)
  ) {
    stop(
      "The source period could not be extracted from: ",
      file_name,
      call. = FALSE
    )
  }

  year <- suppressWarnings(
    as.integer(substr(period, 1, 4))
  )

  month <- suppressWarnings(
    as.integer(substr(period, 5, 6))
  )

  if (
    is.na(year) ||
    is.na(month) ||
    month < 1L ||
    month > 12L
  ) {
    stop(
      "The filename contains an invalid source period: ",
      file_name,
      call. = FALSE
    )
  }

  period
}


# List the available monthly source files -------------------------------------

list_dgt_source_files <- function(
    path = path_data_raw,
    pattern = source_file_pattern
) {

  if (!dir.exists(path)) {
    stop(
      "The raw-data directory does not exist: ",
      path,
      call. = FALSE
    )
  }

  files <- list.files(
    path = path,
    pattern = pattern,
    full.names = TRUE,
    recursive = FALSE,
    ignore.case = FALSE
  )

  files <- sort(files)

  if (length(files) == 0L) {
    warning(
      "No DGT monthly files were found in: ",
      path,
      call. = FALSE
    )

    return(character())
  }

  periods <- vapply(
    files,
    extract_dgt_period,
    FUN.VALUE = character(1)
  )

  if (anyDuplicated(periods) > 0L) {
    duplicated_periods <- unique(
      periods[duplicated(periods)]
    )

    stop(
      "More than one source file was found for the following period(s): ",
      paste(duplicated_periods, collapse = ", "),
      call. = FALSE
    )
  }

  files[order(periods)]
}


# Create an inventory of the source files --------------------------------------

create_dgt_file_inventory <- function(
    files = list_dgt_source_files()
) {

  if (length(files) == 0L) {
    return(
      tibble::tibble(
        file_name = character(),
        period = character(),
        file_size_mb = numeric()
      )
    )
  }

  file_information <- file.info(files)

  tibble::tibble(
    file_name = basename(files),
    period = vapply(
      files,
      extract_dgt_period,
      FUN.VALUE = character(1)
    ),
    file_size_mb = round(
      file_information$size / 1024^2,
      digits = 2
    )
  )
}


# Read one monthly fixed-width file --------------------------------------------

read_dgt_fixed_width_file <- function(
    file_path,
    skip_header = TRUE,
    progress = interactive()
) {

  validate_dgt_layout()

  if (!file.exists(file_path)) {
    stop(
      "The following DGT source file does not exist: ",
      file_path,
      call. = FALSE
    )
  }

  file_name <- basename(file_path)

  if (!grepl(source_file_pattern, file_name)) {
    stop(
      "The filename does not follow the expected DGT pattern: ",
      file_name,
      call. = FALSE
    )
  }

  source_period <- extract_dgt_period(file_path)

  imported_data <- readr::read_fwf(
    file = file_path,
    col_positions = readr::fwf_widths(
      dgt_field_widths,
      col_names = dgt_field_names
    ),
    col_types = readr::cols(
      .default = readr::col_character()
    ),
    trim_ws = FALSE,
    skip = if (isTRUE(skip_header)) 1L else 0L,
    progress = progress,
    name_repair = "minimal"
  )

  imported_data |>
    tibble::as_tibble() |>
    dplyr::mutate(
      source_file = file_name,
      periodo = source_period,
      .before = 1
    )
}


# Optional validation of the complete study period -----------------------------

validate_complete_source_period <- function(
    files = list_dgt_source_files()
) {

  if (length(files) == 0L) {
    stop(
      "No source files are available for period validation.",
      call. = FALSE
    )
  }

  observed_periods <- as.Date(
    paste0(
      vapply(
        files,
        extract_dgt_period,
        FUN.VALUE = character(1)
      ),
      "01"
    ),
    format = "%Y%m%d"
  )

  expected_periods <- seq.Date(
    from = analysis_start_date,
    to = analysis_end_date,
    by = "month"
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
      "Missing DGT source periods: ",
      paste(
        format(missing_periods, "%Y%m"),
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  if (length(unexpected_periods) > 0L) {
    warning(
      "Source periods outside the study window: ",
      paste(
        format(unexpected_periods, "%Y%m"),
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  tibble::tibble(
    expected_files = length(expected_periods),
    observed_files = length(observed_periods),
    missing_files = length(missing_periods),
    unexpected_files = length(unexpected_periods)
  )
}


# Usage examples ---------------------------------------------------------------

# List the monthly source files:
#
# dgt_files <- list_dgt_source_files()
#
# Inspect the source-file inventory:
#
# create_dgt_file_inventory(dgt_files)
#
# Validate coverage from January 2015 to December 2025:
#
# validate_complete_source_period(dgt_files)
#
# Read a single monthly file:
#
# monthly_raw_data <- read_dgt_fixed_width_file(
#   dgt_files[[1]]
# )