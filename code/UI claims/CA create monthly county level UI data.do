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
global raw "${root}/data/raw/UI claims/CA UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"


/*** Import and clean the county-level UI claims data for CA. Output a
clean dataset that is long on county and date. 
***/

local years "2019 2020"
foreach year of local years {
	* Import excel file
	project, relies_on("${raw}/source.txt")
	project, original("${raw}/qsui-Initial_Claims_by_County_`year'.xlsx")
	import excel "${raw}/qsui-Initial_Claims_by_County_`year'.xlsx", ///
		 cellrange(A4:M63) firstrow clear

	* Rename variables
	rename (County)  (county_name)	 
			 
	* Keep only county-level data
	keep if ~mi(county_name) & county_name!="Total All Counties"

	* Rename variables to get a stub for the reshape
	foreach var of varlist *`year' {
		rename `var' initial_claims`var'
	}

	* Reshape to be long on county date
	reshape long initial_claims, i(county_name ) j(date) string

	* Drop empty years
	drop if mi(initial_claims)
	
	* Save a temp file to append
	tempfile CA_UI_`year'
	save `CA_UI_`year''
}
	
* Append all years together
* Note that this doesn't really need to be done in a loop now, but I'm coding
* it this way for consistency with other do files and so it will be easy
* to update in the future. 
use `CA_UI_2020', clear
local years "2019"
foreach year of local years {
	append using `CA_UI_`year''
}	
	
* Format the date variable 
gen date_numeric = date(date, "MY")
format date_numeric %td
drop date
rename date_numeric date
sort county_name date

* Getting a crosswalk for county names
preserve
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="CA"

tempfile CA_county_names 
save `CA_county_names'
restore

* Format county_name for the merge
replace county_name = proper(county_name)

* Merge in county name, state, name and fips
merge m:1 county_name using `CA_county_names', assert(3) nogen

* Label variables based on information from the Employment Development Department
* of the State of California https://www.edd.ca.gov/about_edd/Quick_Statistics_Information_by_County.htm
lab var initial_claims "Individuals who certified for UI benefits for the week containing the 12th of the month. Includes counts for the regular UI program and federal extended benefit programs.  Initial claims totals are not representative of the number of individuals filing as a claimant can have multiple initial claims."

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
save "${output}/CA_monthly_county_UI.dta", replace
export delim "${output}/CA_monthly_county_UI.csv", replace
project, creates("${output}/CA_monthly_county_UI.dta") 
project, creates("${output}/CA_monthly_county_UI.csv") 

