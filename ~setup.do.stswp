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
//Run these top lines to get your Stata directory on whatever computer you're using. Then, use the below if loops as a baseline to create your necessary setups; just paste an extra else if loop to the else if list and change the "if" line to your directory. If you're working through Remote Desktop (which you should) you'll notice that it's got a different baseline directory than your Hilltop laptop. So you can do (as I've done) two separate else if's, for each of those two directories. 

//PW PC
if "$directory" == "C:\Users\pwils\Documents" {
	global folder "C:\Users\pwils\Documents\Hilltop"
	global raw_data "C:\Users\pwils\Documents\Hilltop\raw_data"
	global intermediate_data "C:\Users\pwils\Documents\Hilltop\intermediate_data"
	global final_data "C:\Users\pwils\Documents\Hilltop\final_data"
	global output "C:\Users\pwils\Documents\Hilltop\products"
	global code "C:\Users\pwils\Documents\Hilltop\project_code"
}

//Hilltop computer (for PW)
else if "$directory" == "C:\Users\peterw1\Documents" {
	global folder "J:\projects\NSF Build and Broaden\PW TS Project"
	global raw_data "J:\projects\NSF Build and Broaden\PW TS Project\raw_data"
	global intermediate_data "J:\projects\NSF Build and Broaden\PW TS Project\intermediate_data"
	global final_data "J:\projects\NSF Build and Broaden\PW TS Project\final_data"
	global output "J:\projects\NSF Build and Broaden\PW TS Project\products"
	global code "J:\projects\NSF Build and Broaden\PW TS Project\project_code"
}

//Hilltop Remote Desktop (for PW)
else if "$directory" == "J:\projects\NSF Build and Broaden\PW folder\Codes" {
	global folder "J:\projects\NSF Build and Broaden\PW TS Project"
	global raw_data "J:\projects\NSF Build and Broaden\PW TS Project\raw_data"
	global intermediate_data "J:\projects\NSF Build and Broaden\PW TS Project\intermediate_data"
	global final_data "J:\projects\NSF Build and Broaden\PW TS Project\final_data"
	global output "J:\projects\NSF Build and Broaden\PW TS Project\products"
	global code "J:\projects\NSF Build and Broaden\PW TS Project\project_code"
}

//Hilltop Remote Desktop (for Timothy)
else if "$directory" == "C:\Users\tshaia1\Documents" {
	global folder "J:\projects\NSF Build and Broaden\PW TS Project"
	global raw_data "J:\projects\NSF Build and Broaden\PW TS Project\raw_data"
	global intermediate_data "J:\projects\NSF Build and Broaden\PW TS Project\intermediate_data"
	global final_data "J:\projects\NSF Build and Broaden\PW TS Project\final_data"
	global output "J:\projects\NSF Build and Broaden\PW TS Project\products"
	global code "J:\projects\NSF Build and Broaden\PW TS Project\project_code"
}