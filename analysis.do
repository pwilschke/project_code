********************************************************************************
**********************************Setup*****************************************
********************************************************************************
//RUN THE SETUP DO FILE FIRST. 


********************************************************************************
**************************Start of Data Work************************************
********************************************************************************
use "$intermediate_data/shoppables_analysis.dta", clear

est clear
//Basic research q: How do prices vary in rural vs urban hospitals?
eststo: areg log_price pop age hh_inc hosp_per_zip, absorb(code) robust
//Population has a positive and significant coef: so does household income, and also, the more hospitals per zip code, the cheaper prices are. This is OVERALL

//Commercial Prices
eststo: areg log_price pop age hh_inc hosp_per_zip if comm == 1, absorb(code) robust
estadd scalar r2s = e(r2_a)
estadd local fe "Procedure Code"
//Cash Prices
eststo: areg log_price pop age hh_inc hosp_per_zip if cash == 1, absorb(code) robust
estadd scalar r2s = e(r2_a)
estadd local fe "Procedure Code"
//Govt Prices
eststo: areg log_price pop age hh_inc hosp_per_zip if govt == 1, absorb(code) robust
estadd scalar r2s = e(r2_a)
estadd local fe "Procedure Code"

esttab using "$output/regressions.tex", replace  ///
 b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) ///
 stats(r2s N fe, label("Adj. R$^2$" "Obs" "Fixed Effects")fmt(3 0)) ///
 booktabs  ///
 title("Regressions by Payor Type"})   ///
 mtitles("Commercial Payors" "Cash Prices" "Government Payors") ///
 addnotes("Dependent Variable: Log(Procedure Price+1)")