
/*==============================================================================
DO FILE NAME:			ethnicity pyramid plots
PROJECT:				Immunosuppressant meds research
DATE: 					14 feb 2021
AUTHOR:					J Galloway / S Norton	/ N Kennedy							
DESCRIPTION OF FILE:	graphs
DATASETS USED:			imid all file
DATASETS CREATED: 		none
OTHER OUTPUT: 			graph files as svg, printed to folder $Logdir
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
log using "$logdir/pyramid_plots", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

foreach group in genpop imid joint skin bowel {
  use "output/data/file_imid_all.dta", clear
  if "`group'" == "genpop" {
    drop if imid != 0
  }
  else {
    drop if `group' != 1
  }
  
  collapse (count) patient_id, by(sex agegroup ethnicity) 
  
  export delimited "output/data/age_sex_summary_`group'.csv", replace
  
  gen zero = 0
  
  bys ethnicity sex: egen totalpop = total(patient_id)
  
  gen percentage = patient_id/totalpop *100
  replace patient_id = -patient_id if sex=="M"
  replace percentage = -percentage if sex=="M"
  
  levelsof ethnicity
  foreach l in `r(levels)' {
  	local name: label ethnicity `l'
  	twoway (bar percentage agegroup if sex=="M" & ethnicity==`l', horizontal bfcolor(ltblue) blcolor(gs1)) ///
  	(bar percentage agegroup if sex=="F" & ethnicity==`l', horizontal bfcolor(cranberry) blcolor(gs1))	///
  	(scatter agegroup zero, mlabel(agegroup) mlabcolor(black) msymbol(none)), ///
  	title("`name': Male and Female Population by Age") legend(off) xlabel(-40 "40%" -30 "30%"-20 "20%" -10 "10%" 0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%") ///
  	ytitle("Age group") yscale(noline) ylabel(none) text(4 -30 "Male") text(4 30 "Female") ///
  	xtitle("Population") name(ethnicity`l', replace)
  	graph export $projectdir/output/figures/pyramidplot_`group'_`l'.svg , as(svg) replace
	}
}
	
log close

