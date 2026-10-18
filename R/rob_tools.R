#' Built-in risk of bias tools
#'
#' @return Character vector of built-in tool names.
#' @noRd
rob_tools <- function() {
  c("rob2", "robins_i", "robins_e", "quadas2", "clarity", "rob_nma", "probast", "probast_ai")
}


#' Get a built-in risk of bias tool specification
#'
#' @param rob_tool Tool name, one of `rob_tools()`:
#'   * `"rob2"`: RoB 2, including the cluster-randomized (`D1b`) and crossover
#'     (`DS`) variants.
#'   * `"robins_i"`: ROBINS-I V2 (November 2025).
#'   * `"robins_e"`: ROBINS-E (March 2024).
#'   * `"quadas2"`: QUADAS-2.
#'   * `"clarity"`: CLARITY tool for randomized trials.
#'   * `"rob_nma"`: RoB NMA, optionally with ROBIS domains 1-3.
#'   * `"probast"`: PROBAST (2019).
#'   * `"probast_ai"`: PROBAST+AI (2025).
#'
#' @return A `rob_spec` object.
#' @noRd
get_rob_spec <- function(rob_tool = "rob2") {
  rob_tool <- rlang::arg_match(rob_tool, rob_tools())
  switch(
    rob_tool,
    rob2 = spec_rob2(),
    robins_i = spec_robins_i(),
    robins_e = spec_robins_e(),
    quadas2 = spec_quadas2(),
    clarity = spec_clarity(),
    rob_nma = spec_rob_nma(),
    probast = spec_probast("probast", "PROBAST", "Participants", "Overall risk of bias"),
    probast_ai = spec_probast("probast_ai", "PROBAST+AI", "Participants and data sources", "Overall quality (development) / risk of bias (evaluation)"))
}


syn_low <- c("low", "low risk", "low risk of bias", "low concern", "low concerns")
syn_some <- c("some concerns", "some concern", "concerns")
syn_high <- c("high", "high risk", "high risk of bias", "high concern", "high concerns")
syn_unclear <- c("unclear", "unclear risk", "unclear risk of bias", "no information", "ni")
syn_low_except <- c(
  "low (except for concerns about uncontrolled confounding)",
  "low risk of bias (except for concerns about uncontrolled confounding)",
  "low risk of bias except for concerns about uncontrolled confounding",
  "low except for concerns about uncontrolled confounding",
  "low (except for uncontrolled confounding)",
  "low (except confounding)",
  "low except confounding")

robins_low_levels <- c(
  "Low" = "Low risk of bias",
  "Low (except confounding)" = "Low risk of bias (except for concerns about uncontrolled confounding)")


spec_rob2 <- function() {
  rob_spec(
    name = "rob2",
    study_label = "Trial",
    label = "RoB 2",
    domains = c(
      D1 = "Bias arising from the randomization process",
      D1b = "Bias arising from the timing of identification or recruitment of participants (cluster-randomized trials)",
      D2 = "Bias due to deviations from intended interventions",
      D3 = "Bias due to missing outcome data",
      D4 = "Bias in measurement of the outcome",
      D5 = "Bias in selection of the reported result",
      DS = "Bias arising from period and carryover effects (crossover trials)"),
    optional = c("D1b", "DS"),
    levels = c(Low = "Low risk of bias", "Some concerns" = "Some concerns", High = "High risk of bias"),
    severity = c(Low = 1L, "Some concerns" = 2L, High = 3L),
    synonyms = list(Low = syn_low, "Some concerns" = syn_some, High = syn_high))
}


spec_robins_i <- function() {
  rob_spec(
    name = "robins_i",
    label = "ROBINS-I V2",
    domains = c(
      D1 = "Bias due to confounding",
      D2 = "Bias in classification of interventions",
      D3 = "Bias in selection of participants into the study (or into the analysis)",
      D4 = "Bias due to missing data",
      D5 = "Bias in measurement of the outcome",
      D6 = "Bias in selection of the reported result"),
    levels = c(
      robins_low_levels,
      Moderate = "Moderate risk of bias",
      Serious = "Serious risk of bias",
      Critical = "Critical risk of bias"),
    severity = c(Low = 1L, "Low (except confounding)" = 2L, Moderate = 3L, Serious = 4L, Critical = 5L),
    synonyms = list(
      Low = syn_low,
      "Low (except confounding)" = syn_low_except,
      Moderate = c("moderate", "moderate risk", "moderate risk of bias"),
      Serious = c("serious", "serious risk", "serious risk of bias"),
      Critical = c("critical", "critical risk", "critical risk of bias")))
}


spec_robins_e <- function() {
  rob_spec(
    name = "robins_e",
    label = "ROBINS-E",
    domains = c(
      D1 = "Bias due to confounding",
      D2 = "Bias arising from measurement of the exposure",
      D3 = "Bias in selection of participants into the study (or into the analysis)",
      D4 = "Bias due to post-exposure interventions",
      D5 = "Bias due to missing data",
      D6 = "Bias arising from measurement of the outcome",
      D7 = "Bias in selection of the reported result"),
    levels = c(
      robins_low_levels,
      "Some concerns" = "Some concerns",
      High = "High risk of bias",
      "Very high" = "Very high risk of bias"),
    severity = c(Low = 1L, "Low (except confounding)" = 2L, "Some concerns" = 3L, High = 4L, "Very high" = 5L),
    synonyms = list(
      Low = syn_low,
      "Low (except confounding)" = syn_low_except,
      "Some concerns" = syn_some,
      High = syn_high,
      "Very high" = c("very high", "very high risk", "very high risk of bias")))
}


spec_quadas2 <- function() {
  rob_spec(
    name = "quadas2",
    label = "QUADAS-2",
    domains = c(
      D1 = "Patient selection",
      D2 = "Index test(s)",
      D3 = "Reference standard",
      D4 = "Flow and timing"),
    levels = c(Low = "Low risk of bias", Unclear = "Unclear risk of bias", High = "High risk of bias"),
    severity = c(Low = 1L, Unclear = 2L, High = 3L),
    synonyms = list(Low = syn_low, Unclear = syn_unclear, High = syn_high))
}


spec_clarity <- function() {
  rob_spec(
    name = "clarity",
    study_label = "Trial",
    label = "CLARITY",
    domains = c(
      D1 = "Allocation sequence adequately generated",
      D2 = "Allocation adequately concealed",
      D3 = "Patients blinded",
      D4 = "Healthcare providers blinded",
      D5 = "Data collectors blinded",
      D6 = "Outcome assessors blinded",
      D7 = "Data analysts blinded",
      D8 = "Missing outcome data infrequent",
      D9 = "No selective outcome reporting",
      D10 = "Free of other bias",
      D11 = "No selective enrolment within clusters (cluster trials)",
      D12 = "No changes between intervention and control periods (cluster cross-over trials)"),
    optional = c("D11", "D12"),
    always = c("D11", "D12"),
    overall = character(),
    overall_from = list(),
    levels = c(
      "Definitely low" = "Definitely low risk",
      "Probably low" = "Probably low risk",
      "Probably high" = "Probably high risk",
      "Definitely high" = "Definitely high risk"),
    severity = c("Definitely low" = 1L, "Probably low" = 2L, "Probably high" = 3L, "Definitely high" = 4L),
    synonyms = list(
      "Definitely low" = c("low", "definitely low"),
      "Probably low" = "probably low",
      "Probably high" = "probably high",
      "Definitely high" = c("high", "definitely high")))
}


spec_rob_nma <- function() {
  rob_spec(
    name = "rob_nma",
    study_label = "Review",
    label = "RoB NMA",
    domains = c(
      R1 = "ROBIS: Study eligibility criteria",
      R2 = "ROBIS: Identification and selection of studies",
      R3 = "ROBIS: Data collection and study appraisal",
      D1 = "Interventions and network geometry",
      D2 = "Effect modifiers",
      D3 = "Statistical synthesis"),
    optional = c("R1", "R2", "R3"),
    overall = c(Results = "Overall risk of bias in the NMA results", Conclusions = "Concerns about the authors' conclusions"),
    overall_from = list(Results = c("R1", "R2", "R3", "D1", "D2", "D3"), Conclusions = NULL),
    levels = c(Low = "Low risk of bias / no concerns", "Some concerns" = "Some concerns", Unclear = "Unclear", High = "High risk of bias"),
    severity = c(Low = 1L, "Some concerns" = 2L, Unclear = 2L, High = 3L),
    synonyms = list(Low = c(syn_low, "no concerns", "no concern"), "Some concerns" = syn_some, Unclear = syn_unclear, High = syn_high),
    spanners = list(ROBIS = c("R1", "R2", "R3"), "RoB NMA" = c("D1", "D2", "D3"), Overall = c("Results", "Conclusions")))
}


spec_probast <- function(name, label, participants, overall_label) {
  spanner_label <- if (name == "probast_ai") "Quality / risk of bias" else "Risk of bias"
  rob_spec(
    name = name,
    label = label,
    domains = c(
      D1 = participants,
      D2 = "Predictors",
      D3 = "Outcome",
      D4 = "Analysis",
      A1 = stringr::str_c("Applicability: ", stringr::str_to_lower(participants)),
      A2 = "Applicability: predictors",
      A3 = "Applicability: outcome"),
    optional = c("A1", "A2", "A3"),
    overall = c(Overall = overall_label, Applicability = "Overall applicability"),
    overall_from = list(Overall = c("D1", "D2", "D3", "D4"), Applicability = c("A1", "A2", "A3")),
    levels = c(Low = "Low risk / concern", Unclear = "Unclear", High = "High risk / concern"),
    severity = c(Low = 1L, Unclear = 2L, High = 3L),
    synonyms = list(Low = syn_low, Unclear = syn_unclear, High = syn_high),
    spanners = rlang::list2(
      !!spanner_label := c("D1", "D2", "D3", "D4", "Overall"),
      Applicability = c("A1", "A2", "A3", "Applicability")))
}
