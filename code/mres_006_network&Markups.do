
/*******************************************************************************
	
	DESCRIPTION: Descriptive statistics about markups and the production network
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 02/05/2020
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
global data "$orig/Data_output/006_network&Markups"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*do-file number, used to save outputs 
global doNum "006"					

*log
cap log close
log using "$log/${doNum}_network&Markups", text append


/*******************************************************************************
	
*******************************************************************************/

*Getting the markups in a usable + portable format
forval y = 1963/2016{
	use "$orig/Data_output/005_markups/temp_file.dta", clear
	destring gvkey, replace
	keep if year == `y'
	gen mu = mu_1					// measure of markups used in the welfare analysis
	save "$data/006_markups`y'.dta", replace
	}

/*	
use "$wd/data/001_network/003_fullNet1983.dta", clear
keep Source Target
save "$data/006_source_target2013.dta", replace
preserve 
keep Source
save "$data/006_source2013.dta", replace
restore
keep Target
rename Target Source
append using "$data/006_source2013.dta"
gen zero = 0
collapse zero, by(Source)
drop zero
keep if Source == 2176
merge 1:m Source using "$data/006_source_target2013.dta"
keep if _merge == 3
// if no observation, this node is the end of the supply chain

use "$wd/data/001_network/003_fullNet1983.dta", clear
keep Source Target
rename Source Source0
rename Target Source
save "$data/006_source_target1983.dta", replace
*/

*Getting the list of all nodes in a year
forval y=1976/2016{
	use "$wd/data/001_network/003_fullNet`y'.dta", clear
	keep Source Target
	save "$data/006_source_target`y'.dta", replace
	preserve 
	keep Source
	save "$data/006_source`y'.dta", replace
	restore
	keep Target
	rename Target Source
	append using "$data/006_source`y'.dta"
	gen zero = 0
	collapse zero, by(Source)
	drop zero

	*Merging the subsequent customers
	forval i = 1/10{
		merge m:m Source using "$wd/data/001_network/003_fullNet`y'.dta"
		keep if _merge!= 2
		keep Sourc* Target
		rename Source Source`i'
		rename Target Source
		}

	*dropping unecessary columns
	forval i = 2/10{
		egen sum`i' = total(Source`i')
		su sum`i'
		if `r(mean)' == 0{
			*drop Source`i'
			}
		drop sum`i'
		}

	*Collapsing the value chains that are the same
	egen len = rownonmiss(Source*)
	forval the_end = 0/9{
		gen endPoint_`the_end' = .
		local limit = 10 - `the_end'
		forval i = 1/`limit'{
			local j = `i' + `the_end'
			replace endPoint_`the_end' = Source`i' if len == `j'
			}
		}

	forval i = 1/9{
		local j = `i' - 1
		duplicates tag endPoint_0-endPoint_`j', gen(tag`j')
		duplicates tag endPoint_0-endPoint_`i', gen(tag`i')
		bys endPoint_0-endPoint_`j': egen minLen = min(len)
		drop if minLen == len & tag`j' !=0 & tag`i' == 0
		drop minLen tag`i' tag`j'
		}

	keep endPoint_*
	save "$data/006_endPoint`y'_wide.dta", replace
	gen n=_n
	reshape long endPoint_ , i(n) j(step)
	rename endPoint_ gvkey
	drop if gvkey == .
	drop n
	gen year = `y'
	save "$data/006_endPoint`y'.dta", replace
		
	}	

*Now merging markups and supply chain measure
forval y = 1976/2016{
	use "$data/006_endPoint`y'.dta", clear
	merge m:1 gvkey year using "$data/006_markups`y'.dta"
	keep if _merge == 3
	drop _merge
	save "$data/006_markups&Network`y'.dta", replace 
	}

forval y = 1976/2016{
use "$data/006_markups&Network`y'.dta", clear

replace sale = round(sale, 1)
gen ln_sale = ln(1+sale)
gen ln_emp = ln(emp+1)
xtile dec_sale = ln_sale, nq(10)
xtile dec_emp = ln_emp, nq(10)
reg mu_1 i.dec_sale i.ind2d i.dec_sale##i.ind2d dec_emp
predict mu_hat
predict res, res
su mu_hat
gen mu_c = `r(mean)' + res
twoway (scatter mu_c ln_sale, msymbol(oh)) (scatter mu_1 ln_sale, msymbol(oh))

gen count = 1
save "$data/006_markups&Network`y'_control.dta", replace

collapse mu_hat mu_1 mu_c (sum) count /*[pw=share_firm_agg]*/, by(step)

twoway (scatter mu_1 step)	///
	(scatter mu_c step, mlabel(count))
	
	graph export "$outputs/006_markups&Network_scatter_`y'.pdf", as(pdf) replace
	save "$data/006_markups&Network_scatter_`y'.dta", replace

}

* comparable markups datasets and plotting evolution over supply chain
use "$data/006_markups&Network1976_control.dta", clear
forval y=1976/2016{
	append using "$data/006_markups&Network`y'_control.dta"
	}
gen t = year>=1996
mean mu_c, over(step)
collapse mu_hat mu_1 mu_c (sum) count /*[pw=share_firm_agg]*/ (sd) sd=mu_c (p5) p5=mu_c (p95) p95=mu_c (p75) p75=mu_c (p25) p25=mu_c (p50) p50=mu_c, by(step t)

twoway (scatter mu_c step if t==1, mlabel(count)) ///
	(scatter p50 step if t==1) ///
	(rcap p95 p5 step if t==1, color(blue) lpattern(dot)) ///
	(rcap p75 p25 step if t==1, color(dknavy) lpattern(dash)), ///
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11)) ///
	xtitle("{it:Downstream} <-              Position in supply chain              -> {it:Upstream}") ///
	ylabel(0(1)6) xlabel(0(1)10) legend( ring(0) pos(2) col(1))
graph export "$outputs/006_markupsSC_1996_CI.pdf", as(pdf) replace

twoway (scatter mu_c step if t==0 & step<6, mlabel(count)) ///
	(scatter p50 step if t==0 & step<6) ///
	(rcap p95 p5 step if t==0 & step<6, color(blue) lpattern(dot)) ///
	(rcap p75 p25 step if t==0 & step<6, color(dknavy) lpattern(dash)), ///
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11)) ///
	xtitle("{it:Downstream} <-              Position in supply chain              -> {it:Upstream}") ///
	ylabel(0(1)6) xlabel(0(1)10) legend( ring(0) pos(2) col(1))
graph export "$outputs/006_markupsSC_1976_CI.pdf", as(pdf) replace

twoway (scatter mu_c step if t==1, mlabel(count)) ///
	(scatter mu_c step if t==0 & step<6, mlabel(count)), ///
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11)) ///
	xtitle("{it:Downstream} <-              Position in supply chain              -> {it:Upstream}") ///
	ylabel(1(1)4) xlabel(0(1)10) legend( ring(0) pos(2) col(1) order(1 "1986-2016" 2 "1976-1985"))
graph export "$outputs/006_markupsSC.pdf", as(pdf) replace


*Show descriptive statistics about number of links and markups


use "$wd/data/001_network/003_fullNet2016.dta", clear
gen count = 1
collapse (sum) count Weight (firstnm) conm_supplier, by(Source)
rename Source gvkey
merge 1:1 gvkey using "$data/006_markups2016.dta"
keep if _m == 3
gen firms = 1
collapse mu_1 (sum) firms, by(count)
scatter mu_1 count
graph export "$outputs/006_markupsVSOutdegree.pdf", as(pdf) replace


use "$wd/data/001_network/003_fullNet2016.dta", clear
gen count = 1
collapse (sum) count Weight (firstnm) conm_customer, by(Target)
rename Target gvkey
merge 1:1 gvkey using "$data/006_markups2016.dta"
keep if _m == 3
gen firms = 1
collapse mu_1 (sum) firms, by(count)
scatter mu_1 count
graph export "$outputs/006_markupsVSIndegree.pdf", as(pdf) replace
