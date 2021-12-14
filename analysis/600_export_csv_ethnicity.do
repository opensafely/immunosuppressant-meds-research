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
log using "$logdir/export_csv_ethnicity", replace

global files imid joint skin bowel
global ethnicity 1 2 3 4 5 u

foreach f in $files {

  foreach g in $ethnicity {
	
	use $projectdir/output/data/cox_model_summary_`f'_ethnicity_`g', replace
	gen ethnicity = "`g'"
	export delimited $projectdir/output/data/csv_`f'_ethnicity_`g', replace

	use $projectdir/output/data/cox_model_summary_haemonc_`f'_ethnicity_`g', replace	
	gen ethnicity = "`g'"
	export delimited $projectdir/output/data/csvhaemonc_`f'_ethnicity_`g', replace

	}
}
