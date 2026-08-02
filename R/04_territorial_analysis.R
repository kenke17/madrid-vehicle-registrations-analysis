# =============================================================================
# Territorial analysis
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("municipal_shapefile_path", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

check_project_packages(
  c("core", "territorial")
)


# Required registration variables ---------------------------------------------

territorial_required_columns <- c(
  "MUNICIPIO",
  "FEC_MATRICULA",
  "RENTING",
  "PERSONA_FISICA_JURIDICA"
)


# Geographic fields used in the original workflow -----------------------------

municipal_boundary_required_columns <- c(
  "NAMEUNIT",
  "NATLEVNAME",
  "CODNUT3"
)

madrid_municipality_level <- "Municipio"
madrid_nuts3_code <- "ES300"


# Territorial groups -----------------------------------------------------------

territorial_group_levels <- c(
  "Madrid city",
  "Metropolitan or business municipalities",
  "Atypical peripheral municipalities",
  "Remaining municipalities"
)

atypical_municipalities <- c(
  "Robledo de Chavela",
  "Moralzarzal",
  "Venturada",
  "Colmenar del Arroyo",
  "Rozas de Puerto Real",
  "Navacerrada",
  "Brunete",
  "Collado Mediano",
  "Patones",
  "Torrelaguna"
)

business_municipalities <- c(
  "Alcobendas",
  "San Sebastián de los Reyes",
  "Pozuelo de Alarcón",
  "Las Rozas de Madrid",
  "Boadilla del Monte",
  "Majadahonda",
  "Rivas-Vaciamadrid",
  "Alcalá de Henares",
  "Torrejón de Ardoz",
  "Getafe",
  "Leganés",
  "Móstoles",
  "Fuenlabrada",
  "Alcorcón"
)


# Map categories used in the original analysis --------------------------------

municipality_count_breaks <- c(
  0,
  50,
  200,
  1000,
  5000,
  20000,
  100000,
  300000,
  Inf
)

municipality_count_labels <- c(
  "0–50",
  "50–200",
  "200–1,000",
  "1,000–5,000",
  "5,000–20,000",
  "20,000–100,000",
  "100,000–300,000",
  ">300,000"
)


# Normalise municipality names -------------------------------------------------

normalise_municipality_name <- function(x) {

  x |>
    iconv(
      from = "",
      to = "UTF-8",
      sub = ""
    ) |>
    stringi::stri_trans_general(
      "Latin-ASCII"
    ) |>
    stringr::str_to_upper() |>
    stringr::str_replace_all(
      "[^A-Z0-9 ]",
      " "
    ) |>
    stringr::str_replace_all(
      "\\b(DE|DEL|LA|LAS|EL|LOS)\\b",
      " "
    ) |>
    stringr::str_squish()
}


# Manual municipality equivalences --------------------------------------------

create_municipality_equivalences <- function() {

  tibble::tribble(
    ~source_name,                    ~map_name,
    "GRION",                         "Griñón",
    "GRI ON",                        "Griñón",
    "REDUEA",                        "Redueña",
    "REDUE A",                       "Redueña",
    "VALDEOLMOS",                    "Valdeolmos-Alalpardo",
    "FRESNEDILLAS",                  "Fresnedillas de la Oliva",
    "MORATA DE TAJUA",               "Morata de Tajuña",
    "MORATA DE TAJU A",              "Morata de Tajuña",
    "COBEA",                         "Cobeña",
    "COBE A",                        "Cobeña",
    "PERALES DE TAJUA",              "Perales de Tajuña",
    "PERALES DE TAJU A",             "Perales de Tajuña",
    "VILLANUEVA DE CAADA",           "Villanueva de la Cañada",
    "VILLANUEVA DE CA ADA",          "Villanueva de la Cañada",
    "CUBAS",                         "Cubas de la Sagra",
    "MORALEJA DE EN MEDIO",          "Moraleja de Enmedio",
    "MARTIN VALDEIGLESIAS",          "San Martín de Valdeiglesias",
    "FUENTIDUEA DE TAJO",            "Fuentidueña de Tajo",
    "FUENTIDUE A DE TAJO",           "Fuentidueña de Tajo",
    "ORUSCO",                        "Orusco de Tajuña",
    "ORUSCO DE TAJUA",               "Orusco de Tajuña",
    "ORUSCO DE TAJU A",              "Orusco de Tajuña",
    "GARGANTILLA LOZOYA",            "Gargantilla del Lozoya y Pinilla de Buitrago",
    "LOZOYUELA N SIETEIGL",          "Lozoyuela-Navas-Sieteiglesias",
    "PIUECAR",                       "Piñuécar-Gandullas",
    "NAVARREDONDA",                  "Navarredonda y San Mamés",
    "HORCAJO DE LA SIERRA",          "Horcajo de la Sierra-Aoslos",
    "SAN SEBASTIAN DE LOS REY",      "San Sebastián de los Reyes",
    "SAN SEBASTIN DE LOS REY",       "San Sebastián de los Reyes",
    "ALCAL DE HENARES",              "Alcalá de Henares",
    "POZUELO DE ALARCN",             "Pozuelo de Alarcón",
    "MSTOLES",                       "Móstoles",
    "LEGANS",                        "Leganés",
    "TORREJN DE ARDOZ",              "Torrejón de Ardoz",
    "SIETEIGLESIAS",                 "Lozoyuela-Navas-Sieteiglesias",
    "CARABAA",                       "Carabaña",
    "CARABA A",                      "Carabaña"
  ) |>
    dplyr::mutate(
      source_name_std = normalise_municipality_name(
        .data$source_name
      )
    ) |>
    dplyr::distinct(
      .data$source_name_std,
      .keep_all = TRUE
    )
}


# Validate registration data ---------------------------------------------------

validate_territorial_input <- function(data) {

  missing_columns <- setdiff(
    territorial_required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The territorial dataset is missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Load the master registration dataset ----------------------------------------

load_territorial_master_dataset <- function(
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

  validate_territorial_input(data)

  data
}


# Load municipal boundaries ---------------------------------------------------

load_madrid_municipal_boundaries <- function(
    shapefile_path = municipal_shapefile_path
) {

  if (!file.exists(shapefile_path)) {
    stop(
      paste0(
        "The municipal shapefile does not exist: ",
        shapefile_path,
        ". Place the complete shapefile inside data/external/geospatial/."
      ),
      call. = FALSE
    )
  }

  municipal_map <- sf::st_read(
    shapefile_path,
    quiet = TRUE,
    stringsAsFactors = FALSE
  )

  missing_columns <- setdiff(
    municipal_boundary_required_columns,
    names(municipal_map)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The municipal boundary file is missing the following fields: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  municipal_map |>
    dplyr::filter(
      .data$NATLEVNAME == madrid_municipality_level,
      .data$CODNUT3 == madrid_nuts3_code
    ) |>
    sf::st_make_valid() |>
    dplyr::mutate(
      municipality_name = .data$NAMEUNIT,
      municipality_std = normalise_municipality_name(
        .data$NAMEUNIT
      )
    )
}


# Prepare lookup table from the municipal map ----------------------------------

create_municipality_map_lookup <- function(
    municipal_boundaries
) {

  municipal_boundaries |>
    sf::st_drop_geometry() |>
    dplyr::transmute(
      municipality_std = .data$municipality_std,
      municipality_name = .data$municipality_name
    ) |>
    dplyr::distinct(
      .data$municipality_std,
      .keep_all = TRUE
    )
}


# Standardise renting ----------------------------------------------------------

normalise_renting <- function(x) {

  x <- stringr::str_to_upper(
    stringr::str_trim(
      as.character(x)
    )
  )

  dplyr::case_when(
    x %in% c(
      "S",
      "SI",
      "SÍ",
      "1",
      "TRUE"
    ) ~ "Yes",

    x %in% c(
      "N",
      "NO",
      "0",
      "FALSE"
    ) ~ "No",

    TRUE ~ NA_character_
  )
}


# Standardise ownership --------------------------------------------------------

normalise_ownership <- function(x) {

  x <- stringr::str_to_upper(
    stringr::str_trim(
      as.character(x)
    )
  )

  dplyr::case_when(
    x %in% c(
      "D",
      "FISICA",
      "FÍSICA",
      "PERSONA FISICA",
      "PERSONA FÍSICA"
    ) ~ "Individual",

    x %in% c(
      "X",
      "JURIDICA",
      "JURÍDICA",
      "PERSONA JURIDICA",
      "PERSONA JURÍDICA"
    ) ~ "Legal entity",

    TRUE ~ NA_character_
  )
}


# Assign territorial group -----------------------------------------------------

assign_territorial_group <- function(municipality_std) {

  atypical_std <- normalise_municipality_name(
    atypical_municipalities
  )

  business_std <- normalise_municipality_name(
    business_municipalities
  )

  madrid_std <- normalise_municipality_name(
    madrid_city_name
  )

  group <- dplyr::case_when(
    municipality_std == madrid_std ~
      "Madrid city",

    municipality_std %in% atypical_std ~
      "Atypical peripheral municipalities",

    municipality_std %in% business_std ~
      "Metropolitan or business municipalities",

    TRUE ~
      "Remaining municipalities"
  )

  factor(
    group,
    levels = territorial_group_levels
  )
}


# Prepare territorial registration data ---------------------------------------

prepare_territorial_data <- function(
    data,
    municipal_boundaries
) {

  validate_territorial_input(data)

  equivalences <- create_municipality_equivalences()

  map_lookup <- create_municipality_map_lookup(
    municipal_boundaries
  )

  data |>
    dplyr::mutate(
      municipality_source = .data$MUNICIPIO,
      source_name_std = normalise_municipality_name(
        .data$MUNICIPIO
      )
    ) |>
    dplyr::left_join(
      equivalences,
      by = "source_name_std"
    ) |>
    dplyr::mutate(
      municipality_corrected = dplyr::coalesce(
        .data$map_name,
        .data$MUNICIPIO
      ),
      municipality_std = normalise_municipality_name(
        .data$municipality_corrected
      )
    ) |>
    dplyr::left_join(
      map_lookup,
      by = "municipality_std"
    ) |>
    dplyr::mutate(
      municipality_name = dplyr::coalesce(
        .data$municipality_name,
        .data$municipality_corrected,
        .data$MUNICIPIO
      ),
      territorial_group = assign_territorial_group(
        .data$municipality_std
      ),
      renting_status = normalise_renting(
        .data$RENTING
      ),
      ownership_type = normalise_ownership(
        .data$PERSONA_FISICA_JURIDICA
      ),
      registration_year = lubridate::year(
        as.Date(.data$FEC_MATRICULA)
      )
    ) |>
        dplyr::select(
      -dplyr::any_of(
        c(
          "source_name",
          "map_name"
        )
      )
    )
}


# Identify unmatched municipality names ---------------------------------------

identify_unmatched_municipalities <- function(
    territorial_data,
    municipal_boundaries
) {

  map_names <- municipal_boundaries |>
    sf::st_drop_geometry() |>
    dplyr::distinct(
      .data$municipality_std
    )

  territorial_data |>
    dplyr::distinct(
      .data$municipality_source,
      .data$municipality_corrected,
      .data$municipality_std
    ) |>
    dplyr::anti_join(
      map_names,
      by = "municipality_std"
    ) |>
    dplyr::arrange(
      .data$municipality_source
    )
}


# Municipal ranking ------------------------------------------------------------

summarise_municipal_ranking <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::count(
      .data$municipality_std,
      .data$municipality_name,
      name = "registrations"
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$registrations)
    ) |>
    dplyr::mutate(
      position = dplyr::row_number(),
      share_of_total = .data$registrations /
        sum(.data$registrations),
      cumulative_share = cumsum(
        .data$share_of_total
      )
    )
}


# Territorial concentration ---------------------------------------------------

summarise_municipal_concentration <- function(
    municipal_ranking,
    thresholds = c(1L, 5L, 10L, 20L)
) {

  if (nrow(municipal_ranking) == 0L) {
    stop(
      "The municipal ranking is empty.",
      call. = FALSE
    )
  }

  total_registrations <- sum(
    municipal_ranking$registrations
  )

  if (total_registrations <= 0) {
    stop(
      "The total number of registrations must be positive.",
      call. = FALSE
    )
  }

  purrr::map_dfr(
    thresholds,
    function(threshold) {

      available_rows <- min(
        threshold,
        nrow(municipal_ranking)
      )

      threshold_registrations <- sum(
        municipal_ranking$registrations[
          seq_len(available_rows)
        ]
      )

      tibble::tibble(
        threshold = threshold,
        group = paste0(
          "Top ",
          threshold
        ),
        registrations = threshold_registrations,
        share = threshold_registrations /
          total_registrations
      )
    }
  )
}


# Territorial-group summary ---------------------------------------------------

summarise_territorial_groups <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::count(
      .data$territorial_group,
      name = "registrations"
    ) |>
    dplyr::mutate(
      share = .data$registrations /
        sum(.data$registrations)
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$registrations)
    )
}


# Renting summaries ------------------------------------------------------------

summarise_municipal_renting <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::group_by(
      .data$municipality_std,
      .data$municipality_name
    ) |>
    dplyr::summarise(
      registrations = dplyr::n(),
      renting = sum(
        .data$renting_status == "Yes",
        na.rm = TRUE
      ),
      non_renting = sum(
        .data$renting_status == "No",
        na.rm = TRUE
      ),
      missing_renting = sum(
        is.na(.data$renting_status)
      ),
      renting_share = dplyr::if_else(
        .data$renting + .data$non_renting > 0,
        .data$renting /
          (
            .data$renting +
              .data$non_renting
          ),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$registrations)
    )
}


summarise_group_renting <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::group_by(
      .data$territorial_group
    ) |>
    dplyr::summarise(
      registrations = dplyr::n(),
      renting = sum(
        .data$renting_status == "Yes",
        na.rm = TRUE
      ),
      non_renting = sum(
        .data$renting_status == "No",
        na.rm = TRUE
      ),
      missing_renting = sum(
        is.na(.data$renting_status)
      ),
      renting_share = dplyr::if_else(
        .data$renting + .data$non_renting > 0,
        .data$renting /
          (
            .data$renting +
              .data$non_renting
          ),
        NA_real_
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$registrations)
    )
}


# Ownership summaries ----------------------------------------------------------

summarise_group_ownership <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::filter(
      !is.na(.data$ownership_type)
    ) |>
    dplyr::count(
      .data$territorial_group,
      .data$ownership_type,
      name = "registrations"
    ) |>
    dplyr::group_by(
      .data$territorial_group
    ) |>
    dplyr::mutate(
      group_total = sum(.data$registrations),
      share = .data$registrations /
        .data$group_total
    ) |>
    dplyr::ungroup()
}


summarise_municipal_ownership <- function(
    territorial_data
) {

  territorial_data |>
    dplyr::filter(
      !is.na(.data$ownership_type)
    ) |>
    dplyr::count(
      .data$municipality_std,
      .data$municipality_name,
      .data$ownership_type,
      name = "registrations"
    ) |>
    dplyr::group_by(
      .data$municipality_std,
      .data$municipality_name
    ) |>
    dplyr::mutate(
      municipality_total = sum(
        .data$registrations
      ),
      share = .data$registrations /
        .data$municipality_total
    ) |>
    dplyr::ungroup()
}


# Annual evolution of leading municipalities ----------------------------------

summarise_top_municipality_evolution <- function(
    territorial_data,
    municipal_ranking,
    number_of_municipalities = 5L
) {

  top_municipalities <- municipal_ranking |>
    dplyr::slice_max(
      order_by = .data$registrations,
      n = number_of_municipalities,
      with_ties = FALSE
    ) |>
    dplyr::pull(
      .data$municipality_std
    )

  territorial_data |>
    dplyr::filter(
      .data$municipality_std %in%
        top_municipalities,
      !is.na(.data$registration_year)
    ) |>
    dplyr::count(
      .data$registration_year,
      .data$municipality_name,
      name = "registrations"
    ) |>
    dplyr::arrange(
      .data$registration_year,
      .data$municipality_name
    )
}


# Join registration totals to the map -----------------------------------------

create_municipal_registration_map <- function(
    municipal_boundaries,
    municipal_ranking
) {

  municipal_boundaries |>
    dplyr::left_join(
      municipal_ranking |>
        dplyr::select(
          .data$municipality_std,
          .data$registrations
        ),
      by = "municipality_std"
    ) |>
    dplyr::mutate(
      registrations = dplyr::coalesce(
        .data$registrations,
        0L
      ),
      registration_category = cut(
        .data$registrations,
        breaks = municipality_count_breaks,
        labels = municipality_count_labels,
        include.lowest = TRUE
      ),
      registration_category = factor(
        .data$registration_category,
        levels = municipality_count_labels
      ),
      territorial_group = assign_territorial_group(
        .data$municipality_std
      )
    )
}


# Visualisations ---------------------------------------------------------------

plot_municipal_registration_map <- function(
    map_data
) {

  ggplot2::ggplot(map_data) +
    ggplot2::geom_sf(
      ggplot2::aes(
        fill = .data$registration_category
      ),
      colour = "white",
      linewidth = 0.2
    ) +
    ggplot2::scale_fill_brewer(
      palette = "Reds",
      na.value = "grey90",
      drop = FALSE,
      name = "Registrations"
    ) +
    ggplot2::labs(
      title = "Passenger car registrations by municipality",
      subtitle = "Community of Madrid, 2015–2025",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      legend.position = "right",
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )
}


plot_territorial_group_map <- function(
    map_data
) {

  ggplot2::ggplot(map_data) +
    ggplot2::geom_sf(
      ggplot2::aes(
        fill = .data$territorial_group
      ),
      colour = "white",
      linewidth = 0.2
    ) +
    ggplot2::labs(
      title = "Analytical territorial classification",
      subtitle = "Madrid city, business municipalities and atypical peripheral municipalities",
      fill = "Territorial group",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      legend.position = "right",
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )
}


plot_municipal_ranking <- function(
    municipal_ranking,
    number_of_municipalities = 20L
) {

  plot_data <- municipal_ranking |>
    dplyr::slice_max(
      order_by = .data$registrations,
      n = number_of_municipalities,
      with_ties = FALSE
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = stats::reorder(
        .data$municipality_name,
        .data$registrations
      ),
      y = .data$registrations
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Municipal registration ranking",
      subtitle = paste(
        number_of_municipalities,
        "municipalities with the highest registration volume"
      ),
      x = NULL,
      y = "Registrations",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_concentration_curve <- function(
    municipal_ranking
) {

  ggplot2::ggplot(
    municipal_ranking,
    ggplot2::aes(
      x = .data$position,
      y = .data$cumulative_share
    )
  ) +
    ggplot2::geom_line(
      linewidth = 1
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent()
    ) +
    ggplot2::labs(
      title = "Municipal concentration curve",
      subtitle = "Cumulative share of registrations by municipal rank",
      x = "Municipal ranking position",
      y = "Cumulative share",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_group_renting <- function(
    group_renting
) {

  ggplot2::ggplot(
    group_renting,
    ggplot2::aes(
      x = stats::reorder(
        .data$territorial_group,
        .data$renting_share
      ),
      y = .data$renting_share
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent()
    ) +
    ggplot2::labs(
      title = "Renting share by territorial group",
      x = NULL,
      y = "Renting share",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_group_ownership <- function(
    group_ownership
) {

  ggplot2::ggplot(
    group_ownership,
    ggplot2::aes(
      x = .data$territorial_group,
      y = .data$share,
      fill = .data$ownership_type
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent()
    ) +
    ggplot2::labs(
      title = "Ownership type by territorial group",
      x = NULL,
      y = "Share",
      fill = "Ownership",
      caption = "Source: Spanish Directorate-General for Traffic"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_top_municipality_evolution <- function(
    evolution_data
) {

  ggplot2::ggplot(
    evolution_data,
    ggplot2::aes(
      x = .data$registration_year,
      y = .data$registrations,
      colour = .data$municipality_name,
      group = .data$municipality_name
    )
  ) +
    ggplot2::geom_line(
      linewidth = 1
    ) +
    ggplot2::geom_point(
      size = 1.5
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::scale_x_continuous(
      breaks = analysis_start_year:analysis_end_year
    ) +
    ggplot2::labs(
      title = "Evolution of the leading municipalities",
      subtitle = "Five municipalities with the highest total registration volume",
      x = "Registration year",
      y = "Registrations",
      colour = "Municipality",
      caption = "Source: Spanish Directorate-General for Traffic"
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


# Run the complete territorial workflow ---------------------------------------

run_territorial_analysis <- function(
    data = load_territorial_master_dataset(),
    shapefile_path = municipal_shapefile_path
) {

  municipal_boundaries <- load_madrid_municipal_boundaries(
    shapefile_path
  )

  territorial_data <- prepare_territorial_data(
    data,
    municipal_boundaries
  )

  unmatched_municipalities <- identify_unmatched_municipalities(
    territorial_data,
    municipal_boundaries
  )

  if (nrow(unmatched_municipalities) > 0L) {
    warning(
      nrow(unmatched_municipalities),
      " municipality name(s) could not be matched to the map.",
      call. = FALSE
    )
  }

  municipal_ranking <- summarise_municipal_ranking(
    territorial_data
  )

  municipal_concentration <- summarise_municipal_concentration(
    municipal_ranking
  )

  territorial_groups <- summarise_territorial_groups(
    territorial_data
  )

  municipal_renting <- summarise_municipal_renting(
    territorial_data
  )

  group_renting <- summarise_group_renting(
    territorial_data
  )

  group_ownership <- summarise_group_ownership(
    territorial_data
  )

  municipal_ownership <- summarise_municipal_ownership(
    territorial_data
  )

  top_municipality_evolution <- summarise_top_municipality_evolution(
    territorial_data,
    municipal_ranking
  )

  municipal_map <- create_municipal_registration_map(
    municipal_boundaries,
    municipal_ranking
  )

  list(
    data = territorial_data,
    geography = list(
      municipal_boundaries = municipal_boundaries,
      municipal_map = municipal_map
    ),
    tables = list(
      unmatched_municipalities = unmatched_municipalities,
      municipal_ranking = municipal_ranking,
      municipal_concentration = municipal_concentration,
      territorial_groups = territorial_groups,
      municipal_renting = municipal_renting,
      group_renting = group_renting,
      group_ownership = group_ownership,
      municipal_ownership = municipal_ownership,
      top_municipality_evolution = top_municipality_evolution
    ),
    figures = list(
      municipal_map = plot_municipal_registration_map(
        municipal_map
      ),
      territorial_group_map = plot_territorial_group_map(
        municipal_map
      ),
      municipal_ranking = plot_municipal_ranking(
        municipal_ranking
      ),
      concentration_curve = plot_concentration_curve(
        municipal_ranking
      ),
      group_renting = plot_group_renting(
        group_renting
      ),
      group_ownership = plot_group_ownership(
        group_ownership
      ),
      top_municipality_evolution = plot_top_municipality_evolution(
        top_municipality_evolution
      )
    )
  )
}


# Usage example ----------------------------------------------------------------

# territorial_results <- run_territorial_analysis()
#
# territorial_results$tables$municipal_ranking
# territorial_results$tables$municipal_concentration
# territorial_results$tables$group_renting
# territorial_results$tables$group_ownership
#
# territorial_results$figures$municipal_map
# territorial_results$figures$territorial_group_map
# territorial_results$figures$municipal_ranking
# territorial_results$figures$concentration_curve