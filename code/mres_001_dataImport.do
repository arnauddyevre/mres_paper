
/*******************************************************************************
	
	DESCRIPTION:
	
	INFILES:	- compustat_segment_customer_76_19.csv
	
	OUTFILES:	- Descriptive stats
	
	LOG: Created 02/12/2019
	
*******************************************************************************/


/*******************************************************************************
	SETUP
*******************************************************************************/

clear all
set more off
macro drop _all
set scheme s1color
set matsize 10000

*Useful modules
ssc install charlist
ssc install matchit
ssc install strip

*Paths
global wd "C:/Users/dyevre/Documents/mres_paper"
global orig "$wd/orig"
global data "$wd/data"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"

global doNum "001"					// do-file number, used to save outputs 


/*******************************************************************************
	DATA CLEANING
*******************************************************************************/

import delimited "$orig/compustat_segment_customer_76_19.csv", clear
tostring srcdate, gen(dataStr)
gen year = substr(dataStr, 1, 4)
destring year, replace
drop srcdate dataStr
tab ctype, sort

*mkdir "$outputs/${doNum}_descriptives"

*types of link
graph hbar (count), over(ctype, sort(1) descending)		///
	title("Types of links") ylabel(, grid)
graph export "$outputs/${doNum}_descriptives/${doNum}_histTypeOfLinks.pdf", as(pdf) replace

*Number of links over time and number of companies over time
drop if ctype!="COMPANY"
gen links = 1
gen freq = 1
collapse freq (sum) links, by(year conm)
collapse links (sum) freq, by(year)
twoway (scatter links year, connect(direct) msymbol(O) mfcolor(white) yaxis(1) yscale(range(1.5 4) axis(1)) ytitle("Average number of customers", axis(1) color(dkgreen))) ///
	(scatter freq year, connect(direct) msymbol(O) mfcolor(white) yaxis(2) yscale(range(0 4000) axis(2)) ytitle("Total number of companies", axis(2) color(dkorange))), ///
	legend(off) xtitle("")
graph export "$outputs/${doNum}_descriptives/${doNum}_links&Companies.pdf", as(pdf) replace

/*******************************************************************************
	CREATING NETWORK DATASET
*******************************************************************************/

import delimited "$orig/compustat_segment_customer_76_19.csv", clear
tostring srcdate, gen(dataStr)
gen year = substr(dataStr, 1, 4)
destring year, replace
drop srcdate dataStr

preserve
	keep if ctype == "COMPANY"
	keep conm
	gen count = 1
	
	*Cleaning company names
	rename conm toClean
	cd $code
	do mres_xxx_cleanCompNames
	rename toClean conm
	
	collapse (sum) count, by(conm)
	drop if conm == ""
	rename conm comp
	*mkdir "$data/${doNum}_network"
	drop count
	save "$data/${doNum}_network/${doNum}_supplierList.dta", replace
restore

preserve
	keep if ctype == "COMPANY"
	keep cnms
	gen count = 1
	
	*Cleaning company names
	rename cnms toClean
	cd $code
	do mres_xxx_cleanCompNames
	rename toClean cnms
	
	collapse (sum) count, by(cnms)
	drop if cnms == ""
	drop count
	rename cnms comp
	save "$data/${doNum}_network/${doNum}_customerList.dta", replace
restore


use "$data/${doNum}_network/${doNum}_customerList.dta", clear
merge 1:1 comp using "$data/${doNum}_network/${doNum}_supplierList.dta"


gen count = 1
collapse count, by(ctype)
graph bar count, over(ctype)

tabstat 
drop if 


/*******************************************************************************
	SUMMARY STATS: No network
*******************************************************************************/


