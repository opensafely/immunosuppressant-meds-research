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

process_smcl <- function(file_name) {
  txt <- read_lines(file_name)
  
  line_pairs <- which(str_detect(txt, "No\\. of subjects")) %>%
    map_chr(~paste(txt[.x + 0:1], collapse = " "))
    
  line_pairs %>% 
    str_subset("No\\. of subjects") %>% 
    {tibble(
      file = file_name,
      analysis = seq_len(length(.)),
      n_subjects = str_extract(., "(?<=No. of subjects\\D{0,99})[0-9,]+"),
      n_events = str_extract(., "(?<=No. of failures\\D{0,99})[0-9,]+")
    )}
}

subject_numbers <- smcl_list %>% map_dfr(process_smcl)

write_csv(subject_numbers, "output/data/subject_numbers.csv")
