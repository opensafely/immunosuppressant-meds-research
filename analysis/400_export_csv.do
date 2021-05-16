/*==============================================================================
DO FILE NAME:			Convert CSV models
PROJECT:				Immunosuppressant meds research
DATE: 					22nd April 21
AUTHOR:					M Yates / J Galloway / S Norton / K Bechman 
DESCRIPTION OF FILE:	export cox models
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
log using "$logdir/export_csv", replace

global files imid joint bowel skin imiddrugcategory standtnf standtnf3m tnfmono  standil6 standil17 standil23 standjaki standritux standinflix

foreach f in $files {
	
	use $projectdir/output/data/cox_model_summary_`f', replace
	export delimited $projectdir/output/data/csv_`f', replace

	use $projectdir/output/data/cox_model_summary_haemonc_`f', replace	
	export delimited $projectdir/output/data/csvhaemonc_`f', replace

	}

