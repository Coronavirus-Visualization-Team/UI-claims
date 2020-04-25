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
global raw "${root}/data/raw/UI claims/WA UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"


/*** Import and clean the county-level UI claims data for WA. Output a
clean dataset that is long on county and date. 
***/

* Note that we could get more past months, I just chose Jan 2019 to have a full year
* Import the raw data
project, relies_on("${raw}/source.txt")
project, original("${raw}/IC_CC_Monthly_County.xlsx")
import excel "${raw}/IC_CC_Monthly_County.xlsx", firstrow

* Keep relevant time period
keep if Yr>=2019

* Keep only county-level data (ie, dropping this aggregate)
drop if CountyArea=="WASHINGTON STATE"

* Rename variables
rename _all, lower
rename (countyarea )  	(county_name)

* Keep relevant variables
keep county_name claimtype date claims

* Clean the claimtype variable for reshaping
replace claimtype = subinstr(claimtype, " claims", "", .)

* Rehape to be wide on claim type
reshape wide claims, i(county_name date) j(claimtype) string

* Renaming after the reshape 
rename (claimsContinued claimsInitial) (continued_claims initial_claims)

* Adding in fips data
preserve
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="WA"
tempfile WA_county_names 
save `WA_county_names'
restore

* Format county_name for merging
replace county_name = proper(county_name)

* Merge on Fips data
merge m:1 county_name using `WA_county_names', assert(3) nogen

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
save "${output}/WA_monthly_county_UI.dta", replace
export delim "${output}/WA_monthly_county_UI.csv", replace
project, creates("${output}/WA_monthly_county_UI.dta")
project, creates("${output}/WA_monthly_county_UI.csv")
