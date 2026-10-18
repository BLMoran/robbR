#' RoB 2 judgements from signalling questions
#'
#' Applies the RoB 2 algorithms to answers to the signalling questions and
#' returns domain and overall risk of bias judgements, ready for [rob_plot()]
#' and [rob_summary()]. Supports individually randomised parallel-group,
#' cluster-randomised and crossover trials (RoB 2 cribsheets, 2019 and 2021),
#' which can be mixed within one meta-analysis.
#'
#' @param data A data frame with one row per study and one column per
#'   signalling question, named as in the RoB 2 cribsheets:
#'   * Domain 1: `1.1`-`1.3` (or `1a.1`-`1a.3`).
#'   * Domain 1b (cluster trials): `1b.1`-`1b.3`.
#'   * Domain S (crossover trials): `S.1`-`S.3`.
#'   * Domain 2: `2.1`-`2.7` (cluster trials, effect of assignment: `2.1a`
#'     and `2.1b` in place of `2.1`).
#'   * Domain 3: `3.1`-`3.4` (cluster trials: `3.1a` and `3.1b`).
#'   * Domain 4: `4.1`-`4.5` (cluster trials: `4.3a` and `4.3b`).
#'   * Domain 5: `5.1`-`5.3` (crossover trials: also `5.4`).
#'
#'   Prefixes and underscores are allowed (e.g. `q1_1`, `D2.1a`). Answers are
#'   `Y`, `PY`, `PN`, `N` or `NI`, abbreviated or in full (e.g. "Probably
#'   yes"). Leave questions the algorithm skips empty; a required question left
#'   empty is treated as "No information".
#' @param design Trial design: `"parallel"` (default), `"cluster"` or
#'   `"crossover"`. Either one value for all studies, or an unquoted column
#'   name giving the design of each study.
#' @param effect Effect of interest for domain 2: `"assignment"` (the
#'   intention-to-treat effect, default) or `"adhering"` (the per-protocol
#'   effect).
#' @param keep_answers Logical. Keep the signalling question columns? (default:
#'   `FALSE`).
#'
#' @details
#' Domain judgements follow the cribsheet algorithms. The overall judgement is
#' "Low" if all domains are low risk, "High" if any domain is high risk, and
#' "Some concerns" otherwise. The guidance allows "some concerns" in multiple
#' domains to be judged high overall; edit `Overall` if you make that call.
#'
#' `D1b` is returned only if there are cluster trials, and `DS` only if there
#' are crossover trials. Both are `NA` for studies of other designs.
#'
#' @return `data` with columns `D1`, (`D1b`), `D2`-`D5`, (`DS`) and `Overall`.
#'
#' @examples
#' answers <- tibble::tibble(
#'   Author = c("Thermopolis", "Sachs", "Austen"),
#'   Year = c(2001, 2006, 2007),
#'   design = c("parallel", "cluster", "crossover"),
#'   `1.1` = c("Y", "Y", "PY"),
#'   `1.2` = c("Y", "PY", "NI"),
#'   `1.3` = c("N", "N", "N"),
#'   `1b.1` = c(NA, "N", NA),
#'   `1b.2` = c(NA, "PN", NA),
#'   `1b.3` = c(NA, "N", NA),
#'   `S.1` = c(NA, NA, "Y"),
#'   `S.3` = c(NA, NA, "PY"),
#'   `2.1` = c("N", NA, "Y"),
#'   `2.1a` = c(NA, "N", NA),
#'   `2.2` = c("N", "Y", "Y"),
#'   `2.3` = c(NA, "PN", "Y"),
#'   `2.4` = c(NA, NA, "PY"),
#'   `2.5` = c(NA, NA, "N"),
#'   `2.6` = c("Y", "Y", "PN"),
#'   `2.7` = c(NA, NA, "N"),
#'   `3.1` = c("Y", NA, "N"),
#'   `3.1a` = c(NA, "Y", NA),
#'   `3.1b` = c(NA, "PY", NA),
#'   `3.2` = c(NA, NA, "N"),
#'   `3.3` = c(NA, NA, "PY"),
#'   `3.4` = c(NA, NA, "PN"),
#'   `4.1` = c("N", "N", "N"),
#'   `4.2` = c("N", "N", "PN"),
#'   `4.3` = c("N", NA, "Y"),
#'   `4.3a` = c(NA, "PN", NA),
#'   `4.4` = c(NA, NA, "PY"),
#'   `4.5` = c(NA, NA, "PN"),
#'   `5.1` = c("Y", "N", "Y"),
#'   `5.2` = c("N", "N", "N"),
#'   `5.3` = c("N", "N", "PN"),
#'   `5.4` = c(NA, NA, "N"))
#'
#' judged <- rob2_algorithm(answers, design = design)
#' judged
#'
#' rob_plot(judged, add_rob_legend = TRUE)
#'
#' @export
rob2_algorithm <- function(data, design = "parallel", effect = c("assignment", "adhering"), keep_answers = FALSE) {
  effect <- rlang::arg_match(effect)
  data <- dplyr::rename_with(data, normalise_sq_names)
  designs <- data |>
    dplyr::mutate(.design = {{ design }}) |>
    dplyr::pull(".design") |>
    standardise_design()
  a <- rob2_answers(data)
  judgements <- tibble::tibble(
    D1 = rob2_d1(a),
    D1b = dplyr::if_else(designs == "cluster", rob2_d1b(a), NA_character_),
    D2 = if (effect == "assignment") rob2_d2_assignment(a, designs) else rob2_d2_adhering(a, designs),
    D3 = rob2_d3(a, designs),
    D4 = rob2_d4(a, designs),
    D5 = rob2_d5(a, designs),
    DS = dplyr::if_else(designs == "crossover", rob2_ds(a), NA_character_))
  judgements <- judgements |>
    dplyr::mutate(Overall = rob2_worst(judgements)) |>
    dplyr::select(-dplyr::any_of(c(if (!any(designs == "cluster")) "D1b", if (!any(designs == "crossover")) "DS")))
  data |>
    dplyr::select(-dplyr::any_of(c(names(judgements), if (!isTRUE(keep_answers)) rob2_questions()))) |>
    dplyr::bind_cols(judgements)
}


#' Internal: RoB 2 signalling question names
#'
#' @noRd
rob2_questions <- function() {
  c("1.1", "1.2", "1.3", "1b.1", "1b.2", "1b.3", "s.1", "s.2", "s.3", "2.1", "2.1a", "2.1b", "2.2", "2.3", "2.4", "2.5", "2.6", "2.7", "3.1", "3.1a", "3.1b", "3.2", "3.3", "3.4", "4.1", "4.2", "4.3", "4.3a", "4.3b", "4.4", "4.5", "5.1", "5.2", "5.3", "5.4")
}


#' Internal: normalise signalling question column names (e.g. "q1_1" -> "1.1")
#'
#' @noRd
normalise_sq_names <- function(x) {
  normalised <- x |>
    stringr::str_to_lower() |>
    stringr::str_squish() |>
    stringr::str_remove("^(domain|sq|q|d)[ _.]?") |>
    stringr::str_replace_all("_", ".") |>
    stringr::str_replace("^1a\\.", "1.")
  dplyr::if_else(normalised %in% rob2_questions(), normalised, x)
}


#' Internal: standardise trial design
#'
#' @noRd
standardise_design <- function(x) {
  y <- stringr::str_to_lower(as.character(x))
  dplyr::case_when(stringr::str_detect(y, "cluster") ~ "cluster", stringr::str_detect(y, "cross") ~ "crossover", .default = "parallel")
}


#' Internal: standardised answers for every signalling question
#'
#' Missing and "not applicable" answers are returned as `NA`.
#'
#' @noRd
rob2_answers <- function(data) {
  answers <- rob2_questions() |>
    rlang::set_names() |>
    purrr::map(\(q) if (q %in% names(data)) data[[q]] else rep(NA_character_, nrow(data)))
  standardised <- purrr::map(answers, standardise_answer)
  unknown <- purrr::map2(answers, standardised, \(raw, std) raw[is.na(std) & !is_missing_answer(raw)]) |>
    purrr::list_c() |>
    unique()
  if (length(unknown) > 0) cli::cli_warn("Unrecognised answer{?s} treated as {.val NI}: {.val {unknown}}.")
  standardised
}


#' Internal: standardise a signalling question answer
#'
#' @noRd
standardise_answer <- function(x) {
  y <- stringr::str_to_lower(stringr::str_squish(as.character(x)))
  dplyr::case_when(
    y %in% c("y", "yes") ~ "Y",
    y %in% c("py", "probably yes") ~ "PY",
    y %in% c("pn", "probably no") ~ "PN",
    y %in% c("n", "no") ~ "N",
    y %in% c("ni", "no information") ~ "NI",
    .default = NA_character_)
}


#' @noRd
is_missing_answer <- function(x) {
  is.na(x) | stringr::str_to_lower(stringr::str_squish(as.character(x))) %in% c("", "na", "n/a", "not applicable")
}


#' @noRd
yes <- function(x) x %in% c("Y", "PY")

#' @noRd
no <- function(x) x %in% c("N", "PN")

#' @noRd
no_info <- function(x) x %in% "NI" | is.na(x)


#' Internal: worst judgement across domains, row by row
#'
#' @noRd
rob2_worst <- function(judgements) {
  purrr::pmap_chr(judgements, \(...) {
    v <- c(...)
    dplyr::case_when(any(v == "High", na.rm = TRUE) ~ "High", any(v == "Some concerns", na.rm = TRUE) ~ "Some concerns", .default = "Low")
  })
}


#' Internal: domain 1, randomisation process
#'
#' @noRd
rob2_d1 <- function(a) {
  dplyr::case_when(
    no(a[["1.2"]]) ~ "High",
    no_info(a[["1.2"]]) & yes(a[["1.3"]]) ~ "High",
    no_info(a[["1.2"]]) ~ "Some concerns",
    no(a[["1.1"]]) ~ "Some concerns",
    yes(a[["1.3"]]) ~ "Some concerns",
    .default = "Low")
}


#' Internal: domain 1b, timing of identification or recruitment (cluster trials)
#'
#' @noRd
rob2_d1b <- function(a) {
  dplyr::case_when(
    yes(a[["1b.1"]]) ~ "Low",
    yes(a[["1b.2"]]) ~ "High",
    no(a[["1b.2"]]) & yes(a[["1b.3"]]) ~ "Some concerns",
    no(a[["1b.2"]]) ~ "Low",
    yes(a[["1b.3"]]) ~ "High",
    .default = "Some concerns")
}


#' Internal: domain S, period and carryover effects (crossover trials)
#'
#' @noRd
rob2_ds <- function(a) {
  dplyr::case_when(
    no(a[["s.3"]]) ~ "High",
    no_info(a[["s.3"]]) ~ "Some concerns",
    yes(a[["s.1"]]) ~ "Low",
    yes(a[["s.2"]]) ~ "Low",
    .default = "Some concerns")
}


#' Internal: domain 2, deviations from intended interventions (effect of assignment)
#'
#' @noRd
rob2_d2_assignment <- function(a, designs) {
  participants <- dplyr::case_when(
    designs == "cluster" & no(a[["2.1a"]]) ~ "N",
    designs == "cluster" ~ dplyr::coalesce(a[["2.1b"]], a[["2.1"]]),
    .default = a[["2.1"]])
  part_1 <- dplyr::case_when(
    no(participants) & no(a[["2.2"]]) ~ "Low",
    no(a[["2.3"]]) ~ "Low",
    no_info(a[["2.3"]]) ~ "Some concerns",
    no(a[["2.4"]]) ~ "Some concerns",
    yes(a[["2.5"]]) ~ "Some concerns",
    .default = "High")
  part_2 <- dplyr::case_when(
    yes(a[["2.6"]]) ~ "Low",
    no(a[["2.7"]]) ~ "Some concerns",
    .default = "High")
  rob2_worst(list(part_1, part_2))
}


#' Internal: domain 2, deviations from intended interventions (effect of adhering)
#'
#' Questions 2.3-2.5 are "if applicable": empty answers mean not applicable.
#'
#' @noRd
rob2_d2_adhering <- function(a, designs) {
  participants <- dplyr::case_when(
    designs == "cluster" & is.na(a[["2.1"]]) & no(a[["2.1a"]]) ~ "N",
    designs == "cluster" & is.na(a[["2.1"]]) ~ a[["2.1b"]],
    .default = a[["2.1"]])
  aware <- !(no(participants) & no(a[["2.2"]]))
  balanced <- !aware | yes(a[["2.3"]]) | is.na(a[["2.3"]])
  problems <- !((no(a[["2.4"]]) | is.na(a[["2.4"]])) & (no(a[["2.5"]]) | is.na(a[["2.5"]])))
  dplyr::case_when(
    balanced & !problems ~ "Low",
    yes(a[["2.6"]]) ~ "Some concerns",
    .default = "High")
}


#' Internal: domain 3, missing outcome data
#'
#' @noRd
rob2_d3 <- function(a, designs) {
  complete <- dplyr::if_else(
    designs == "cluster",
    yes(dplyr::coalesce(a[["3.1a"]], a[["3.1"]])) & yes(dplyr::coalesce(a[["3.1b"]], a[["3.1"]])),
    yes(a[["3.1"]]))
  dplyr::case_when(
    complete ~ "Low",
    yes(a[["3.2"]]) ~ "Low",
    no(a[["3.3"]]) ~ "Low",
    no(a[["3.4"]]) ~ "Some concerns",
    .default = "High")
}


#' Internal: domain 4, measurement of the outcome
#'
#' In cluster trials, 4.3a asks whether assessors knew a trial was taking place.
#'
#' @noRd
rob2_d4 <- function(a, designs) {
  base <- dplyr::if_else(no(a[["4.2"]]), "Low", "Some concerns")
  aware_of_trial <- designs != "cluster" | !no(a[["4.3a"]])
  aware_of_intervention <- dplyr::if_else(designs == "cluster", dplyr::coalesce(a[["4.3b"]], a[["4.3"]]), a[["4.3"]])
  dplyr::case_when(
    yes(a[["4.1"]]) | yes(a[["4.2"]]) ~ "High",
    !aware_of_trial ~ base,
    no(aware_of_intervention) ~ base,
    no(a[["4.4"]]) ~ base,
    no(a[["4.5"]]) ~ "Some concerns",
    .default = "High")
}


#' Internal: domain 5, selection of the reported result
#'
#' @noRd
rob2_d5 <- function(a, designs) {
  q54 <- dplyr::if_else(designs == "crossover", a[["5.4"]], "N")
  dplyr::case_when(
    yes(a[["5.2"]]) | yes(a[["5.3"]]) | yes(q54) ~ "High",
    no_info(a[["5.2"]]) | no_info(a[["5.3"]]) | no_info(q54) ~ "Some concerns",
    yes(a[["5.1"]]) ~ "Low",
    .default = "Some concerns")
}
