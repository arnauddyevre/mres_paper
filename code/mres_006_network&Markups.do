
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
set scheme modern, perm
set matsize 10000

*Useful packages
/*net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
ssc install gtools
gtools, upgrade*/

*Paths
global wd "/Users/ios/Documents/GitHub/mres_paper"
global orig "/Users/ios/Documents/mres_paper_orig"							// I'm using a different orig folder so as not to commit large datasets to GitHub
global data "$orig/Data_output/006_network&Markups"
global outputs "$wd/outputs/006_network&Markups"
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
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11) size(large)) ///
	xtitle("{it:Downstream} <-       Position in supply chain       -> {it:Upstream}" , size(large)) ///
	ylabel(0(1)6) xlabel(0(1)10) legend( ring(0) pos(2) col(1) size(large)) ylabel( , labsize(large)) xlabel( , labsize(large))
graph export "$outputs/006_markupsSC_1996_CI.pdf", as(pdf) replace

twoway (scatter mu_c step if t==0 & step<6, mlabel(count)) ///
	(scatter p50 step if t==0 & step<6) ///
	(rcap p95 p5 step if t==0 & step<6, color(blue) lpattern(dot)) ///
	(rcap p75 p25 step if t==0 & step<6, color(dknavy) lpattern(dash)), ///
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11) size(large)) ///
	xtitle("{it:Downstream} <-       Position in supply chain       -> {it:Upstream}" , size(large)) ///
	ylabel(0(1)6) xlabel(0(1)10) legend( ring(0) pos(2) col(1) size(large)) ylabel( , labsize(large)) xlabel( , labsize(large))
graph export "$outputs/006_markupsSC_1976_CI.pdf", as(pdf) replace

twoway (scatter mu_c step if t==1, mlabel(count)) ///
	(scatter mu_c step if t==0 & step<6, mlabel(count)), ///
	ytitle("") subtitle("{it: {&mu}} (controlling for firm size and NAICS2 industry)", pos(11) size(large)) ///
	xtitle("{it:Downstream} <-       Position in supply chain       -> {it:Upstream}" , size(large)) ///
	ylabel(1(1)4) xlabel(0(1)10) legend( ring(0) pos(2) col(1) order(1 "1996-2016" 2 "1976-1995") size(large)) ylabel( , labsize(large)) xlabel( , labsize(large)) 
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

*Link between markups and firm number of suppliers
*(going back to the original data)
import delimited "$orig/compustat_segment_customer_76_19.csv", clear
keep if ctype == "COMPANY"
tostring srcdate, gen(dataStr)
gen year = substr(dataStr, 1, 4)
destring year, replace
drop srcdate dataStr
gen count=1
collapse (sum) count, by(gvkey year)

forval y=1976/2016{
	preserve
	keep if year == `y'
	merge 1:1 gvkey using "$data/006_markups`y'.dta"
	drop if _merge!=3
	save "$data/${doNum}_markupsVSCustomers_`y'_uncollapsed", replace
	*scatter mu_1 count
	gen hist = 1
	collapse (mean) mu_1 (sum) hist , by(count)
	gen year = `y'
	save "$data/${doNum}_markupsVSCustomers_`y'", replace
	*twoway (scatter mu_1 count)
	*graph export "$outputs/${doNum}_markupsVScustomer`y'.pdf"
	restore
	}

* Graph
use "$data/${doNum}_markupsVSCustomers_1976", clear
forval y=1977/2016{
	append using "$data/${doNum}_markupsVSCustomers_`y'"
	}
gen ln_hist = ln(hist)
gen ln_count = ln(count)

gen yearL = "1976-1985" if year<=1985
replace yearL = "1986-1995" if year <=1995 & yearL==""
replace yearL = "1996-2005" if year <=2005 & yearL==""
replace yearL = "2006-2016" if year <=2016 & yearL==""


twoway (scatter mu_1 count [fw=hist] if yearL=="1976-1985" & mu_1<4, msymbol(Oh) mlwidth(thin) mcolor(%50)) ///
	(scatter mu_1 count [fw=hist] if yearL=="1986-1995" & mu_1<4, msymbol(Oh) mlwidth(thin) mcolor(%50)) ///
	(scatter mu_1 count [fw=hist] if yearL=="1996-2005" & mu_1<4, msymbol(Oh) mlwidth(thin) mcolor(%50)) ///
	(scatter mu_1 count [fw=hist] if yearL=="2006-2016" & mu_1<4, msymbol(Oh) mlwidth(thin) mcolor(%50)) ///
	(lfit mu_1 count [w=hist] if mu_1<4), ///	
	legend( ring(0) pos(11) col(1) order(1 "1976-1985" 2 "1986-1995" 3 "1996-2005" 4 "2006-2016") size(large)) ///
	ytitle("") xtitle("Number of customers", size(large)) xscale(log) xlabel( , labsize(large)) ylabel( , labsize(large))
graph export "$outputs/${doNum}_markupsVScustomer.pdf", replace

*Regression
use "$data/${doNum}_markupsVSCustomers_1976_uncollapsed", clear
forval y=1977/2016{
	append using "$data/${doNum}_markupsVSCustomers_`y'_uncollapsed"
	}

gen ln_count = ln(count)
gen ln_c_sq = ln_count*ln_count
gen sale_D_bil = sale_D/1000000
gen ln_sale = ln(sale_D)
xtile size = ln_sale, nq(5)

/*
reghdfe mu_1 ln_count /*i.year i.ind2*/ ln_sale, vce(robust) noabsorb
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) replace
reghdfe mu_1 ln_count /*i.year i.ind2*/ ln_sale, absorb(year) vce(robust)
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) append
reghdfe mu_1 ln_count /*i.year i.ind2*/ ln_sale, absorb(year ind2) vce(robust)
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) append
*/

reghdfe mu_1 ln_count /*i.year i.ind2*/ i.size, vce(robust) noabsorb
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) replace
reghdfe mu_1 ln_count /*i.year i.ind2*/ i.size, absorb(year) vce(robust)
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) append
reghdfe mu_1 ln_count /*i.year i.ind2*/ i.size, absorb(year ind2) vce(robust)
outreg2 using "$outputs/${doNum}_markupsVSCustomers_reg", tex(pretty) append

**** Simulation, relationship between productivity and price + productivity and markup

