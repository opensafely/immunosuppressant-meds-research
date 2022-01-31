# ********************************************************************
# ********************************************************************
# FILE NAME:		 make_forest_plots_with_3_models_ethnicity.R
# 
# AUTHORS:				Kate Mansfield and Nick Kennedy
# VERSION:				v1
# DATE VERSION CREATED: 	2021-12-14
# DESCRIPTION OF FILE:	Produce forest plots for IMID analyses stratified by ethnicity
# ********************************************************************
# ********************************************************************


library(forestplot)
library(tidyverse)
if (basename(getwd()) == "r-immunosuppressant-meds-research") {
  setwd("../..")
}
if (!(basename(getwd()) %in% c("workspace", "immunosuppressant-meds-research"))) {
  cat("Working directory:", getwd())
  stop("Folder structure seems wrong")
}
csv_files <- list.files("output/data", pattern = "^csv_.*ethnicity_vs_white\\.csv", full.names = TRUE) %>%
  str_subset("spline", negate = TRUE)

model_col_types <- cols(
  cohort = col_character(),
  model = col_character(),
  failure = col_character(),
  ptime_1 = col_double(),
  events_1 = col_double(),
  rate_1 = col_double(),
  ptime_2 = col_double(),
  events_2 = col_double(),
  rate_2 = col_double(),
  ptime_3 = col_double(),
  events_3 = col_double(),
  rate_3 = col_double(),
  ptime_4 = col_double(),
  events_4 = col_double(),
  rate_4 = col_double(),
  ptime_5 = col_double(),
  events_5 = col_double(),
  rate_5 = col_double(),
  hr_2 = col_double(),
  lc_2 = col_double(),
  uc_2 = col_double(),
  hr_3 = col_double(),
  lc_3 = col_double(),
  uc_3 = col_double(),
  hr_4 = col_double(),
  lc_4 = col_double(),
  uc_4 = col_double(),
  hr_5 = col_double(),
  lc_5 = col_double(),
  uc_5 = col_double()
)

do_sdc <- function(data) {
  data %>% 
    pivot_longer(matches("\\d$"), names_to = c(".value", "ethnicity"), names_pattern = "(.*)_(.*)") %>% 
    # First fix SDC for numbers between 1 and 5 as well as those where icuordeath - death is between 1 and 5
    group_by(
      cohort, model, ethnicity
    ) %>% 
    mutate(
      across(
        c(rate, events),
        ~case_when(
          between(events, 1, 5) ~ NA_real_,
          failure == "icuordeath" & between(events[failure == "icuordeath"] - events[failure == "died"], 1, 5) ~ -1,
          TRUE ~ .x
        )
      )
    ) %>% 
    ungroup()
}

model_outputs <- map_dfr(csv_files, read_csv, col_types = model_col_types) %>%
  do_sdc() %>% 
  mutate(ethnicity = factor(ethnicity, levels = 1:5, labels = c("White", "South Asian", "Black", "Mixed", "Other")))
write_csv(model_outputs, "output/data/merged_csv_normal_ethnicity_vs_white.csv")

source("analysis/r-immunosuppressant-meds-research/imr_fplot.R")

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

export_fplot_svg <- function(fplot_outcome, outcome_name) {
  svg(sprintf("output/figures/forest_plot_ethnicity_vs_white_%s.svg", fplot_outcome), width = 12, height = 20)
  imr_fplot(
    model_outputs %>% filter(failure == fplot_outcome),
    ref_exposure_name = "White",
    exposures = levels(model_outputs$ethnicity) %>% set_names(., .),
    exposure_var = ethnicity,
    exposure_label = "Ethnicity",
    groups = c("All immune-mediated inflammatory diseases" = "imid",
               "Inflammatory joint disease" = "joint",
               "Inflammatory skin disease" = "skin",
               "Inflammatory bowel disease" = "bowel"),
    models = c("Minimally adjusted" = "agesex",
               "Confounder adjusted (IMID)" = "adjusted_imid_conf",
               "Mediator adjusted (IMID)" = "adjusted_imid_med"),
    group_var = cohort,
    group_label = "Cohort",
    ref_pop_called_comparator = FALSE,
    # clip axis
    clip = c(0.2, 7),
    # specified positions for xticks
    xticks = c(0.2, 0.5, 1, 2, 5, 7)
  )
  dev.off()
}

iwalk(
  c("COVID-19 death" = "died",
    "COVID-19 ICU/death" = "icuordeath",
    "COVID-19 hospitalisation" = "hospital"),
  export_fplot_svg
)
