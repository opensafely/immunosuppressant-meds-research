/*==============================================================================
DO FILE NAME:			cox models
PROJECT:				Immunosuppressant meds research
DATE: 					22 Mar 21
AUTHOR:					M Yates / J Galloway / S Norton
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

* Open a log file
cap log close
log using "$logdir/cox_models", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"


/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

global crude

global agesex i.agegroup male

global adjusted_main i.agegroup male i.ethnicity i.imd bmicat bowel skin joint chronic_cardiac_disease cancer stroke i.diabcat steroidcat 

global adjusted_extra i.agegroup male i.ethnicity i.imd bmicat bowel skin joint chronic_cardiac_disease cancer stroke i.diabcat steroidcat i.ckd chronic_liver_disease chronic_respiratory_disease

global files imid joint skin bowel imiddrugcategory standtnf standtnf3m tnfmono standil6 standil17 standil23 standjaki standritux 

tempname coxoutput
	postfile `coxoutput' str20(cohort) str20(model) str20(failure) ///
		ptime_exposed events_exposed rate_exposed /// 
		ptime_comparator events_comparator rate_comparator hr lc uc ///
		using $projectdir/output/data/cox_model_summary, replace						

foreach f in $files {
		
	use $projectdir/output/data/file_`f', replace

	*generate censor date
	gen diecensor = mdy(10,01,2020)
	format diecensor %td
	
	egen stopdied = rmin(died_ons_date diecensor)
	egen stopicu = rmin(icu_or_death_covid_date diecensor)
	egen stopswab = rmin(first_pos_test_sgss_date diecensor)

	gen faildied = died_ons_covid_flag_any
	gen failicu = icu_or_death_covid
	gen failswab = first_pos_test_sgss
	
	gen exitdied = died_ons_covid_flag_any
	gen exiticu = icu_or_death_covid
	gen exitswab = first_pos_test_sgss 
	 

	foreach fail in died icu swab {

		stset stop`fail', id(patient_id) failure(fail`fail'==1) origin(time enter_date)  enter(time enter_date) scale(365.25) 
						
		foreach model in crude agesex adjusted_main adjusted_extra {
				
			stcox `f' $`model', vce(robust)
						matrix b = r(table)
						local hr = b[1,1]
						local lc = b[5,1]
						local uc = b[6,1]

			stptime if `f' == 1
						local rate_exposed = `r(rate)'
						local ptime_exposed = `r(ptime)'
						local events_exposed .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_exposed `r(failures)'
						
			stptime if `f' == 0
						local rate_comparator = `r(rate)'
						local ptime_comparator = `r(ptime)'
						local events_comparator .
						if `r(failures)' == 0 | `r(failures)' > 5 local events_comparator `r(failures)'

			post `coxoutput' ("`f'") ("`model'") ("`fail'") (`ptime_exposed') (`events_exposed') (`rate_exposed') ///
						(`ptime_comparator') (`events_comparator') (`rate_comparator') ///
						(`hr') (`lc') (`uc')
		}
	}
}

postclose `coxoutput'




log close


