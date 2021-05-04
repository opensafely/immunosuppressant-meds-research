/*==============================================================================
DO FILE NAME:			survival curves
PROJECT:				Immunosuppressant meds research
DATE: 					2nd April 21
AUTHOR:					M Yates / J Galloway / S Norton	/ K Bechman									
DESCRIPTION OF FILE:	survival curves
DATASETS USED:			imid main file plus sub files for specific drug cohorts
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
log using "$logdir/graphs", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"


/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

global crude

global files imid joint skin bowel imiddrugcategory 

foreach f in $files {
		
	use $projectdir/output/data/file_`f', replace

	*generate censor date
	gen diecensor = mdy(09,01,2020)
	format diecensor %td
		
	egen stopdied = rmin(died_ons_date diecensor)
	egen stophospital = rmin(hosp_admit_date_covid diecensor)
	egen stopicuordeath = rmin(icu_or_death_covid_date diecensor)

	gen faildied = died_ons_covid_flag_any
	gen failhospital = hosp_admit_covid
	gen failicuordeath = icu_or_death_covid
	
	gen exitdied = died_ons_covid_flag_any
	gen exithospital = hosp_admit_covid
	gen exiticuordeath = icu_or_death_covid	 
	
	

	foreach fail in died hospital icuordeath {

		stset stop`fail', id(patient_id) failure(fail`fail'==1) origin(time enter_date)  enter(time enter_date)
								
			stcox `f' 
			stcurve, survival at1(`f'=0) at2(`f'=1) title("") range(0 180) xtitle("Analysis time (years)") ///
			legend(order(1 "Comparator" 2 "Exposed") rows(2) symxsize(*0.4) size(small)) ///
			ylabel(,angle(horizontal)) plotregion(color(white)) graphregion(color(white)) ///
			ytitle("Survival Probability" ) xtitle("Time (Days)" ) saving($projectdir/output/figures/`f'_graph, replace)
	
	graph export $projectdir/output/figures/survcurv_`f'_`fail'.svg , as(svg) replace

	}
}
log close
