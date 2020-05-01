global raw "$root/data/raw"
global crosswalks "$raw/crosswalks"
global derived "$root/data/derived"

local state "WI"
local frequency "weekly"

import excel "$raw/UI_claims/`state'_UI_claims/initial_claims_by_county.xlsx", firstrow case(lower) clear

drop if county == "UNKNOWN"
drop in 73/`=_N'
drop grandtotal
rename county county_name
replace county_name = proper(county_name)
replace county_name = "Fond du Lac" if county_name == "Fond Du Lac"
gen year = 2020

reshape long uiweek, i(county_name) j(week)
rename uiweek claims

preserve
	import delimited "$crosswalks/cty_cz_st_crosswalk.csv", clear
	keep county_name cty statename state_fips stateabbrv
	rename (cty statename stateabbrv) (county_fips  state_name state_abbrev)
	keep if state_abbrev=="`state'"

	tempfile `state'_county_names
	save ``state'_county_names'
restore

* Merge in county name, state, name and fips
merge m:1 county_name using ``state'_county_names', assert(3) nogen

* Label variables based on information from WI DWD
lab var claims "Unemployment Insurance Initial Claims. Excludes claims where county is unknown."

* Order
order state* county* year week

* Check the ID
sort county_fips year week

save "$derived/UI_claims/`state'_`frequency'_county_UI.dta", replace
export delim "$derived/UI_claims/`state'_`frequency'_county_UI.csv", replace
