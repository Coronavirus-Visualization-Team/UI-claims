*** Initialization ***
version 14.1
set more off
set varabbrev off

project, doinfo
local pdir=r(pdir)
adopath ++ "`pdir'/code/ado_ssc"
adopath ++ "`pdir'/code/ado"

project, relies_on("`pdir'/code/set_environment.do")

*** Make required folders ***
cap mkdir "`pdir'/data/derived"


* Create monthly county level UI data
project, do("code/UI claims/CA create monthly county level UI data.do")
project, do("code/UI claims/GA create monthly county level UI data.do")
project, do("code/UI claims/NY create monthly county level UI data.do")
project, do("code/UI claims/OH create monthly county level UI data.do")
project, do("code/UI claims/PA create monthly county level UI data.do")
project, do("code/UI claims/WA create monthly county level UI data.do")

