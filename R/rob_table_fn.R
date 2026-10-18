#' Internal: gt table of risk of bias judgements
#'
#' @noRd
rob_table_fn <- function(df, spec, rob_cols, subgroup = FALSE, study_label = NULL, font = NULL) {
  study_label <- study_label %||% spec@study_label
  df <- dplyr::mutate(df, Author = dplyr::if_else(is.na(.data$Year), as.character(.data$Author), stringr::str_c(.data$Author, " (", .data$Year, ")")))
  base_table <- if (isTRUE(subgroup)) {
    gt::gt(df, groupname_col = "Subgroup") |>
      gt::tab_options(row_group.font.weight = "bold") |>
      gt::tab_style(style = gt::cell_fill(color = "grey95"), locations = gt::cells_row_groups()) |>
      gt::cols_label(Author = gt::md(stringr::str_c("Subgroup/ \n", study_label))) |>
      gt::tab_style(style = gt::cell_text(indent = gt::px(10)), locations = gt::cells_body(columns = "Author"))
  } else {
    gt::gt(df) |>
      gt::cols_label(Author = study_label)
  }
  base_table |>
    gt::cols_align(align = "left", columns = "Author") |>
    gt::cols_align(align = "center", columns = dplyr::all_of(rob_cols)) |>
    gt::tab_options(column_labels.font.weight = "bold", table.border.top.color = "white", table.border.bottom.color = "white", table.font.names = font) |>
    gt::cols_hide(columns = "Year") |>
    gt::opt_table_lines(extent = "none") |>
    gt::text_transform(locations = gt::cells_body(columns = dplyr::all_of(rob_cols)), fn = \(x) rob_icon(x, levels = names(spec@levels), height = "1.1em")) |>
    add_rob_spanners(spec, rob_cols)
}


#' Internal: column spanners (shown when at least two groups are present)
#'
#' @noRd
add_rob_spanners <- function(table, spec, rob_cols) {
  spanners <- spec@spanners |>
    purrr::map(\(x) dplyr::intersect(x, rob_cols)) |>
    purrr::keep(\(x) length(x) > 0)
  if (length(spanners) < 2) return(table)
  purrr::reduce2(names(spanners), spanners, \(tbl, label, cols) gt::tab_spanner(tbl, label = label, columns = dplyr::all_of(cols), id = stringr::str_c("spanner_", label)), .init = table) |>
    gt::tab_style(style = gt::cell_text(weight = "bold"), locations = gt::cells_column_spanners())
}


#' Internal: risk of bias legend
#'
#' Only the domains and judgement levels present in the plot are listed.
#'
#' @noRd
rob_legend_fn <- function(spec, domains_present = NULL, levels_present = NULL, font = NULL) {
  domains <- spec@domains[names(spec@domains) %in% (domains_present %||% names(spec@domains))]
  levels <- spec@levels[names(spec@levels) %in% (levels_present %||% names(spec@severity))]
  legend <- dplyr::bind_rows(
    tibble::tibble(Code = stringr::str_c("(", names(domains), ")"), Description = unname(domains), type = "domain"),
    tibble::tibble(Code = "", Description = "", type = "spacer"),
    tibble::tibble(Code = names(levels), Description = unname(levels), type = "level")) |>
    gt::gt() |>
    gt::cols_hide(columns = "type") |>
    gt::cols_label(Code = "", Description = "") |>
    gt::tab_header(title = "Risk of bias legend") |>
    gt::tab_style(style = gt::cell_text(weight = "bold", size = gt::px(16)), locations = gt::cells_title(groups = "title")) |>
    gt::tab_style(style = gt::cell_text(weight = "bold", size = gt::px(12)), locations = gt::cells_body(columns = "Code", rows = .data$type == "domain")) |>
    gt::tab_style(style = "padding-left:2px;", locations = gt::cells_body(columns = "Code")) |>
    gt::cols_width(Code ~ gt::px(40), Description ~ gt::px(300)) |>
    gt::tab_options(table.border.top.color = "white", table.border.bottom.color = "white", heading.align = "left", heading.padding = gt::px(6), table.font.size = gt::px(12), table.font.names = font) |>
    gt::opt_table_lines(extent = "none")
  if (length(levels) == 0) return(legend)
  legend |>
    gt::text_transform(locations = gt::cells_body(columns = "Code", rows = .data$type == "level"), fn = \(x) rob_icon(x, levels = names(spec@levels), height = "1.5em")) |>
    gt::tab_style(style = gt::cell_text(weight = "bold", style = "italic"), locations = gt::cells_body(columns = "Description", rows = .data$type == "level"))
}


#' Internal: icon for each judgement level
#'
#' ROBINS-I/E use a graded scale: Low (green), Low except for uncontrolled
#' confounding (light green), Moderate / Some concerns (yellow), Serious / High
#' (red), Critical / Very high (dark red).
#'
#' @noRd
rob_icon_table <- function() {
  tibble::tribble(
    ~level, ~icon, ~fill, ~prefer,
    "Low", "circle-minus", "#77bb41", "solid",
    "Low (except confounding)", "circle-minus", "#b5d98f", "solid",
    "Some concerns", "circle-question", "#f5ec00", "solid",
    "Moderate", "circle-question", "#f5ec00", "solid",
    "Unclear", "circle-question", "#5b9bd5", "solid",
    "High", "circle-plus", "#e32400", "solid",
    "Serious", "circle-plus", "#e32400", "solid",
    "Very high", "circle-exclamation", "#8b0000", "solid",
    "Critical", "circle-exclamation", "#8b0000", "solid",
    "Definitely low", "circle-minus", "#3d7a1f", "solid",
    "Probably low", "circle-minus", "#a9d18e", "solid",
    "Probably high", "circle-plus", "#f5a000", "solid",
    "Definitely high", "circle-plus", "#e32400", "solid",
    "Not applicable", "circle", "#d9d9d9", "solid",
    "ONM", "circle", "#9e9e9e", "regular")
}


#' Internal: map judgements to icons
#'
#' Judgements not in `levels` (or missing) are rendered as empty cells.
#'
#' @noRd
rob_icon <- function(x, levels = NULL, height = "1.1em") {
  icons <- rob_icon_table()
  if (!is.null(levels)) icons <- dplyr::filter(icons, .data$level %in% levels)
  tibble::tibble(level = as.character(x)) |>
    dplyr::left_join(icons, by = "level", relationship = "many-to-one") |>
    dplyr::select(-"level") |>
    purrr::pmap_chr(\(icon, fill, prefer) if (is.na(icon)) "" else as.character(fontawesome::fa(icon, fill = fill, height = height, prefer_type = prefer)))
}
