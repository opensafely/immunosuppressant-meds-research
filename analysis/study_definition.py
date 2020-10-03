from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, filter_codes_by_category

from codelists import *

def first_diagnosis_in_period(dx_codelist):
    return patients.with_these_clinical_events(
        dx_codelist,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    )

def medication_count_3m_0m(med_codelist):
    return patients.with_these_medications(
        med_codelist,
        between=["2019-12-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    )

def medication_count_6m_3m(med_codelist):
    return patients.with_these_medications(
        med_codelist,
        between=["2019-09-01", "2020-11-30"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    )

def medication_count_12m_6m(med_codelist):
    return patients.with_these_medications(
        med_codelist,
        between=["2019-03-01", "2020-08-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    )

def medication_earliest(med_codelist):
    return patients.with_these_medications(
        med_codelist,
        between=["2010-01-01", "2020-02-29"],
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    )

def medication_latest(med_codelist):
    return patients.with_these_medications(
        med_codelist,
        between=["2010-01-01", "2020-02-29"],
        returning="date",
        find_last_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    )

def medication_counts_and_dates(var_name, med_codelist_file):
    """
    Generates dictionary of covariats for a medication including counts and dates
    
    Takes a variable prefix and medication codelist filename (minus .csv)
    Returns a dictionary suitable for unpacking into the main study definition
    This will include all five of the items defined in the functions above
    """
    
    definitions={}
    med_codelist=codelist_from_csv("codelists/" + med_codelist_file + ".csv", system="snomed", column="snomed_id")
    med_functions=[
        ("3m_0m", medication_count_3m_0m),
        ("6m_3m", medication_count_6m_3m),
        ("12m_6m", medication_count_12m_6m),
        ("earliest", medication_earliest),
        ("latest", medication_latest)
    ]
    for (suffix, fun) in med_functions:
        definitions[var_name + "_" + suffix] = fun(med_codelist)
    return definitions

def medication_counts_and_dates_all(meds_list):
    """
    Generate dictionary of covariates for list of medications including counts and dates
    
    Takes a list of tuples of the form (variable prefix, medication codelist filename (minus .csv))
    Returns a dictionary suitable for unpacking into the main study definition
    For each tuple, this will include all of the items specified in `medication_counts_and_dates`
    """
    definitions={}
    for (var_name, med_codelist_file) in meds_list:
        definitions.update(medication_counts_and_dates(var_name, med_codelist_file))
    return definitions

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.1,
    },
    # This line defines the study population
    population=patients.registered_with_one_practice_between(
        "2019-03-01", "2020-03-01"
    ),
    # Outcomes
    icu_date_admitted=patients.admitted_to_icu(
        on_or_after="2020-03-01",
        include_day=True,
        returning="date_admitted",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
    ),
    died_date_cpns=patients.with_death_recorded_in_cpns(
        on_or_before="2020-06-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_identification, on_or_after="2020-03-01", match_only_underlying_cause=False,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
    ),
    died_ons_covid_flag_underlying=patients.with_these_codes_on_death_certificate(
        covid_identification, on_or_after="2020-03-01", match_only_underlying_cause=True,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_after="2020-06-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
    ),
    # The rest of the lines define the covariates with associated GitHub issues
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/33
    age=patients.age_as_of(
        "2020-03-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    # IMID disease codes
    crohns_disease=first_diagnosis_in_period(crohns_disease_codes),
    ulcerative_colitis=first_diagnosis_in_period(ulcerative_colitis_codes),
    inflammatory_bowel_disease_unclassified=first_diagnosis_in_period(inflammatory_bowel_disease_unclassified_codes),
    psoriasis=first_diagnosis_in_period(psoriasis_codes),
    hidradenitis_suppurativa=first_diagnosis_in_period(hidradenitis_suppurativa_codes),
    psoriatic_arthritis=first_diagnosis_in_period(psoriatic_arthritis_codes),
    rheumatoid_arthritis=first_diagnosis_in_period(rheumatoid_arthritis_codes),
    
    # Comorbidities
    chronic_cardiac_disease=first_diagnosis_in_period(chronic_cardiac_disease_codes),
    diabetes=first_diagnosis_in_period(diabetes_codes),
    hba1c_new=first_diagnosis_in_period(hba1c_new_codes),
    hba1c_old=first_diagnosis_in_period(hba1c_old_codes),
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        on_or_before="2020-02-29",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-02-29"},
            "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
            "incidence": 0.95,
        },
    ),

    hba1c_percentage=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        on_or_before="2020-02-29",
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "date": {"latest": "2020-02-29"},
            "float": {"distribution": "normal", "mean": 5, "stddev": 2},
            "incidence": 0.95,
        },
    ),
    hypertension=first_diagnosis_in_period(hypertension_codes),
    chronic_respiratory_disease=first_diagnosis_in_period(chronic_respiratory_disease_codes),
    copd=first_diagnosis_in_period(copd_codes),
    chronic_liver_disease=first_diagnosis_in_period(chronic_liver_disease_codes),
    stroke=first_diagnosis_in_period(stroke_codes),
    lung_cancer=first_diagnosis_in_period(lung_cancer_codes),
    haem_cancer=first_diagnosis_in_period(haem_cancer_codes),
    other_cancer=first_diagnosis_in_period(other_cancer_codes),
    #CKD
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["2018-12-01", "2020-02-29"],
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "float": {"distribution": "normal", "mean": 150.0, "stddev": 200.0},
            "date": {"earliest": "2018-12-01", "latest": "2020-02-29"},
            "incidence": 0.95,
        },
    ),
    #### end stage renal disease codes incl. dialysis / transplant 
    esrf=patients.with_these_clinical_events(
        ckd_codes,
        on_or_before="2020-02-29",
        return_last_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "2020-02-29"}},
    ),
    ckd=first_diagnosis_in_period(ckd_codes),
    organ_transplant=first_diagnosis_in_period(organ_transplant_codes),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    stp=patients.registered_practice_as_of(
        "2020-03-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    msoa=patients.registered_practice_as_of(
        "2020-03-01",
        returning="msoa_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"MSOA1": 0.5, "MSOA2": 0.5}},
        },
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/52
    imd=patients.address_as_of(
        "2020-03-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),
    rural_urban=patients.address_as_of(
        "2020-03-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
    #SMOKING
    smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (    
                       most_recent_smoking_code = 'N' AND ever_smoked   
                     )  
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="2020-02-29",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="2020-02-29",
        ),
    ),
    smoking_status_date=patients.with_these_clinical_events(
        clear_smoking_codes,
        on_or_before="2020-02-29",
        return_last_date_in_period=True,
        include_month=True,
        return_expectations={"date": {"latest": "2020-02-29"}},
    ),
    ### GP CONSULTATION RATE
    gp_consult_count=patients.with_gp_consultations(
        between=["2019-03-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 4, "stddev": 2},
            "date": {"earliest": "2019-03-01", "latest": "2020-02-29"},
            "incidence": 0.7,
        },
    ),
    has_consultation_history=patients.with_complete_gp_consultation_history_between(
        "2019-03-01", "2020-02-29", return_expectations={"incidence": 0.9},
    ),
    # Medications
    **medication_counts_and_dates_all([
        ("oral_prednisolone", "opensafely-asthma-oral-prednisolone-medication"),
        ("anti_tnf", "crossimid-anti-tnf-medication"),
        ("anti_il6", "crossimid-anti-il6-medication"),
        ("anti_il12-23", "crossimid-anti-il12-23-medication"),
        ("anti_il1", "crossimid-anti-il1-medication"),
        ("anti_il4", "crossimid-anti-il4-medication"),
        ("jak_inhibitors", "crossimid-jak-inhibitors-medication"),
        ("rituximab", "crossimid-rituximab-medication"),
        ("anti_integrin", "crossimid-anti-integrin-medication"),
        ("azathioprine", "crossimid-azathioprine-medication"),
        ("ciclosporin", "crossimid-ciclosporin-medication"),
        ("gold", "crossimid-gold-medication"),
        ("jak_inhibitors", "crossimid-jak-inhibitors-medication"),
        ("leflunomide", "crossimid-leflunomide-medication"),
        ("mercaptopurine", "crossimid-mercaptopurine-medication"),
        ("methotrexate", "crossimid-methotrexate-medication"),
        ("mycophenolate", "crossimid-mycophenolate-medication"),
        ("penicillamine", "crossimid-penicillamine-medication"),
        ("sulfasalazine", "crossimid-sulfasalazine-medication")
    ])
)