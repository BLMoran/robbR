#' Internal: disambiguate duplicate Author names
#'
#' Same Author + Year (e.g. multi-arm trials) gets a letter appended to Year
#' ("1999a", "1999b"); any repeated Author is made unique ("Smith_a"). The
#' original name is kept in `Author_original`.
#'
#' @noRd
make_authors_unique <- function(data) {
  data |>
    dplyr::mutate(Author_original = .data$Author, Year = as.character(.data$Year)) |>
    dplyr::mutate(Year = if (dplyr::n() > 1) stringr::str_c(.data$Year, letters[dplyr::row_number()]) else .data$Year, .by = c("Author", "Year")) |>
    dplyr::mutate(Author = if (dplyr::n() > 1) stringr::str_c(.data$Author, "_", letters[dplyr::row_number()]) else .data$Author, .by = "Author")
}


#' Internal: sort studies, keeping Pooled Effect and Prediction rows last
#'
#' @noRd
sort_studies_fn <- function(data, sort_studies_by = "author") {
  sort_vars <- switch(sort_studies_by, author = "Author", year = c("Year", "Author"), effect = c("yi", "Author"))
  if (!all(sort_vars %in% names(data))) cli::cli_abort("{.arg sort_studies_by} = {.val {sort_studies_by}} requires column{?s} {.field {setdiff(sort_vars, names(data))}}.")
  data |>
    dplyr::mutate(.row_type = dplyr::case_when(.data$Author == "Pooled Effect" ~ 2L, .data$Author == "Prediction" ~ 3L, .default = 1L)) |>
    dplyr::arrange(.data$.row_type, dplyr::pick(dplyr::any_of("Subgroup")), dplyr::pick(dplyr::all_of(sort_vars))) |>
    dplyr::select(-".row_type") |>
    dplyr::mutate(Author = forcats::fct_inorder(as.character(.data$Author)))
}


#' Internal: order and filter subgroups
#'
#' @noRd
order_subgroups <- function(data, subgroup = FALSE, sort_subgroup_by = "alphabetical") {
  if (!isTRUE(subgroup)) return(data)
  subgroup_order <- get_subgroup_order(data, sort_subgroup_by, append_overall = FALSE)
  data |>
    dplyr::filter(.data$Subgroup %in% subgroup_order) |>
    dplyr::mutate(Subgroup = factor(.data$Subgroup, levels = subgroup_order)) |>
    dplyr::arrange(.data$Subgroup)
}


#' Internal: subgroup order based on sorting preference
#'
#' @param append_overall Append "Overall" to the end (forest plots).
#' @noRd
get_subgroup_order <- function(data, sort_subgroup_by, append_overall = TRUE) {
  if (!"Subgroup" %in% names(data)) return(NULL)
  if (!is.character(sort_subgroup_by)) cli::cli_abort("{.arg sort_subgroup_by} must be {.val alphabetical}, {.val effect}, or a character vector of subgroup names.")
  subgroups <- data |>
    dplyr::filter(!is.na(.data$Subgroup)) |>
    dplyr::pull("Subgroup") |>
    as.character() |>
    unique()
  subgroup_order <- if (identical(sort_subgroup_by, "alphabetical")) {
    stringr::str_sort(subgroups)
  } else if (identical(sort_subgroup_by, "effect")) {
    if (!"yi" %in% names(data)) cli::cli_abort("{.arg sort_subgroup_by} = {.val effect} requires an effect column.")
    data |>
      dplyr::summarise(mean_effect = mean(.data$yi, na.rm = TRUE), .by = "Subgroup") |>
      dplyr::arrange(.data$mean_effect) |>
      dplyr::pull("Subgroup") |>
      as.character()
  } else {
    missing_groups <- setdiff(sort_subgroup_by, subgroups)
    dropped_groups <- setdiff(subgroups, sort_subgroup_by)
    if (length(missing_groups) > 0) cli::cli_warn("Subgroup{?s} in {.arg sort_subgroup_by} not found in data: {.val {missing_groups}}.")
    if (length(dropped_groups) > 0) cli::cli_warn("Subgroup{?s} not in {.arg sort_subgroup_by} will be dropped: {.val {dropped_groups}}.")
    sort_subgroup_by
  }
  if (isTRUE(append_overall)) c(subgroup_order, "Overall") else subgroup_order
}


#' Internal: add title and subtitle to the patchwork plot
#'
#' @noRd
add_rob_titles <- function(plot, title = NULL, subtitle = NULL, title_align = "left", font = NULL) {
  if (is.null(title) && is.null(subtitle)) return(plot)
  hjust <- dplyr::case_when(title_align == "left" ~ 0, title_align %in% c("center", "centre") ~ 0.5, .default = 1)
  title_theme <- ggplot2::theme(
    plot.title = if (!is.null(title)) ggplot2::element_text(size = 16, face = "bold", hjust = hjust, margin = ggplot2::margin(b = if (is.null(subtitle)) 10 else 5), family = font),
    plot.subtitle = if (!is.null(subtitle)) ggplot2::element_text(size = 14, hjust = hjust, margin = ggplot2::margin(b = 10), color = "gray30", family = font))
  plot + patchwork::plot_annotation(title = title, subtitle = subtitle, theme = title_theme)
}
