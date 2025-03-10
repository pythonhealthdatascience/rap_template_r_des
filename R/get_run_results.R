#' Process the raw monitored arrivals and resources.
#'
#' For the provided replication, calculate the:
#' (1) number of arrivals
#' (2) mean wait time for each resource
#' (3) mean activity time for each resource
#' (4) mean resource utilisation.
#'
#' Credit: The utilisation calculation is taken from the
#' `plot.resources.utilization()` function in simmer.plot 0.1.18, which is
#' shared under an MIT Licence (Ucar I, Smeets B (2023). simmer.plot: Plotting
#' Methods for 'simmer'. https://r-simmer.org
#' https://github.com/r-simmer/simmer.plot.).
#'
#' Note: When calculating the mean wait time, it is rounded to 10 decimal
#' places. This is to resolve an issue that occurs because `start_time`,
#' `end_time` and `activity_time` are all to 14 decimal places, but the
#' calculations can produce tiny negative values due to floating-point errors.
#'
#' @param results Named list with `arrivals` containing output from
#' `get_mon_arrivals()` and `resources` containing output from
#' `get_mon_resources()` (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param run_number Integer representing index of current simulation run.
#'
#' @importFrom dplyr group_by summarise n_distinct mutate lead full_join
#' @importFrom dplyr bind_cols
#' @importFrom purrr reduce
#' @importFrom rlang .data
#' @importFrom simmer get_mon_resources get_mon_arrivals now
#' @importFrom stats setNames
#' @importFrom tidyr pivot_wider drop_na
#' @importFrom tidyselect any_of
#' @importFrom tibble tibble
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number) {

  # If there were no arrivals, return dataframe row with just the replication
  # number and arrivals column set to 0
  if (nrow(results[["arrivals"]]) == 0L) {
    processed_result <- tibble(replication = run_number, arrivals = 0L)

    # Otherwise...
  } else {

    # Calculate the number of arrivals
    calc_arr <- results[["arrivals"]] %>%
      summarise(arrivals = n_distinct(.data[["name"]]))

    # Create subset of data that removes patients who were still waiting and
    # had not completed
    complete_arrivals <- results[["arrivals"]] %>%
      drop_na(any_of("end_time"))

    # If there are any patients who were seen...
    if (nrow(complete_arrivals) > 0L) {

      # Calculate the mean wait time for each resource
      calc_wait <- complete_arrivals %>%
        group_by(.data[["resource"]]) %>%
        summarise(mean_waiting_time = mean(.data[["wait_time"]])) %>%
        pivot_wider(names_from = "resource",
                    values_from = "mean_waiting_time",
                    names_glue = "mean_waiting_time_{resource}")

      # Calculate the mean time spent with each resource
      calc_serv <- complete_arrivals %>%
        group_by(.data[["resource"]]) %>%
        summarise(mean_serve_time = mean(.data[["serve_length"]])) %>%
        pivot_wider(names_from = "resource",
                    values_from = "mean_serve_time",
                    names_glue = "mean_serve_time_{resource}")

      # Otherwise, create same tibbles but set values to NA
    } else {
      unique_resources <- unique(results[["resources"]]["resource"])

      calc_wait <- tibble::tibble(
        !!!setNames(rep(list(NA_real_), length(unique_resources)),
                    paste0("mean_waiting_time_", unique_resources))
      )

      calc_serv <- tibble::tibble(
        !!!setNames(rep(list(NA_real_), length(unique_resources)),
                    paste0("mean_serve_time_", unique_resources))
      )
    }

    # Calculate the mean resource utilisation
    # Utilisation is given by the total effective usage time (`in_use`) over
    # the total time intervals considered (`dt`).
    calc_util <- results[["resources"]] %>%
      group_by(.data[["resource"]]) %>%
      # nolint start
      mutate(dt = lead(.data[["time"]]) - .data[["time"]]) %>%
      mutate(capacity = pmax(.data[["capacity"]], .data[["server"]])) %>%
      mutate(dt = ifelse(.data[["capacity"]] > 0L, .data[["dt"]], 0L)) %>%
      mutate(in_use = (.data[["dt"]] * .data[["server"]] /
                         .data[["capacity"]])) %>%
      # nolint end
      summarise(
        utilisation = sum(.data[["in_use"]], na.rm = TRUE) /
          sum(.data[["dt"]], na.rm = TRUE)
      ) %>%
      pivot_wider(names_from = "resource",
                  values_from = "utilisation",
                  names_glue = "utilisation_{resource}")

    # Calculate the number of patients unseen at end of simulation
    calc_unseen_n <- results[["arrivals"]] %>%
      group_by(.data[["resource"]]) %>%
      summarise(value = sum(!is.na(.data[["wait_time_unseen"]]))) %>%
      pivot_wider(names_from = "resource",
                  values_from = "value",
                  names_glue = "count_unseen_{resource}")

    # Calculate the mean waiting time of patients unseen at end of simulation
    calc_unseen_mean <- results[["arrivals"]] %>%
      group_by(.data[["resource"]]) %>%
      summarise(value = mean(.data[["wait_time_unseen"]], na.rm = TRUE)) %>%
      pivot_wider(names_from = "resource",
                  values_from = "value",
                  names_glue = "mean_waiting_time_unseen_{resource}")

    # Combine all calculated metrics into a single dataframe, and along with
    # the replication number
    processed_result <- dplyr::bind_cols(
      tibble(replication = run_number),
      calc_arr, calc_wait, calc_serv, calc_util, calc_unseen_n, calc_unseen_mean
    )
  }
  return(processed_result) # nolint
}
