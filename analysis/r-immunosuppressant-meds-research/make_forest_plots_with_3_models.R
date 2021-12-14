# ********************************************************************
# ********************************************************************
# FILE NAME:		 make_forest_plots.R
# 
# AUTHORS:				Kate Mansfield and Nick Kennedy
# VERSION:				v2
# DATE VERSION CREATED: 	2021-05-12
# DESCRIPTION OF FILE:	Produce a forest plot for IMID analyses
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

do_sdc <- function(data) {
  data %>% 
    group_by(
      cohort, model
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
    ungroup()
}

csv_files <- list.files("output/data", pattern = "^csv_.*\\.csv", full.names = TRUE) %>%
  str_subset("spline|ethnicity", negate = TRUE)
model_outputs <- map_dfr(csv_files, read_csv) %>% 
  do_sdc()
write_csv(model_outputs, "output/data/merged_csv_normal.csv")

csv_files_ho <- list.files("output/data", pattern = "^csvhaemonc_.*\\.csv", full.names = TRUE) %>%
  str_subset("spline|ethnicity", negate = TRUE)
model_outputs_ho <- map_dfr(csv_files_ho, read_csv) %>% 
  do_sdc()
write_csv(model_outputs_ho, "output/data/merged_csv_haemonc.csv")

source("analysis/r-immunosuppressant-meds-research/imr_fplot.R")

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
svg("output/figures/forest_plot_vs_gen_pop.svg", width = 12, height = 10)
imr_fplot(
  model_outputs,
  ref_exposure_name = "General population",
  exposures = c("All immune-mediated inflammatory diseases" = "imid",
                "Inflammatory joint disease" = "joint",
                "Inflammatory skin disease" = "skin",
                "Inflammatory bowel disease" = "bowel"),
  outcomes = c("COVID-19 death" = "died",
               "COVID-19 ICU/death" = "icuordeath",
               "COVID-19 hospitalisation" = "hospital"),
  models = c("Minimally adjusted" = "agesex",
             "Confounder adjusted (IMID)" = "adjusted_imid_conf",
             "Mediator adjusted (IMID)" = "adjusted_imid_med"),
  # clip axis
  clip = c(0.7, 2),
  # specified positions for xticks
  xticks = c(0.7, 1, 1.5, 2)
)
dev.off()

svg("output/figures/forest_plot_vs_standard_systemic.svg", width = 12, height = 16)
imr_fplot(
  model_outputs,
  ref_exposure_name = "Standard therapy",
  exposures = c("Targeted therapy" = "imiddrugcategory",
                "TNF inhibitor" = "standtnf",
                "IL-12/-23 inhibitor" = "standil23",
                "IL-17 inhibitor" = "standil17",
                "IL-6 inhibitor" = "standil6",
                "JAK inhibitor" = "standjaki", 
                "Rituximab" = "standritux",
                "Vedolizumab" = "standvedolizumab",
                "Abatacept" = "standabatacept"),
  outcomes = c("COVID-19 death" = "died",
               "COVID-19 ICU/death" = "icuordeath",
               "COVID-19 hospitalisation" = "hospital"),
  models = c("Minimally adjusted"="agesex",
             "Confounder adjusted (Drugs)" = "adjusted_drugs_conf",
             "Mediator adjusted (Drugs)"="adjusted_drugs_med"),
  clip =c(0.1, 5.5), # clip axis
  xticks = c(0.25, 0.5, 1, 2, 4), # specified positions for xticks
)
dev.off()
