To run this code from top-to-bottom:

1. In Stata, install -project- from the SSC if you haven't already: ssc install project
2. Add the master do-file to -project-
	- Run `project, setup` in Stata, then navigate to countyUI.do. Decide whether you want plain-text or SMCL log files, then hit OK.
3. Run `project countyUI, build`
