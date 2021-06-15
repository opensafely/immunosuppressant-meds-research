/*==============================================================================
DO FILE NAME:			schoenfeld residuals 
PROJECT:				Immunosuppressant meds research
DATE: 					15th June 21
AUTHOR:					M Yates / J Galloway / S Norton / K Bechman 
DESCRIPTION OF FILE:	run schoenfeld
DATASETS USED:			imid main file plus sub files for specific drug cohorts
DATASETS CREATED: 		coxoutput
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

* import delimited `c(pwd)'/output/input.csv, clear

* set filepaths

/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

* Open a log file
cap log close
log using "$logdir/cox_model_diagnostics", replace

				
foreach f in $files {
		use $projectdir/output/data/file_$files, replace
 
		*generate censor date
		gen diecensor = mdy(09,01,2020)
		format diecensor %td
		egen stopdied = rmin(died_ons_date diecensor)
		gen faildied = died_ons_covid_flag_any
		gen exitdied = died_ons_covid_flag_any

		stset stopdied, id(patient_id) failure(faildied==1) origin(time enter_date)  enter(time enter_date) scale(365.25) 
						
		stcox `f' age(age1 age2 age3) male, noshow nolog schoenfeld(sch1) scaledsch(sca1) 
				stphtest, log detail
}

log close


