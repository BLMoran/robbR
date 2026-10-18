#' Example risk of bias datasets
#'
#' Fictional risk of bias assessments for each supported tool. Each "study" is
#' a film character, with the character's surname as `Author` and the film's
#' release year as `Year`:
#'
#' * `rob2_data`: RoB 2 for individually randomised parallel-group trials,
#'   characters played by Anne Hathaway, with `Subgroup` by genre.
#' * `clarity_data`: CLARITY (all 12 domains), characters played by Anne
#'   Hathaway. Includes cluster (`D11`) and cluster crossover (`D12`) trials;
#'   these domains are `NA` for other trials.
#' * `robins_i_data`: ROBINS-I V2, characters played by Bill Murray.
#' * `robins_e_data`: ROBINS-E, characters played by Bill Murray.
#' * `quadas2_data`: QUADAS-2, characters played by Adam Sandler.
#' * `rob_nma_data`: RoB NMA with ROBIS domains 1-3, characters played by Adam
#'   Sandler.
#' * `probast_data`: PROBAST, characters played by Emily Blunt.
#' * `probast_ai_data`: PROBAST+AI, characters played by Emily Blunt, with
#'   `Subgroup` separating model development and evaluation.
#' * `rob2_sq_data`: answers to the RoB 2 signalling questions for 7 trials
#'   (characters played by Anne Hathaway): 3 parallel-group, 2
#'   cluster-randomised and 2 crossover trials, with `design` giving the
#'   design. Columns are named as in the cribsheets (`1.1`, `1b.1`, `2.1a`,
#'   ..., `S.3`), with the crossover questions `S.1`-`S.3` last. Questions
#'   skipped by the algorithm are `NA`. Use with [rob2_algorithm()].
#'
#' Overall judgements are not included (except `Conclusions` in
#' `rob_nma_data`), so they are derived by [rob_plot()] and [rob_summary()],
#' or by [rob2_algorithm()] for `rob2_sq_data`.
#'
#' @format Tibbles with one row per study:
#' \describe{
#'   \item{Author}{Character surname, used as the study label.}
#'   \item{Year}{Release year of the film.}
#'   \item{Subgroup}{Subgroup (`rob2_data` and `probast_ai_data` only).}
#'   \item{weight}{Study weight, summing to 1 (not in `rob_nma_data`,
#'     `probast_data` or `probast_ai_data`).}
#'   \item{D1, D2, ...}{Domain judgements. See [rob_plot()] for the domains of
#'     each tool.}
#'   \item{R1-R3}{ROBIS domain judgements (`rob_nma_data` only).}
#'   \item{A1-A3}{Applicability judgements (`probast_data` and
#'     `probast_ai_data` only).}
#'   \item{Conclusions}{Concerns about the authors' conclusions
#'     (`rob_nma_data` only).}
#' }
#'
#' @source Fictional data for illustration.
#'
#' @examples
#' rob_plot(rob2_data, add_rob_legend = TRUE)
#' rob_summary(robins_i_data, weight = weight, rob_tool = "robins_i")
#'
#' rob2_sq_data |>
#'   rob2_algorithm(design = design) |>
#'   rob_plot(add_rob_legend = TRUE)
#'
#' @name rob_datasets
NULL

#' @rdname rob_datasets
"rob2_data"

#' @rdname rob_datasets
"robins_i_data"

#' @rdname rob_datasets
"robins_e_data"

#' @rdname rob_datasets
"quadas2_data"

#' @rdname rob_datasets
"clarity_data"

#' @rdname rob_datasets
"rob_nma_data"

#' @rdname rob_datasets
"probast_data"

#' @rdname rob_datasets
"probast_ai_data"

#' @rdname rob_datasets
"rob2_sq_data"
