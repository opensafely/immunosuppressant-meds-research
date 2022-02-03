imr_fplot <- function(
  data,
  ref_exposure_name,
  exposures,
  groups,
  models,
  group_var = failure,
  group_label = "Outcome",
  exposure_var = cohort,
  exposure_label = "Exposure",
  ref_pop_called_comparator = TRUE,
  ...
) {
  group_var <- enquo(group_var)
  exposure_var <- enquo(exposure_var)
  if (ref_pop_called_comparator) {
    ref_pop <- data %>% 
      filter(model %in% models, !!exposure_var == exposures[1]) %>% 
      transmute(
        !!exposure_var := "ref_pop",
        model,
        !!group_var,
        ptime = ptime_comparator,
        events = events_comparator,
        rate = rate_comparator,
        hr = 1,
        lc = if_else(model == models[2], exp(-0.03), NA_real_),
        uc = if_else(model == models[2], exp(0.03), NA_real_)
      )
    data_for_fp <- data %>%
      rename(ptime = ptime_exposed, events = events_exposed, rate = rate_exposed) %>% 
      bind_rows(ref_pop)
  } else {
    data_for_fp <- data %>% 
      mutate(
        hr = if_else(!!exposure_var == ref_exposure_name, if_else(model == models[2], 1, NA_real_), hr),
        lc = if_else(!!exposure_var == ref_exposure_name, if_else(model == models[2], exp(-0.03), NA_real_), lc),
        uc = if_else(!!exposure_var == ref_exposure_name, if_else(model == models[2], exp(0.03), NA_real_), uc)
      )
  }

  data_for_fp <- data_for_fp %>%   
    mutate(
      Exposure = factor(!!exposure_var, levels = c("ref_pop", exposures), labels = c(ref_exposure_name, names(exposures))),
      Group = factor(!!group_var, levels = groups, labels = names(groups)),
      Model = factor(model, levels = models, labels = names(models))
    ) %>% 
    filter(
      !is.na(Exposure),
      !is.na(Group),
      !is.na(Model)
    ) %>% 
    arrange(Group, Exposure, Model)
  
  text_data_for_fp <- data_for_fp %>% 
    group_by(Group, Exposure) %>% 
    mutate(
      rate_ci = if (!is.na(events[1]) & events[1] > -1) {
        list(poisson.test(events[1], ptime[1])$conf.int)
      } else {
        list(rep(NA_real_, 2))
      }
    ) %>%
    summarise(
      `HR (95% CI)` = if((!!exposure_var)[1] == "ref_pop" | (!!exposure_var)[1] == ref_exposure_name) {
        "reference"
      } else {
        paste(sprintf("%0.2f (%0.2f, %0.2f)", hr, lc, uc), collapse = "\n")
      },
      `Number of events` = if (!is.na(events[1]) && events[1] > -1) {
          prettyNum(events[1], big.mark = ",")
        } else if (is.na(events[1])) {
          paste0("\U2264", 5)
        } else {
          "*"
        },
      `Rate (95% CI)\n(per 1,000 pyear)` = if (!is.na(events[1]) && events[1] > -1) {
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
    mutate(Group = if_else(duplicated(Group), "", as.character(Group))) %>% 
    rename(!!group_label := Group, !!exposure_label := Exposure)
  
  text_data_for_fp_list <- text_data_for_fp %>%
    imap(~c(.y, as.character(.x)))
  
  numeric_data_for_fp <- data_for_fp %>% 
    select(Group, Exposure, Model, hr, lc, uc) %>% 
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
    bind_rows(tibble(Group = NA, is_summary = TRUE, horiz_line = list(NULL)), .)
  
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
