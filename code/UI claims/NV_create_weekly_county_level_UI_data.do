global raw "$root/data/raw"
global crosswalks "$raw/crosswalks"
global derived "$root/data/derived"

local state "NV"
local frequency "weekly"

import delimited "$raw/UI_claims/`state'_UI_claims/State of Nevada Unemployment Insurance Trends by County.csv", varnames(1) clear

keep if claimtype == "initial" & county != "Unknown"
keep county weekending claims
rename county county_name

destring claims, replace ignore(`","')

gen date = date(weekending, "YMD")
format date %td
gen year = year(date)
gen week = week(date)
drop weekending

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

* Label variables based on information from Nevada DETR
lab var claims "Unemployment Insurance Initial Claims. Excludes claims where county is unknown."

* Order
order state* county* year week

* Check the ID
sort county_fips year week

rename claims initial_claims

save "$derived/UI_claims/`state'_`frequency'_county_UI_derived.dta", replace
export delim "$derived/UI_claims/`state'_`frequency'_county_UI_derived.csv", replace
