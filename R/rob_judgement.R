#' Derive an overall risk of bias judgement
#'
#' Takes the worst judgement across the selected domains, using the tool's
#' severity ranking (e.g. ROBINS-I: Low < Low (except confounding) < Moderate <
#' Serious < Critical). "Not applicable" and "ONM" are ignored. CLARITY has no
#' overall judgement.
#'
#' Tool guidance permits reviewer judgement to override this rule (e.g. RoB 2
#' "some concerns" in multiple domains -> High). Supply your own overall column
#' in those cases.
#'
#' @param data Data frame of domain judgements.
#' @param rob_tool Tool name (see `rob_tools()`).
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Domain columns to
#'   combine. Defaults to the domains defined for `name` in the tool.
#' @param name Name of the overall column to create.
#'
#' @return `data` with standardised domain judgements and the overall column.
#'
#' @examples
#' rob <- tibble::tibble(D1 = c("Low", "Moderate"), D2 = c("Serious", "Low"))
#' rob_overall(rob, "robins_i", cols = c(D1, D2))
#'
#' @noRd
rob_overall <- function(data, rob_tool = "rob2", cols = NULL, name = "Overall") {
  spec <- as_rob_spec(rob_tool)
  cols <- if (rlang::quo_is_null(rlang::enquo(cols))) {
    dplyr::intersect(spec@overall_from[[name]] %||% names(spec@domains), names(data))
  } else {
    names(tidyselect::eval_select(rlang::enquo(cols), data))
  }
  if (length(cols) == 0) cli::cli_abort("No domain columns available to derive {.field {name}}.")
  data |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(cols), \(x) standardise_judgement(x, spec@synonyms)),
      "{name}" := purrr::pmap_chr(dplyr::pick(dplyr::all_of(cols)), \(...) rob_overall_judgement(spec, c(...))))
}


#' Risk of bias columns present in a data frame
#'
#' @param data A data frame.
#' @param rob_tool Tool name (see `rob_tools()`).
#'
#' @return Domain and overall columns in `data`, in display order.
#' @noRd
rob_columns <- function(data, rob_tool = "rob2") {
  spec <- as_rob_spec(rob_tool)
  data |>
    dplyr::select(dplyr::any_of(c(names(spec@domains), names(spec@overall)))) |>
    names()
}


#' Internal: standardise judgements against a synonym lookup
#'
#' @noRd
standardise_judgement <- function(x, lookup) {
  tibble::tibble(value = as.character(x)) |>
    dplyr::mutate(synonym = stringr::str_to_lower(stringr::str_squish(.data$value))) |>
    dplyr::left_join(lookup, by = "synonym", relationship = "many-to-one") |>
    dplyr::mutate(level = dplyr::case_when(is.na(.data$value) ~ "Not applicable", .default = dplyr::coalesce(.data$level, .data$value))) |>
    dplyr::pull("level")
}


#' Internal: validate, standardise and derive overall columns
#'
#' @noRd
prepare_rob_data <- function(data, spec, derive_overall = FALSE) {
  missing_cols <- setdiff(spec@required, names(data))
  if (length(missing_cols) > 0) cli::cli_abort("Missing {spec@label} column{?s}: {.field {missing_cols}}.")
  data <- data |>
    dplyr::mutate(!!!rlang::rep_named(setdiff(spec@always, names(data)), list(NA_character_))) |>
    dplyr::mutate(dplyr::across(dplyr::any_of(names(spec@domains)), \(x) standardise_judgement(x, spec@synonyms))) |>
    purrr::reduce(names(spec@overall), \(df, name) add_overall(df, spec, name, derive_overall), .init = _)
  warn_unknown_judgements(data, spec)
  data
}


#' Internal: derive an overall column if absent (or forced), else standardise it
#'
#' @noRd
add_overall <- function(data, spec, name, derive_overall = FALSE) {
  cols <- dplyr::intersect(spec@overall_from[[name]], names(data))
  if ((isTRUE(derive_overall) || !name %in% names(data)) && length(cols) > 0) return(rob_overall(data, spec, cols = dplyr::all_of(cols), name = name))
  if (!name %in% names(data)) return(data)
  dplyr::mutate(data, "{name}" := standardise_judgement(.data[[name]], spec@overall_synonyms))
}


#' Internal: warn about judgements that will be shown as blank cells
#'
#' @noRd
warn_unknown_judgements <- function(data, spec) {
  unknown <- data |>
    dplyr::select(dplyr::all_of(rob_columns(data, spec))) |>
    purrr::map(as.character) |>
    purrr::list_c() |>
    unique() |>
    setdiff(names(spec@levels))
  if (length(unknown) > 0) cli::cli_warn("Unrecognised {spec@label} judgement{?s} shown as blank cell{?s}: {.val {unknown}}.")
  invisible(unknown)
}
