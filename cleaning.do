********************************************************************************
**********************************Setup*****************************************
********************************************************************************
//RUN THE SETUP DO FILE FIRST. 

********************************************************************************
*********************Pulling in Census demographic data*************************
********************************************************************************
//Age and Sex (note: also has population)
import delimited using "$raw_data/ACSDP5Y2022.DP05-Data.csv", varnames(1) clear
drop if _n == 1

keep name dp05_0001e dp05_0018e
ren name zip_cd
ren dp05_0001e pop
ren dp05_0018e age


replace zip_cd = subinstr(zip_cd, "ZCTA5 ", "", .)
replace zip_cd = "00" + zip_cd if length(zip_cd) == 3
replace zip_cd = "0" + zip_cd if length(zip_cd) == 4

destring age pop, replace force
//we have some whose data they won't give us, they have 0 pop so dropping to avoid any confusion later
drop if age == .

save "$intermediate_data/age_pop_byzip.dta", replace 

//Income (has population too, but we'll get it from age & sex)
import delimited using "$raw_data/ACSST5Y2022.S1901-Data.csv", varnames(1) clear
drop if _n == 1

keep name s1901_c01_012e
ren name zip_cd
replace zip_cd = subinstr(zip_cd, "ZCTA5 ", "", .)
ren s1901_c01_012e hh_inc
replace zip_cd = "00" + zip_cd if length(zip_cd) == 3
replace zip_cd = "0" + zip_cd if length(zip_cd) == 4

destring hh_inc, replace force

drop if hh_inc == .

save "$intermediate_data/hh_inc_byzip.dta", replace

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

**********************Merging in CMS Services***********************************
merge m:1 code using "$intermediate_data/shoppable_services.dta", force
gen shoppable = 0
replace shoppable = 1 if _merge == 3
drop _merge
//now we have a dummy indicator for whether an obs is one of the 70 shoppable services!

*******************Merging in Census demographic data***************************
merge m:1 zip_cd using "$intermediate_data/age_pop_byzip.dta", force
drop if _merge == 2
drop _merge

merge m:1 zip_cd using "$intermediate_data/hh_inc_byzip.dta", force
drop if _merge == 2
drop _merge


********************************************************************************
*********************Creating Vars for Regressions******************************
********************************************************************************
//These can be whatever we want to use; for now there's not much here, but the dummies below are useful in pretty much any analysis we'd like to do


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

//Doing log price for dependent variable. Log price + 1 is b/c there are a bunch of zero's that we'd like to keep around

gen log_price = ln(price+1)

//Number of hospitals per zip code area: control
egen tag = tag(ccn zip_cd)
egen hosp_per_zip = total(tag), by(zip_cd)

save "$intermediate_data/analysis_data.dta", replace

//Separate, smaller, dataset if we just want to work with shoppables only
preserve
keep if shoppable == 1
save "$intermediate_data/shoppables_analysis.dta", replace
restore
