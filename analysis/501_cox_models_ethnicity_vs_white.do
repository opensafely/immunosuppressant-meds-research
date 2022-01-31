/*==============================================================================
DO FILE NAME:			cox models
PROJECT:				Immunosuppressant meds research
DATE: 					20th January 2022
AUTHOR:					M Yates / J Galloway / S Norton / K Bechman / N Kennedy
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
global outfile `1'_ethnicity_vs_white

* Open a log file
cap log close
log using "$logdir/cox_models_$outfile", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"


/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"


* Crude models
global crude

global agesex i.agegroup male


* For IMID vs general population
global adjusted_imid_conf i.agegroup male i.imd i.smoke_nomiss

global adjusted_imid_med i.agegroup male i.imd i.smoke_nomiss i.obese4cat chronic_cardiac_disease i.diabcat steroidcat 

/* global adjusted_imid_sens_one i.agegroup male i.imd i.smoke_nomiss ethnicity */

global adjusted_imid_sens_two i.agegroup male i.imd i.smoke_nomiss i.ckd chronic_liver_disease chronic_respiratory_disease

global adjusted_imid_sens_three i.agegroup male i.imd i.smoke


* For Targeted vs standard immunosupressants
global adjusted_drugs_conf i.agegroup male i.imd i.smoke_nomiss i.obese4cat chronic_cardiac_disease i.diabcat cancer stroke i.ckd chronic_liver_disease chronic_respiratory_disease bowel skin joint

global adjusted_drugs_med i.agegroup male i.imd i.smoke_nomiss i.obese4cat chronic_cardiac_disease i.diabcat cancer stroke i.ckd chronic_liver_disease chronic_respiratory_disease bowel skin joint steroidcat

/* global adjusted_drugs_sens_one i.agegroup male i.imd i.smoke_nomiss i.obese4cat chronic_cardiac_disease i.diabcat cancer stroke i.ckd chronic_liver_disease chronic_respiratory_disease bowel skin joint ethnicity */

global adjusted_drugs_sens_three i.agegroup male i.imd i.smoke i.bmicat chronic_cardiac_disease i.diabcat cancer stroke i.ckd chronic_liver_disease chronic_respiratory_disease bowel skin joint

tempname coxoutput
	postfile `coxoutput' str20(cohort) str20(model) str20(failure) ///
	  ptime_1 events_1 rate_1 ///
	  ptime_2 events_2 rate_2 ///
	  ptime_3 events_3 rate_3 ///
	  ptime_4 events_4 rate_4 ///
	  ptime_5 events_5 rate_5 ///
		hr_2 lc_2 uc_2 ///
		hr_3 lc_3 uc_3 ///
		hr_4 lc_4 uc_4 ///
		hr_5 lc_5 uc_5 ///
		using $projectdir/output/data/cox_model_summary_$outfile, replace						

use $projectdir/output/data/file_imid_all, replace

if "$files" == "genpop" {
  drop if imid != 0
}
else {
  drop if $files != 1
}

drop if ethnicity ==.u

*generate censor date
gen diecensor = mdy(09,01,2020)
format diecensor %td
	
egen stopdied = rmin(died_ons_date diecensor)
egen stophospital = rmin(hosp_admit_date_covid diecensor)
egen stopicuordeath = rmin(icu_or_death_covid_date diecensor)
egen stopicu_sens = rmin(icu_admit_date_covid_sens diecensor)

gen faildied = died_ons_covid_flag_any
gen failhospital = hosp_admit_covid
gen failicuordeath = icu_or_death_covid
gen failicu_sens = icu_covid_sens
	
gen exitdied = died_ons_covid_flag_any
gen exithospital = hosp_admit_covid
gen exiticuordeath = icu_or_death_covid	 
gen exiticu_sens = icu_covid_sens

foreach fail in died hospital icuordeath icu_sens {

	stset stop`fail', id(patient_id) failure(fail`fail'==1) origin(time enter_date)  enter(time enter_date) scale(365.25) 
						
	foreach model in crude agesex adjusted_imid_conf adjusted_imid_med adjusted_drugs_conf adjusted_drugs_med adjusted_imid_sens_two adjusted_imid_sens_three adjusted_drugs_sens_three {
				
		stcox i.ethnicity $`model', vce(robust)
					matrix b = r(table)
					local hr_2 = b[1,2]
					local lc_2 = b[5,2]
					local uc_2 = b[6,2]
					local hr_3 = b[1,3]
					local lc_3 = b[5,3]
					local uc_3 = b[6,3]
					local hr_4 = b[1,4]
					local lc_4 = b[5,4]
					local uc_4 = b[6,4]
					local hr_5 = b[1,5]
					local lc_5 = b[5,5]
					local uc_5 = b[6,5]

					
		stptime if ethnicity == 1
					local rate_1 = `r(rate)'
					local ptime_1 = `r(ptime)'
					local events_1 .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_1 `r(failures)'

		stptime if ethnicity == 2
					local rate_2 = `r(rate)'
					local ptime_2 = `r(ptime)'
					local events_2 .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_2 `r(failures)'

		stptime if ethnicity == 3
					local rate_3 = `r(rate)'
					local ptime_3 = `r(ptime)'
					local events_3 .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_3 `r(failures)'

		stptime if ethnicity == 4
					local rate_4 = `r(rate)'
					local ptime_4 = `r(ptime)'
					local events_4 .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_4 `r(failures)'

		stptime if ethnicity == 5
					local rate_5 = `r(rate)'
					local ptime_5 = `r(ptime)'
					local events_5 .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_5 `r(failures)'

		post `coxoutput' ("$files") ("`model'") ("`fail'") ///
		      (`ptime_1')  (`events_1')  (`rate_1') ///
					(`ptime_2')  (`events_2')  (`rate_2') ///
					(`ptime_3')  (`events_3')  (`rate_3') ///
					(`ptime_4')  (`events_4')  (`rate_4') ///
					(`ptime_5')  (`events_5')  (`rate_5') ///
					(`hr_2') (`lc_2') (`uc_2') ///
					(`hr_3') (`lc_3') (`uc_3') ///
					(`hr_4') (`lc_4') (`uc_4') ///
					(`hr_5') (`lc_5') (`uc_5')
	}
}

postclose `coxoutput'


log close


