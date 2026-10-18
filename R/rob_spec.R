#' Risk of bias tool specification
#'
#' S7 class describing a risk of bias tool: its domains, judgement levels, how
#' judgements are standardised, and how overall judgements are derived.
#' Built-in tools are returned by `get_rob_spec()`. Custom tools can be created
#' with `rob_spec()` and passed to [rob_plot()] via `rob_tool`.
#'
#' @param name Short tool identifier.
#' @param label Display name.
#' @param domains Named character vector of domain columns (display order) and
#'   their descriptions.
#' @param levels Named character vector of domain judgement levels (display
#'   order) and their legend labels. "Not applicable" and "ONM" are added.
#' @param severity Named integer vector ranking the overall judgement levels
#'   (higher = worse). The worst level present is used for overall judgements;
#'   ties are broken by the order of `severity`.
#' @param synonyms Named list mapping each level to the lower-case values that
#'   are standardised to it.
#' @param optional Domains that may be absent (shown only if present).
#' @param always Optional domains added as "Not applicable" when absent.
#' @param overall Named character vector of overall columns and descriptions.
#' @param overall_from Named list of the domains each overall column is derived
#'   from. `NULL` elements are never derived.
#' @param overall_map Named character vector mapping domain levels to overall
#'   levels before ranking by `severity`.
#' @param overall_synonyms As `synonyms`, for overall columns.
#' @param spanners Named list of column groups shown as table spanners.
#' @param study_label Default header for the study column (e.g. "Trial").
#'
#' @examples
#' get_rob_spec("robins_i")
#'
#' my_tool <- rob_spec(
#'   name = "custom",
#'   label = "Custom tool",
#'   domains = c(D1 = "Selection", D2 = "Measurement"),
#'   levels = c(Low = "Low risk", High = "High risk"),
#'   severity = c(Low = 1L, High = 2L),
#'   synonyms = list(Low = "low", High = "high"))
#'
#' @noRd
rob_spec <- S7::new_class(
  "rob_spec",
  properties = list(
    name = S7::class_character,
    label = S7::class_character,
    domains = S7::class_character,
    levels = S7::class_character,
    severity = S7::class_integer,
    synonyms = S7::class_data.frame,
    optional = S7::class_character,
    always = S7::class_character,
    overall = S7::class_character,
    overall_from = S7::class_list,
    overall_map = S7::class_character,
    overall_synonyms = S7::class_data.frame,
    spanners = S7::class_list,
    study_label = S7::class_character,
    required = S7::new_property(
      S7::class_character,
      getter = \(self) setdiff(names(self@domains), self@optional))),
  constructor = function(name, label, domains, levels, severity, synonyms, optional = character(), always = character(), overall = c(Overall = "Overall risk of bias"), overall_from = NULL, overall_map = NULL, overall_synonyms = NULL, spanners = list(), study_label = "Study") {
    levels <- c(levels, "Not applicable" = "Not applicable", ONM = "Outcome not measured")
    S7::new_object(
      S7::S7_object(),
      name = name,
      label = label,
      domains = domains,
      levels = levels,
      severity = rlang::set_names(as.integer(severity), names(severity)),
      synonyms = rob_synonyms(synonyms, names(levels)),
      optional = optional,
      always = always,
      overall = overall,
      overall_from = overall_from %||% list(Overall = names(domains)),
      overall_map = overall_map %||% rlang::set_names(names(levels)),
      overall_synonyms = rob_synonyms(overall_synonyms %||% synonyms, names(levels)),
      spanners = spanners,
      study_label = study_label)
  },
  validator = function(self) {
    c(
      if (!all(self@optional %in% names(self@domains))) "@optional must be domain names.",
      if (!all(self@always %in% self@optional)) "@always must be optional domains.",
      if (!all(names(self@overall_from) %in% names(self@overall))) "@overall_from must be named by overall columns.",
      if (!all(names(self@severity) %in% names(self@levels))) "@severity must be named by levels in @levels.")})


#' Coerce to a risk of bias tool specification
#'
#' @param x A tool name (see `get_rob_spec()`) or a `rob_spec` object.
#' @noRd
as_rob_spec <- S7::new_generic("as_rob_spec", "x")

S7::method(as_rob_spec, rob_spec) <- function(x) x

S7::method(as_rob_spec, S7::class_character) <- function(x) get_rob_spec(x)


#' Overall judgement for one set of domain judgements
#'
#' @noRd
rob_overall_judgement <- S7::new_generic("rob_overall_judgement", "spec")

S7::method(rob_overall_judgement, rob_spec) <- function(spec, x) {
  severity <- tibble::tibble(level = names(spec@severity), severity = unname(spec@severity), rank = seq_along(spec@severity))
  judged <- tibble::tibble(level = dplyr::coalesce(unname(spec@overall_map[x]), x)) |>
    dplyr::inner_join(severity, by = "level", relationship = "many-to-one") |>
    dplyr::slice_max(.data$severity, n = 1, with_ties = TRUE) |>
    dplyr::slice_min(.data$rank, n = 1, with_ties = FALSE)
  if (nrow(judged) == 0) "Not applicable" else judged$level
}


S7::method(print, rob_spec) <- function(x, ...) {
  cli::cli_text("{.cls rob_spec} {x@label}")
  cli::cli_bullets(c(
    "*" = "Domains: {.field {names(x@domains)}}",
    "*" = "Overall: {.field {names(x@overall)}}",
    "*" = "Levels: {.val {setdiff(names(x@levels), c('Not applicable', 'ONM'))}}"))
  invisible(x)
}


#' Internal: synonym lookup table
#'
#' Explicit synonyms take precedence over lower-case level names.
#'
#' @noRd
rob_synonyms <- function(synonyms, levels) {
  c(synonyms, list("Not applicable" = c("na", "n/a", "not applicable", ""), ONM = c("onm", "outcome not measured"))) |>
    purrr::imap(\(synonym, level) tibble::tibble(synonym = synonym, level = level)) |>
    purrr::list_rbind() |>
    dplyr::bind_rows(tibble::tibble(synonym = stringr::str_to_lower(levels), level = levels)) |>
    dplyr::slice_head(n = 1, by = "synonym")
}
