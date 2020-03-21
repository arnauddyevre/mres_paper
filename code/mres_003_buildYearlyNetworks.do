
/*******************************************************************************
	
	DESCRIPTION: Do file building yearly networks of firms, using the cleaning
				procedure of 002
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 28/02/2020
	
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
set scheme modern, perm
ssc install gtools
gtools, upgrade*/

*Paths
global wd "/Users/ios/Documents/GitHub/mres_paper"
global orig "/Users/ios/Documents/mres_paper_orig"							// I'm using a different orig folder so as not to commit large datasets to GitHub
global data "$wd/data/001_network"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"

*do-file number, used to save outputs 
global doNum "003"					

*log
cap log close
log using "$log/${doNum}_buildYearlyNetworks", text append

/*******************************************************************************
	GETTING THE WHOLE COMPUSTAT COMPANY DATA WITH GVKEYs
*******************************************************************************/

import delimited "$orig/compustat_quarterly_61_19.csv", clear
collapse fqtr, by(gvkey conm) fast
drop fqtr
duplicates tag gvkey, gen(tag)													// No duplicates, good
tab tag, mi
drop tag

*Applying the cleaning algorithm used in 002
do "$code/mres_xxx_cleanCompNames"

duplicates tag comp, gen(tag)
br if tag!=0
sort comp tag

*Reshaping dataset in wide format, with all gvkeys and alternative names
drop if comp==""
bys comp: gen n = _n
drop tag
reshape wide conm gvkey, i(comp) j(n)											// 32,193 companies
sort comp
gen n = _n
save "$data/${doNum}_netCompList.dta", replace

/*******************************************************************************
	USING THE CUSTOMER DATA AND GETTING SHARES OF INPUT/SALES
*******************************************************************************/

*Getting balance sheet data for firms by year
import delimited "$orig/compustat_quarterly_61_19.csv", clear
keep gvkey fyearq conm saleq sic
gcollapse (sum) saleq (firstnm) gvkey, by(fyearq conm sic)						// using firstnm as TELECOM ITALIA has two for the years 2001-2003
duplicates tag conm fyear, gen(tag)
tab tag																			// 0 duplicates, good
rename fyearq year
do "$code/mres_xxx_cleanCompNames"
gcollapse (sum) saleq (firstnm) gvkey, by(year comp sic)						//very few firms are being collapsed together after the cleaning, which is a good sign
sort year comp
hist year, discrete
rename saleq sales
compress
save "$data/${doNum}_allComp.dta", replace 
levelsof year
foreach y in `r(levels)' {
	preserve
	keep if year==`y'
	save "$data/${doNum}_allComp`y'.dta", replace
	restore
	} 

import delimited "$orig/compustat_segment_customer_76_19.csv", clear
gen year = floor(srcdate/10000)
merge m:1 gvkey year using "$data/${doNum}_allComp.dta"
keep if year>1975

*mergining in clean customer data
drop cid gareac gareat sid stype srcdate tic cusip cik
foreach v of varlist gvkey salecs conm sic naics comp sales _merge{
	rename `v' `v'_supplier
	}
rename cnms conm
do "$code/mres_xxx_cleanCompNames"
merge m:1 comp using "$data/${doNum}_netCompList.dta"

*collapse by 5-year window (to smooth out the volatility in customers)


drop if _merge

*saving datasets by year, after having cleaned company names, and added balance sheet data
forval y=1976/2019{
	preserve
	keep if year==`y'
	save "$data/${doNum}_cust`y'.dta", replace
	restore
	}
	
	
keep if year==1980


 
do 

