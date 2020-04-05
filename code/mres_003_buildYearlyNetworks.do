
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
collapse (sum) saleq (firstnm) gvkey (firstnm) conm, by(year comp sic)	fast	//very few firms are being collapsed together after the cleaning, which is a good sign
sort year comp
hist year, discrete
rename saleq sales
compress

duplicates tag comp year, gen(tag)
drop if tag!=0																	// 99.13% of unique firm*year records
drop tag

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
merge m:1 comp year using "$data/${doNum}_allcomp.dta"
tab ctype _merge, mi row 
*merge m:1 comp using "$data/${doNum}_netCompList.dta"
	// 25% of all company being supplied to find a match (76,649)
	// This is the highest match rate I get across customer type (followed by "market")
	// "Market" is a srange one, decent match rate but I'm unsure about their quality
keep if ctype == "MARKET" | ctype == "COMPANY"
	// All MARKETs NEED TO BE KEPT! These are the companies with final consumers, we want to keep 
foreach v of varlist conm ctype comp sic sales gvkey n _merge{
	rename `v' `v'_customer
	}
compress
save "$data/${doNum}_fullNet.dta", replace

*Keeping matched customer
use "$data/${doNum}_fullNet.dta", clear
keep if _merge_customer == 3

*generating 3 year windows
gen year3 = floor((year-2)/3)*3+3													// so that 1976, 1977 and 1978 are grouped in year3 = 1977

collapse (firstnm) conm_customer conm_supplier (sum) sale* , by(year3 sic_supplier sic_customer gvkey_supplier gvkey_customer comp_customer comp_supplier)
gen share = salecs_supplier/sales_supplier
replace share = 1 if share>=1
replace share = . if share<0
replace share = 0.1 if share == 0
hist share, freq
levelsof year3

foreach y in `r(levels)'{
	preserve
	keep if year3 == `y'
	compress
	
	*Creating edge list
	rename gvkey_supplier Source
	rename gvkey_customer Target
	gen Type = "Directed"
	rename share Weight
	save "$data/${doNum}_fullNet`y'.dta", replace
	export delimited "$data/${doNum}_fullNet`y'.csv", replace
		
	*For Python
	keep Source Target Weight
	order Source Target Weight
	outfile using "$data/${doNum}_fullNet`y'.txt", replace wide
	export delimited "$data/${doNum}_fullNet`y'_short.csv", replace
	
	*Creating node list
	use "$data/${doNum}_allcomp.dta", clear
	compress
	do "$code/mres_xxx_coarseningSIC"
	gen year3 = floor((year-2)/3)*3+3
	keep if year3 == `y'
	replace sales = . if year3!=`y'
	collapse (firstnm) conm comp sic coarseSIC (mean) sales, by(gvkey) fast
	rename gvkey Id
	rename conm Label
	export delimited "$data/${doNum}_nodeList`y'.csv", replace
	
	restore
	}

