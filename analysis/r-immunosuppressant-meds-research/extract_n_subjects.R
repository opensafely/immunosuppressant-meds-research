# Extract numbers of subjects from smcl files
library(tidyverse)
if (basename(getwd()) == "r-immunosuppressant-meds-research") {
  setwd("../..")
}
if (!(basename(getwd()) %in% c("workspace", "immunosuppressant-meds-research"))) {
  cat("Working directory:", getwd())
  stop("Folder structure seems wrong")
}
smcl_list <- list.files("logs", "\\.smcl$", full.names = TRUE)
subject_numbers <- smcl_list %>%
  map_dfr(
    ~read_lines(.x) %>% 
      str_subset("No. of subjects") %>%
      {tibble(
        file = .x,
        analysis = seq_len(length(.)),
        n_subjects = str_extract(., "(?<=No. of subjects\\D{0,99})[0-9,]+"),
        n_obs = str_extract(., "(?<=Number of obs\\D{0,99})[0-9,]+")
      )}
  )

write_csv(subject_numbers, "output/data/subject_numbers.csv")
