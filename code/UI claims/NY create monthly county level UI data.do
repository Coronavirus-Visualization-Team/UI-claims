 * Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${homebase_root}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${homebase_root}/code/set_environment.do"
}

* Create required folders
cap mkdir "${root}/data/derived/UI claims"

* Set convenient globals
global raw "${root}/data/raw/UI claims/NY UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"

/*** Import and clean the county-level UI claims data for NY state. Output a
clean dataset that is long on county and date. 
***/

* We could get more past months, I just chose October 2019 because 
* I couldn't find September 2019
* Loop over date tags to import monthly excel sheets
local dates "October-2019 November-2019 December-2019 January-2020 February-2020"
foreach date of local dates {
	project, relies_on("${raw}/source.txt")
	project, original("${raw}/Beneficiaries-and-Amounts-by-Region-and-County-`date'.xlsx")
	import excel "${raw}/Beneficiaries-and-Amounts-by-Region-and-County-`date'.xlsx", ///
		 cellrange(A3 ) clear

	* Keep only relevant vars
	keep B C E

	rename (B C E) (county_name initial_claims amount_paid)
	
	* Generate a date variable
	gen date = "`date'"

	
	
	* Save a tempfile for appending 
	* note that "-" seems to be illegal for tempfile names. Make a new local that
	* does not include -
	local filename = subinstr("`date'", "-", "", .)
	tempfile NY_UI_`filename'
	save `NY_UI_`filename''
	 }

	
* Append all months together
use `NY_UI_February2020', clear
local dates "October2019 November2019 December2019 January2020"
foreach date of local dates {
	append using `NY_UI_`date''
}

* Keep only county-level data (empty counties are cumulatives for residents, non
* residents, etc)
keep if ~mi(county_name) & county_name!="Regional Total"

* Format the date variable 
replace date = subinstr(date, "-", " ", .)
gen date_numeric = date(date, "MY")
format date_numeric %td
drop date
rename date_numeric date

* getting a crosswalk for county names
preserve
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="NY"
replace county_name="St. Lawrence" if county_name=="St Lawrence"
tempfile NY_county_names 
save `NY_county_names'
restore

*merging in county name, state, name and fips
merge m:1 county_name using `NY_county_names', assert(3) nogen


* NY State DOL codes missing as 1/ for initial claims and 2/ for amount paid 
replace initial_claims = "" if initial_claims=="1/" 
replace amount_paid = "" if amount_paid=="2/"

* Destring key variables
destring initial_claims amount_paid, replace

* Label variables based on the NY State Department of Labor 
* https://labor.ny.gov/stats/UI/Unemployment-Insurance-Data.shtm 
lab var initial_claims "Counts of beneficiaries of regular unemployment insurance"
lab var amount_paid "Dollar amount of benefits paid for regular unemployment insurance"

* Switch date to year / month
gen int year = year(date)
gen byte month = month(date)
drop date

* Order
order state* county* year month

* Check the ID
sort county_fips year month
isid county_fips year month

* Save
save "${output}/NY_monthly_county_UI.dta", replace
export delim  "${output}/NY_monthly_county_UI.csv", replace
project, creates("${output}/NY_monthly_county_UI.dta")
project, creates("${output}/NY_monthly_county_UI.csv")
