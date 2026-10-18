# Create Risk of Bias Plot

Creates a publication-ready risk of bias plot using gt tables, for
single studies or subgroup analyses.

## Usage

``` r
rob_plot(
  data,
  studyvar = Author,
  year = Year,
  group = Subgroup,
  effect = yi,
  rob_tool = "rob2",
  sort_studies_by = c("author", "year", "effect"),
  subgroup = FALSE,
  sort_subgroup_by = "alphabetical",
  show_overall = TRUE,
  derive_overall = FALSE,
  add_rob_legend = FALSE,
  study_label = NULL,
  font = NULL,
  title = NULL,
  title_align = c("left", "center", "centre", "right"),
  subtitle = NULL
)
```

## Arguments

- data:

  A data frame with a study, year and domain columns for the chosen
  `rob_tool` (see Details). Judgements are standardised (e.g. "low risk"
  -\> "Low"); `NA` -\> "Not applicable". Judgements not recognised by
  the tool are shown as blank cells, with a warning.

- studyvar, year:

  \<[`data-masking`](https://dplyr.tidyverse.org/reference/dplyr_data_masking.html)\>
  Study label and year columns.

- group:

  \<[`data-masking`](https://dplyr.tidyverse.org/reference/dplyr_data_masking.html)\>
  Subgroup column, used when `subgroup = TRUE`.

- effect:

  \<[`data-masking`](https://dplyr.tidyverse.org/reference/dplyr_data_masking.html)\>
  Effect size column, used when sorting by `"effect"`.

- rob_tool:

  Risk of bias tool: `"rob2"` (default), `"robins_i"`, `"robins_e"`,
  `"quadas2"`, `"clarity"`, `"rob_nma"`, `"probast"`, or `"probast_ai"`.

- sort_studies_by:

  How to sort studies: `"author"` (default), `"year"`, or `"effect"`.

- subgroup:

  Logical. Create a subgroup plot? (default: `FALSE`).

- sort_subgroup_by:

  Subgroup ordering: `"alphabetical"` (default), `"effect"`, or a
  character vector of subgroup names in the desired order.

- show_overall:

  Logical. Show the overall column(s)? (default: `TRUE`). Overall
  columns absent from `data` are derived from the domains (worst
  judgement).

- derive_overall:

  Logical. Always re-derive overall column(s) from the domains,
  overwriting supplied values? (default: `FALSE`).

- add_rob_legend:

  Logical. Add a legend? (default: `FALSE`).

- study_label:

  Header for the study column. Defaults to `"Trial"` for randomised
  trial tools (`"rob2"`, `"clarity"`), `"Review"` for `"rob_nma"`, and
  `"Study"` otherwise.

- font:

  Font family.

- title, subtitle:

  Plot title and subtitle.

- title_align:

  Title alignment: `"left"` (default), `"center"`/`"centre"`, or
  `"right"`.

## Value

A patchwork composition of the risk of bias table (and legend).

## Details

Domain columns by tool (optional columns in brackets are shown only if
present; `NA` rows are shown as "Not applicable"):

- rob2:

  D1, (D1b), D2-D5, (DS), Overall. D1b: timing of identification or
  recruitment (cluster-randomized trials). DS: period and carryover
  effects (crossover trials). Leave `NA` for other designs.

- robins_i:

  ROBINS-I V2: D1-D6, Overall. Low / Low (except confounding) / Moderate
  / Serious / Critical.

- robins_e:

  D1-D7, Overall. Low / Low (except confounding) / Some concerns / High
  / Very high.

- quadas2:

  D1-D4, Overall. Low / Unclear / High.

- clarity:

  D1-D10, (D11), (D12). No overall judgement. D11/D12 (cluster trials)
  are always shown.

- rob_nma:

  (R1-R3: ROBIS domains 1-3), D1-D3, Results, Conclusions. `Conclusions`
  is never derived and is shown only if supplied.

- probast, probast_ai:

  D1-D4, (A1-A3: applicability), Overall, Applicability. Low / Unclear /
  High. For PROBAST+AI, use the subgroup column (e.g. "Development",
  "Evaluation") to separate quality and risk of bias assessments.

## Examples

``` r
if (FALSE) { # \dontrun{
rob_data <- tibble::tibble(
  Author = c("Smith", "Jones", "Brown", "Lee"),
  Year = c(2020, 2021, 2022, 2023),
  D1 = c("Low", "High", "Some concerns", "Low"),
  D1b = c(NA, "Some concerns", NA, NA),
  DS = c(NA, NA, NA, "Low"),
  D2 = c("Low", "Low", "High", "Low"),
  D3 = c("Some concerns", "Low", "Low", "Low"),
  D4 = c("Low", "Low", "Low", "Some concerns"),
  D5 = c("Low", "Some concerns", "Low", "Low"))

rob_plot(rob_data, add_rob_legend = TRUE)
rob_plot(rob_data, show_overall = FALSE)

robins_data <- tibble::tibble(
  study = c("Ahmed", "Baker"),
  pub_year = c(2019, 2024),
  D1 = c("Low (except confounding)", "Serious"),
  D2 = c("Low", "Moderate"),
  D3 = c("Low", "Low"),
  D4 = c("Moderate", "Critical"),
  D5 = c("Low", "Low"),
  D6 = c("Low", "Moderate"))

rob_plot(robins_data, studyvar = study, year = pub_year, rob_tool = "robins_i", add_rob_legend = TRUE)
} # }
```
