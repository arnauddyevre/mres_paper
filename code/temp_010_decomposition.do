
/*******************************************************************************
	
	DESCRIPTION: Decomposition of the effect
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 02/06/2020
			Last modified XX/05/2020
	
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
global data "$orig/Data_output"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*do-file number, used to save outputs 
global doNum "010"					

*log
cap log close
log using "$log/${doNum}_decomposition", text append

/*******************************************************************************
	Getting all datasets together
*******************************************************************************/

use "$data/009_calibration/009_welfare_constantNSuppliers.dta", clear
gen series = 1
append using "$data/009_calibration/009_welfare_buyingSameFirms.dta"
replace series = 2 if series == .
append using "$data/009_calibration/009_welfare_constantLength.dta"
replace series = 3 if series == .
append using "$data/009_calibration/009_welfare_constantMarkups.dta"
replace series = 4 if series == .

gen diff = ratio_all_ma - ratio_last
xtset series year
gen diff_sm = (L.diff + diff + F.diff)/3
replace diff_sm = diff if diff_sm == .


twoway (scatter diff_sm year if series == 1, connect(direct)) ///
	(scatter diff_sm year if series == 2, connect(direct)) ///
	(scatter diff_sm year if series == 3, connect(direct)) ///
	(scatter diff_sm year if series == 4, connect(direct))
	
bys year: egen sum_year = sum(diff_sm)
gen sh = diff_sm/sum_year

twoway (scatter sh year if series == 1, connect(direct)) ///
	(scatter sh year if series == 2, connect(direct)) ///
	(scatter sh year if series == 3, connect(direct)) ///
	(scatter sh year if series == 4, connect(direct))

gen collapse_level1 = sh if series ==2
gen collapse_level2 = sh if series == 2 | series == 3
gen collapse_level3 = sh if series == 2 | series == 3 | series == 4
gen collapse_level4 = sh if series == 2 | series == 3 | series == 4 | series == 1

collapse (sum) collapse_*, by(year)

gen zero = 0
replace zero = collapse_level1 if zero>collapse_level1
replace collapse_level1 = 0 if collapse_level1<0

twoway (rarea collapse_level1 zero year) ///
	(rarea collapse_level2 collapse_level1 year) ///
	(rarea collapse_level3 collapse_level2 year) ///
	(rarea collapse_level4 collapse_level3 year), ///
	xtitle("") legend(col(1) order(4 "# suppliers" 3 "Markups" 2 "Length" 1 "Reallocation") size(large)) ///
	xlabel(, labsize(large)) ylabel(, labsize(large))

graph export "$outputs/010_decomposition/010_decomposition.pdf", as(pdf) replace		




use "$data/009_calibration/009_welfare_buyingFromLowMarkupFirms.dta", clear

