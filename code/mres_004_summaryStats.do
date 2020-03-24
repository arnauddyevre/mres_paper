
/*******************************************************************************
	
	DESCRIPTION: Do file generating summary statistics of the network
	
	INFILES:	- summary_stats_3ynetwork.xlsx
	
	OUTFILES:	- graphs
	
	LOG: Created 24/03/2020
	
*******************************************************************************/

/*******************************************************************************
	SETUP
*******************************************************************************/

clear all
set more off
macro drop _all
set scheme s1color
set matsize 10000

*Useful packages
/*net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
ssc install gtools
gtools, upgrade*/

set scheme modern, perm

*Paths
global wd "/Users/ios/Documents/GitHub/mres_paper"
global orig "/Users/ios/Documents/mres_paper_orig"							// I'm using a different orig folder so as not to commit large datasets to GitHub
global data "$wd/data/001_network"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"

*do-file number, used to save outputs 
global doNum "004"					

*log
cap log close
log using "$log/${doNum}_summaryStats", text append

/*******************************************************************************
	GETTING THE WHOLE COMPUSTAT COMPANY DATA WITH GVKEYs
*******************************************************************************/

import excel "$doc/summary_stats/summary_stats_3ynetwork.xlsx", sheet("Sheet1") firstrow clear
twoway (scatter Averageweighteddegree Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) ///
	ytitle("") subtitle("Average weighted degree: {stSymbol:S}{sub:i}{bf:1}[neighbour=1]{it:w}{sub:i}/n{stSymbol:S}{sub:i}{it:w}{sub:i}", pos(11)))

twoway (scatter Clusteringcoefficientdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) ytitle("Clustering")) ///
	(scatter Averagepathlengthdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) yaxis(2) ytitle("Path length", axis(2)) ) ///
	, legend( ring(0) pos(5) col(1))


twoway (scatter Networkdiameterdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash))

