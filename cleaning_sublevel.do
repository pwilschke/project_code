//ONLY RUN THIS THROUGH THE OFFICIAL CLEANING DO FILE: cleaning.do
compress, nocoalesce
//cleaning.do will iterate this process across each Hilltop state file; then merge them all together. 

//Can keep only non-missing prices for ease of data manipulation, since we can't do anything w/ those, analysis-wise
drop if price == .

//Standardizing hospital_name 
replace hospital_name = lower(hospital_name)
replace hospital_name = subinstr(hospital_name, "-", "", .) 
replace hospital_name = subinstr(hospital_name, "&", "", .) 
replace hospital_name = subinstr(hospital_name, "'", "", .)  
replace hospital_name = subinstr(hospital_name, "  ", " ", .)

gen prvdr_num = string(ccn)

//Creating usable categories from price_type
do "$code/cleaning_price_type.do"

************************Merge with HHI + ARHQ data******************************
//Should be totally unnecessary to merge along hospital name if we are using ccn

merge m:1 ccn /*hospital_name*/ state using "$intermediate_data/arhq_hhi_data.dta", force
drop if _merge != 3
drop _merge


