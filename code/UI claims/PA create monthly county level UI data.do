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
global raw "${root}/data/raw/UI claims/PA UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"

/*** Import and clean the county-level UI claims data for PA. Output a
clean dataset that is long on county and date. 
***/

local claimtypes "Initial Continued"
foreach claimtype of local claimtypes {

project, relies_on("${raw}/source.txt")
project, original("${raw}/UC_`claimtype'_Claims_WIA.xlsx")
import excel "${raw}/UC_`claimtype'_Claims_WIA.xlsx", ///
		 cellrange(A9:H101) firstrow clear
		 
* Keep relevant variables
keep WorkforceDevelopmentArea JANUARY* DECEMBER*

* Drop empty rows
drop if mi(WorkforceDevelopmentArea)

* Rename
rename (WorkforceDevelopmentArea JANUARY2020 DECEMBER2019 JANUARY2019)	(county_name `claimtype'_claimsJanuary2020 `claimtype'_claimsDecember2020 `claimtype'_claimsJanuary2019)

* Reshape
reshape long `claimtype'_claims, i(county_name) j(date) string

tempfile `claimtype'_temp
save ``claimtype'_temp'
} 

* Merge variables together 
use `Initial_temp', clear
merge 1:1 county_name date using `Continued_temp', assert(3) nogen

* Make variable names lower case
rename _all, lower

* Format the date variable
gen int date_numeric = date(date, "MY")
format date_numeric %td
drop date 
rename date_numeric date
sort county_name date

* Getting a crosswalk for county/state names and fips
preserve
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="PA"

tempfile PA_county_names 
save `PA_county_names'
restore

* Format names for merge
replace county_name = proper(county_name)
replace county_name = "McKean" if county_name=="Mckean"


* Merge in county name, state, name and fips
* Note that this merge will not work with assert(3) because there are some
* rows that are counties and some that are WFAs.
merge m:1 county_name using `PA_county_names', assert(1 3)
* There are 22 WFAs and 1 aggregate. Over 3 months this should give 69 obs for _merge==1
count if _merge==1
assert r(N)==69
keep if _merge==3
drop _merge

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
save "${output}/PA_monthly_county_UI.dta", replace
export delim "${output}/PA_monthly_county_UI.csv", replace
project, creates("${output}/PA_monthly_county_UI.dta")
project, creates("${output}/PA_monthly_county_UI.csv")
