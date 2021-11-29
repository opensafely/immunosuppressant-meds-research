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
csv_files <- list.files("output/data", pattern = "^csv_.*\\.csv", full.names = TRUE)
model_outputs <- map_dfr(csv_files, read_csv) %>% 
  mutate(
    events_exposed = if_else(between(events_exposed, 1, 5), NA_real_, events_exposed),
    rate_exposed = if_else(is.na(events_exposed), NA_real_, rate_exposed),
  )
write_csv(model_outputs, "output/data/merged_csv_normal.csv")

imr_fplot <- function(
  data,
  ref_exposure_name,
  exposures,
  outcomes,
  models,
  ...
) {
  ref_pop <- data %>% 
    filter(model %in% models, cohort == exposures[1]) %>% 
    transmute(
      cohort = "ref_pop",
      model,
      failure,
      ptime = ptime_comparator,
      events = events_comparator,
      rate = rate_comparator,
      hr = 1,
      lc = if_else(model == models[1], exp(-0.03), NA_real_),
      uc = if_else(model == models[1], exp(0.03), NA_real_)
    )
  
  data_for_fp <- data %>%
    rename(ptime = ptime_exposed, events = events_exposed, rate = rate_exposed) %>% 
    bind_rows(ref_pop) %>% 
    mutate(
      Exposure = factor(cohort, levels = c("ref_pop", exposures)) %>% 
        fct_recode(
          !!(ref_exposure_name) := "ref_pop",
          !!!exposures
        ),
      Outcome = factor(failure, levels = outcomes) %>% 
        fct_recode(
          !!!outcomes
        ),
      Model = factor(model, models) %>% 
        fct_recode(
          !!!models
        )
    ) %>% 
    filter(
      !is.na(Exposure),
      !is.na(Outcome),
      !is.na(Model)
    ) %>% 
    arrange(Outcome, Exposure, Model)
  
  text_data_for_fp <- data_for_fp %>% 
    group_by(Outcome, Exposure) %>% 
    mutate(
      rate_ci = if (!is.na(events[1])) {
        list(poisson.test(events[1], ptime[1])$conf.int)
      } else {
        list(rep(NA_real_, 2))
      }
    ) %>%
    summarise(
      `HR (95% CI)` = if(cohort[1] == "ref_pop") {
        "reference"
      } else {
        paste(sprintf("%0.2f (%0.2f, %0.2f)", hr, lc, uc), collapse = "\n")
      },
      `Number of events` = if (!is.na(events[1])) prettyNum(events[1], big.mark = ",") else "\U22645",
      `Rate (95% CI)\n(per 1,000 pyear)` = if (!is.na(rate_ci[[1]][1])) {
        sprintf(
          "%0.2f (%0.2f, %0.2f)",
          1000 * rate[1],
          1000 * rate_ci[[1]][1],
          1000 * rate_ci[[1]][2]
        )
      } else {
        "-"
      },
      .groups = "drop"
    ) %>% 
    mutate(Outcome = if_else(duplicated(Outcome), "", as.character(Outcome)))
  
  text_data_for_fp_list <- text_data_for_fp %>%
    imap(~c(.y, as.character(.x)))
  
  numeric_data_for_fp <- data_for_fp %>% 
    select(Outcome, Exposure, Model, hr, lc, uc) %>% 
    pivot_wider(names_from = Model, values_from = hr:uc) %>%
    mutate(
      is_summary = Exposure == ref_exposure_name,
      horiz_line = map(
        Exposure == ref_exposure_name,
        ~gpar(
          lwd = 1,
          col = if (.x) "#919191" else "#e8e8e8",
          lty = if (.x) 1 else 2
        )
      )
    ) %>% 
    bind_rows(tibble(Outcome = NA, is_summary = TRUE, horiz_line = list(NULL)), .)
  
  forestplot(
    text_data_for_fp_list,
    mean = numeric_data_for_fp %>% select(starts_with("hr")),
    lower = numeric_data_for_fp %>% select(starts_with("lc")),
    upper = numeric_data_for_fp %>% select(starts_with("uc")),
    # makes colours for models different shades light grey to black
    col = fpColors(
      zero = "#707070",
      box = c("#C0C0C0", "black"),
      summary = "#707070"
    ),
    fn.ci_norm = c(fpDrawCircleCI, fpDrawDiamondCI),
    # estimation indicators are circles and diamonds
    # set the zero line at 1
    zero = 1,
    boxsize = .15,
    line.margin = .3,
    graphwidth = unit(2, "inches"),
    colgap = unit(2, "mm"),
    legend = levels(data_for_fp$Model),
    legend_args = fpLegend(
      # specify position of legend
      pos = list(x = .5, y = 1),
      # specify colour of outline and background
      gp = gpar(col = "#CCCCCC", fill = "#F9F9F9")
    ),
    txt_gp = fpTxtGp(
      legend = gpar(cex = .6),
      ticks = gpar(cex = .7),
      xlab = gpar(cex = .9),
      summary = gpar(cex = .8),
      label = rep(list(gpar(cex = .9), gpar(cex = .8)), c(2, 3))
    ),
    xlog = TRUE,
    xlab = "HR (95% CI)",
    # Use "l", "c", or "r" for left, center, or right aligned
    align = c("l", "l", "c", "c", "c"),
    # vector with logical values representing if value is a summary val (will have diff font style)
    is.summary = numeric_data_for_fp$is_summary,
    graph.pos = 3,
    hrzl_lines = c(numeric_data_for_fp$horiz_line, list(NULL)),
    ...
  )
}

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
svg("output/figures/forest_plot_vs_gen_pop.svg", width = 12, height = 8)
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
             "Confounder adjusted" = "adjusted_imid_conf"),
  # clip axis
  clip = c(0.7, 2),
  # specified positions for xticks
  xticks = c(0.7, 1, 1.5, 2)
)
dev.off()

svg("output/figures/forest_plot_vs_standard_systemic.svg", width = 12, height = 12)
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
  models = c("Minimally adjusted" = "agesex",
             "Confounder adjusted" = "adjusted_drugs_conf"),
  clip =c(0.4, 5.5), # clip axis
  xticks = c(0.5, 1, 2, 4), # specified positions for xticks
)
dev.off()
