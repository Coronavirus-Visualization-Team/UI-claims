version 14.1
clear all
set more off

global root "${homebase_root}"

adopath ++ "$root/code/ado_ssc"
adopath ++ "$root/code/ado"
set scheme opp_insights_policy

* Disable project (since running do-files directly)
cap program drop project
program define project
	di "Project is disabled, skipping project command. (To re-enable, run -{stata program drop project}-)"
end
