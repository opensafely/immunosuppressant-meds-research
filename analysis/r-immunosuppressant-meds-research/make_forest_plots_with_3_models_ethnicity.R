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
library(svglite)
if (basename(getwd()) == "r-immunosuppressant-meds-research") {
  setwd("../..")
}
if (!(basename(getwd()) %in% c("workspace", "immunosuppressant-meds-research"))) {
  cat("Working directory:", getwd())
  stop("Folder structure seems wrong")
}
csv_files <- list.files("output/data", pattern = "^csv_.*ethnicity_.\\.csv", full.names = TRUE) %>%
  str_subset("spline", negate = TRUE)

model_col_types <- cols(
  cohort = col_character(),
  model = col_character(),
  failure = col_character(),
  ptime_exposed = col_double(),
  events_exposed = col_double(),
  rate_exposed = col_double(),
  ptime_comparator = col_double(),
  events_comparator = col_double(),
  rate_comparator = col_double(),
  hr = col_double(),
  lc = col_double(),
  uc = col_double(),
  ethnicity = col_character()
)

do_sdc <- function(data) {
  data %>% 
    # First fix SDC for numbers between 1 and 5 as well as those where icuordeath - death is between 1 and 5
    group_by(
      cohort, model, ethnicity
    ) %>% 
    mutate(
      across(
        c(rate_exposed, events_exposed),
        ~case_when(
          between(events_exposed, 1, 5) ~ NA_real_,
          failure == "icuordeath" & between(events_exposed[failure == "icuordeath"] - events_exposed[failure == "died"], 1, 5) ~ -1,
          TRUE ~ .x
        )
      )
    ) %>% 
    ungroup() %>% 
    # Then fix SDC for across ethnicities since the totals are also displayed in a separate figure
    group_by(cohort, model, failure) %>% 
    mutate(
      across(
        c(rate_exposed, events_exposed),
        ~case_when(
          sum(is.na(events_exposed) | events_exposed == -1) == 1 &
            row_number() == which.min(abs(events_exposed) / !(is.na(events_exposed) | events_exposed == -1)) ~ -1,
          TRUE ~ .x
        )
      )
    ) %>%
    ungroup()
}

model_outputs <- map_dfr(csv_files, read_csv, col_types = model_col_types) %>% 
  do_sdc() %>% 
  mutate(
    ethnicity_label = factor(ethnicity, levels = c(1:5, "u"), labels = c("White", "South Asian", "Black", "Mixed", "Other", "Unknown"))
  )
write_csv(model_outputs, "output/data/merged_csv_normal_ethnicity.csv")

csv_files_ho <- list.files("output/data", pattern = "^csvhaemonc_.*ethnicity_.\\.csv", full.names = TRUE) %>%
  str_subset("spline", negate = TRUE)

model_outputs_ho <- map_dfr(csv_files_ho, read_csv, col_types = model_col_types) %>% 
  do_sdc()
write_csv(model_outputs_ho, "output/data/merged_csv_haemonc_ethnicity.csv")

source("analysis/r-immunosuppressant-meds-research/imr_fplot.R")

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

export_fplot_svg <- function(fplot_ethnicity) {
  svglite(sprintf("output/figures/forest_plot_vs_gen_pop_ethnicity_%s.svg", fplot_ethnicity), width = 12, height = 10)
  imr_fplot(
    model_outputs %>% filter(ethnicity == fplot_ethnicity),
    ref_exposure_name = "General population",
    exposures = c("All immune-mediated inflammatory diseases" = "imid",
                  "Inflammatory joint disease" = "joint",
                  "Inflammatory skin disease" = "skin",
                  "Inflammatory bowel disease" = "bowel"),
    groups = c("COVID-19 death" = "died",
                 "COVID-19 ICU/death" = "icuordeath",
                 "COVID-19 hospitalisation" = "hospital"),
    models = c("Minimally adjusted" = "agesex",
               "Confounder adjusted (IMID)" = "adjusted_imid_conf",
               "Mediator adjusted (IMID)" = "adjusted_imid_med"),
    # clip axis
    clip = c(0.2, 7),
    # specified positions for xticks
    xticks = c(0.2, 0.5, 1, 2, 5, 7)
  )
  dev.off()
}

# c("White", "Asian", "Black", "Mixed", "Other", "Unknown")
walk(c(1:5, "u"), export_fplot_svg)

model_outputs %>% 
  filter(
    model %in% c("agesex", "adjusted_imid_conf", "adjusted_imid_med"),
    failure %in% c("died", "icuordeath", "hospital")
  ) %>% 
  select(ethnicity, everything()) %>%
  write_csv("output/data/model_data_ethnicity.csv")

export_fplot_svg <- function(fplot_outcome, outcome_name) {
  svglite(sprintf("output/figures/forest_plot_vs_gen_pop_ethnicity_%s.svg", fplot_outcome), width = 12, height = 20)
  imr_fplot(
    model_outputs %>% filter(failure == fplot_outcome),
    ref_exposure_name = "General population",
    exposures = c("All immune-mediated inflammatory diseases" = "imid",
                  "Inflammatory joint disease" = "joint",
                  "Inflammatory skin disease" = "skin",
                  "Inflammatory bowel disease" = "bowel"),
    groups = levels(model_outputs$ethnicity_label) %>% set_names(., .),
    models = c("Minimally adjusted" = "agesex",
               "Confounder adjusted (IMID)" = "adjusted_imid_conf",
               "Mediator adjusted (IMID)" = "adjusted_imid_med"),
    group_var = ethnicity_label,
    group_label = "Ethnicity",
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
