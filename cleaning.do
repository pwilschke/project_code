********************************************************************************
**********************************Setup*****************************************
********************************************************************************
//RUN THE SETUP DO FILE FIRST. 

//Alternative HHI measure: from AMA Health Insurance Concentration measure, which is downloadable and has state and MSA level "total HHI" measure. Code to run this is taken from MH's previously created code for opening text files in Stata; running that separately here, which just produces the file. 

do "$code/cleaning_ama_concentration.do"

********************************************************************************
***********************Preparing CMS 70 services********************************
********************************************************************************
//Alternative to using procedure code FEs: list of 70 shoppable services that hospitals must have on their sites. 
import excel using "$raw_data/cms_services.xlsx", firstrow clear
//First, a few codes require attention: they have multiple options!
split code, p(– "or")

preserve
drop code code2
ren code1 code
save "$raw_data/temp1.dta", replace
restore
drop code code1
ren code2 code
drop if missing(code)
save "$raw_data/temp2.dta", replace

use "$raw_data/temp1.dta", clear
append using "$raw_data/temp2.dta", force

erase "$raw_data/temp1.dta"
erase "$raw_data/temp2.dta"

save "$intermediate_data/shoppable_services.dta", replace


********************************************************************************
********************Data on Rural vs Urban Hospitals****************************
********************************************************************************
//from https://ruralhospitals.chqpr.org/Data.html
import excel using "$raw_data/urban_rural_hospitals.xlsx", firstrow clear

ren Hospital hospital_name
replace hospital_name = lower(hospital_name)
replace hospital_name = subinstr(hospital_name, "-", "", .) 
replace hospital_name = subinstr(hospital_name, "&", "", .) 
replace hospital_name = subinstr(hospital_name, "'", "", .)  
replace hospital_name = subinstr(hospital_name, "  ", " ", .)

ren State state_cd

save "$intermediate_data/urban_rural_hospitals.dta", replace
********************************************************************************
*******************Preparing hospital systems data for merges*******************
********************************************************************************
import excel using "$raw_data/chsp-hospital-linkage-2022-rev.xlsx", firstrow clear
//Data dictionary:
//https://www.ahrq.gov/sites/default/files/wysiwyg/chsp/compendium/2022-hospital-linkage-techdoc-021224.pdf

//Hospitals that aren't acute care hospitals are not ones that we'd like to deal with
keep if acutehosp_flag == 1

replace hospital_name = lower(hospital_name)
replace hospital_name = subinstr(hospital_name, "-", "", .) 
replace hospital_name = subinstr(hospital_name, "&", "", .) 
replace hospital_name = subinstr(hospital_name, "'", "", .)  
replace hospital_name = subinstr(hospital_name, "  ", " ", .)

replace ccn = "0" + ccn if length(ccn) == 5
replace ccn = "00" + ccn if length(ccn) == 4

//CAN USE DISCHARGES for hospital market power, exists in this dataset

rename hospital_state state_cd

rename hospital_zip zip_cd

replace zip_cd = "00" + zip_cd if length(zip_cd) == 3
replace zip_cd = "0" + zip_cd if length(zip_cd) == 4

duplicates drop ccn zip_cd state, force

save "$raw_data/hospital_system_raw.dta", replace 
********************************************************************************
**************Merging ARHQ hospital data with HRR zones*************************
********************************************************************************
//Dartmouth matching Hospital Referral Region to zip code
import delimited using "$raw_data/ZipHsaHrr19.csv", clear
//Excel messed up the zip codes, adding zeroes when necessary to get all to their 5 digit forms
gen zip_cd = string(zipcode19)
replace zip_cd = "00" + zip_cd if length(zip_cd) == 3
replace zip_cd = "0" + zip_cd if length(zip_cd) == 4

drop zipcode19

//We may as well make sure results are consistent through HSAs and HRRs both
//Has city-level IDs for HSAs/HRRs, not sure if this is useful

rename hrrstate state_cd

save "$raw_data/zip_hrr_link.dta", replace

//CMS data on hospitals
use "$raw_data/hospital_system_raw.dta", clear

merge m:1 zip_cd state_cd using "$raw_data/zip_hrr_link.dta", force
//Not a perfect merge but we do get 4.2k hospitals linked, out of 4.7k total acute care hospitals. 

drop if _merge != 3
drop _merge

//Standardizing variables and names to merge w/ Hilltop data

rename state_cd state

//Note: there are 14 hospitals with outright missing CCNs. Nothing we can do with them
destring ccn, force replace
drop if missing(ccn)

********************************************************************************
************************HHI Calculation*****************************************
********************************************************************************
//Creating a short function that does the HHI calculation for whichever variables we'd like 

/*For use troubleshooting these commands only: can run this after running them to retest 

drop hhi_dsch
drop hhi_syst_dsch
drop hhi_beds
drop hhi_syst_beds
*/
cap program drop calc_hhi
program calc_hhi
	//groupvar = HHI region to calculate (i.e., HRR in most cases)
	//byvar = level at which to divide up the measure of concentration (i.e., hospital-level or system-level)
	//measure = actual measure of concentration (i.e., discharges or beds)
	//outvar = desired name of the HHI variable
	
	syntax, groupvar(varname) byvar(varname) measure(varname) outvar(name)
	tempvar tot_measure indiv_measure pct_measure pct_sqd dup outtemp
	//Start by getting the denominator for our percentage of [measure]
	bysort `groupvar': egen `tot_measure' = sum(`measure')
	//In case our measure is higher than the observation level, creating the measure level here
	bysort `groupvar' `byvar': egen `indiv_measure' = sum(`measure')
	//creating percent and percent^2 for HHI
	gen `pct_measure' = 100 * (`indiv_measure' / `tot_measure')
	gen `pct_sqd' = `pct_measure' * `pct_measure'
	//Next steps are basically making sure that, if the measure is above the observation level, we're not double-counting observations that are part of the same measure, which would happen by default.
	bysort `groupvar' `byvar': gen `dup' = cond(_N==1, 0, _n)
	bysort `groupvar': egen `outtemp' = sum(`pct_sqd') if `dup' == 0 | `dup' == 1
	bysort `groupvar': egen `outvar' = max(`outtemp')
end

//If hospitals are not in a system, treat them as if they are on their own: else, sum their beds by system and HRR
bysort health_sys_id: gen dup = cond(_N==1, 0, _n)
gen non_syst = string(dup)
replace non_syst = "" if health_sys_id != ""
replace health_sys_id = non_syst if health_sys_id == ""
drop non_syst dup
//Basically this way all the missing system ones (who are not part of a system for us) are not implicitly treated as being part of the same, missing, system: instead they are treated as being their own individual systems which is functionally what we want

//Now we can run the HHI function with whatever we want

calc_hhi, groupvar(hrrnum) byvar(ccn) measure(hos_beds) outvar(hhi_beds)

calc_hhi, groupvar(hrrnum) byvar(ccn) measure(hos_dsch) outvar(hhi_dsch)

calc_hhi, groupvar(hrrnum) byvar(health_sys_id) measure(hos_dsch) outvar(hhi_syst_dsch)

calc_hhi, groupvar(hrrnum) byvar(health_sys_id) measure(hos_beds) outvar(hhi_syst_beds)

save "$intermediate_data/arhq_hhi_data.dta", replace

********************************************************************************
**********Going state by state with Hilltop Data, cleaning + merging************
********************************************************************************
//Currently not including Utah because it is FAR larger than all other state files and hard to run: 35mil observations vs ~7mil in all others combined

local statename arkansas colorado idaho iowa minnesota montana new-mexico north-dakota /*utah*/ virginia wyoming

foreach state of local statename {
	import delimited using "$raw_data/`state'.csv", clear
	
	do "$code/cleaning_sublevel.do"
	
	save "$intermediate_data/`state'_cleaned.dta", replace
}

use "$intermediate_data/arkansas_cleaned.dta", clear

local statename1 colorado idaho iowa minnesota montana new-mexico north-dakota /*utah */virginia wyoming

foreach state of local statename1 {
	append using "$intermediate_data/`state'_cleaned.dta", force
}

compress, nocoalesce

save "$intermediate_data/all_states_hilltop_data.dta", replace

********************************************************************************
****************Creating Insurer HHI and Alt Hosp Concentration*****************
********************************************************************************
use "$intermediate_data/all_states_hilltop_data.dta", clear
**************************First, State HHI**************************************

ren state state_cd

merge m:1 state_cd using "$intermediate_data/ama_ins_state_3_6_24.dta", force
drop if _merge != 3
drop _merge

//Now have state-level HHI measure from the AMA in this file
ren hhi ins_st_hhi
//All the state-level variables
ren ins_1 st_ins_1
ren ins_2 st_ins_2
ren mkt_share_1 st_mkt_share_1
ren mkt_share_2 st_mkt_share_2

**************************Second, MSA HHI***************************************
//This currently does not work very well. No worries for now but should think about fixing... (in cleaning_ama_concentration)

merge m:1 zip_cd using "$intermediate_data/msa_hhi_zip.dta", force
drop if _merge == 2
drop _merge

ren hhi ins_msa_hhi
ren ins_1 msa_ins_1
ren ins_2 msa_ins_2
ren mkt_share_1 msa_mkt_share_1
ren mkt_share_2 msa_mkt_share_2

**********************Merging in CMS Services***********************************
merge m:1 code using "$intermediate_data/shoppable_services.dta", force
gen shoppable = 0
replace shoppable = 1 if _merge == 3
drop _merge
//now we have a dummy indicator for whether an obs is one of the 70 shoppable services!

********************Merging in Rural/Urban Data*********************************
merge m:1 hospital_name state_cd using "$intermediate_data/urban_rural_hospitals.dta", force
drop if _merge == 2
drop _merge

********************************************************************************
*********************Creating Vars for Regressions******************************
********************************************************************************
destring ins_st_hhi, replace

***********Creating hospital-level HHI: may not end up using this***************

//First step: Total number of *actual charges* (i.e., those with non-missing prices) that each hospital has, across all its procedures, ONLY FOR ITS NON-GOVT PRICES -- including Medicare or Medicaid is not super important because they should not impact competition. (If a hospital has a bunch of Medicaid services, and only two insurers, those two insurers are competing with each other, NOT medicaid).

bysort ccn: egen num_procedures = total(plan_category != "Medicaid" & plan_category != "Medicare" & plan_category != "VA" & plan_category != "Dual") 
//note: Medicare Advantage, which is rare to see explicitly anyway, is excluded here, but I think that's correct to do because it's a private plan? In any case, this measure is adjustable, to make sure that won't skew results...

//Now, to produce our measure of *Percent of Total Non-Govt Hospital Services Covered by Payor*, create a measure per hospital and insurer of the total number of services that particular insurer covers: using payor_name, and the same govt-related exclusions
bysort ccn payor_name: egen num_covered = total(plan_category != "Medicaid" & plan_category != "Medicare" & plan_category != "VA" & plan_category != "Dual")

replace num_covered = 0 if payor_name == "" //this is an issue: easiest way to deal with it 

//Make sure to consider doing missing vs 0 -- since we're producing a percentage I think 0 is better so we don't do (.)/(num_procedures)

gen pct_procedures_covered = 100*(num_covered / num_procedures)

//now, square it and sum by hospital
gen pct_procedures_sqd = pct_procedures_covered * pct_procedures_covered

//This time around, we don't want to double-count insurers (which obviously would happen since there are multiple procedures per insurer). So we're using dup_tag again to catch the first of each observation of pct_procedures_covered per hospital, and creating our measure of hhi as the sum of that, which should be correct...

bysort ccn pct_procedures_covered: gen dup_tag = cond(_N==1, 0, _n) 
bysort ccn: egen insurer_hhi_temp = sum(pct_procedures_sqd) if dup_tag == 1
bysort ccn: egen ins_hhi = max(insurer_hhi_temp)
drop insurer_hhi_temp
drop dup_tag

**********************Creating relevant dummies and such************************
//Variable dictionary for ARHQ dataset: https://www.ahrq.gov/sites/default/files/wysiwyg/chsp/compendium/2022-hospital-linkage-techdoc-021224.pdf

//Note that we should be excluding Critical Access Hospitals from the get-go

//Creating dummies for ownership type
//Private, not for profit: majority of these
gen nfp = 0
replace nfp = 1 if hos_ownership == 1

//Some other type
gen public = 0
replace public = 1 if hos_ownership == 2

//For profit
gen fp = 0
replace fp = 1 if hos_ownership == 5

//Local hospital
gen church = 0
replace church = 1 if hos_ownership == 3

//commercial dummy: assuming anything that's not gov't insurer, or cash price/gross charge, is a commercial plan. this may not be 100% realistic, but it is certainly true that the "Commercial" tag in cleaning_price_type vastly underrepresents the universe of commercial plans.

gen comm = 0
replace comm = 1 if plan_category != "Medicaid" & plan_category != "Medicare" & plan_category != "VA" & plan_category != "Dual" & plan_category != "cash" & plan_category != "Gross Charge"

//Cash price dummy
gen cash = 0
replace cash = 1 if plan_category == "Uninsured"

//Govt dummy
gen govt = 0
replace govt = 1 if plan_category == "Medicaid" | plan_category == "Medicare" | plan_category == "VA" | plan_category == "Dual" | payor_name == "State Health Plan" | payor_name == "Government"

//Doing log price for dependent variable. Should go later and make sure I'm doing an acceptable log method...

gen log_price = ln(price+1)

//Interaction terms: Hospital and Insurer HHIs * comm payors and cash price (so results are interpretable in both cases as changes in these w/ concentration relative to gov't payors)

foreach payor in cash comm {
	foreach hhi in ins_st_hhi hhi_dsch hhi_syst_dsch hhi_beds hhi_syst_beds ins_hhi {
		gen `hhi'_x_`payor' = `hhi'*`payor'
	}
}

********************************************************************************
*************************Creating Demeaned Variables****************************
********************************************************************************
//Discounting any singular code observations for this: these are not included in fixed effects and so should not be accounted for in the demeaning process
duplicates tag code, gen(dup)
//if dup == 0, then the code is unique and should not be included; all regressions I'm doing include code FEs so it's not a loss to have these dropped

//NOTE 3/24/24: For some reason, dropping if dup == 0 does not pick up all "unique" codes, according to unique(code). Not sure why...
drop if dup == 0
unique(code)
drop dup
//Replicating code fixed effects through de-meaning all variables: this way we can actually run a qreg and other things without doing 10k FEs
local varlist log_price price hhi_syst_beds hhi_dsch hhi_syst_dsch hhi_beds ins_st_hhi comm govt cash fp public church hos_ucburden hhi_syst_beds_x_comm hhi_dsch_x_comm hhi_syst_dsch_x_comm hhi_beds_x_comm ins_st_hhi_x_comm hhi_syst_beds_x_cash hhi_dsch_x_cash hhi_syst_dsch_x_cash hhi_beds_x_cash ins_st_hhi_x_cash ins_hhi ins_hhi_x_cash ins_hhi_x_comm

foreach var of local varlist {
	bysort code: egen `var'm =  mean(`var')
	gen `var'_code = `var' - `var'm
}

********************************************************************************
*****************Standardizing Independent Variables****************************
********************************************************************************
//With HHI as independent variable, creating standardized HHI vars (mean 0, std 1) for regressions so that effect sizes can be interpreted as the effect of a 1-sd change in HHI (easier plus universally comparable btwn HHIs). Doing all the regular independent variables as well as their demeaned counterparts -- lots bc it includes all interactions!

local indep_vars hhi_syst_beds hhi_syst_dsch hhi_beds hhi_dsch ins_st_hhi hhi_syst_beds_code hhi_syst_dsch_code hhi_beds_code hhi_dsch_code ins_st_hhi_code hhi_syst_beds_x_comm hhi_syst_dsch_x_comm hhi_beds_x_comm hhi_dsch_x_comm ins_st_hhi_x_comm hhi_syst_beds_x_cash hhi_syst_dsch_x_cash hhi_beds_x_cash hhi_dsch_x_cash ins_st_hhi_x_cash hhi_syst_beds_x_comm_code hhi_syst_dsch_x_comm_code hhi_beds_x_comm_code hhi_dsch_x_comm_code ins_st_hhi_x_comm_code hhi_syst_beds_x_cash_code hhi_syst_dsch_x_cash_code hhi_beds_x_cash_code hhi_dsch_x_cash_code ins_st_hhi_x_cash_code ins_hhi ins_hhi_x_cash ins_hhi_x_comm ins_hhi_code ins_hhi_x_cash_code ins_hhi_x_comm_code

foreach ivar of local indep_vars {
	egen std_`ivar' = std(`ivar')
}

//Will use these in all regressions, but can always remove the std_ if desired

//LASTLY: Winsorizing price, which we hope does not affect results but easily may
winsor2 price, cuts(1 99) suffix(_w)
winsor2 log_price, cuts(1 99) suffix(_w)
winsor2 price_code, cuts(1 99) suffix(_w)
winsor2 log_price_code, cuts(1 99) suffix(_w)

save "$intermediate_data/analysis_hhi_data.dta", replace

//Separate, smaller, dataset if we just want to work with shoppables only
preserve
keep if shoppable == 1
save "$intermediate_data/shoppables_analysis.dta", replace
restore
