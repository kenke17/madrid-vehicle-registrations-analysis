# =============================================================================
# Monthly time-series analysis
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Load project configuration ---------------------------------------------------

if (!exists("time_series_frequency", inherits = TRUE)) {
  source(
    here::here("R", "00_configuration.R")
  )
}

check_project_packages("core")


# Required variables -----------------------------------------------------------

time_series_required_columns <- c(
  "FEC_MATRICULA"
)

analysis_period_levels <- c(
  "Pre-2020",
  "Disruption and initial recovery",
  "Subsequent recovery"
)


# Load the master dataset ------------------------------------------------------

load_time_series_master_dataset <- function(
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


# Validate the input -----------------------------------------------------------

validate_time_series_input <- function(data) {

  missing_columns <- setdiff(
    time_series_required_columns,
    names(data)
  )

  if (length(missing_columns) > 0L) {
    stop(
      "The time-series dataset is missing the following columns: ",
      paste(
        missing_columns,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# Build the complete monthly series --------------------------------------------

prepare_monthly_registration_series <- function(data) {

  validate_time_series_input(data)

  first_month <- lubridate::floor_date(
    analysis_start_date,
    unit = "month"
  )

  last_month <- lubridate::floor_date(
    analysis_end_date,
    unit = "month"
  )

  monthly_series <- data |>
    dplyr::mutate(
      FEC_MATRICULA = as.Date(
        .data$FEC_MATRICULA
      ),
      month = lubridate::floor_date(
        .data$FEC_MATRICULA,
        unit = "month"
      )
    ) |>
    dplyr::filter(
      !is.na(.data$month),
      .data$month >= first_month,
      .data$month <= last_month
    ) |>
    dplyr::count(
      .data$month,
      name = "registrations"
    ) |>
    tidyr::complete(
      month = seq.Date(
        from = first_month,
        to = last_month,
        by = "month"
      ),
      fill = list(
        registrations = 0L
      )
    ) |>
    dplyr::arrange(
      .data$month
    ) |>
    dplyr::mutate(
      year = lubridate::year(
        .data$month
      ),
      month_number = lubridate::month(
        .data$month
      ),
      month_name = factor(
        .data$month_number,
        levels = 1:12,
        labels = month.name,
        ordered = TRUE
      )
    )

  monthly_series
}


# Validate the monthly series --------------------------------------------------

validate_monthly_registration_series <- function(
    monthly_series,
    check_expected_total = TRUE
) {

  observed_months <- nrow(
    monthly_series
  )

  observed_total <- sum(
    monthly_series$registrations
  )

  first_observed_month <- min(
    monthly_series$month
  )

  last_observed_month <- max(
    monthly_series$month
  )

  if (
    observed_months !=
      expected_number_of_months
  ) {
    warning(
      "Expected ",
      expected_number_of_months,
      " months but obtained ",
      observed_months,
      ".",
      call. = FALSE
    )
  }

  if (
    isTRUE(check_expected_total) &&
      observed_total !=
        expected_master_observations
  ) {
    warning(
      "Expected ",
      expected_master_observations,
      " registrations but obtained ",
      observed_total,
      ".",
      call. = FALSE
    )
  }

  tibble::tibble(
    observed_months = observed_months,
    expected_months =
      expected_number_of_months,
    observed_registrations =
      observed_total,
    expected_registrations =
      expected_master_observations,
    first_month =
      first_observed_month,
    last_month =
      last_observed_month,
    missing_calendar_months = sum(
      monthly_series$registrations == 0L
    )
  )
}


# Annual summary ---------------------------------------------------------------

summarise_annual_time_series <- function(
    monthly_series
) {

  monthly_series |>
    dplyr::group_by(
      .data$year
    ) |>
    dplyr::summarise(
      registrations = sum(
        .data$registrations
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$year
    ) |>
    dplyr::mutate(
      absolute_change =
        .data$registrations -
        dplyr::lag(
          .data$registrations
        ),
      percentage_change = 100 * (
        .data$registrations /
          dplyr::lag(
            .data$registrations
          ) -
          1
      )
    )
}


# Summary by analytical period ------------------------------------------------

summarise_time_series_periods <- function(
    monthly_series
) {

  monthly_series |>
    dplyr::mutate(
      analysis_period = dplyr::case_when(
        .data$year <= 2019 ~
          "Pre-2020",

        .data$year %in% c(
          2020,
          2021
        ) ~
          "Disruption and initial recovery",

        .data$year >= 2022 ~
          "Subsequent recovery",

        TRUE ~ NA_character_
      ),
      analysis_period = factor(
        .data$analysis_period,
        levels = analysis_period_levels
      )
    ) |>
    dplyr::group_by(
      .data$analysis_period
    ) |>
    dplyr::summarise(
      months = dplyr::n(),
      mean_monthly_registrations = mean(
        .data$registrations
      ),
      median_monthly_registrations =
        stats::median(
          .data$registrations
        ),
      minimum_monthly_registrations = min(
        .data$registrations
      ),
      maximum_monthly_registrations = max(
        .data$registrations
      ),
      .groups = "drop"
    )
}


# Monthly seasonality summary -------------------------------------------------

summarise_monthly_seasonality <- function(
    monthly_series
) {

  monthly_series |>
    dplyr::group_by(
      .data$month_name
    ) |>
    dplyr::summarise(
      mean_registrations = mean(
        .data$registrations
      ),
      median_registrations =
        stats::median(
          .data$registrations
        ),
      minimum_registrations = min(
        .data$registrations
      ),
      maximum_registrations = max(
        .data$registrations
      ),
      .groups = "drop"
    )
}


# Create the regular R time-series object -------------------------------------

create_registration_ts <- function(
    monthly_series
) {

  if (
    nrow(monthly_series) !=
      expected_number_of_months
  ) {
    stop(
      "The monthly series must contain exactly ",
      expected_number_of_months,
      " observations.",
      call. = FALSE
    )
  }

  stats::ts(
    monthly_series$registrations,
    start = c(
      analysis_start_year,
      1
    ),
    frequency =
      time_series_frequency
  )
}


# STL decomposition ------------------------------------------------------------

decompose_registration_series <- function(
    registration_ts
) {

  stats::stl(
    registration_ts,
    s.window =
      stl_seasonal_window
  )
}


# Extract STL components -------------------------------------------------------

extract_stl_components <- function(
    stl_model,
    monthly_series
) {

  time_series_matrix <-
    stl_model$time.series

  tibble::tibble(
    month =
      monthly_series$month,
    observed = as.numeric(
      monthly_series$registrations
    ),
    trend = as.numeric(
      time_series_matrix[, "trend"]
    ),
    seasonal = as.numeric(
      time_series_matrix[, "seasonal"]
    ),
    remainder = as.numeric(
      time_series_matrix[, "remainder"]
    )
  )
}


# Final summary indicators -----------------------------------------------------

create_time_series_indicators <- function(
    monthly_series
) {

  minimum_position <- which.min(
    monthly_series$registrations
  )

  maximum_position <- which.max(
    monthly_series$registrations
  )

  tibble::tibble(
    total_registrations = sum(
      monthly_series$registrations
    ),
    mean_monthly_registrations = mean(
      monthly_series$registrations
    ),
    median_monthly_registrations =
      stats::median(
        monthly_series$registrations
      ),
    minimum_month =
      monthly_series$month[
        minimum_position
      ],
    minimum_registrations =
      monthly_series$registrations[
        minimum_position
      ],
    maximum_month =
      monthly_series$month[
        maximum_position
      ],
    maximum_registrations =
      monthly_series$registrations[
        maximum_position
      ]
  )
}


# Visualisations ---------------------------------------------------------------

plot_monthly_time_series <- function(
    monthly_series
) {

  maximum_value <- max(
    monthly_series$registrations
  )

  ggplot2::ggplot(
    monthly_series,
    ggplot2::aes(
      x = .data$month,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.7
    ) +
    ggplot2::geom_vline(
      xintercept =
        covid_break_date,
      linetype = "dashed",
      linewidth = 0.7
    ) +
    ggplot2::annotate(
      "text",
      x = covid_break_date,
      y = maximum_value,
      label = "COVID-19",
      hjust = -0.1,
      vjust = 1,
      size = 3.5
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
      subtitle = "Community of Madrid, 2015–2025",
      x = NULL,
      y = "Registrations"
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


plot_smoothed_time_series <- function(
    monthly_series
) {

  ggplot2::ggplot(
    monthly_series,
    ggplot2::aes(
      x = .data$month,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_line(
      alpha = 0.45,
      linewidth = 0.6
    ) +
    ggplot2::geom_smooth(
      method = "loess",
      se = FALSE,
      span = time_series_loess_span,
      linewidth = 1
    ) +
    ggplot2::geom_vline(
      xintercept =
        covid_break_date,
      linetype = "dashed",
      linewidth = 0.7
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Smoothed registration trend",
      subtitle = "Monthly series with LOESS smoothing",
      x = NULL,
      y = "Registrations"
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


plot_annual_time_series <- function(
    annual_series
) {

  ggplot2::ggplot(
    annual_series,
    ggplot2::aes(
      x = factor(.data$year),
      y = .data$registrations
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::geom_text(
      ggplot2::aes(
        label = scales::label_comma()(
          .data$registrations
        )
      ),
      vjust = -0.3,
      size = 3
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
      x = "Year",
      y = "Registrations"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    )
}


plot_monthly_seasonality <- function(
    monthly_series
) {

  ggplot2::ggplot(
    monthly_series,
    ggplot2::aes(
      x = .data$month_name,
      y = .data$registrations
    )
  ) +
    ggplot2::geom_boxplot() +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Monthly seasonality",
      subtitle = "Distribution by calendar month, 2015–2025",
      x = "Month",
      y = "Registrations"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      )
    )
}


plot_stl_trend <- function(
    stl_components
) {

  ggplot2::ggplot(
    stl_components,
    ggplot2::aes(
      x = .data$month
    )
  ) +
    ggplot2::geom_line(
      ggplot2::aes(
        y = .data$observed
      ),
      alpha = 0.4,
      linewidth = 0.6
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        y = .data$trend
      ),
      linewidth = 1
    ) +
    ggplot2::geom_vline(
      xintercept =
        covid_break_date,
      linetype = "dashed",
      linewidth = 0.7
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "Observed series and STL trend",
      subtitle = "Monthly passenger car registrations",
      x = NULL,
      y = "Registrations"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      )
    )
}


plot_stl_components <- function(
    stl_components
) {

  plot_data <- stl_components |>
    tidyr::pivot_longer(
      cols = c(
        "observed",
        "trend",
        "seasonal",
        "remainder"
      ),
      names_to = "component",
      values_to = "value"
    ) |>
    dplyr::mutate(
      component = dplyr::recode(
        .data$component,
        observed = "Observed series",
        trend = "Trend",
        seasonal = "Seasonal component",
        remainder = "Irregular component"
      ),
      component = factor(
        .data$component,
        levels = c(
          "Observed series",
          "Trend",
          "Seasonal component",
          "Irregular component"
        )
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$month,
      y = .data$value
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.6
    ) +
    ggplot2::facet_wrap(
      ~ component,
      scales = "free_y",
      ncol = 1
    ) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y"
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_comma()
    ) +
    ggplot2::labs(
      title = "STL decomposition",
      subtitle = "Observed series, trend, seasonality and irregular component",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      )
    )
}


# Save compact outputs ---------------------------------------------------------

save_time_series_results <- function(
    results,
    output_path = file.path(
      path_data_processed,
      time_series_results_filename
    )
) {

  compact_results <- list(
    parameters = list(
      start_date =
        analysis_start_date,
      end_date =
        analysis_end_date,
      frequency =
        time_series_frequency,
      covid_break_date =
        covid_break_date,
      stl_seasonal_window =
        stl_seasonal_window
    ),
    validation =
      results$validation,
    monthly_series =
      results$monthly_series,
    stl_components =
      results$stl_components,
    tables =
      results$tables
  )

  saveRDS(
    compact_results,
    output_path
  )

  message(
    "Time-series results saved to: ",
    output_path
  )

  invisible(output_path)
}


# Run the complete workflow ----------------------------------------------------

run_time_series_analysis <- function(
    data =
      load_time_series_master_dataset(),
    save_output = TRUE,
    check_expected_total = TRUE
) {

  monthly_series <-
    prepare_monthly_registration_series(
      data
    )

  validation <-
    validate_monthly_registration_series(
      monthly_series,
      check_expected_total =
        check_expected_total
    )

  annual_series <-
    summarise_annual_time_series(
      monthly_series
    )

  period_summary <-
    summarise_time_series_periods(
      monthly_series
    )

  seasonality_summary <-
    summarise_monthly_seasonality(
      monthly_series
    )

  registration_ts <-
    create_registration_ts(
      monthly_series
    )

  stl_model <-
    decompose_registration_series(
      registration_ts
    )

  stl_components <-
    extract_stl_components(
      stl_model,
      monthly_series
    )

  indicators <-
    create_time_series_indicators(
      monthly_series
    )

  results <- list(
    monthly_series =
      monthly_series,
    registration_ts =
      registration_ts,
    stl_model =
      stl_model,
    stl_components =
      stl_components,
    validation =
      validation,
    tables = list(
      annual_series =
        annual_series,
      period_summary =
        period_summary,
      seasonality_summary =
        seasonality_summary,
      indicators =
        indicators
    ),
    figures = list(
      monthly_series =
        plot_monthly_time_series(
          monthly_series
        ),
      smoothed_series =
        plot_smoothed_time_series(
          monthly_series
        ),
      annual_series =
        plot_annual_time_series(
          annual_series
        ),
      monthly_seasonality =
        plot_monthly_seasonality(
          monthly_series
        ),
      stl_trend =
        plot_stl_trend(
          stl_components
        ),
      stl_components =
        plot_stl_components(
          stl_components
        )
    )
  )

  if (isTRUE(save_output)) {
    save_time_series_results(
      results
    )
  }

  results
}


# Usage example ----------------------------------------------------------------

# time_series_results <- run_time_series_analysis(
#   save_output = TRUE
# )
#
# time_series_results$validation
# time_series_results$tables$annual_series
# time_series_results$tables$period_summary
# time_series_results$tables$seasonality_summary
# time_series_results$tables$indicators
#
# time_series_results$figures$monthly_series
# time_series_results$figures$smoothed_series
# time_series_results$figures$annual_series
# time_series_results$figures$monthly_seasonality
# time_series_results$figures$stl_trend
# time_series_results$figures$stl_components