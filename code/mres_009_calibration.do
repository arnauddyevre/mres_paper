

/*******************************************************************************
	
	DESCRIPTION: Calibration of model
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 31/06/2020
			Last modified XX/05/2020
	
*******************************************************************************/

/*******************************************************************************
	SETUP
*******************************************************************************/

clear all
set more off
macro drop _all
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
global doNum "009"					

*log
cap log close
log using "$log/${doNum}_calibration", text append


/*******************************************************************************
	Estimating relevant parameters for all firms
*******************************************************************************/

use "$orig/Compustat_standard", clear

*Productivity
replace sale = 0 if sale< 0
gen prod = sale/xlr
replace prod = 1 if prod<=1
gen ln_prod = ln(prod)
*hist ln_prod
hist prod if prod<40, freq xtitle("Firm productivity")
gen count = 1
*collapse count prod, by(gvkey)
*gen prod_low = floor(prod)
/*
collapse (sum) count, by(prod_low)
drop if prod_low == .
gen ln_prod = ln(prod_low)
scatter count ln_prod
gen ln_count = ln(count)
scatter ln_count ln_prod
egen sum_count=sum(count)
gen cum_count = count
replace cum_count = cum_count + cum_count[_n-1] if _n>1
gen F = cum_count/sum_count
gen ln_1_F = ln(1-F)
twoway (scatter ln_1_F ln_prod , msymbol(Oh) xtitle("ln({&Phi}{subscript:k})", size(large)) ytitle("") subtitle("ln(1-F({&Phi}{subscript:k}))", pos(11) size(large)) ), ///
	xlabel(, labsize(large)) ylabel(, labsize(large))
graph export "$outputs/009_paretoProd.pdf", as(pdf) replace

reg ln_1_F ln_prod

collapse 
graph export "$outputs/009_prod.pdf", as(pdf) replace
*/

*Imputing ln_prod
*scatter ln_prod sale
reg ln_prod sale
gen ln_prod_imp = _b[sale]*sale + _b[_cons]
bys gvkey: egen ln_prod_mean = mean(ln_prod_imp)
replace ln_prod_imp = ln_prod_mean if ln_prod_imp==.
bys gvkey: egen prod_mean = mean(prod)
replace prod = prod_mean if prod==.
gen phi = exp(ln_prod_imp)

*Verifying that the relationship between market share and productivity is S-shaped. That's not the case...
gen sic2 = substr(sic, 1, 2)
destring sic2, replace
bys sic fyear: egen totsales = sum(sale)
gen sh = sale/totsales
binscatter sh ln_prod if prod<50 & fyear>1976, nquantiles(100) //& fyear<=1990
bys sic2 fyear: egen prod_mean_sector = mean(prod)
replace prod = prod_mean_sector if prod==.
replace prod=40 if prod>40

*generating omega: share of wage expenses among total expenses
gen omega = xlr/(cogs+xlr) if cogs>0 & xlr>0 //mean is 1/3, note that this is different from capital/labour share, there is no capital here
su \omega

*replacing omega by the sector value when missing 
bys sic2 fyear: egen mean_omega = mean(omega)
replace omega = mean_omega if omega == .

*Saving the relevant parameters
keep gvkey fyear conm naics sic prod ln_prod_* phi sic2 sh omega mean_omega
rename fyear year
destring gvkey, replace
duplicates drop year gvkey, force

save "$data/009_calibration/${doNum}_firm_level_parameters.dta", replace


/*******************************************************************************
	Getting the value chains for all firms
*******************************************************************************/

forval y = 1976/2016{

qui{

*Adding a_ij's i.e. input expenditures as a share of sales
use "$data/001_network/003_fullNet`y'.dta", clear
collapse (sum) salecs_supplier (mean) sales_customer (firstnm) comp_supplier comp_customer , by(Source Target year)
gen a = salecs_supplier/sales_customer
keep Source comp_supplier comp_customer Target /*year3*/ year a
*rename year3 year
replace a = 1 if a>1
save "$data/007_welfare/007_aij`y'.dta", replace

*Starting from the supply chain
use "$data/006_network&Markups/006_endPoint`y'_wide.dta", clear

*Getting the sales share of the end point
rename endPoint_0 gvkey
gen year = `y'
merge m:1 gvkey year using "$data/006_network&Markups/006_markups`y'.dta", keepusing(mu_1 sale)
drop if _merge == 2
drop _merge

*Replacing missing markup by average markup
su mu_1
replace mu_1 = `r(mean)' if mu_1 == .

*Getting company names
merge m:1 gvkey year using "$data/001_network/003_allcomp.dta", keepusing(conm)
drop if _merge == 2
drop _merge

rename sale finalSale
rename mu_1 mu_0

*Now including sales of shares and markups further up the value chain
rename gvkey Target 
rename endPoint_1 Source
merge m:1 Source Target year using "$data/007_welfare/007_aij`y'.dta", keepusing(a)
drop if _merge == 2
drop _merge
rename a a10
rename Target endPoint_0
rename Source endPoint_1

*Now including markups and sales shares of other steps in the value chain
forval step = 1/8{
	local nextStep = `step'+1
	local previousStep = `step'-1
	rename endPoint_`step' gvkey
	merge m:1 gvkey year using "$data/006_network&Markups/006_markups`y'.dta", keepusing(mu) //markups
	drop if _merge == 2
	drop _merge
	rename mu mu_`step'
	rename gvkey Target 
	rename endPoint_`nextStep' Source
	merge m:1 Source Target year using "$data/007_welfare/007_aij`y'.dta", keepusing(a)
	drop if _merge == 2
	drop _merge
	rename a a`nextStep'`step'
	rename Target endPoint_`step'
	rename Source endPoint_`nextStep'
	}
	
	}
	compress
	save "$data/009_calibration/${doNum}_supplyChain`y'.dta", replace
	}



