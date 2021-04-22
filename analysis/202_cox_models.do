/*==============================================================================
DO FILE NAME:			cox models
PROJECT:				Immunosuppressant meds research
DATE: 					22nd April 21
AUTHOR:					M Yates / J Galloway / S Norton / K Bechman 
DESCRIPTION OF FILE:	run cox models
DATASETS USED:			imid main file plus sub files for specific drug cohorts
DATASETS CREATED: 		coxoutput
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

* import delimited `c(pwd)'/output/input.csv, clear

* set filepaths

global projectdir `c(pwd)'
di "$projectdir"

global logdir "$projectdir/logs"
di "$logdir"

global files `1' 

* Open a log file
cap log close
log using "$logdir/cox_models_$files", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"


/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

global crude

global agesex i.agegroup male

global adjusted_main i.agegroup male i.ethnicity i.imd bmicat bowel skin joint chronic_cardiac_disease cancer stroke i. steroidcat 

global adjusted_extra i.agegroup male i.ethnicity i.imd bmicat bowel skin joint chronic_cardiac_disease cancer stroke i.diabcat steroidcat i.ckd chronic_liver_disease chronic_respiratory_disease


tempname coxoutput
	postfile `coxoutput' str20(cohort) str20(model) str20(failure) ///
		ptime_exposed events_exposed rate_exposed /// 
		ptime_comparator events_comparator rate_comparator hr lc uc ///
		using $projectdir/output/data/cox_model_summary_$files, replace						

use $projectdir/output/data/file_$files, replace


*generate censor date
gen diecensor = mdy(09,01,2020)
format diecensor %td
	
egen stopdied = rmin(died_ons_date diecensor)
egen stophospital = rmin(hosp_admit_date_covid diecensor)
egen stopicuordeath = rmin(icu_or_death_covid_date diecensor)
egen stophospital_sens = rmin(hosp_admit_date_covid_sens diecensor)
egen stopicu_sens = rmin(icu_admit_date_covid_sens diecensor)

gen faildied = died_ons_covid_flag_any
gen failhospital = hosp_admit_covid
gen failicuordeath = icu_or_death_covid
gen failhospital_sens = hosp_admit_covid_sens
gen failicu_sens = icu_covid_sens
	
gen exitdied = died_ons_covid_flag_any
gen exithospital = hosp_admit_covid
gen exiticuordeath = icu_or_death_covid	 
gen exithospital_sens = hosp_admit_covid_sens
gen exiticu_sens = icu_covid_sens

foreach fail in died hospital icuordeath hospital_sens icu_sens {

	stset stop`fail', id(patient_id) failure(fail`fail'==1) origin(time enter_date)  enter(time enter_date) scale(365.25) 
						
	foreach model in crude agesex adjusted_main adjusted_extra {
				
		stcox $files $`model', vce(robust)
					matrix b = r(table)
					local hr = b[1,1]
					local lc = b[5,1]
					local uc = b[6,1]

		stptime if $files == 1
					local rate_exposed = `r(rate)'
					local ptime_exposed = `r(ptime)'
					local events_exposed .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_exposed `r(failures)'
						
		stptime if $files == 0
					local rate_comparator = `r(rate)'
					local ptime_comparator = `r(ptime)'
					local events_comparator .
					if `r(failures)' == 0 | `r(failures)' > 5 local events_comparator `r(failures)'

		post `coxoutput' ("$files") ("`model'") ("`fail'") (`ptime_exposed') (`events_exposed') (`rate_exposed') ///
					(`ptime_comparator') (`events_comparator') (`rate_comparator') ///
					(`hr') (`lc') (`uc')	
	}
}

postclose `coxoutput'


log close


