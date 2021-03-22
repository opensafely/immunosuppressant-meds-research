/*==============================================================================
DO FILE NAME:			survival curves
PROJECT:				Immunosuppressant meds research
DATE: 					22 Mar 21
AUTHOR:					M Yates / J Galloway / S Norton										
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

global projectdir $projectdir/

/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

global crude

global files imid joint skin bowel imiddrugcategory 

foreach f in $files {
		
	use $homedir/file_`f', replace

	*generate censor date
	gen diecensor = mdy(10,01,2020)
	format diecensor %td
	egen stopdied = rmin(died_ons_date diecensor)
	egen stopicu = rmin(icu_or_death_covid_date diecensor)

	gen faildied = died_ons_covid_flag_any
	gen failicu = icu_or_death_covid

	gen exitdied = died_ons_covid_flag_any
	gen exiticu = icu_or_death_covid

	foreach fail in died icu {

		stset stop`fail', id(patient_id) failure(fail`fail'==1) origin(time enter_date)  enter(time enter_date)
						
				
			stcox `f' 
			stcurve, haz at1(`f'=0) at2(`f'=1) title("") range(0 180) xtitle("Analysis time (years)") ///
			legend(order(1 "Comparator" 2 "Exposed") rows(2) symxsize(*0.4) size(small)) ///
			ylabel(,angle(horizontal)) plotregion(color(white)) graphregion(color(white)) ///
			ytitle("Survival Probability" ) xtitle("Time (Days)" ) saving(`f'_graph, replace)
	
	graph export survcurv_`f'_`fail'.svg , as(svg) replace

	}
}
log close
