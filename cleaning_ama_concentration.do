********************************************************************************
*****************Importing AMA Insurer Competitiveness Table********************
********************************************************************************

*Source: https://www.ama-assn.org/system/files/competition-health-insurance-us-markets.pdf, table A1

//Before doing the first table, preparing to connect states to state cds
import delimited using "$raw_data/states.csv", clear
ren v1 state_name
replace state_name = upper(state_name)
ren v2 state_cd
drop if _n == 1

save "$raw_data/state_cd_link.dta", replace
*****************
*****************
*Table A1 - all markets
*****************
*****************
import delimited using "$raw_data\AMA_insurer_A1.txt", clear

*First, keep only the states - keep if v2 is empty 
keep if missing(v2)

*Now, clean this up
replace v1 = upper(v1)

*Grab the state name
gen state_name = word(v1, 1)

*Replace this for the two-worded states 
replace state_name = "DISTRICT OF COLUMBIA" if strpos(v1, "DISTRICT OF COLUMBIA")!=0 
replace state_name = "NEW YORK" if strpos(v1, "NEW YORK")!=0 
replace state_name = "NEW HAMPSHIRE" if strpos(v1, "NEW HAMPSHIRE")!=0 
replace state_name = "NEW JERSEY" if strpos(v1, "NEW JERSEY")!=0 
replace state_name = "NEW MEXICO" if strpos(v1, "NEW MEXICO")!=0 
replace state_name = "NORTH CAROLINA" if strpos(v1, "NORTH CAROLINA")!=0 
replace state_name = "NORTH DAKOTA" if strpos(v1, "NORTH DAKOTA")!=0 
replace state_name = "RHODE ISLAND" if strpos(v1, "RHODE ISLAND")!=0 
replace state_name = "SOUTH CAROLINA" if strpos(v1, "SOUTH CAROLINA")!=0 
replace state_name = "SOUTH DAKOTA" if strpos(v1, "SOUTH DAKOTA")!=0 
replace state_name = "WEST VIRGINIA" if strpos(v1, "WEST VIRGINIA")!=0 

*Now, make a copy of v1 and cut this out
gen v1_copy = v1
replace v1_copy = subinstr(v1_copy, state_name, "", 1)

*NOw, take the first word from the copy. That's hhi
gen hhi = word(v1_copy, 1)

*NOw, cut this out
replace v1_copy = trim(v1_copy)
replace v1_copy = subinstr(v1_copy, hhi, "", 1)
replace v1_copy = trim(v1_copy)

*Now, find the string position of the first numbers
local c = 1
foreach i in "1" "2" "3" "4" "5" "6" "7" "8" "9"{
gen strpos_`c' = strpos(v1_copy, "`i'")
local c = `c' + 1
}

*Now, take the minimum that's not zero - THAT'S where the first number shows up
forval i = 1/9{
replace strpos_`i' = . if strpos_`i'==0
}
egen first_num = rowmin(strpos_*)

*Now, cut at the first number 
gen ins_1 = substr(v1_copy, 1, first_num-1)

*Now, cut this from v1_copy 
replace v1_copy = subinstr(v1_copy, ins_1, "", 1)

*NOw, trim
replace ins_1 = trim(ins_1)

*Now, grab the first word  from v1_ copy - this is market share
gen mkt_share_1 = word(v1_copy, 1)
replace mkt_share_1 = trim(mkt_share_1)

*Now, cut this out of v1 copy
replace v1_copy = subinstr(v1_copy, mkt_share_1, "", 1)

*Now, grab the final word - this is market share for the second insurer
gen mkt_share_2 = word(v1_copy, -1)

*replace this in the v1_copy - what's left is the name of the second most popular insurer
replace v1_copy = subinstr(v1_copy, mkt_share_2, "", 1)

*Now, rename
ren v1_copy ins_2

*Now, order
order state_name hhi ins_1 mkt_share_1 ins_2 mkt_share_2, first 
keep state_name hhi ins_1 mkt_share_1 ins_2 mkt_share_2
destring hhi, replace
destring mkt_share_1, replace
destring mkt_share_2, replace

*merge with state code

merge m:1 state_name using "$raw_data/state_cd_link.dta", force
drop if _merge != 3
drop _merge

*Now, save 
save "$intermediate_data\ama_ins_state_3_6_24", replace


*****************
*****************
*****************
*Now, do the MSAs
*****************
*****************
*****************
import delimited using "$raw_data\AMA_insurer_A1.txt", clear

*State and MSAs TOTAL HHI Insurer 1 Share (%) Insurer 2 Share (%)

*First, keep only the MSA - drop if v2 is empty 
drop if missing(v2)

*Now, rename the v1 to be MSA, and then use the same code as above for the v2
ren v1 msa
ren v2 v1

*Now, clean this up
replace v1 = upper(v1)

*Grab the state abb
gen state_abb = word(v1, 1)

*Now, make a copy of v1 and cut this out
gen v1_copy = v1
replace v1_copy = subinstr(v1_copy, state_abb, "", 1)
replace v1 = trim(v1)

*NOw, take the first word from the copy. That's hhi
gen hhi = word(v1_copy, 1)

*NOw, cut this out
replace v1_copy = trim(v1_copy)
replace v1_copy = subinstr(v1_copy, hhi, "", 1)
replace v1_copy = trim(v1_copy)

*quick fix - POINT32HEALTH is breaking... rename quickly, then rename back at end
replace v1_copy = subinstr(v1_copy, "POINT32HEALTH", "POINTTHREETWOHEALTH", .)

*Now, find the string position of the first numbers
local c = 1
foreach i in "1" "2" "3" "4" "5" "6" "7" "8" "9"{
gen strpos_`c' = strpos(v1_copy, "`i'")
local c = `c' + 1
}

*Now, take the minimum that's not zero - THAT'S where the first number shows up
forval i = 1/9{
replace strpos_`i' = . if strpos_`i'==0
}
egen first_num = rowmin(strpos_*)

*Now, cut at the first number 
gen ins_1 = substr(v1_copy, 1, first_num-1)

*Now, cut this from v1_copy 
replace v1_copy = subinstr(v1_copy, ins_1, "", 1)

*NOw, trim
replace ins_1 = trim(ins_1)

*Now, grab the first word  from v1_ copy - this is market share
gen mkt_share_1 = word(v1_copy, 1)
replace mkt_share_1 = trim(mkt_share_1)

*Now, cut this out of v1 copy
replace v1_copy = subinstr(v1_copy, mkt_share_1, "", 1)

*Now, grab the final word - this is market share for the second insurer
gen mkt_share_2 = word(v1_copy, -1)

*replace this in the v1_copy - what's left is the name of the second most popular insurer
replace v1_copy = subinstr(v1_copy, mkt_share_2, "", 1)

*Now, rename
ren v1_copy ins_2

*Now, replace POINTTHREETWOHEALTH with POINT32HEALTH
replace ins_1 = "POINT32HEALTH" if ins_1 == "POINTTHREETWOHEALTH"
replace ins_2 = "POINT32HEALTH" if ins_2 == "POINTTHREETWOHEALTH"

*Now, order
order msa state_abb hhi ins_1 mkt_share_1 ins_2 mkt_share_2, first 
keep msa state_abb hhi ins_1 mkt_share_1 ins_2 mkt_share_2
destring hhi, replace
destring mkt_share_1, replace
destring mkt_share_2, replace

//Standardizing MSA name to merge with MSA code
replace msa = lower(msa)
replace msa = subinstr(msa, "--", "-", .)
replace msa = subinstr(msa, " ", "", .)

//Need to split apart any state abbreviations here too
split state_abb, p("-")

duplicates drop msa state_abb1, force

//TESTING: splitting MSA names here for easier merge

split msa, p("-")
//now we have msa1-msa4

*Now, save 
save "$intermediate_data\ama_ins_MSA_3_6_24", replace
//381 MSAs in this file


***********************************
//Connecting MSAs to zip code
***********************************
//Multiple steps: first connecting MSA names from AMA to MSA (CBSA) code, then connecting CBSAs to ZIP codes

***********************************
//using NBER MSA crosswalk to connect MSA name to CBSA code
***********************************
use "$raw_data/cbsa2fipsxw.dta", clear

//Standardizing MSA name to merge with MSA code
keep if metropolitanmicropolitanstatis == "Metropolitan Statistical Area"
ren cbsatitle msa
replace msa = lower(msa)
replace msa = subinstr(msa, "--", "-", .)
replace msa = subinstr(msa, " ", "", .)
//get the state name out of the MSA string to merge
split msa, p(",")
drop msa msa2
ren msa1 msa

ren statename state_name
replace state_name = upper(state_name)

merge m:1 state_name using "$raw_data/state_cd_link.dta"
keep if _merge == 3
drop _merge

ren state_cd state_abb1

collapse (lastnm) state_abb1 state_name msa, by(cbsacode)
//387 MSA names and CBSA codes here!

//TESTING splitting MSA names here too
split msa, p("-")

merge 1:1 msa1 state_abb1 using "$intermediate_data/ama_ins_MSA_3_6_24.dta", force


//This merges most MSAs: many non-merges here are because of the second or third name of the MSA not being perfectly standardized. For instance, "panamacity" does not merge with "panamacity-panamacitybeach" despite the two almost assuredly being the same MSA. It does catch 308 out of 381 MSAs though

sort state_abb1 msa
order msa state_abb1 cbsacode _merge
save "$intermediate_data/msa_merge_p1.dta", replace

*******PART TWO of the merge: merging any failed ones that link a first name to a second name
use "$intermediate_data/msa_merge_p1.dta", clear
//Only interested here in the ones that failed the initial merge, from the NBER side
keep if _merge == 1
drop _merge

drop msa1
ren msa2 msa1

merge m:1 msa1 state_abb1 using "$intermediate_data/ama_ins_MSA_3_6_24.dta", force
//Adds more of them!
keep if _merge == 3 //only keeping those that we were able to update
drop _merge

save "$intermediate_data/msa_merge_p2.dta", replace


********Combining parts of MSA merges
use "$intermediate_data/msa_merge_p1.dta", clear
keep if _merge == 3
drop _merge

append using "$intermediate_data/msa_merge_p2.dta", force

//clearing the intermediate steps
erase "$intermediate_data/msa_merge_p1.dta"
erase "$intermediate_data/msa_merge_p2.dta"

ren cbsacode msa_cd
destring msa_cd, replace force

collapse (lastnm) msa state_abb1 hhi ins_1 mkt_share_1 ins_2 mkt_share_2, by(msa_cd)

save "$intermediate_data/hhi_msa_codes.dta", replace

******************Bringing in MSA-ZIP matcher***********************************
import excel using "$raw_data/cbsa_zip_032022.xlsx", sheet(CBSA_ZIP_032022) firstrow clear 
keep CBSA ZIP
ren CBSA msa_cd
ren ZIP zip_cd
destring msa_cd, replace force

merge m:1 msa_cd using "$intermediate_data/hhi_msa_codes.dta", force
//Good merge; catching all MSAs in the HHI-MSA dataset
keep if _merge == 3
drop _merge

//In very occasional situations (182/5058 obs) the same zip code overlaps into two MSAs. In this case, taking the "average HHI" for that zip code: so just the average HHI of the two MSAs comprising that zip code.
//Note also that this is collapsing to the zip code level -- functionally equivalent to doing it at the state level
collapse (mean) hhi mkt_share_1 mkt_share_2 (lastnm) msa msa_cd ins_1 ins_2, by(zip_cd)

save "$intermediate_data/msa_hhi_zip.dta", replace

********************************************************************************
*************Finally, merging MSAs to Zip Codes in Hilltop data*****************
********************************************************************************
//This part of the code happens in cleaning_sublevel: once we've run this and produced msa_hhi_zip, it eventually will merge with the Hilltop data. 

//CURRENTLY: the merge is not good enough so it does not happen. 

























