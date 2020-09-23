from cohortextractor import (
    codelist_from_csv,
    codelist,
)


# OUTCOME CODELISTS
covid_identification = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)

covid_pos_primcare_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_pos_primcare_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3",
    column="CTV3ID",
)


# MEDICATIONS - EXPOSURES


# DEMOGRAPHIC CODELIST
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

# SMOKING CODELIST
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

unclear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

# CLINICAL CONDITIONS CODELISTS
crohns_disease_codes = codelist_from_csv(
    "codelists/crossimid-crohns-disease.csv", system="ctv3", column="CTV3ID",
)

ulcerative_colitis_codes = codelist_from_csv(
    "codelists/crossimid-ulcerative-colitis.csv", system="ctv3", column="CTV3ID",
)

inflammatory_bowel_disease_unclassified_codes = codelist_from_csv(
    "codelists/crossimid-inflammatory-bowel-disease-unclassified.csv", system="ctv3", column="CTV3ID",
)

psoriasis_codes = codelist_from_csv(
    "codelists/crossimid-psoriasis.csv", system="ctv3", column="CTV3ID",
)

psoriatic_arthritis_codes = codelist_from_csv(
    "codelists/crossimid-psoriatic-arthritis.csv", system="ctv3", column="CTV3ID",
)

rheumatoid_arthritis_codes = codelist_from_csv(
    "codelists/opensafely-rheumatoid-arthritis.csv", system="ctv3", column="CTV3ID",
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID",
)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", system="ctv3", column="CTV3ID",
)

hba1c_new_codes = codelist(["XaPbt", "Xaeze", "Xaezd"], system="ctv3")
hba1c_old_codes = codelist(["X772q", "XaERo", "XaERp"], system="ctv3")

hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension.csv", system="ctv3", column="CTV3ID",
)

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

copd_codes = codelist_from_csv(
    "codelists/opensafely-current-copd.csv", system="ctv3", column="CTV3ID",
)

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID",
)

stroke_codes = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", system="ctv3", column="CTV3ID",
)

lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", system="ctv3", column="CTV3ID",
)

haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", system="ctv3", column="CTV3ID",
)

other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)

creatinine_codes = codelist(["XE2q5"], system="ctv3")

ckd_codes = codelist_from_csv(
    "codelists/opensafely-chronic-kidney-disease.csv", system="ctv3", column="CTV3ID",
)

organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv",
    system="ctv3",
    column="CTV3ID",
)

# Medication

oral_pred_codes = codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)
anti_tnf_med_codes = codelist_from_csv(
    "codelists/crossimid-anti-tnf-medication.csv",
    system="snomed",
    column="snomed_id",
)
anti_il6_med_codes = codelist_from_csv(
    "codelists/crossimid-anti-il6-medication.csv",
    system="snomed",
    column="snomed_id",
)
anti_il12_23_med_codes = codelist_from_csv(
    "codelists/crossimid-anti-il12-23-medication.csv",
    system="snomed",
    column="snomed_id",
)
anti_il1_med_codes = codelist_from_csv(
    "codelists/crossimid-anti-il1-medication.csv",
    system="snomed",
    column="snomed_id",
)
anti_il4_med_codes = codelist_from_csv(
    "codelists/crossimid-anti-il4-medication.csv",
    system="snomed",
    column="snomed_id",
)
jak_inhibitors_med_codes = codelist_from_csv(
    "codelists/crossimid-jak-inhibitors-medication.csv",
    system="snomed",
    column="snomed_id",
)
standard_systemic_immunosuppressant_med_codes = codelist_from_csv(
    "codelists/opensafely-dmards.csv",
    system="snomed",
    column="snomed_id",
)
rituximab_med_codes = codelist_from_csv(
    "codelists/crossimid-rituximab-medication.csv",
    system="snomed",
    column="snomed_id",
)
