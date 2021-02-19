library(tidyverse)
hc_drug_names <- read_csv("drug_name_unique.csv", col_types = cols(.default = col_character()))
drug_mapping <- read_csv("druglist_mapping.csv")
drug_mapping_regex <- drug_mapping %>% 
  group_by(new_clean_drug) %>% 
  summarise(
    drug_regex = paste(old_drug_name, collapse = "|")
  )

hc_mapped <- pmap_dfc(
  drug_mapping_regex,
  function(new_clean_drug, drug_regex) {
    tibble(!!new_clean_drug := str_detect(hc_drug_names$DrugName, regex(drug_regex, ignore_case = TRUE)))
  }
) %>% 
  bind_cols(olddrugname = hc_drug_names$DrugName, .)

check_doubles <- hc_mapped %>% 
  filter(rowSums(select(., -old_drug_name)) > 1)

if (nrow(check_doubles) > 0) {
  stop(paste0("The following have more than one drug name match: ", paste0(check_doubles$olddrugname, collapse = ", ")))
}

hc_mapped_named <- hc_mapped %>% 
  pivot_longer(-olddrugname, names_to = "drug", values_to = "present") %>% 
  filter(present) %>% 
  select(-present)
  
hc_split <- split(hc_mapped_named$olddrugname, str_replace_all(hc_mapped_named$drug, " ", "-"))
iwalk(hc_split, ~write_lines(c("olddrugname", .x), sprintf("crossimid-%s-drug-names.csv", .y)))

hc_metadata <- drug_mapping %>%
  group_by(new_clean_drug) %>% 
  summarise(
    description = sprintf("This is a list of all the unique values from the Drug Name variable in the High Cost Drugs Dataset that relate to the prescribing of %s.", new_clean_drug),
    methodology = sprintf(
    "The values in this variable do not follow a coding system so the selection for this codelist is based on the drug name value, after converting all text to lower case, containing one or more of the following strings (these are the generic medicine name and brand names):
    
%s

All drug name values that contain at least one of the above strings are included in the %s group and assigned the VTM (virtual therapeutic moiety) code %s.",
    paste0("- ", old_drug_name, collapse = "\n"),
    new_clean_drug,
    vtm
    )
  )
