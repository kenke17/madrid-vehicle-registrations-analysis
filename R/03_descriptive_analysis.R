# =============================================================================
# Descriptive analysis
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("path_data_processed", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}


# Required columns -------------------------------------------------------------

descriptive_required_columns <- c(
  "FEC_MATRICULA",
  "COD_PROPULSION_ITV",
  "CATEGORIA_VEHICULO_ELECTRICO",
  "KW_ITV",
  "CILINDRADA_ITV",
  "CO2_ITV"
)

descriptive_propulsion_levels <- c(
  "Petrol",
  "Diesel",
  "Hybrid",
  "Electric"
)


# Load the master dataset ------------------------------------------------------

load_master_dataset <- function(
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


# Validate the descriptive-analysis input -------------------------------------

validate_descriptive_input <- function(data) {

  missing_columns <- setdiff(
    descriptive_required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The descriptive dataset is missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  if (nrow(data) != expected_master_observations) {
    warning(
      "Expected ",
      expected_master_observations,
      " observations but obtained ",
      nrow(data),
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Recode propulsion for the descriptive analysis ------------------------------

derive_descriptive_propulsion <- function(
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

  # This order reproduces the final descriptive results of the thesis.
  propulsion_type <- dplyr::case_when(
    propulsion_code == propulsion_code_electric ~ "Electric",
    electric_vehicle_category %in% hybrid_vehicle_categories ~ "Hybrid",
    propulsion_code == propulsion_code_petrol ~ "Petrol",
    propulsion_code == propulsion_code_diesel ~ "Diesel",
    TRUE ~ NA_character_
  )

  factor(
    propulsion_type,
    levels = descriptive_propulsion_levels
  )
}


# Prepare the common descriptive dataset --------------------------------------

prepare_descriptive_data <- function(data) {

  validate_descriptive_input(data)

  prepared_data <- data |>
    dplyr::mutate(
      FEC_MATRICULA = as.Date(.data$FEC_MATRICULA),
      registration_month = lubridate::floor_date(
        .data$FEC_MATRICULA,
        unit = "month"
      ),
      registration_year = lubridate::year(
        .data$FEC_MATRICULA
      ),
      propulsion_type = derive_descriptive_propulsion(
        .data$COD_PROPULSION_ITV,
        .data$CATEGORIA_VEHICULO_ELECTRICO
      ),
      KW_ITV = suppressWarnings(
        as.numeric(.data$KW_ITV)
      ),
      CILINDRADA_ITV = suppressWarnings(
        as.numeric(.data$CILINDRADA_ITV)
      ),
      CO2_ITV = suppressWarnings(
        as.numeric(.data$CO2_ITV)
      )
    ) |>
    dplyr::filter(
      !is.na(.data$FEC_MATRICULA),
      .data$FEC_MATRICULA >= analysis_start_date,
      .data$FEC_MATRICULA <= analysis_end_date
    )

  prepared_data
}


# Monthly and annual registration totals --------------------------------------

summarise_monthly_registrations <- function(data) {

  data |>
    dplyr::count(
      .data$registration_month,
      name = "registrations"
    ) |>
    tidyr::complete(
      registration_month = seq.Date(
        from = analysis_start_date,
        to = analysis_end_date,
        by = "month"
      ),
      fill = list(
        registrations = 0L
      )
    ) |>
    dplyr::arrange(
      .data$registration_month
    )
}


summarise_annual_registrations <- function(data) {

  data |>
    dplyr::count(
      .data$registration_year,
      name = "registrations"
    ) |>
    tidyr::complete(
      registration_year = analysis_start_year:analysis_end_year,
      fill = list(
        registrations = 0L
      )
    ) |>
    dplyr::arrange(
      .data$registration_year
    ) |>
    dplyr::mutate(
      share_of_total = 100 * .data$registrations /
        sum(.data$registrations),
      annual_change = .data$registrations -
        dplyr::lag(.data$registrations),
      annual_change_pct = 100 * (
        .data$registrations /
          dplyr::lag(.data$registrations) -
          1
      )
    )
}


# Propulsion summaries ---------------------------------------------------------

summarise_monthly_propulsion <- function(data) {

  data |>
    dplyr::filter(
      !is.na(.data$propulsion_type)
    ) |>
    dplyr::mutate(
      propulsion_type = as.character(
        .data$propulsion_type
      )
    ) |>
    dplyr::count(
      .data$registration_month,
      .data$propulsion_type,
      name = "registrations"
    ) |>
    tidyr::complete(
      registration_month = seq.Date(
        from = analysis_start_date,
        to = analysis_end_date,
        by = "month"
      ),
      propulsion_type = descriptive_propulsion_levels,
      fill = list(
        registrations = 0L
      )
    ) |>
    dplyr::group_by(
      .data$registration_month
    ) |>
    dplyr::mutate(
      monthly_total = sum(.data$registrations),
      monthly_share = dplyr::if_else(
        .data$monthly_total > 0,
        100 * .data$registrations /
          .data$monthly_total,
        NA_real_
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      propulsion_type = factor(
        .data$propulsion_type,
        levels = descriptive_propulsion_levels
      )
    ) |>
    dplyr::arrange(
      .data$registration_month,
      .data$propulsion_type
    )
}


summarise_annual_propulsion <- function(data) {

  data |>
    dplyr::filter(
      !is.na(.data$propulsion_type)
    ) |>
    dplyr::mutate(
      propulsion_type = as.character(
        .data$propulsion_type
      )
    ) |>
    dplyr::count(
      .data$registration_year,
      .data$propulsion_type,
      name = "registrations"
    ) |>
    tidyr::complete(
      registration_year = analysis_start_year:analysis_end_year,
      propulsion_type = descriptive_propulsion_levels,
      fill = list(
        registrations = 0L
      )
    ) |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::mutate(
      annual_total = sum(.data$registrations),
      annual_share = 100 * .data$registrations /
        .data$annual_total
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      propulsion_type = factor(
        .data$propulsion_type,
        levels = descriptive_propulsion_levels
      )
    ) |>
    dplyr::arrange(
      .data$registration_year,
      .data$propulsion_type
    )
}


# Technical-data preparation ---------------------------------------------------

prepare_technical_data <- function(data) {

  data |>
    dplyr::mutate(
      CO2_ITV = dplyr::if_else(
        .data$CO2_ITV == 999,
        NA_real_,
        .data$CO2_ITV
      )
    ) |>
    dplyr::filter(
      !is.na(.data$CILINDRADA_ITV),
      .data$CILINDRADA_ITV >= 50,
      .data$CILINDRADA_ITV <= 6000,
      is.na(.data$CO2_ITV) |
        .data$CO2_ITV <= 500
    )
}


# Annual power summary ---------------------------------------------------------

summarise_annual_power <- function(
    data,
    technical_data = prepare_technical_data(data)
) {

  central_statistics <- technical_data |>
    dplyr::filter(
      !is.na(.data$KW_ITV),
      .data$KW_ITV > 0
    ) |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      mean_kw = mean(.data$KW_ITV),
      median_kw = stats::median(.data$KW_ITV),
      .groups = "drop"
    )

  distribution_statistics <- data |>
    dplyr::filter(
      !is.na(.data$KW_ITV),
      .data$KW_ITV > 0
    ) |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::summarise(
      p10_kw = as.numeric(
        stats::quantile(.data$KW_ITV, 0.10)
      ),
      p25_kw = as.numeric(
        stats::quantile(.data$KW_ITV, 0.25)
      ),
      p75_kw = as.numeric(
        stats::quantile(.data$KW_ITV, 0.75)
      ),
      p90_kw = as.numeric(
        stats::quantile(.data$KW_ITV, 0.90)
      ),
      .groups = "drop"
    )

  dplyr::left_join(
    central_statistics,
    distribution_statistics,
    by = "registration_year"
  )
}


# Annual engine-displacement summary ------------------------------------------

summarise_annual_displacement <- function(
    data,
    technical_data = prepare_technical_data(data)
) {

  central_statistics <- technical_data |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      mean_displacement_cc = mean(
        .data$CILINDRADA_ITV
      ),
      median_displacement_cc = stats::median(
        .data$CILINDRADA_ITV
      ),
      .groups = "drop"
    )

  distribution_statistics <- data |>
    dplyr::filter(
      !is.na(.data$CILINDRADA_ITV)
    ) |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::summarise(
      p10_displacement_cc = as.numeric(
        stats::quantile(
          .data$CILINDRADA_ITV,
          0.10
        )
      ),
      p25_displacement_cc = as.numeric(
        stats::quantile(
          .data$CILINDRADA_ITV,
          0.25
        )
      ),
      p75_displacement_cc = as.numeric(
        stats::quantile(
          .data$CILINDRADA_ITV,
          0.75
        )
      ),
      p90_displacement_cc = as.numeric(
        stats::quantile(
          .data$CILINDRADA_ITV,
          0.90
        )
      ),
      .groups = "drop"
    )

  dplyr::left_join(
    central_statistics,
    distribution_statistics,
    by = "registration_year"
  )
}


# Annual CO2 summary -----------------------------------------------------------

summarise_annual_co2 <- function(
    technical_data
) {

  technical_data |>
    dplyr::filter(
      !is.na(.data$CO2_ITV)
    ) |>
    dplyr::group_by(
      .data$registration_year
    ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      mean_co2_g_km = mean(.data$CO2_ITV),
      median_co2_g_km = stats::median(
        .data$CO2_ITV
      ),
      .groups = "drop"
    )
}


# Monthly technical summaries -------------------------------------------------

summarise_monthly_power <- function(
    technical_data
) {

  technical_data |>
    dplyr::filter(
      !is.na(.data$KW_ITV),
      .data$KW_ITV > 0
    ) |>
    dplyr::group_by(
      .data$registration_month
    ) |>
    dplyr::summarise(
      mean_value = mean(.data$KW_ITV),
      median_value = stats::median(
        .data$KW_ITV
      ),
      .groups = "drop"
    )
}


summarise_monthly_displacement <- function(
    technical_data
) {

  technical_data |>
    dplyr::group_by(
      .data$registration_month
    ) |>
    dplyr::summarise(
      mean_value = mean(
        .data$CILINDRADA_ITV
      ),
      median_value = stats::median(
        .data$CILINDRADA_ITV
      ),
      .groups = "drop"
    )
}


summarise_monthly_co2 <- function(
    technical_data
) {

  technical_data |>
    dplyr::filter(
      !is.na(.data$CO2_ITV)
    ) |>
    dplyr::group_by(
      .data$registration_month
    ) |>
    dplyr::summarise(
      mean_value = mean(.data$CO2_ITV),
      median_value = stats::median(
        .data$CO2_ITV
      ),
      .groups = "drop"
    )
}


# Visualisations ---------------------------------------------------------------

plot_monthly_registrations <- function(
    monthly_data
) {

  ggplot2::ggplot(
    monthly_data,
    ggplot2::aes(
      x = .data$registration_month,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.8
    ) +
    ggplot2::labs(
      title = "Monthly passenger car registrations",
      subtitle = "Community of Madrid, 2015–2025",
      x = NULL,
      y = "Registrations"
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )
}


plot_monthly_propulsion_counts <- function(
    propulsion_data
) {

  ggplot2::ggplot(
    propulsion_data,
    ggplot2::aes(
      x = .data$registration_month,
      y = .data$registrations,
      colour = .data$propulsion_type
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.8
    ) +
    ggplot2::labs(
      title = "Registrations by propulsion technology",
      subtitle = "Monthly absolute frequencies",
      x = NULL,
      y = "Registrations",
      colour = "Propulsion"
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      legend.position = "bottom"
    )
}


plot_monthly_propulsion_share <- function(
    propulsion_data
) {

  ggplot2::ggplot(
    propulsion_data,
    ggplot2::aes(
      x = .data$registration_month,
      y = .data$monthly_share,
      fill = .data$propulsion_type
    )
  ) +
    ggplot2::geom_col(
      width = 25
    ) +
    ggplot2::labs(
      title = "Monthly market composition",
      subtitle = "Share by propulsion technology",
      x = NULL,
      y = "Share",
      fill = "Propulsion"
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 100),
      labels = scales::label_percent(
        scale = 1
      ),
      expand = c(0, 0)
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      legend.position = "bottom"
    )
}


plot_technical_evolution <- function(
    monthly_data,
    title,
    y_label
) {

  plot_data <- monthly_data |>
    tidyr::pivot_longer(
      cols = c(
        "mean_value",
        "median_value"
      ),
      names_to = "statistic",
      values_to = "value"
    ) |>
    dplyr::mutate(
      statistic = dplyr::recode(
        .data$statistic,
        mean_value = "Mean",
        median_value = "Median"
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$registration_month,
      y = .data$value,
      linetype = .data$statistic
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.8
    ) +
    ggplot2::labs(
      title = title,
      subtitle = "Monthly mean and median",
      x = NULL,
      y = y_label,
      linetype = "Statistic"
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      legend.position = "bottom"
    )
}


# Run the complete descriptive workflow ---------------------------------------

run_descriptive_analysis <- function(
    data = load_master_dataset()
) {

  descriptive_data <- prepare_descriptive_data(
    data
  )

  technical_data <- prepare_technical_data(
    descriptive_data
  )

  monthly_registrations <- summarise_monthly_registrations(
    descriptive_data
  )

  annual_registrations <- summarise_annual_registrations(
    descriptive_data
  )

  monthly_propulsion <- summarise_monthly_propulsion(
    descriptive_data
  )

  annual_propulsion <- summarise_annual_propulsion(
    descriptive_data
  )

  annual_power <- summarise_annual_power(
    descriptive_data,
    technical_data
  )

  annual_displacement <- summarise_annual_displacement(
    descriptive_data,
    technical_data
  )

  annual_co2 <- summarise_annual_co2(
    technical_data
  )

  monthly_power <- summarise_monthly_power(
    technical_data
  )

  monthly_displacement <- summarise_monthly_displacement(
    technical_data
  )

  monthly_co2 <- summarise_monthly_co2(
    technical_data
  )

  list(
    data = descriptive_data,
    technical_data = technical_data,
    tables = list(
      monthly_registrations = monthly_registrations,
      annual_registrations = annual_registrations,
      monthly_propulsion = monthly_propulsion,
      annual_propulsion = annual_propulsion,
      annual_power = annual_power,
      annual_displacement = annual_displacement,
      annual_co2 = annual_co2
    ),
    figures = list(
      monthly_registrations = plot_monthly_registrations(
        monthly_registrations
      ),
      propulsion_counts = plot_monthly_propulsion_counts(
        monthly_propulsion
      ),
      propulsion_share = plot_monthly_propulsion_share(
        monthly_propulsion
      ),
      power = plot_technical_evolution(
        monthly_power,
        title = "Evolution of vehicle power",
        y_label = "Power (kW)"
      ),
      displacement = plot_technical_evolution(
        monthly_displacement,
        title = "Evolution of engine displacement",
        y_label = "Engine displacement (cc)"
      ),
      co2 = plot_technical_evolution(
        monthly_co2,
        title = "Evolution of reported CO2 emissions",
        y_label = "CO2 emissions (g/km)"
      )
    )
  )
}


# Usage example ----------------------------------------------------------------

# descriptive_results <- run_descriptive_analysis()
#
# descriptive_results$tables$annual_registrations
# descriptive_results$tables$annual_propulsion
# descriptive_results$tables$annual_power
# descriptive_results$tables$annual_displacement
# descriptive_results$tables$annual_co2
#
# descriptive_results$figures$monthly_registrations
# descriptive_results$figures$propulsion_counts
# descriptive_results$figures$propulsion_share
# descriptive_results$figures$power
# descriptive_results$figures$displacement
# descriptive_results$figures$co2