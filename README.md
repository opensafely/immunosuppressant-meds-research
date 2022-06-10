# Risk of severe COVID-19 outcomes associated with immune-mediated inflammatory diseases and immune modifying therapies: a nationwide cohort study in the OpenSAFELY platform

This is the code and configuration for our paper _Risk of severe COVID-19 outcomes associated with immune-mediated inflammatory diseases and immune-modifying therapies: a nationwide cohort study in the OpenSAFELY platform_.

* The [here in Lancet Rheumatology](https://doi.org/10.1016/S2665-9913(22)00098-4).
* Raw model outputs, including charts, crosstabs, etc, are available [here](https://jobs.opensafely.org/datalab/immunosuppresant-medication/immunosuppressant-meds-research/outputs/).
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for electronic health records research in the NHS.

Instead of requesting access for slices of patient data and transporting them elsewhere for analysis, the framework supports developing analytics against dummy data, and then running against the real data within the same infrastructure that the data is stored. Read more at [OpenSAFELY.org](https://opensafely.org).

