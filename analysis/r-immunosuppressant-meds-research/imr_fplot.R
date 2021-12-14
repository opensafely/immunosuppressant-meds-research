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
      lc = if_else(model == models[2], exp(-0.03), NA_real_),
      uc = if_else(model == models[2], exp(0.03), NA_real_)
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
      Model = factor(model, levels=models) %>% 
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
      `Number of events` = if (!is.na(events[1])) {
          prettyNum(events[1], big.mark = ",")
        } else if (events[1] == -1) {
          "*"
        } else {
          paste0("\U2264", 5)
        },
      `Rate (95% CI)\n(per 1,000 pyear)` = if (!is.na(rate_ci[[1]][1])) {
        sprintf(
          "%0.2f (%0.2f, %0.2f)",
          1000 * rate[1],
          1000 * rate_ci[[1]][1],
          1000 * rate_ci[[1]][2]
        )
      } else if (events[1] == -1) {
        "-"
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
  
  shape_cols <- scales::brewer_pal(palette = "Dark2")(length(levels(data_for_fp$Model)))
  
  forestplot(
    text_data_for_fp_list,
    mean = numeric_data_for_fp %>% select(starts_with("hr")),
    lower = numeric_data_for_fp %>% select(starts_with("lc")),
    upper = numeric_data_for_fp %>% select(starts_with("uc")),
    # makes colours for models different shades light grey to black
    col = fpColors(
      zero = "#707070",
      box = shape_cols,
      summary = "#707070"
    ),
    fn.ci_norm = c(fpDrawCircleCI, fpDrawDiamondCI, fpDrawNormalCI),
    # estimation indicators are circles and diamonds
    # set the zero line at 1
    zero = 1,
    boxsize = .12,
    line.margin = 0.2,
    graphwidth = unit(2, "inches"),
    colgap = unit(2, "mm"),
    legend = levels(data_for_fp$Model),
    legend_args = fpLegend(
      # specify position of legend
      pos = list(x = .5, y = 0.98),
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
