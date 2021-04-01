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

def get_medication_for_dates(med_codelist, with_med_func, dates, return_count):
    if (return_count):
        returning="number_of_matches_in_period"
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        }
    else:
        returning="binary_flag"
        return_expectations={
            "incidence": 0.1
        }
    return with_med_func(
        med_codelist,
        between=dates,
        returning=returning,
        return_expectations=return_expectations
    )

def get_medication_early_late(med_codelist, with_med_func, type):
    if (type == "latest"):
        med_params={"find_last_match_in_period": True}
    else:
        med_params={"find_first_match_in_period": True}        
    return with_med_func(
        med_codelist,
        between=["2010-01-01", "2020-02-29"],
        returning="date",
        **med_params,
        date_format="YYYY-MM",
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "2010-01-01", "latest": "2020-02-29"},
        },
    )

def medication_counts_and_dates(var_name, med_codelist_file, high_cost, needs_6m_12m=False):
    """
    Generates dictionary of covariats for a medication including counts (or binary flags for high cost drugs) and dates
    
    Takes a variable prefix and medication codelist filename (minus .csv)
    Returns a dictionary suitable for unpacking into the main study definition
    This will include all five of the items defined in the functions above
    """
    
    definitions={}
    
    if (med_codelist_file[0:5] == "cross"):
        med_codelist_file = "crossimid-codelists/" + med_codelist_file
    else:
        med_codelist_file = "codelists/" + med_codelist_file
    if (high_cost):
        med_codelist=codelist_from_csv(med_codelist_file + ".csv", system="high_cost_drugs", column="olddrugname")
        with_med_func=patients.with_high_cost_drugs
    else:
        if ("medication" in med_codelist_file):
            column_name="snomed_id"
        else:
            column_name="dmd_id"
        med_codelist=codelist_from_csv(med_codelist_file + ".csv", system="snomed", column=column_name)
        with_med_func=patients.with_these_medications
    
    med_functions=[
        ("3m_0m", get_medication_for_dates, {"dates": ["2019-12-01", "2020-02-29"], "return_count": not high_cost}),
        ("6m_3m", get_medication_for_dates, {"dates": ["2019-09-01", "2020-11-30"], "return_count": not high_cost})
    ]
    if (needs_6m_12m):
      med_functions += [("12m_6m", get_medication_for_dates, {"dates": ["2019-03-01", "2020-08-31"], "return_count": not high_cost})]
    for (suffix, fun, params) in med_functions:
        definitions[var_name + "_" + suffix] = fun(med_codelist, with_med_func, **params)
    return definitions

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.1,
    },
    # This line defines the study population
    population=patients.satisfying(
            """
            has_follow_up AND
            (age >=18 AND age <= 110) AND
            (sex = "M" OR sex = "F")
            """,
            has_follow_up=patients.registered_with_one_practice_between(
                "2019-02-28", "2020-02-29"
            )
        ),
    # Outcomes
    icu_date_admitted=patients.admitted_to_icu(
        on_or_after="2020-03-01",
        include_day=True,
        returning="date_admitted",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
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
        on_or_after="2020-03-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence": 0.1},
    ),
    # COVID-19 outcomes
    first_pos_test_sgss=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-01-01"}},
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
    # atopic_dermatitis=first_diagnosis_in_period(atopic_dermatitis_codes),
    crohns_disease=first_diagnosis_in_period(crohns_disease_codes),
    ulcerative_colitis=first_diagnosis_in_period(ulcerative_colitis_codes),
    inflammatory_bowel_disease_unclassified=first_diagnosis_in_period(inflammatory_bowel_disease_unclassified_codes),
    psoriasis=first_diagnosis_in_period(psoriasis_codes),
    hidradenitis_suppurativa=first_diagnosis_in_period(hidradenitis_suppurativa_codes),
    psoriatic_arthritis=first_diagnosis_in_period(psoriatic_arthritis_codes),
    rheumatoid_arthritis=first_diagnosis_in_period(rheumatoid_arthritis_codes),
    ankylosing_spondylitis=first_diagnosis_in_period(ankylosing_spondylitis_codes),
    
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
#    smoking_status_date=patients.with_these_clinical_events(
#        clear_smoking_codes,
#        on_or_before="2020-02-29",
#        return_last_date_in_period=True,
#        include_month=True,
#        return_expectations={"date": {"latest": "2020-02-29"}},
#    ),
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
#    has_consultation_history=patients.with_complete_gp_consultation_history_between(
#        "2019-03-01", "2020-02-29", return_expectations={"incidence": 0.9},
#    ),
    # Medications

    **medication_counts_and_dates("oral_prednisolone", "opensafely-asthma-oral-prednisolone-medication", False),
    **medication_counts_and_dates("azathioprine", "opensafely-azathioprine-dmd", False),
    **medication_counts_and_dates("ciclosporin", "opensafely-ciclosporin-oral-dmd", False),
    **medication_counts_and_dates("gold", "crossimid-gold-medication", False),
    **medication_counts_and_dates("leflunomide", "opensafely-leflunomide-dmd", False),
    **medication_counts_and_dates("mercaptopurine", "opensafely-mercaptopurine-dmd", False),
    **medication_counts_and_dates("methotrexate", "opensafely-methotrexate-oral", False),
    **medication_counts_and_dates("methotrexate_inj", "opensafely-methotrexate-injectable", False),
    **medication_counts_and_dates("mycophenolate", "opensafely-mycophenolate", False),
    **medication_counts_and_dates("penicillamine", "opensafely-penicillamine-dmd", False),
    **medication_counts_and_dates("sulfasalazine", "opensafely-sulfasalazine-oral-dmd", False),
    **medication_counts_and_dates("mesalazine", "opensafely-newer-aminosalicylates-for-ibd-dmd", False),
   # **medication_counts_and_dates("atopic_dermatitis_meds", "crossimid-atopic-dermatitis-medication", False),
    **medication_counts_and_dates("abatacept", "opensafely-high-cost-drugs-abatacept", True),
    **medication_counts_and_dates("adalimumab", "opensafely-high-cost-drugs-adalimumab", True),
    **medication_counts_and_dates("baricitinib", "opensafely-high-cost-drugs-baricitinib", True),
    **medication_counts_and_dates("brodalumab", "opensafely-high-cost-drugs-brodalumab", True),
    **medication_counts_and_dates("certolizumab", "opensafely-high-cost-drugs-certolizumab", True),
    #**medication_counts_and_dates("dupilumab", "opensafely-high-cost-drugs-dupilumab", True),
    **medication_counts_and_dates("etanercept", "opensafely-high-cost-drugs-etanercept", True),
    **medication_counts_and_dates("golimumab", "opensafely-high-cost-drugs-golimumab", True),
    **medication_counts_and_dates("guselkumab", "opensafely-high-cost-drugs-guselkumab", True),
    **medication_counts_and_dates("infliximab", "opensafely-high-cost-drugs-infliximab", True),
    **medication_counts_and_dates("ixekizumab", "opensafely-high-cost-drugs-ixekizumab", True),
    **medication_counts_and_dates("mepolizumab", "opensafely-high-cost-drugs-mepolizumab", True),
    **medication_counts_and_dates("methotrexate_hcd", "opensafely-high-cost-drugs-methotrexate", True),
    **medication_counts_and_dates("risankizumab", "opensafely-high-cost-drugs-risankizumab", True),
    **medication_counts_and_dates("rituximab", "opensafely-high-cost-drugs-rituximab", True, True),
    **medication_counts_and_dates("sarilumab", "opensafely-high-cost-drugs-sarilumab", True),
    **medication_counts_and_dates("secukinumab", "opensafely-high-cost-drugs-secukinumab", True),
    **medication_counts_and_dates("tildrakizumab", "opensafely-high-cost-drugs-tildrakizumab", True),
    **medication_counts_and_dates("tocilizumab", "opensafely-high-cost-drugs-tocilizumab", True),
    **medication_counts_and_dates("tofacitinib", "opensafely-high-cost-drugs-tofacitinib", True),
    **medication_counts_and_dates("upadacitinib", "opensafely-high-cost-drugs-upadacitinib", True),
    **medication_counts_and_dates("ustekinumab", "opensafely-high-cost-drugs-ustekinumab", True),
    **medication_counts_and_dates("vedolizumab", "opensafely-high-cost-drugs-vedolizumab", True)
)
