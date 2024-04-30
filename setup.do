********************************************************************************
**********************************Setup*****************************************
********************************************************************************
cls
clear all
set more off
set maxvar 100000

pwd

global directory "`c(pwd)'"

di "$directory"

//PC
if "$directory" == "C:\Users\pwils\Documents" {
	global folder "C:\Users\pwils\Documents\ECON612\Research Project"
	global raw_data "C:\Users\pwils\Documents\ECON612\Research Project\raw_data"
	global intermediate_data "C:\Users\pwils\Documents\ECON612\Research Project\intermediate_data"
	global final_data "C:\Users\pwils\Documents\ECON612\Research Project\final_data"
	global output "C:\Users\pwils\Documents\ECON612\Research Project\products"
	global code "C:\Users\pwils\Documents\ECON612\Research Project\code\Hospital-Concentration-Pricing"
}

//Hilltop computer
else if "$directory" == "C:\Users\peterw1\Documents" {
	global folder "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024"
	global raw_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\raw_data"
	global intermediate_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\intermediate_data"
	global final_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\final_data"
	global output "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\products"
	global code "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\Hospital-Concentration-Pricing"
}

//Hilltop Remote Desktop
else if "$directory" == "J:\projects\NSF Build and Broaden\PW folder\Codes" {
	global folder "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024"
	global raw_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\raw_data"
	global intermediate_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\intermediate_data"
	global final_data "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\final_data"
	global output "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\products"
	global code "J:\projects\NSF Build and Broaden\PW folder\URCAD 2024\Hospital-Concentration-Pricing"
}