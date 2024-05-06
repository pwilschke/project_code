********************************************************************************
**********************************Setup*****************************************
********************************************************************************
//RUN THE SETUP DO FILE FIRST. 


********************************************************************************
**************************Start of Data Work************************************
********************************************************************************
use "$intermediate_data/shoppables_analysis.dta", clear
gen pop_sqd = pop*pop

//Basic research q: How do prices vary in rural vs urban hospitals?
regress log_price pop pop_sqd age hh_inc hosp_per_zip, robust
//Population has a positive and significant coef: so does household income, and also, the more hospitals per zip code, the cheaper prices are. This is OVERALL

//Cash Prices
regress log_price pop pop_sqd age hh_inc hosp_per_zip if cash == 1, robust

//Commercial Prices
regress log_price pop pop_sqd age hh_inc hosp_per_zip if comm == 1, robust

//Govt Prices
regress log_price pop pop_sqd age hh_inc hosp_per_zip if govt == 1, robust