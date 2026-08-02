# =============================================================================
# Project execution controller
# Passenger Car Registrations in the Community of Madrid
# Author: Miguel Moscardó
# =============================================================================


# Private execution environment ------------------------------------------------

.project_runner_environment <- new.env(
  parent = globalenv()
)

configuration_file <- file.path(
  "R",
  "00_configuration.R"
)

if (!file.exists(configuration_file)) {
  stop(
    "The project configuration file could not be found: ",
    configuration_file,
    call. = FALSE
  )
}

sys.source(
  configuration_file,
  envir = .project_runner_environment
)


# Available analytical stages -------------------------------------------------

project_stage_registry <- list(
  descriptive = list(
    order = 1L,
    script = "03_descriptive_analysis.R",
    function_name = "run_descriptive_analysis",
    requires_master_data = TRUE
  ),
  territorial = list(
    order = 2L,
    script = "04_territorial_analysis.R",
    function_name = "run_territorial_analysis",
    requires_master_data = TRUE
  ),
  famd = list(
    order = 3L,
    script = "05_famd_analysis.R",
    function_name = "run_famd_analysis",
    requires_master_data = TRUE
  ),
  cluster = list(
    order = 4L,
    script = "06_cluster_analysis.R",
    function_name = "run_cluster_analysis",
    requires_master_data = FALSE
  ),
  time_series = list(
    order = 5L,
    script = "07_time_series_analysis.R",
    function_name = "run_time_series_analysis",
    requires_master_data = TRUE
  )
)


# Show execution plan ----------------------------------------------------------

show_project_plan <- function() {

  stage_names <- names(
    project_stage_registry
  )

  plan <- data.frame(
    order = vapply(
      project_stage_registry,
      function(stage) stage$order,
      integer(1)
    ),
    stage = stage_names,
    script = vapply(
      project_stage_registry,
      function(stage) stage$script,
      character(1)
    ),
    function_name = vapply(
      project_stage_registry,
      function(stage) stage$function_name,
      character(1)
    ),
    requires_master_data = vapply(
      project_stage_registry,
      function(stage) stage$requires_master_data,
      logical(1)
    ),
    stringsAsFactors = FALSE
  )

  plan <- plan[
    order(plan$order),
    ,
    drop = FALSE
  ]

  print(
    plan,
    row.names = FALSE
  )

  invisible(plan)
}


# Normalise requested stages ---------------------------------------------------

normalise_project_stages <- function(stages) {

  available_stages <- names(
    project_stage_registry
  )

  stages <- unique(
    as.character(stages)
  )

  if (
    length(stages) == 1L &&
      identical(stages, "all")
  ) {
    return(available_stages)
  }

  unknown_stages <- setdiff(
    stages,
    available_stages
  )

  if (length(unknown_stages) > 0L) {
    stop(
      "Unknown project stages: ",
      paste(
        unknown_stages,
        collapse = ", "
      ),
      ". Available stages are: ",
      paste(
        available_stages,
        collapse = ", "
      ),
      ".",
      call. = FALSE
    )
  }

  available_stages[
    available_stages %in% stages
  ]
}


# Load one analytical script ---------------------------------------------------

load_project_stage <- function(stage) {

  stage_definition <-
    project_stage_registry[[stage]]

  function_name <-
    stage_definition$function_name

  if (
    exists(
      function_name,
      envir = .project_runner_environment,
      inherits = FALSE
    )
  ) {
    return(
      invisible(function_name)
    )
  }

  script_path <- file.path(
    "R",
    stage_definition$script
  )

  if (!file.exists(script_path)) {
    stop(
      "The script for stage '",
      stage,
      "' could not be found: ",
      script_path,
      call. = FALSE
    )
  }

  sys.source(
    script_path,
    envir = .project_runner_environment
  )

  if (
    !exists(
      function_name,
      envir = .project_runner_environment,
      inherits = FALSE
    )
  ) {
    stop(
      "The expected function '",
      function_name,
      "' was not created by ",
      script_path,
      ".",
      call. = FALSE
    )
  }

  invisible(function_name)
}


# Call a function using only supported arguments -------------------------------

call_project_function <- function(
    function_name,
    arguments = list()
) {

  project_function <- get(
    function_name,
    envir = .project_runner_environment,
    inherits = FALSE
  )

  supported_arguments <- names(
    formals(project_function)
  )

  if (!"..." %in% supported_arguments) {
    arguments <- arguments[
      names(arguments) %in%
        supported_arguments
    ]
  }

  do.call(
    project_function,
    arguments
  )
}


# Load the processed master dataset --------------------------------------------

load_project_master_data <- function() {

  master_dataset_path <- file.path(
    .project_runner_environment$path_data_processed,
    .project_runner_environment$master_dataset_filename
  )

  if (!file.exists(master_dataset_path)) {
    stop(
      "The processed master dataset does not exist: ",
      master_dataset_path,
      "\nRun the import and cleaning scripts before the analytical workflow.",
      call. = FALSE
    )
  }

  message(
    "Loading processed master dataset: ",
    master_dataset_path
  )

  master_data <- readRDS(
    master_dataset_path
  )

  if (!is.data.frame(master_data)) {
    stop(
      "The processed master dataset must be a data frame.",
      call. = FALSE
    )
  }

  message(
    "Master dataset loaded: ",
    format(
      nrow(master_data),
      big.mark = ",",
      scientific = FALSE
    ),
    " rows."
  )

  master_data
}


# Check whether the FAMD clustering input exists -------------------------------

check_saved_famd_input <- function() {

  famd_input_path <- file.path(
    .project_runner_environment$path_data_processed,
    .project_runner_environment$famd_cluster_input_filename
  )

  if (!file.exists(famd_input_path)) {
    stop(
      "The clustering stage requires the FAMD clustering input: ",
      famd_input_path,
      "\nRun the FAMD stage first or include both 'famd' and 'cluster'.",
      call. = FALSE
    )
  }

  invisible(famd_input_path)
}


# Run selected analytical stages ----------------------------------------------

run_project <- function(
    stages = "status",
    save_output = TRUE,
    keep_results = FALSE,
    compare_cluster_candidates = FALSE,
    save_famd_full_model = FALSE,
    validate_expected_famd_size = TRUE
) {

  if (
    length(stages) == 1L &&
      stages %in% c(
        "status",
        "plan"
      )
  ) {
    message(
      "No analytical stage has been executed."
    )

    return(
      show_project_plan()
    )
  }

  selected_stages <- normalise_project_stages(
    stages
  )

  message(
    "Selected stages: ",
    paste(
      selected_stages,
      collapse = " -> "
    )
  )

  needs_master_data <- any(
    vapply(
      selected_stages,
            function(stage) {
        project_stage_registry[[stage]]$requires_master_data
      },
      logical(1)
    )
  )

  master_data <- NULL

  if (needs_master_data) {
    master_data <- load_project_master_data()
  }

  stored_results <- list()
  famd_clustering_input <- NULL
  completed_stages <- character()

  for (stage in selected_stages) {

    stage_definition <-
      project_stage_registry[[stage]]

    function_name <- load_project_stage(
      stage
    )

    message(
      "\nStarting stage: ",
      stage
    )

    start_time <- Sys.time()

    stage_arguments <- list(
      data = master_data,
      save_output = save_output
    )

    if (stage == "famd") {
      stage_arguments$save_full_model <-
        save_famd_full_model

      stage_arguments$validate_expected_size <-
        validate_expected_famd_size
    }

    if (stage == "cluster") {

      if (is.null(famd_clustering_input)) {

        if (!"famd" %in% selected_stages) {
          check_saved_famd_input()
        }

        load_project_stage(
          "cluster"
        )

        famd_clustering_input <-
          call_project_function(
            "load_famd_clustering_input"
          )
      }

      stage_arguments <- list(
        famd_object =
          famd_clustering_input,
        compare_candidates =
          compare_cluster_candidates,
        save_output =
          save_output
      )
    }

    stage_result <- call_project_function(
      function_name,
      stage_arguments
    )

    if (stage == "famd") {

      if (
        !is.list(stage_result) ||
          is.null(
            stage_result$clustering_object
          )
      ) {
        stop(
          "The FAMD stage did not return the expected clustering object.",
          call. = FALSE
        )
      }

      famd_clustering_input <-
        stage_result$clustering_object
    }

    elapsed_time <- difftime(
      Sys.time(),
      start_time,
      units = "mins"
    )

    message(
      "Completed stage: ",
      stage,
      " | Elapsed minutes: ",
      round(
        as.numeric(elapsed_time),
        2
      )
    )

    completed_stages <- c(
      completed_stages,
      stage
    )

    if (isTRUE(keep_results)) {
      stored_results[[stage]] <-
        stage_result
    }

    if (
      !isTRUE(keep_results) &&
        stage != "famd"
    ) {
      rm(stage_result)
      invisible(gc())
    }
  }

  message(
    "\nCompleted project stages: ",
    paste(
      completed_stages,
      collapse = ", "
    )
  )

  if (isTRUE(keep_results)) {
    return(
      invisible(stored_results)
    )
  }

  invisible(
    list(
      completed_stages =
        completed_stages,
      outputs_saved =
        save_output
    )
  )
}


# Usage examples ---------------------------------------------------------------

# Display the execution plan without running any analysis:
#
# run_project()
#
# Run one analytical stage:
#
# run_project(
#   stages = "descriptive"
# )
#
# Run FAMD followed by clustering:
#
# run_project(
#   stages = c(
#     "famd",
#     "cluster"
#   ),
#   compare_cluster_candidates = FALSE
# )
#
# Run every analytical stage:
#
# run_project(
#   stages = "all",
#   compare_cluster_candidates = FALSE
# )
#
# Keep returned R objects in memory for interactive inspection:
#
# project_results <- run_project(
#   stages = "time_series",
#   keep_results = TRUE
# )