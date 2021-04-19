library(tidyverse)
library(haven)
library(here)

imid <- read_dta(file = here::here("output", "data", "file_imid.dta")) %>%
  select(icu_admitted_date, icu_admit_date_covid, hospital_admission_date, 
         hosp_admit_date_covid, first_pos_test_sgss_date)

outcomes_check <- imid %>%
  mutate(icu_admit_flag = if_else(is.na(icu_admitted_date),0,1),
         icu_admit_covid_flag = if_else(is.na(icu_admit_date_covid),0,1),
         hosp_admit_flag = if_else(is.na(hospital_admission_date), 0, 1),
         hosp_admit_covid_flag = if_else(is.na(hosp_admit_date_covid), 0, 1),
         pos_test_flag = ifelse(is.na(first_pos_test_sgss_date), 0, 1)) %>%
  group_by(icu_admit_flag, icu_admit_covid_flag, hosp_admit_flag, hosp_admit_covid_flag, pos_test_flag) %>%
  summarise(count = n())

write.csv(outcomes_check, file = here::here("output", "data", "outcomes_check.csv"))

