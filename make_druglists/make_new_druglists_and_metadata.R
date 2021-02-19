library(tidyverse)
library(glue)

hc_drug_names <- read_csv("drug_name_unique.csv", col_types = cols(.default = col_character())) %>%
  mutate(DrugName = tolower(DrugName)) %>% 
  distinct(DrugName)
drug_mapping <- read_csv("druglist_mapping.csv")
drug_mapping_regex <- drug_mapping %>% 
  group_by(new_clean_drug) %>% 
  summarise(
    drug_regex = paste(old_drug_name, collapse = "|")
  )

hc_mapped <- pmap_dfr(
  drug_mapping_regex,
  function(new_clean_drug, drug_regex) {
    tibble(
      drug = new_clean_drug,
      olddrugname = str_subset(unique(hc_drug_names$DrugName), regex(drug_regex, ignore_case = TRUE)))
  }
)

check_doubles <- hc_mapped %>% 
  group_by(olddrugname) %>% 
  filter(n() > 1)

if (nrow(check_doubles) > 0) {
  stop(paste0("The following have more than one drug name match: ", paste0(check_doubles$olddrugname, collapse = ", ")))
}

hc_mapped %>% 
  group_by(drug = str_replace_all(hc_mapped$drug, " ", "-")) %>% 
  group_walk(~write_csv(.x, glue("crossimid-{.y$drug}-drug-names.csv")))

hc_metadata <- drug_mapping %>%
  group_by(drug_name = new_clean_drug, vtm) %>% 
  summarise(
    drug_terms = paste0("- ", old_drug_name, collapse = "\n")
  ) %>% 
  mutate(
    title = glue("*High cost drug codes* {drug_name}"),
    description = glue(
      "This is a list of all the unique values from the Drug Name variable in",
      "the High Cost Drugs Dataset that relate to the prescribing of {drug_name}."),
    methodology = glue(
      "The values in this variable do not follow a coding system so the selection",
      "for this codelist is based on the drug name value, after converting all",
      "text to lower case, containing one or more of the following strings (these",
      "are the generic medicine name and brand names):\n\n{drug_terms}",
      "\n\nAll drug name values that contain at least one of the above strings are",
      "included in the {drug_name} group and assigned the VTM (virtual therapeutic",
      "moiety) code {vtm}."),
    gh_body = glue(
      "## Description\n\n{description}\n\n",
      "## Methodology\n\n{methodology}"
    )
  )

update_gh <- FALSE
if (update_gh) {
  repos <- "opensafely/immunosuppressant-meds-research"

  issues <- gh::gh(glue("GET /repos/{repos}/issues"), per_page = 50)
  
  issues_hcd <- issues %>%
    map_dfr(
      ~tibble(number = .x$number, title = .x$title)
    ) %>% 
    filter(str_detect(title, "High cost")) %>% 
    mutate(
      drug_name = str_extract(title, "(?<=codes\\* ).*")
    )
  
  new_issues <- hc_metadata %>% anti_join(issues_hcd, by = "title")
  
  if (nrow(new_issues) > 0) {
    
  }
  
  add_refs <- function(number, drug_name, title) {
    ref_body <- glue(
      "## References\n\n",
      "- [GitHub issue: {title}](https://github.com/{repos}/issues/{number})\n",
      "- [Script used to produce codelist](https://github.com/{repos}/tree/master/make_druglists/make_new_druglists_and_metadata.R)\n",
      "- [Draft codelist: {drug_name}](https://github.com/{repos}/tree/master/crossimid-codelists/crossimid-{drug_name}-drug-names.csv)\n"
    )
    gh(glue("POST /repos/{repos}/issues/{number}/comments"), body = ref_body)
  }
}

unmapped <- hc_drug_names %>%
  anti_join(hc_mapped, by = c("DrugName" = "olddrugname"))

unmapped_words <- unmapped$DrugName %>% 
  tolower() %>% 
  str_split("[^a-z]") %>%
  unlist() %>% 
  unique() %>% 
  sort()

unmapped_mabs <- unmapped_words %>% 
  str_subset("mab")
