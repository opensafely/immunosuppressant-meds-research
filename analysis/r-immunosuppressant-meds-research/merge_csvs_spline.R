library(tidyverse)
if (basename(getwd()) == "r-immunosuppressant-meds-research") {
  setwd("../..")
}
if (!(basename(getwd()) %in% c("workspace", "immunosuppressant-meds-research"))) {
  cat("Working directory:", getwd())
  stop("Folder structure seems wrong")
}
csv_files <- list.files("output/data", pattern = "^csv_.*\\.csv", full.names = TRUE) %>%
  str_subset("spline")
model_outputs <- map_dfr(csv_files, read_csv) %>% 
  mutate(
    events_exposed = if_else(between(events_exposed, 1, 5), NA_real_, events_exposed),
    rate_exposed = if_else(is.na(events_exposed), NA_real_, rate_exposed),
  )
write_csv(model_outputs, "output/data/merged_csv_normal_spline.csv")

csv_files_ho <- list.files("output/data", pattern = "^csvhaemonc_.*\\.csv", full.names = TRUE) %>%
  str_subset("spline")
model_outputs_ho <- map_dfr(csv_files_ho, read_csv) %>% 
  mutate(
    events_exposed = if_else(between(events_exposed, 1, 5), NA_real_, events_exposed),
    rate_exposed = if_else(is.na(events_exposed), NA_real_, rate_exposed),
  )
write_csv(model_outputs_ho, "output/data/merged_csv_haemonc_spline.csv")
