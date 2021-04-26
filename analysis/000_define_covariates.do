/*==============================================================================
DO FILE NAME:			create_analysis_dataset
PROJECT:				Immunosuppressant meds research
DATE: 					22nd April 21
AUTHOR:					M Yates / J Galloway / K Bechman
						adapted from C Rentsch										
DESCRIPTION OF FILE:	data management for immunosuppressant meds project  
						reformat variables 
						categorise variables
						label variables 
DATASETS USED:			data in memory (from output/input.csv)
DATASETS CREATED: 		analysis files
OTHER OUTPUT: 			logfiles, printed to folder $Logdir
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)						
==============================================================================*/

import delimited `c(pwd)'/output/input.csv, clear

* set filepaths

global projectdir `c(pwd)'
di "$projectdir"

global logdir "$projectdir/logs"
di "$logdir"

* Open a log file
cap log close
log using "$logdir/start_create_analysis_dataset", replace

* Set Ado file path
adopath + "$projectdir/analysis/extra_ados"

/* SET Index date ===========================================================*/
global indexdate 			= "01/03/2020"

/* RENAME VARIABLES===========================================================*/

rename inflammatory_bowel_disease_uncla ibd_uncla

/* Drop variables not needed ================================================*/
*calculating ckd from creat 
drop ckd ethnicity_date mepolizumab_3m_0m mepolizumab_6m_3m vedolizumab_3m_0m vedolizumab_6m_3m

/* CONVERT STRINGS TO DATE====================================================*/
/* Comorb dates are given with month/year only, so adding day 15 to enable
   them to be processed as dates */

foreach var of varlist 	 crohns_disease						///
						 ulcerative_colitis					///
						 ibd_uncla	                        ///
						 psoriasis							///
						 hidradenitis_suppurativa			///
						 psoriatic_arthritis				///
						 rheumatoid_arthritis				///
						 ankylosing_spondylitis				///
						 chronic_cardiac_disease			///
						 hba1c_new							///
						 hba1c_old							///
						 hba1c_mmol_per_mol_date			///
						 hba1c_percentage_date				///
						 diabetes							///
						 hypertension						///
						 chronic_respiratory_disease		///
						 esrf								///
						 copd								///
						 chronic_liver_disease				///
						 stroke								///
						 lung_cancer						///
						 haem_cancer						///
						 other_cancer						///
						 creatinine_date      				///
						 organ_transplant					///
						 bmi_date_measured				{
						 	
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				replace `var' = `var' + "-15"
				rename `var' `var'_dstr
				replace `var'_dstr = " " if `var'_dstr == "-15"
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
		}
	
	format `var'_date %td
}

/*conversion for dates with day already included*/

foreach var of varlist 	 icu_date_admitted					///
						 died_date_ons						///
						 first_pos_test_sgss				///
						 hospital_admission_date			///
						 {
						 
		capture confirm string variable `var'
		if _rc!=0 {
			assert `var'==.
			rename `var' `var'_date
		}
	
		else {
				rename `var' `var'_dstr
				gen `var'_date = date(`var'_dstr, "YMD") 
				order `var'_date, after(`var'_dstr)
				drop `var'_dstr
				gen `var'_date15 = `var'_date+15
				order `var'_date15, after(`var'_date)
				drop `var'_date
				rename `var'_date15 `var'_date
		}
	
	format `var'_date %td
}
						 

/* RENAME VARAIBLES===========================================================*/
*  An extra 'date' added to the end of some variable names, remove 
rename icu_date_admitted_date			icu_admitted_date			
rename bmi_date_measured_date  			bmi_measured_date
rename died_date_ons_date		        died_ons_date 
rename creatinine_date_date				creatinine_measured_date
rename hba1c_mmol_per_mol_date_date		hba1c_mmol_per_mol_date	
rename hba1c_percentage_date_date		hba1c_percentage_date
rename hospital_admission_date_date		hospital_admission_date


* Some names too long for loops below, shorten

/* CREATE BINARY VARIABLES====================================================*/


*  Make indicator variables for all conditions where relevant 


foreach var of varlist 	 crohns_disease_date				    ///
						 ulcerative_colitis_date				///
						 ibd_uncla_date	                        ///
						 psoriasis_date							///
						 hidradenitis_suppurativa_date			///
						 psoriatic_arthritis_date				///
						 rheumatoid_arthritis_date	            ///
						 ankylosing_spondylitis_date 			///
						 chronic_cardiac_disease_date			///
						 hypertension_date						///
						 chronic_respiratory_disease_date		///
						 copd_date								///
						 chronic_liver_disease_date				///
						 stroke_date							///
						 lung_cancer_date						///
						 haem_cancer_date						///
						 other_cancer_date						///
						 diabetes_date							///
						 esrf_date								///
						 creatinine_measured_date      		    ///
						 organ_transplant_date					///
						 bmi_measured_date					    ///
						 icu_admitted_date					    ///
						 died_ons_date							///
						 hospital_admission_date				///
						 first_pos_test_sgss_date	{
	/* date ranges are applied in python, so presence of date indicates presence of 
	  disease in the correct time frame */ 
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'!=. )
	order `newvar', after(`var')
}

/* CREATE VARIABLES===========================================================*/

/* DEMOGRAPHICS */ 

* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"

* Ethnicity
replace ethnicity = .u if ethnicity == .

*rearrange in order of prevalence
recode ethnicity 2=6 /* mixed to 6 */
recode ethnicity 3=2 /* south asian to 2 */
recode ethnicity 4=3 /* black to 3 */
recode ethnicity 6=4 /* mixed to 4 */

label define ethnicity 	1 "White"  					///
						2 "South Asian"				///
						3 "Black"  					///
						4 "Mixed" 					///
						5 "Other"					///
						.u "Unknown"
label values ethnicity ethnicity

//On reflection - this code below is probably not changing anything 
//.u in Stata will handle missingness in the same manner
//gen ethnicity2 = ethnicity
//replace ethnicity2 = . if ethnicity == .u

* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes

* add one to create groups 1 - 5 
replace imd = imd + 1

* - 1 is missing, should be excluded from population 
replace imd = .u if imd_o == -1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5 = 1 4 = 2 3 = 3 2 = 4 1 = 5 .u = .u

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 

/*  Age variables  */ 
********works if ages 18 and over
* Create categorised age
drop if age<18 & age !=.
drop if age>109 & age !=.

recode age 18/39.9999 = 1 /// 
           40/49.9999 = 2 ///
		   50/59.9999 = 3 ///
	       60/69.9999 = 4 ///
		   70/79.9999 = 5 ///
		   80/max = 6, gen(agegroup) 

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
						
label values agegroup agegroup

* Create binary age
recode age min/69.999 = 0 ///
           70/max = 1, gen(age70)

* Check there are no missing ages
assert age < .
assert agegroup < .
assert age70 < .

* Create restricted cubic splines for age
mkspline age = age, cubic nknots(4)

/*  Body Mass Index  */
* NB: watch for missingness

* Recode strange values 
replace bmi = . if bmi == 0 
replace bmi = . if !inrange(bmi, 10, 60)

* Restrict to within 10 years of index and aged > 16 
gen bmi_time = (date("$indexdate", "DMY") - bmi_measured_date)/365.25
gen bmi_age = age - bmi_time

replace bmi = . if bmi_age < 16 
replace bmi = . if bmi_time > 10 & bmi_time != . 

* Set to missing if no date, and vice versa 
replace bmi = . if bmi_measured_date == . 
replace bmi_measured_date = . if bmi == . 
replace bmi_measured_date = . if bmi == . 

gen 	bmicat = .
recode  bmicat . = 1 if bmi < 18.5
recode  bmicat . = 2 if bmi < 25
recode  bmicat . = 3 if bmi < 30
recode  bmicat . = 4 if bmi < 35
recode  bmicat . = 5 if bmi < 40
recode  bmicat . = 6 if bmi < .
replace bmicat = .u if bmi >= .

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Unknown (.u)"
					
label values bmicat bmicat

* Create less  granular categorisation
recode bmicat 1/3 .u = 1 4 = 2 5 = 3 6 = 4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		

label values obese4cat obese4cat
order obese4cat, after(bmicat)

/*  Smoking  */

* Smoking 
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

gen     smoke = 1  if smoking_status == "N"
replace smoke = 2  if smoking_status == "E"
replace smoke = 3  if smoking_status == "S"
replace smoke = .u if smoking_status == "M"
replace smoke = .u if smoking_status == "" 

label values smoke smoke
drop smoking_status

* Create non-missing 3-category variable for current smoking
* Assumes missing smoking is never smoking 
recode smoke .u = 1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke


/* CLINICAL COMORBIDITIES */ 

/* GP consultation rate */ 
replace gp_consult_count = 0 if gp_consult_count <1 

* those with no count assumed to have no visits 
replace gp_consult_count = 0 if gp_consult_count == . 
gen gp_consult = (gp_consult_count >=1)


/* eGFR */

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 

* Remove creatinine dates if no measurements, and vice versa 

replace creatinine = . if creatinine_measured_date == . 
replace creatinine_measured_date = . if creatinine == . 


* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min = .
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat_all = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat_all 0 = 5 15 = 4 30 = 3 45 = 2 60 = 0, generate(ckd_egfr)

/* 
0 "No CKD, eGFR>60" 	or missing -- have been shown reasonable in CPRD
2 "stage 3a, eGFR 45-59" 
3 "stage 3b, eGFR 30-44" 
4 "stage 4, eGFR 15-29" 
5 "stage 5, eGFR <15"
*/

gen egfr_cat = .
recode egfr_cat . = 3 if egfr < 30
recode egfr_cat . = 2 if egfr < 60
recode egfr_cat . = 1 if egfr < .
replace egfr_cat = .u if egfr >= .

label define egfr_cat 	1 ">=60" 		///
						2 "30-59"		///
						3 "<30"			///
						.u "Unknown (.u)"
					
label values egfr_cat egfr_cat

*if missing eGFR, assume normal

gen egfr_cat_nomiss = egfr_cat
replace egfr_cat_nomiss = 1 if egfr_cat == .u

label define egfr_cat_nomiss 	1 ">=60/missing" 	///
								2 "30-59"			///
								3 "<30"	
label values egfr_cat_nomiss egfr_cat_nomiss

gen egfr_date = creatinine_measured_date
format egfr_date %td

* Add in end stage renal failure and create a single CKD variable 
* Missing assumed to not have CKD 
gen ckd = 0
replace ckd = 1 if ckd_egfr != . & ckd_egfr >= 1
replace ckd = 1 if esrf == 1

label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"

* Create date (most recent measure prior to index)
gen temp1_ckd_date = creatinine_measured_date if ckd_egfr >=1
gen temp2_ckd_date = esrf_date if esrf == 1
gen ckd_date = max(temp1_ckd_date,temp2_ckd_date) 
format ckd_date %td 

/* HbA1c */

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage <= 0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0

* Set most recent values of >15 months prior to index to missing
replace hba1c_percentage   = . if (date("$indexdate", "DMY") - hba1c_percentage_date) > 15*30 & hba1c_percentage_date != .
replace hba1c_mmol_per_mol = . if (date("$indexdate", "DMY") - hba1c_mmol_per_mol_date) > 15*30 & hba1c_mmol_per_mol_date != .

* Clean up dates
replace hba1c_percentage_date = . if hba1c_percentage == .
replace hba1c_mmol_per_mol_date = . if hba1c_mmol_per_mol == .

/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)

/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==0
replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabcat 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabcat

* create cancer *variable 'other cancer currently' includes carcinoma of the head and neck - need to confirm if this excludes NMSC
gen cancer =0
replace cancer =1 if lung_cancer ==1 | haem_cancer ==1 | other_cancer ==1

*creat other comorbid variables
gen combined_cv_comorbid =1 if chronic_cardiac_disease ==1 | stroke==1


* Delete unneeded variables
drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol

*************************************************************************************************
/* POPULATIONS =============================================================*/

/* Diagnosis =============*/
*include only most recent diagnosis within each specialty
*Rheum
replace rheumatoid_arthritis =0 if psoriatic_arthritis_date > rheumatoid_arthritis_date & psoriatic_arthritis_date !=.
replace rheumatoid_arthritis =0 if ankylosing_spondylitis_date > rheumatoid_arthritis_date & ankylosing_spondylitis_date !=.
replace psoriatic_arthritis	=0 if rheumatoid_arthritis_date > psoriatic_arthritis_date & rheumatoid_arthritis_date !=.
replace psoriatic_arthritis	=0 if ankylosing_spondylitis_date > psoriatic_arthritis_date & ankylosing_spondylitis_date !=.
replace ankylosing_spondylitis =0 if psoriatic_arthritis_date > ankylosing_spondylitis_date & psoriatic_arthritis_date !=.
replace ankylosing_spondylitis =0 if rheumatoid_arthritis_date > ankylosing_spondylitis_date & rheumatoid_arthritis_date !=.

 
*Derm
replace psoriasis =0 if hidradenitis_suppurativa_date > psoriasis_date & hidradenitis_suppurativa_date !=.
*replace psoriasis =0 if atopic_dermatitis_date > psoriasis_date & atopic_dermatitis_date !=.
replace hidradenitis_suppurativa =0 if psoriasis_date > hidradenitis_suppurativa_date & psoriasis_date !=.
*replace hidradenitis_suppurativa =0 if atopic_dermatitis_date > hidradenitis_suppurativa_date & atopic_dermatitis_date !=.
*replace atopic_dermatitis =0 if psoriasis_date > atopic_dermatitis_date & psoriasis_date !=.
*replace atopic_dermatitis =0 if hidradenitis_suppurativa_date > atopic_dermatitis_date & hidradenitis_suppurativa_date !=.

*Gastro
replace ibd_uncla =0 if ulcerative_colitis_date > ibd_uncla_date  & ulcerative_colitis_date !=.
replace ibd_uncla =0 if crohns_disease_date > ibd_uncla_date  & crohns_disease_date !=.
replace ulcerative_colitis =0 if crohns_disease_date > ulcerative_colitis_date & crohns_disease_date !=.
replace ulcerative_colitis =0 if ibd_uncla_date > ulcerative_colitis_date & ibd_uncla_date !=.
replace crohns_disease =0 if ulcerative_colitis_date > crohns_disease_date & ulcerative_colitis_date !=.
replace crohns_disease =0 if ibd_uncla_date > crohns_disease_date & ibd_uncla_date !=.

*consider the effect of patients diagnosed with imid post 1st March 2020
*ignoring this will bias to null
*diagnoses after 1st March have been culled via python code

gen imid = .
replace imid = 1 if rheumatoid_arthritis ==1 | psoriatic_arthritis ==1 | ankylosing_spondylitis==1 | ibd_uncla ==1 | ulcerative_colitis ==1 | crohns_disease ==1 | psoriasis ==1 | hidradenitis_suppurativa ==1
replace imid = 0 if rheumatoid_arthritis !=1 & psoriatic_arthritis !=1 & ibd_uncla !=1 & ulcerative_colitis !=1 & crohns_disease !=1 & psoriasis !=1 & hidradenitis_suppurativa !=1 & ankylosing_spondylitis !=1

label define imid 0 "Gen Pop" 1 "IMID"
label values imid imid

gen bowel =0
replace bowel =1 if crohns_disease ==1 | ibd_uncla ==1 | ulcerative_colitis ==1
label define bowel 0 "Gen Pop" 1 "Bowel"
label values bowel bowel

gen skin =0
replace skin =1 if psoriasis ==1 | hidradenitis_suppurativa ==1
label define skin 0 "Gen Pop" 1 "Skin"
label values skin skin

gen joint =0
replace joint =1 if rheumatoid_arthritis ==1 | psoriatic_arthritis ==1 | ankylosing_spondylitis ==1
label define joint 0 "Gen Pop" 1 "Joint"
label values joint joint


*Loop to replace missing with 0
foreach var of varlist  oral_prednisolone_3m_0m  ///
						oral_prednisolone_6m_3m  /// 
						adalimumab_3m_0m 		 ///
						adalimumab_6m_3m		 ///
						abatacept_3m_0m			 ///
						abatacept_6m_3m			 ///
						certolizumab_3m_0m		 ///
						certolizumab_6m_3m       ///
						etanercept_3m_0m		 ///
						etanercept_6m_3m		 ///
						golimumab_3m_0m			 ///
						golimumab_6m_3m  		 ///
						infliximab_3m_0m		 ///
						infliximab_6m_3m		 ///
						sarilumab_3m_0m			 ///
						sarilumab_6m_3m			 ///
						tocilizumab_3m_0m		 ///
						tocilizumab_6m_3m		 ///
						ustekinumab_3m_0m 		 ///
						ustekinumab_6m_3m		 ///
						guselkumab_3m_0m 		 ///
						guselkumab_6m_3m 		 ///
						tildrakizumab_3m_0m 	 ///
						tildrakizumab_6m_3m 	 ///
						risankizumab_3m_0m 	 	 ///
						risankizumab_6m_3m		 ///
						secukinumab_3m_0m 		 ///
						secukinumab_6m_3m 		 ///
						ixekizumab_3m_0m 		 ///
						ixekizumab_6m_3m 		 ///
						brodalumab_3m_0m 		 ///
						brodalumab_6m_3m		 ///
						baricitinib_3m_0m 		 ///
						baricitinib_6m_3m 		 ///
						tofacitinib_3m_0m 		 ///
						tofacitinib_6m_3m		 ///
						rituximab_12m_6m 		 ///
						rituximab_6m_3m 		 ///
						rituximab_3m_0m			 ///
						azathioprine_3m_0m		 ///
						azathioprine_6m_3m		 ///
						ciclosporin_3m_0m		 ///
						ciclosporin_6m_3m		 ///
						gold_3m_0m				 ///
						gold_6m_3m				 ///
						leflunomide_3m_0m		 ///
						leflunomide_6m_3m		 ///
						mercaptopurine_3m_0m	 ///
						mercaptopurine_6m_3m	 ///
						methotrexate_3m_0m		 ///
						methotrexate_6m_3m		 ///
						methotrexate_inj_3m_0m	 ///
						methotrexate_inj_6m_3m   ///
						methotrexate_hcd_3m_0m 	 ///	
						methotrexate_hcd_6m_3m	 ///
						mycophenolate_3m_0m		 ///
						mycophenolate_6m_3m		 ///
						penicillamine_3m_0m		 ///
						penicillamine_6m_3m		 ///
						sulfasalazine_3m_0m	     ///
						sulfasalazine_6m_3m		 ///
						mesalazine_3m_0m		 ///
						mesalazine_6m_3m	{
						
						replace `var' =0 if `var' ==.
						}


*stand sys drugs data are count, not binary!
gen standsys =1 if azathioprine_3m_0m >=1 | azathioprine_6m_3m >=1 | ciclosporin_3m_0m >=1 |ciclosporin_6m_3m >=1 | leflunomide_3m_0m >=1 |leflunomide_6m_3m >=1 | mercaptopurine_3m_0m >=1 |mercaptopurine_6m_3m >=1 | methotrexate_3m_0m >=1 | methotrexate_6m_3m >=1 | methotrexate_inj_3m_0m >=1 | methotrexate_inj_6m_3m >=1 |methotrexate_hcd_3m_0m >=1 | methotrexate_hcd_6m_3m >=1 | mycophenolate_3m_0m >=1 | mycophenolate_6m_3m >=1 | sulfasalazine_3m_0m >=1 |sulfasalazine_6m_3m >=1 | mesalazine_3m_0m >=1 | mesalazine_6m_3m >=1
replace standsys =. if imid !=1

gen standsys3m =1 if azathioprine_3m_0m >=1 | ciclosporin_3m_0m >=1 | leflunomide_3m_0m >=1 | mercaptopurine_3m_0m >=1 | methotrexate_3m_0m >=1 | methotrexate_inj_3m_0m >=1 | methotrexate_hcd_3m_0m >=1 | mycophenolate_3m_0m >=1 | sulfasalazine_3m_0m >=1  | mesalazine_3m_0m >=1
replace standsys3m =. if imid !=1

gen tnf =1 if adalimumab_6m_3m !=0 | adalimumab_3m_0m !=0 | certolizumab_6m_3m !=0 | certolizumab_3m_0m !=0 | etanercept_6m_3m !=0 | etanercept_3m_0m !=0 | golimumab_6m_3m !=0 | golimumab_3m_0m !=0 | infliximab_6m_3m !=0 | infliximab_3m_0m !=0
replace tnf =. if imid !=1

gen inflix=1 if infliximab_6m_3m !=0 | infliximab_3m_0m !=0
replace inflix =. if imid !=1

gen tnfmono =1 if tnf==1 & standsys !=1
recode tnfmono .=0 if tnf==1 & standsys ==1

label define tnfmono 	0 "TNF combination"  			///
						1 "TNF monotherapy"	
label values tnfmono tnfmono
label var tnfmono "TNF strategy"

*high cost drug data pull through as binary variable, not count
gen standtnf =1 if tnf ==1
replace standtnf =0 if standsys ==1 & tnf !=1

gen standtnf3m =1 if adalimumab_3m_0m ==1 | certolizumab_3m_0m ==1 | etanercept_3m_0m ==1 | golimumab_3m_0m ==1 | infliximab_3m_0m ==1
replace standtnf3m =0 if adalimumab_3m_0m !=1 & certolizumab_3m_0m !=1 & etanercept_3m_0m !=1 & golimumab_3m_0m !=1 & infliximab_3m_0m !=1 & standsys3m ==1
				
gen il23 =1 if ustekinumab_3m_0m !=0 | ustekinumab_6m_3m !=0 | guselkumab_3m_0m !=0 | guselkumab_6m_3m !=0 | tildrakizumab_3m_0m !=0 | tildrakizumab_6m_3m !=0 | risankizumab_3m_0m !=0 | risankizumab_6m_3m !=0 
replace il23 =. if imid !=1

gen standil23 =1 if il23 ==1
replace standil23 =0 if standsys ==1 & il23 !=1

gen standil233m =1 if ustekinumab_3m_0m ==1 | guselkumab_3m_0m ==1 | tildrakizumab_3m_0m ==1 | risankizumab_3m_0m ==1 
replace standil233m =0 if ustekinumab_3m_0m !=1 & guselkumab_3m_0m !=1 & tildrakizumab_3m_0m !=1 & risankizumab_3m_0m !=1 & standsys3m ==1

gen jaki =1 if baricitinib_3m_0m !=0 | baricitinib_6m_3m !=0 | tofacitinib_3m_0m !=0 | tofacitinib_6m_3m !=0 
replace jaki =. if imid !=1

gen standjaki =1 if jaki ==1
replace standjaki =0 if standsys ==1 & jaki !=1

gen standjaki3m =1 if baricitinib_3m_0m ==1 | tofacitinib_3m_0m ==1 
replace standjaki3m =0 if baricitinib_3m_0m !=1 & tofacitinib_3m_0m !=1 & standsys3m ==1

gen ritux =1 if rituximab_3m_0m !=0 | rituximab_6m_3m !=0 | rituximab_12m_6m !=0
replace ritux =. if rheumatoid_arthritis !=1

gen standritux =1 if ritux ==1
replace standritux =0 if standsys ==1 & ritux !=1

gen standritux3m =1 if rituximab_3m_0m ==1
replace standritux3m =0 if rituximab_3m_0m !=1 & standsys3m ==1

gen il6 =1 if sarilumab_3m_0m !=0 | sarilumab_6m_3m !=0 | tocilizumab_3m_0m !=0 | tocilizumab_6m_3m !=0
replace il6 =. if rheumatoid_arthritis !=1

gen standil6 =1 if il6 ==1
replace standil6 =0 if standsys ==1 & il6 !=1

gen standil63m =1 if sarilumab_3m_0m ==1 | tocilizumab_3m_0m ==1
replace standil63m =0 if sarilumab_3m_0m !=1 & tocilizumab_3m_0m !=1 & standsys3m ==1

gen il17 =1 if secukinumab_3m_0m !=0 | secukinumab_6m_3m !=0 | ixekizumab_3m_0m !=0 | ixekizumab_6m_3m !=0 | brodalumab_3m_0m !=0 | brodalumab_6m_3m !=0 
replace il17 =. if psoriatic_arthritis !=1 & ankylosing_spondylitis !=1 & psoriasis !=1

gen standil17 =1 if il17 ==1
replace standil17 =0 if standsys ==1 & il17 !=1

gen standil173m =1 if secukinumab_3m_0m ==1 | ixekizumab_3m_0m ==1 | brodalumab_3m_0m ==1 
replace standil173m =0 if secukinumab_3m_0m !=1 & ixekizumab_3m_0m !=1 & brodalumab_3m_0m !=1 & standsys3m ==1

gen mesalazine =1 if mesalazine_3m_0m >=1 | mesalazine_6m_3m >=1
replace mesalazine =. if imid !=1

gen standmesalazine =1 if mesalazine >=1
replace standmesalazine =0 if standsys ==1 & mesalazine ==0

gen standmesalazine3m =1 if mesalazine_3m_0m >=1
replace standmesalazine3m =0 if mesalazine_3m_0m ==0 & standsys3m ==1

gen steroidcat = 0
replace steroidcat =1 if oral_prednisolone_3m_0m >=1 & oral_prednisolone_3m_0m!=.

*gen imiddrugcategory = (standard v highcost)
gen imiddrugcategory = 1 if standtnf ==1 | standil23 ==1 | standjaki ==1 | standritux ==1 | standil6 ==1 | standil17 ==1
recode imiddrugcategory .=0 if standsys ==1 

foreach var in standtnf standtnf3m standil6 standil17 standil23 standjaki standritux inflix {
	recode `var' 0=. if imiddrugcategory ==1
}


/* OUTCOME AND SURVIVAL TIME==================================================*/
/*  Cohort entry and censor dates  */

* Date of cohort entry, 1 Mar 2020
gen enter_date = date("$indexdate", "DMY")
format enter_date %td

/*   Outcomes   */

* Outcomes: itu admission, ONS-covid death, hospital admission   

* Add half-day buffer if outcome on indexdate
replace died_ons_date=died_ons_date+0.5 if died_ons_date==enter_date
replace icu_admitted_date=icu_admitted_date+0.5 if icu_admitted_date==enter_date
replace hospital_admission_date=hospital_admission_date+0.5 if hospital_admission_date==enter_date

* Date of Covid death in ONS
gen died_ons_date_covid = died_ons_date if died_ons_covid_flag_any == 1

* Date of non-COVID death in ONS 
* If missing date of death resulting died_date will also be missing
gen died_ons_date_noncovid = died_ons_date if died_ons_covid_flag_any != 1 

*date of COVID hospital admission ** issue we have is how we define a hospital admission as a COVID one. 
gen hosp_admit_diff = hospital_admission_date - first_pos_test_sgss_date
replace hosp_admit_diff =. if hosp_admit_diff <-5
gen hosp_admit_date_covid = hospital_admission_date if hosp_admit_diff <28 
gen hosp_admit_covid =1 if hosp_admit_date_covid !=.

*date of COVID ITU admission ** issue we have is how we define an ITU admission as a COVID one. 
gen icu_admit_date_covid = icu_admitted_date if hosp_admit_covid ==1 
gen icu_or_death_covid_date = icu_admit_date_covid
replace icu_or_death_covid_date = died_ons_date_covid if icu_admit_date_covid ==.
gen icu_or_death_covid =1 if icu_or_death_covid_date !=.

//it is possible to be in the ICU / died cohort, but NOT in hospital cohort IF a patient dies from COVID in community

* sensitivity analysis extra variables - COVID hospital admission ** excluding 28 day cut off
gen hosp_admit_date_covid_sens = hospital_admission_date if hosp_admit_diff !=. 
gen hosp_admit_covid_sens =1 if hosp_admit_date_covid_sens !=.

gen icu_admit_date_covid_sens = icu_admitted_date if hosp_admit_covid ==1 
gen icu_covid_sens =1 if icu_admit_date_covid_sens !=.


format died_ons_date_covid died_ons_date_noncovid icu_admit_date_covid icu_or_death_covid_date hosp_admit_date_covid hosp_admit_date_covid_sens icu_admit_date_covid_sens %td


/* CENSORING */
/* SET FU DATES===============================================================*/ 
* Censoring dates for each outcome (largely, last date outcome data available, minus a lag window based on previous graphs)
*death
tw histogram died_ons_date, discrete width(2) frequency ytitle(Number of ONS deaths) xtitle(Date) scheme(meta) saving(out_death_freq, replace)
graph export "output/figures/out_death_freq.pdf", as(pdf) replace
graph close
/* erase out_death_freq.pdf
summ died_ons_date, format */
*gen onscoviddeathcensor_date = r(max)-7



foreach var in imid joint skin bowel imiddrugcategory standtnf standtnf3m tnfmono  standil6 standil17 standil23 standjaki standritux inflix {
	preserve
	drop if `var' ==.
	save $projectdir/output/data/file_`var', replace	
	restore
}

log close
