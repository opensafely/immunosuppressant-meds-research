/*==============================================================================
DO FILE NAME:			Convert CSV models
PROJECT:				Immunosuppressant meds research
DATE: 					22nd April 21
AUTHOR:					M Yates / J Galloway / S Norton / K Bechman / N Kennedy
DESCRIPTION OF FILE:	export cox models
DATASETS USED:			imid main file plus sub files for specific drug cohorts
DATASETS CREATED: 		coxoutput
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

* set filepaths

global projectdir `c(pwd)'
di "$projectdir"

global logdir "$projectdir/logs"
di "$logdir"

* Open a log file
cap log close
log using "$logdir/export_csv_ethnicity_vs_white", replace

global files imid joint skin bowel

foreach f in $files {

	use $projectdir/output/data/cox_model_summary_`f'_ethnicity_vs_white, replace
	export delimited $projectdir/output/data/csv_`f'_ethnicity_vs_white, replace
}
