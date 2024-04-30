/*This Do File should not be run on its own. It is designed to clean the
price_type columns of each cleaned state file. Each cleaned state checking do file
can run this file through itself. 

GENERAL GOAL: takes the (hard to use) price_type column, and produces (currently) three
standardized columns out of it: Plan type, Provider name, and Plan design. Can add more, and can add more potential options to each. When going through each cleaned state, look at all the price_type entries and add to whichever standardized column based on anything seen that doesn't line up. (Run this file on the state data, then tab price_type if plan_category is missing & so on)
*/

//Last edit: Peter Wilschke, 10/12/2023

replace price_type = lower(price_type)

********************************************************************************
******************************PLAN TYPE COLUMN**********************************
********************************************************************************

gen plan_category = ""

replace plan_category = "Commercial" if (strpos(price_type, "commer") > 0 )

replace plan_category = "Medicare Advantage" if strpos(" " + price_type + " ", " ma ") > 0 | strpos(price_type, "medicare adv") > 0 | strpos(price_type, "mcr adv") > 0 | strpos(price_type, "care improvement plus") > 0 | strpos(price_type, "blue advantage") > 0 /*Care Improvement Plus is a United subsidiary explicitly for Advantage plans: https://q1medicare.com/MedicareAdvantage-PartC-MedicareHealthPlanBenefits.php?state=MO&ZIP=&countyCode=29101&contractId=R3444&planId=012&segmentId=0&plan=Care%20Improvement%20Plus%20Medicare%20Advantage%20(Regional%20PPO)*/ | strpos(price_type, "medicare complete") > 0 /*medicare complete is an Advantage plan: https://medicare.healthpartnersplans.com/for-members/plan-details/health-partners-medicare-complete-hmo-pos*/ | strpos(price_type, "med advantage") > 0 | (strpos(price_type, "medicare") > 0 & strpos(price_type, "advantage") > 0) | strpos(price_type, "freedom blue") > 0 /*Freedom Blue is a Medicare Advantage only plan name: https://medicare.highmark.com/resources/medicare-library/plan-documents/freedom-blue-ppo.html*/

replace plan_category = "Medicare" if strpos(price_type, "medicare") > 0 | strpos(price_type, "m'care") > 0  | strpos(price_type, "mcr") > 0 & (strpos(" " + price_type + " ", " ma ") == 0 & strpos(price_type, "medicare adv") == 0 & strpos(price_type, "mcr adv") == 0 & strpos(price_type, "care improvement plus") == 0 & strpos(price_type, "blue advantage") == 0 & strpos(price_type, "medicare complete") == 0 & strpos(price_type, "med advantage") == 0 & strpos(price_type, "advantage") == 0 & strpos(price_type, "freedom blue") == 0 & strpos(price_type, "care improvement plus") > 0 & strpos(price_type, " advantage") > 0)
//making sure to not catch any Medicare Advantage plans in traditional Medicare check

replace plan_category = "Medicaid" if strpos(price_type, "medicaid") > 0 | (strpos(price_type, "summit") > 0 & strpos(price_type, "care") > 0) /* Summit care is part of PASSE below: https://www.summitcommunitycare.com/arkansas-passe/home.html */ | strpos(price_type, "tenncare") > 0 /*Tenessee's Medicaid program: https://www.tn.gov/tenncare/members-applicants/eligibility/tenncare-medicaid.html#:~:text=TennCare%20is%20the%20state%20of,the%20income%20and%20resource%20limits.*/| strpos(price_type, "passe") > 0 /*PASSE is a Medicaid plan for behavioral health in AR: https://humanservices.arkansas.gov/divisions-shared-services/medical-services/healthcare-programs/passe/ */

replace plan_category = "Dual" if strpos(price_type, "dual") > 0
//for people with both mcare and mcaid

replace plan_category = "CHIP" if strpos(price_type, "child") > 0 //potentially imperfect, but this seems not to produce any false positives

replace plan_category = "Gross Charge" if strpos(price_type, "gross charge") > 0 | strpos(price_type, "standard price") > 0

replace plan_category = "Uninsured" if strpos(price_type, "self pay") > 0 | strpos(price_type, "cash price") > 0 

replace plan_category = "VA" if strpos(" " + price_type + " ", " va ") > 0 | strpos(price_type, "veteran") > 0 | strpos(price_type, "champva") > 0

********************************************************************************
*******************************PAYOR NAME COLUMN********************************
********************************************************************************

gen payor_name = ""

replace payor_name = "90 Degree Benefits" if strpos(price_type, "90 degree") > 0

replace payor_name = "AARP" if strpos(price_type, "aarp") > 0 

replace payor_name = "Aetna" if strpos(price_type, "aetna") > 0 

replace payor_name = "Allegiance" if strpos(price_type, "allegiance") > 0

replace payor_name = "Allied Benefit Systems" if strpos(price_type, "allied benefit") > 0

replace payor_name = "Allwell" if strpos(price_type, "allwell") > 0

replace payor_name = "AmBetter" if strpos(price_type, "ambetter") > 0

replace payor_name = "America's" if strpos(price_type, "america's") > 0 | strpos(price_type, "americas") > 0

replace payor_name = "Anthem" if strpos(price_type, "anthem") > 0 | strpos(price_type, "ameriben") > 0 /*Anthem purchased AmeriBen in 2020 */ | strpos(price_type, "amerigroup") > 0 /*Amerigroup is a subsidiary of Anthem*/ & (strpos(price_type, "bcbs") == 0 & strpos(price_type, "bc/bs") == 0 & strpos(price_type, "blue cross") == 0 & strpos(price_type, "blue shield") == 0 & strpos(price_type, "bc_") > 0) //Anthem on its own is not the same as Anthem BC/BS for our purpose, making sure that these are two separate enterprises

replace payor_name = "Anthem BC/BS" if (strpos(price_type, "bcbs") > 0 | strpos(price_type, "bc/bs") > 0 | strpos(price_type, "blue cross") > 0 | strpos(price_type, "blue shield") > 0 | strpos(price_type, "bc_") > 0) & strpos(price_type, "anthem") > 0

replace payor_name = "APWU Health Plan" if strpos(price_type, "apwu") > 0

replace payor_name = "Auxiant" if strpos(price_type, "auxiant") > 0

replace payor_name = "Avera" if strpos(price_type, "avera") > 0 | strpos(price_type, "dakotacare") > 0 /* DakotaCare is for SD, currently owned by Avera: https://www.dakotacare.com/services/ */

replace payor_name = "Blue Cross Blue Shield" if strpos(price_type, "bcbs") > 0 | strpos(price_type, "bc/bs") > 0 | strpos(price_type, "blue cross") > 0 | strpos(price_type, "blue advantage") > 0 /*blue advantage specifically is a BCBS MA plan: https://www.bcbsalmedicare.com/sales/web/medicare/blueadvantage-overview */ | strpos(price_type, "blue_shie") > 0 /*in ID there is one with a typo, this catches it and any normal spellings */ | strpos(price_type, "blue_cross") > 0 | strpos(price_type, "blue plus") > 0 /* Blue Plus is kind of a weird case: It's a BC/BS plan but run through MinnesotaCare for people who don't qualify for Medicaid. Could be an exchange plan, but it's not stated anywhere: https://www.bluecrossmn.com/members/shop-plans/minnesota-health-care-programs/minnesotacare */ | strpos(price_type, "bc_") > 0 & strpos(price_type, "anthem") == 0

replace payor_name = "CapRock" if strpos(price_type, "caprock") > 0

replace payor_name = "Centene" if strpos(price_type, "centene") > 0 | strpos(price_type, "iowa total") > 0 /* Iowa Total Care is a Centene subsidiary: https://www.iowatotalcare.com/ */

replace payor_name = "Cigna" if strpos(price_type, "cigna") > 0

replace payor_name = "Cofinity" if strpos(price_type, "cofinity") > 0

replace payor_name = "Comprehensive Health Services" if strpos(price_type, "comprehensive") > 0

replace payor_name = "CorVel" if strpos(price_type, "corvel") > 0

replace payor_name = "Coventry" if strpos(price_type, "coventry") > 0

replace payor_name = "Deseret" if strpos(price_type, "deseret") > 0

replace payor_name = "EBMS" if strpos(price_type, "ebms") > 0

replace payor_name = "Empower" if strpos(price_type, "empower") > 0

replace payor_name = "First Choice" if strpos(price_type, "first choice") > 0 | strpos(price_type, "firstchoice") > 0

replace payor_name = "First Health" if strpos(price_type, "first health") > 0

replace payor_name = "Group Health"  if strpos(price_type, "group health") > 0 //there are a lot of situations where there might be a plan called "group health", hard to divide 

replace payor_name = "Great West Healthcare" if strpos(price_type, "great") > 0 & strpos(price_type, "west") > 0

replace payor_name = "Health Net" if strpos(price_type, "healthnet") > 0 | strpos(price_type, "health net") > 0

replace payor_name = "Health Partners" if strpos(price_type, "health partners") > 0 | strpos(price_type, "healthpartners") > 0 | strpos(price_type, "health_partners") > 0

replace payor_name = "HealthSmart" if strpos(price_type, "healthsmart") > 0 

replace payor_name = "Humana" if strpos(price_type, "humana") > 0 

replace payor_name = "Kaiser Permanente" if strpos(price_type, "kaiser ") > 0

replace payor_name = "Liberty Mutual" if strpos(price_type, "liberty mutual") > 0

replace payor_name = "MedCost" if strpos(price_type, "med cost") > 0

replace payor_name = "Medica" if strpos(" " + price_type + " ", " medica ") > 0 | strpos(price_type, "medica2") > 0

replace payor_name = "Meritain" if strpos(price_type, "meritain") > 0

replace payor_name = "Molina" if strpos(price_type, "molina") > 0

replace payor_name = "MHBP" if strpos(price_type, "mhbp") > 0

replace payor_name = "Multiplan" if strpos(price_type, "multiplan") > 0

replace payor_name = "NovaSys" if strpos(price_type, "novasys") > 0

replace payor_name = "PacificSource" if strpos(price_type, "pacificsource") > 0 | strpos(price_type, "pacific source") > 0

replace payor_name = "PreferredOne" if strpos(price_type, "preferred") > 0 & strpos(price_type, "one") > 0 

replace payor_name = "Presbyterian" if strpos(price_type, "presbyterian") > 0

replace payor_name = "QualChoice" if strpos(price_type, "qualchoice") > 0 | strpos(price_type, "qual choice") > 0

replace payor_name = "Sanford" if strpos(price_type, "sanford") > 0

replace payor_name = "South Country Health Alliance" if strpos(price_type, "south country") > 0

replace payor_name = "State Health Plan" if strpos(price_type, "primewest") > 0 | strpos(price_type, "prime west") > 0  /* MN state-run plan: https://www.primewest.org/home */ | (strpos(price_type, "mountain") > 0 & strpos(price_type, "health") > 0) /* state run co-op for MT, ID, WY: https://mountainhealth.coop/plans-listing/ */ | ( (strpos(price_type, "mt") > 0 | strpos(price_type, "montana") > 0) & strpos(price_type, "health") > 0) | (strpos(price_type, "health") > 0 & strpos(price_type, "co") > 0) /* CO's exchange: https://connectforhealthco.com/ */ | strpos(price_type, "rocky mountain") > 0 | strpos(price_type, "rmhp") > 0 /*Colorado health plan: https://www.rmhp.org/ */ | strpos(price_type, "health connection") > 0 /* Health Connections seems to be a name for the state run health insurance marketplaces: for instance, https://www.marylandhealthconnection.gov/ */ | (strpos(price_type, "friday") > 0 & strpos(price_type, "health") > 0) /*This is a state-run, marketplace type provider: they are also currently being liquidated: https://www.healthinsurance.org/blog/how-friday-health-plans-insolvency-will-affect-policyholders-in-five-states/#:~:text=The%20carrier%20is%20terminating%20its,what%20enrollees%20need%20to%20know.&text=Reviewed%20by%20our%20health%20policy,will%20terminate%20on%20August%2031. */ | strpos(price_type, "ucare") > 0 /* MN plan: https://www.ucare.org/ */ | strpos(price_type, "uc health") > 0 /* Colorado plan, with some WY coverage: https://www.uchealth.org/ */

***Important to note regarding State Health Plans: These are NOT all state-run explicitly. Many are cooperatives, some are nonprofits that just focus on one state. These *could* be split into their own payors, if desired. 

replace payor_name = "Three Rivers Provider Network" if strpos(price_type, "three rivers") > 0

replace payor_name = "Tricare" if strpos(price_type, "tricare") > 0

replace payor_name = "Triwest" if strpos(price_type, "triwest") > 0

replace payor_name = "Trustmark" if strpos(price_type, "trustmark") > 0 | strpos(price_type, "coresource") > 0 //coresource is a subsidiary of trustmark

replace payor_name = "United Healthcare" if strpos(price_type, "united healthcare") > 0 | strpos(price_type, "uhc") > 0 | strpos(price_type, "unitedhealth") > 0 | strpos(price_type, "united behavioral") > 0 | strpos(price_type, "united health care") > 0 | strpos(price_type, "care improvement plus") > 0 | strpos(price_type, "umr") > 0 /* UMR is owned by UHC: https://www.uhc.com/employer/employer-resources/umr#:~:text=As%20a%20UnitedHealthcare%20company%2C%20UMR,insurance%20landscape%20along%20the%20way. */ | strpos(price_type, "united_health") > 0 | strpos(price_type, "united commercial") > 0 | strpos(price_type, "united heath") > 0 | strpos(price_type, "golden rule") > 0 /* owned by United: https://www.uhone.com/ */ | strpos(price_type, " united ") > 0

replace payor_name = "Vantage" if strpos(" " + price_type + " ", " vantage ") > 0

replace payor_name = "Wellcare" if strpos(price_type, "wellcare") > 0

replace payor_name = "Wellfleet" if strpos(price_type, "wellfleet") > 0

replace payor_name = "Wellmark" if strpos(price_type, "wellmark") > 0 

//DOING GOVERNMENT LAST even though it's not alphabetical: we do not want it to be be overwritten in the case of, say, United running the Medicare plan, which happens
replace payor_name = "Government" if plan_category == "Medicaid" | plan_category == "VA" | plan_category == "Medicare" | strpos(price_type, "geha") > 0
//replace payor_name = "" if strpos(price_type, "") > 0 (sample line of code to add any more in)

********************************************************************************
*******************************Plan Design**************************************
********************************************************************************

gen plan_design = "" //can change this variable's name

replace plan_design = "HMO" if (strpos(price_type, "hmo") > 0 | strpos(price_type, "health maintenance") > 0) & strpos(price_type, "ppo") == 0 //this is b/c HMO/PPO is a different category

replace plan_design = "PPO" if (strpos(price_type, "ppo") > 0 | strpos(price_type, "preferred provider") > 0) & strpos(price_type, "hmo") == 0 | strpos(price_type, "novanet") > 0 | strpos(price_type, "multiplan") > 0 
//this is b/c HMO/PPO is a different category, and Novanet is a national PPO org

replace plan_design = "HMO/PPO" if strpos(price_type, "ppo") > 0 & strpos(price_type, "hmo") > 0

replace plan_design = "MCO" if strpos(price_type, "mco") > 0 | strpos(price_type, "managed care") > 0

replace plan_design = "POS" if strpos(price_type, "pos") > 0 | strpos(price_type, "point of service") > 0

replace plan_design = "Supplemental" if strpos(price_type, "supplemental") > 0 | strpos(" " + price_type + " ", " ssi ") > 0 | strpos(price_type, "medigap") > 0 | strpos(price_type, " sup") > 0

********************************************************************************
***************************Other Plan Details***********************************
********************************************************************************

//is the plan an ACA exchange plan?
gen exchange_dummy = 0
replace exchange_dummy = 1 if strpos(price_type, "exchange") > 0 | strpos(price_type, "hix") > 0 | strpos(price_type, "marketplace") > 0 | strpos(price_type, "health connection") > 0 /*Health Connections seems to be a name for the state run health insurance marketplaces: for instance, https://www.marylandhealthconnection.gov/ */

gen fee_type = ""

capture confirm variable billing_class, exact 

//in some of these datasets, billing_class does not exist; where it doesn't, I'm adding it as an empty variable so this program runs

if _rc == 0 {
	di "billing_class exists"	
}
else {
	gen billing_class = ""
}

//replace billing_class = lower(billing_class)
replace description = lower(description)

replace fee_type = "Professional" if /*strpos(billing_class, "pro") > 0 | */strpos(description, "pf ") > 0 | strpos(description, "professional") > 0

//replace fee_type = "Facility" if strpos(billing_class, "facility") > 0

