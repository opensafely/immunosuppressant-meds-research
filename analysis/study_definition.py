from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, filter_codes_by_category

from codelists import *

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
    # Disease codes
    crohns_disease=patients.with_these_clinical_events(
        crohns_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    ulcerative_colitis=patients.with_these_clinical_events(
        ulcerative_colitis_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    inflammatory_bowel_disease_unclassified=patients.with_these_clinical_events(
        inflammatory_bowel_disease_unclassified_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    psoriasis=patients.with_these_clinical_events(
        psoriasis_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    hidradenitis_suppurativa=patients.with_these_clinical_events(
        hidradenitis_suppurativa_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),   
    psoriatic_arthritis=patients.with_these_clinical_events(
        psoriatic_arthritis_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    rheumatoid_arthritis=patients.with_these_clinical_events(
        rheumatoid_arthritis_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    ankylosing_spondylitis=patients.with_these_clinical_events(
        ankylosing_spondylitis_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    hba1c_new=patients.with_these_clinical_events(
        hba1c_new_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    hba1c_old=patients.with_these_clinical_events(
        hba1c_old_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    
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
    
    hypertension=patients.with_these_clinical_events(
        hypertension_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    copd=patients.with_these_clinical_events(
        copd_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    stroke=patients.with_these_clinical_events(
        stroke_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    other_cancer=patients.with_these_clinical_events(
        other_cancer_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),

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

    ckd=patients.with_these_clinical_events(
        ckd_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
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
    oral_prednisolone_count=patients.with_these_medications(
        oral_pred_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    anti_tnf_med_count=patients.with_these_medications(
        anti_tnf_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    anti_il6_med_count=patients.with_these_medications(
        anti_il6_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    anti_il12_23_med_count=patients.with_these_medications(
        anti_il12_23_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    anti_il1_med_count=patients.with_these_medications(
        anti_il1_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    anti_il4_med_count=patients.with_these_medications(
        anti_il4_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    jak_inhibitors_med_count=patients.with_these_medications(
        jak_inhibitors_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    standard_systemic_immunosuppressant_med_count=patients.with_these_medications(
        standard_systemic_immunosuppressant_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),
    rituximab_med_count=patients.with_these_medications(
        rituximab_med_codes,
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        },
    ),    
)
