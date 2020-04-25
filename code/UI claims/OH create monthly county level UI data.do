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
global raw "${root}/data/raw/UI claims/OH UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"

* looping over all files so we can append them 
local months "oct2019 nov2019 dec2019 jan2020 feb2020"
foreach month of local months {
	* Import excel file
	project, relies_on("${raw}/source.txt")
		project, original("${raw}/ohio`month'_manual_edits.xlsx")
		import excel "${raw}/ohio`month'_manual_edits.xlsx", ///
			 firstrow clear

	* Keep only non_missing rows and relevant variables
	keep county_name initial_claims continued_claims

	* Keep only county-level data
	keep if ~mi(county_name) & (regex(county_name, "Interstate Agent")!=1 & ///
		regex(county_name, "Out of State")!=1 & regex(county_name, "Total")!=1)

	* Add a date variable
	gen date = "`month'"

	* Save a temp file to append
	tempfile OH_UI_`month'
	save `OH_UI_`month''
	}
	
	
* Append all years together
use `OH_UI_oct2019', clear
local months "nov2019 dec2019 jan2020 feb2020"
foreach month of local months {
	append using `OH_UI_`month''
	}	
		
* Remove spaces "," from vars I want to destring and destring them
foreach var of varlist initial_claims continued_claims {
	replace `var' = subinstr(`var', ",", "", .)
	destring `var', replace
	}
	
* Clean the county names for merging
replace county_name = subinstr(county_name, ".", "", .)
replace county_name = strtrim(county_name)
* There are some pesky " "s still in the names, using charlist to fix this
project, relies_on("$root/code/ado_ssc/charlist.ado") preserve
project, relies_on("$root/code/ado_ssc/charlist.sthlp") preserve
charlist county_name
replace county_name = subinstr(county_name, char(10), "", .)

* Clean the date variable 
gen date_numeric = date(date, "MY")
format date_numeric %td
drop date
rename date_numeric date
sort county_name date

* Get a crosswalk for county names, state names, and fips
preserve
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="OH"

tempfile OH_county_names 
save `OH_county_names'
restore

* Merge in the fips and names
merge m:1 county_name using `OH_county_names', assert(3) nogen

* Label variables based on information from the Ohio Department of Job and
* Family Services https://ohiolmi.com/home/UIclaims
lab var initial_claims "initial claims, excluding transitional claims"

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
export delim  "${output}/OH_monthly_county_UI.csv", replace
save "${output}/OH_monthly_county_UI.dta", replace
project, creates("${output}/OH_monthly_county_UI.dta")
project, creates("${output}/OH_monthly_county_UI.csv")
