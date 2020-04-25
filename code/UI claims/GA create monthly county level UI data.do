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
global raw "${root}/data/raw/UI claims/GA UI claims"
global crosswalks "${root}/data/raw/crosswalks"
global output "${root}/data/derived/UI claims"


/*** Import and clean the county-level UI claims data for GA. Output a
clean dataset that is long on county and date. 
***/

project, relies_on("${raw}/source.txt")
project, original("${raw}/initialuiclaims.xlsx")
import excel "${raw}/initialuiclaims.xlsx", ///
		 cellrange(A4:K172) firstrow clear
	
* Keep relevant variables
keep LWDAArea FEB2020 JAN2020 FEB2019
	
* Rename variables
rename (LWDAArea FEB2020 JAN2020 FEB2019) (county_name initial_claimsFeb2020 initial_claimsJan2020 initial_claimsFeb2019)
	
* This sheet has some extra formatting, dropping rows for source information, extra 
* headers, etc
drop if regex(county_name, "Georgia Department of Labor,")==1 | mi(county_name) //
drop if county_name=="County Unemployment Insurance Initial Claims" | county_name=="LWDA Area"

* Reshape to be long on county date
reshape long initial_claims , i(county_name) j(date) string

* Formate the date variable
gen int date_numeric = date(date, "MY")
format date_numeric %td
drop date
rename date_numeric date
sort county_name date

* Destring relevant variables 
destring initial_claims, replace 

* Getting a crosswalk for county names
project, original("${crosswalks}/cty_cz_st_crosswalk.csv") preserve
preserve
import delimited "${crosswalks}/cty_cz_st_crosswalk.csv", clear
keep county_name cty statename state_fips stateabbrv
rename (cty statename stateabbrv) (county_fips  state_name state_abbrev) 
keep if state_abbrev=="GA"

tempfile GA_county_names 
save `GA_county_names'
restore

* Merge in county name, state, name and fips
merge m:1 county_name using `GA_county_names', assert(3) nogen

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
save "${output}/GA_monthly_county_UI.dta", replace
export delim  "${output}/GA_monthly_county_UI.csv", replace
project, creates("${output}/GA_monthly_county_UI.dta")
project, creates("${output}/GA_monthly_county_UI.csv")
