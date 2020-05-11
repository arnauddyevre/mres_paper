
/*******************************************************************************
	
	DESCRIPTION: Do file generating summary statistics of the network
	
	INFILES:	- summary_stats_3ynetwork.xlsx
	
	OUTFILES:	- graphs
	
	LOG: Created 24/03/2020
		Last modified 05/05/2020
	
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
	Graphs for introduction: rise in connectedness
*******************************************************************************/

import excel "$doc/summary_stats/summary_stats_3ynetwork.xlsx", sheet("Sheet1") firstrow clear
twoway (scatter Averageweighteddegree Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) ///
	ytitle("") subtitle("Average weighted degree: {stSymbol:S}{sub:i}{bf:1}[neighbour=1]{it:w}{sub:i}/n{stSymbol:S}{sub:i}{it:w}{sub:i}", pos(11)))
graph export "$outputs/${doNum}_degreeTS.pdf", as(pdf)

twoway (scatter Clusteringcoefficientdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) ytitle("Clustering")) ///
	(scatter Averagepathlengthdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash) yaxis(2) ytitle("Path length", axis(2)) ) ///
	, legend( ring(0) pos(5) col(1))
graph export "$outputs/${doNum}_clusterPathTS.pdf", as(pdf)


twoway (scatter Networkdiameterdirected Year, msymbol(O) mfcolor(white) connect(direct) lpattern(dash))

/*******************************************************************************
	Density
*******************************************************************************/

forval y = 1976/2019{
	qui use "$wd/data/001_network/003_fullNet`y'.dta", clear
	qui nwset Source Target Weight, edgelist directed
	di "`y'"
	nwsummarize
	global density_`y' = `r(density)'
	}
 
clear
set obs 44
gen y = 1975 + _n
gen density = .
forval y = 1976/2019{
	replace density = ${density_`y'} if y == `y'
	}
scatter density y if y>1978 & y<2019
graph export "$outputs/${doNum}_densityTS_directed.pdf", as(pdf)

/*******************************************************************************
	Power law degree distribution
*******************************************************************************/

*Getting the in-degree distributions for all years

forval y=1980(3)2016{
	use "$data/003_fullNet`y'.dta", clear
	drop if Weight<=0.11
	collapse (firstnm) conm_customer (sum) Weight (mean) sales_customer, by(Target)

	*generating histogram of weighted degree
	kdensity Weight, bwidth(0.5) gen(x d) nograph
	gen year = `y'
	
	*Generating data to show the Pareto tail
	sort Weight
	gen n = _n
	gen ln_n = ln(n)
	gen ln_w = ln(Weight)
	gen CDF = n/_N
	gen log_1mCDF = log(1 - CDF)
	gen ln_1mCDF = ln(1 - CDF)
	gen log_w = log(Weight)

	save "$data/${doNum}_hist`y'.dta", replace
	}
	
use "$data/${doNum}_hist2016.dta", clear
append using "$data/${doNum}_hist1983.dta"
append using "$data/${doNum}_hist2001.dta"

twoway (scatter d x if year == 2016, msymbol(Oh)) ///
	(scatter d x if year == 2001, msymbol(Oh)) ///
	(scatter d x if year == 1983, msymbol(Oh)), legend(lab(1 "2016") lab(2 "2001") lab(3 "1983"))
graph export "$outputs/${doNum}_histTS.pdf", as(pdf)

twoway (scatter log_1mCDF log_w if year == 2016, msymbol(Oh)) ///
	(scatter log_1mCDF log_w if year == 2001, msymbol(Oh)) ///
	(scatter log_1mCDF log_w if year == 1983, msymbol(Oh)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:weighted degree}))", pos(11)) ///
	ytitle("") xtitle("Weighted degree") xline(0.75)

*Including k and zeta parameters
reg log_1mCDF log_w if year == 2016 & log_w > 0.75
global zeta_2016 = round(_b[log_w], 0.01)
reg log_1mCDF log_w if year == 2001 & log_w > 0.75
global zeta_2001 = round(_b[log_w], 0.01)
reg log_1mCDF log_w if year == 1983 & log_w > 0.75
global zeta_1983 = round(_b[log_w], 0.01)

twoway (scatter log_1mCDF log_w if year == 2016, msymbol(Oh) mlwidth(thin)) ///
	(scatter log_1mCDF log_w if year == 2001, msymbol(Oh) mlwidth(thin)) ///
	(scatter log_1mCDF log_w if year == 1983, msymbol(Oh) mlwidth(thin)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:Weighted degree}))", pos(11)) ///
	ytitle("") xtitle("x = Weighted degree") xline(0.75) ///
	text(-0.8 2 "Pr(X>x) = kx{sup:-{stSymbol:z}}", place(e)) ///
	text(-1.4 1.95 "{bf:OLS estimates} (x>0.75):", place(e)) ///
	text(-1.8 2 "{stSymbol:z}{sub:2016} = $zeta_2016", place(e)) ///
	text(-2.2 2 "{stSymbol:z}{sub:2001} = $zeta_2001", place(e)) ///
	text(-2.6 2 "{stSymbol:z}{sub:1983} = $zeta_1983", place(e))
graph export "$outputs/${doNum}_powerLawTS.pdf", as(pdf)
	

twoway (scatter ln_1mCDF ln_w if year == 2016, msymbol(Oh)) ///
	(scatter ln_1mCDF ln_w if year == 2001, msymbol(Oh)) ///
	(scatter ln_1mCDF ln_w if year == 1983, msymbol(Oh)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:weighted degree}))", pos(11)) ///
	ytitle("") xtitle("Weighted degree")
	
sort Weight
gen n = _n
scatter Weight n
gen ln_n = ln(n)
gen ln_w = ln(Weight)
scatter ln_w n

*Plot log(1-CDF) vs. log(weighted degree)

scatter log_1mCDF log_w
scatter ln_1mCDF ln_w

hist Weight





*Getting the out-degree distributions for all years

forval y=1980(3)2016{
	use "$data/003_fullNet`y'.dta", clear
	drop if Weight<=0.11
	collapse (firstnm) conm_customer (sum) Weight (mean) sales_customer, by(Source)

	*generating histogram of weighted degree
	kdensity Weight, bwidth(0.5) gen(x d) nograph
	gen year = `y'
	
	*Generating data to show the Pareto tail
	sort Weight
	gen n = _n
	gen ln_n = ln(n)
	gen ln_w = ln(Weight)
	gen CDF = n/_N
	gen log_1mCDF = log(1 - CDF)
	gen ln_1mCDF = ln(1 - CDF)
	gen log_w = log(Weight)

	save "$data/${doNum}_hist`y'_out.dta", replace
	}
	
use "$data/${doNum}_hist2016_out.dta", clear
append using "$data/${doNum}_hist1983_out.dta"
append using "$data/${doNum}_hist2001_out.dta"

twoway (scatter d x if year == 2016, msymbol(Oh)) ///
	(scatter d x if year == 2001, msymbol(Oh)) ///
	(scatter d x if year == 1983, msymbol(Oh)), legend(lab(1 "2016") lab(2 "2001") lab(3 "1983"))
graph export "$outputs/${doNum}_histTS.pdf", as(pdf)

twoway (scatter log_1mCDF log_w if year == 2016, msymbol(Oh)) ///
	(scatter log_1mCDF log_w if year == 2001, msymbol(Oh)) ///
	(scatter log_1mCDF log_w if year == 1983, msymbol(Oh)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:weighted degree}))", pos(11)) ///
	ytitle("") xtitle("Weighted degree") xline(0.75)

*Including k and zeta parameters
reg log_1mCDF log_w if year == 2016 & log_w > 0.75
global zeta_2016 = round(_b[log_w], 0.01)
reg log_1mCDF log_w if year == 2001 & log_w > 0.75
global zeta_2001 = round(_b[log_w], 0.01)
reg log_1mCDF log_w if year == 1983 & log_w > 0.75
global zeta_1983 = round(_b[log_w], 0.01)

twoway (scatter log_1mCDF log_w if year == 2016, msymbol(Oh) mlwidth(thin)) ///
	(scatter log_1mCDF log_w if year == 2001, msymbol(Oh) mlwidth(thin)) ///
	(scatter log_1mCDF log_w if year == 1983, msymbol(Oh) mlwidth(thin)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:Weighted degree}))", pos(11)) ///
	ytitle("") xtitle("x = Weighted degree") xline(0.75) ///
	text(-0.8 2 "Pr(X>x) = kx{sup:-{stSymbol:z}}", place(e)) ///
	text(-1.4 1.95 "{bf:OLS estimates} (x>0.75):", place(e)) ///
	text(-1.8 2 "{stSymbol:z}{sub:2016} = $zeta_2016", place(e)) ///
	text(-2.2 2 "{stSymbol:z}{sub:2001} = $zeta_2001", place(e)) ///
	text(-2.6 2 "{stSymbol:z}{sub:1983} = $zeta_1983", place(e))
graph export "$outputs/${doNum}_powerLawTS.pdf", as(pdf)
	

twoway (scatter ln_1mCDF ln_w if year == 2016, msymbol(Oh)) ///
	(scatter ln_1mCDF ln_w if year == 2001, msymbol(Oh)) ///
	(scatter ln_1mCDF ln_w if year == 1983, msymbol(Oh)), ///
	legend(pos(5) ring(0) lab(1 "2016") lab(2 "2001") lab(3 "1983")) subtitle("log(1 - F({it:weighted degree}))", pos(11)) ///
	ytitle("") xtitle("Weighted degree")



