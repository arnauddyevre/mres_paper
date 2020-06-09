



forval y=1976/2016{

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
forval step = 1/9{
	local nextStep = `step'+1
	local previousStep = `step'-1
	rename endPoint_`step' gvkey
	merge m:1 gvkey year using "$data/006_network&Markups/006_markups`y'.dta", keepusing(mu) //markups
	drop if _merge == 2
	drop _merge
	rename mu mu_`step'
	rename gvkey Target 
	
	if `step' != 9{
		rename endPoint_`nextStep' Source
		merge m:1 Source Target year using "$data/007_welfare/007_aij`y'.dta", keepusing(a)
		drop if _merge == 2
		drop _merge
		rename a a`nextStep'`step'
		rename Source endPoint_`nextStep'
		}
		rename Target endPoint_`step'

	}
	
	compress
	save "$data/009_calibration/${doNum}_supplyChain`y'.dta", replace

	
use "$data/009_calibration/${doNum}_supplyChain`y'.dta", clear

forval i = 0/9{
	rename endPoint_`i' gvkey
	merge m:1 gvkey year using "$data/009_calibration/${doNum}_firm_level_parameters.dta", keepusing(prod ln_prod_* phi sic2 sh omega mean_omega) //markups
	drop if _merge ==2
	drop _merge
	foreach v of varlist prod-mean_omega{
		rename `v' `v'_`i'
		}
	rename gvkey endPoint_`i'
	}

*Calculating the cost of the final firm, starting from the most upstream one
gen mostUpstream = .
forval i = 0/9{
	replace mostUpstream = `i' if endPoint_`i'!=.
	}

*parameters
/*
gen beta = 1.92
gen eta = 4.55
gen rho = 7.5	
*/

*save "$data/009_calibration/${doNum}_supplyChain`y'_temp.dta", replace

*use "$data/009_calibration/${doNum}_supplyChain`y'_temp.dta", clear


gen beta = 1.92
gen eta = 4.55
gen rho = 7.5


/* TEST */
/*
foreach v of varlist mu_*{
	replace `v' = 5 if `v'!=.
	}
*/
*foreach v of varlist prod_*{
*	replace `v' = `v'*10 if `v'!=.
*	}

/*TEST
gen n = _n
gen omega = 0.3
gen cost = (1/1)*( omega^beta + ((1-omega)^beta)*( ( (n)^(1-rho) )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta))
scatter cost n if n<100
*/


*HERE - Changing the marginal cost of int bundle to 0
gen cost_9 = (1/prod_9)*( omega_9^beta + ((1-omega_9)^beta)*(( (1) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_9!=.

forval step = 0/8{
	
	local i = 9 - `step'
	local j = `i' - 1
	
	*9 is most upstream
	bys endPoint_`j' endPoint_`i': gen n_`i' = _n
	*generating markups of 1 if does not exist
	replace mu_`i' = 1 if mu_`i' == .
	
	*HERE - Step taken to limit the impact of low outliers
	*replace cost_`i'=0.1 if cost_`i'<0.1
	
	gen sumOver_`i' = (mu_`i'*cost_`i')^(1 - rho) if n_`i' == 1 & endPoint_`i'!=.
	bys endPoint_`j' endPoint_`i': egen sum_`i' = sum(sumOver_`i') if /*n_`i' == 1 &*/ endPoint_`i'!=.
	replace sum_`i' = . if n_`i'!=1
	gen cost_`j' = (1/prod_`j')*( omega_`j'^beta + ((1-omega_`j')^beta)*( ( (sum_`i') /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_`i'!=.

	*8 is most upstream
	*HERE - Changing the marginal cost of int bundle to 0
	replace cost_`j' = (1/prod_`j')*( omega_`j'^beta + ((1-omega_`j')^beta)*(( (1) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_`i'==. & endPoint_`j'!=.
	*replace cost_`i' = . if n !=1

	*drop n sumOver sum 
	}

drop cost_0 //(irrelevant marginal cost, calculated for the loop to still run)
*costs faced by firm 0, the relevant one
bys endPoint_0: gen n = _n
*generating markups of 1 if does not exist
replace mu_1 = 1 if mu_1 == .

*HERE - Step taken to limit the impact of low outliers
replace cost_1=0.1 if cost_1<0.1

gen sumOver = (mu_1*cost_1)^(1 - rho) if n == 1 & endPoint_1!=.
bys endPoint_0: egen sum = sum(sumOver) if n == 1 & endPoint_0!=.
gen cost_0 = (1/prod_0)*( omega_0^beta + ((1-omega_0)^beta)*( ( (sum) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_0!=.


*********************************************************************************
*		COUNTERFACTUAL COSTS													*
*********************************************************************************

*HERE
gen cost_9_c = (1/prod_9)*( omega_9^beta + ((1-omega_9)^beta)*(( (1) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_9!=.


forval step = 0/8{
	
	local i = 9 - `step'
	local j = `i' - 1
	
	*9 is most upstream
	bys endPoint_`j' endPoint_`i': gen n_`i'_c = _n

	*HERE - Step taken to limit the impact of low outliers
	*replace cost_`i'_c=0.1 if cost_`i'_c<0.1	
	
	gen sumOver_`i'_c = (cost_`i'_c)^(1 - rho) if n_`i'_c == 1 & endPoint_`i'!=.
	bys endPoint_`j' endPoint_`i': egen sum_`i'_c = sum(sumOver_`i'_c) if /*n_`i' == 1 &*/ endPoint_`i'!=.
	replace sum_`i' = . if n_`i'!=1
	gen cost_`j'_c = (1/prod_`j')*( omega_`j'^beta + ((1-omega_`j')^beta)*( ( (sum_`i'_c) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_`i'!=.

	*8 is most upstream
	replace cost_`j'_c = (1/prod_`j')*( omega_`j'^beta + ((1-omega_`j')^beta)*( ( (1) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_`i'==. & endPoint_`j'!=.
	replace cost_`i' = . if n !=1

	*drop n sumOver sum 
	}

drop cost_0_c //(irrelevant marginal cost, calculated for the loop to still run)
*costs faced by firm 0, the relevant one
bys endPoint_0: gen n_c = _n
*generating markups of 1 if does not exist

*HERE - Step taken to limit the impact of low outliers
replace cost_1_c=0.1 if cost_1_c<0.1

gen sumOver_c = (cost_1_c)^(1 - rho) if n_c == 1 & endPoint_1!=.
bys endPoint_0: egen sum_c = sum(sumOver_c) if n_c == 1 & endPoint_0!=.
gen cost_0_c = (1/prod_0)*( omega_0^beta + ((1-omega_0)^beta)*( ( (sum_c) /*^(1-rho)*/ )^((1-eta)/(1-rho)) )^((1-beta)/(1-eta)) )^(1/(1-beta)) if endPoint_0!=.

********

*replace cost_0_c = . if cost_0_c>1
*replace cost_0 = . if cost_0>1

gen ratioCost = cost_0_c/cost_0

scatter cost_0 cost_0_c if cost_0_c<20
hist ratioCost if ratioCost<2

save "$data/009_calibration/${doNum}_welfare_`y'_temp.dta", replace
}
}




*TEMP - Test
use "$data/009_calibration/${doNum}_welfare_2016_temp.dta", replace
br cost*
twoway (hist cost_0 if cost_0<1, color(dknavy%30) width(0.05)) (hist cost_0_c if cost_0_c<2, color(dkgreen%30) width(0.05))
su cost_0, de
su cost_0_c, de


forval y=1976/2016{

use "$data/009_calibration/${doNum}_welfare_`y'_temp.dta", replace


*use "$data/009_calibration/${doNum}_welfare_2016_temp.dta", clear
*HERE
*replace cost_0 = ln(1+cost_0)
*replace cost_0_c = ln(1+cost_0_c)

keep ratioCost cost_0_c cost_0 finalSale n_c rho beta eta mu_*

su cost_0_c, de
*replace cost_0_c=. if cost_0_c>`r(p95)'
*replace cost_0_c=. if cost_0_c<`r(p5)'

su cost_0, de
*replace cost_0=. if cost_0>`r(p95)'
*replace cost_0=. if cost_0<`r(p5)'


replace cost_0_c = . if cost_0_c>3 //| cost_0_c<0.1
replace cost_0 = . if cost_0>3 //| cost_0<0.1

*Getting the 3 price indices
*getting sales shares
gen sale = finalSale if n_c == 1
egen totSales = sum(sale)
gen shSale = sale/totSale
*drop if shSale<0.01

*HERE
*drop if ratioCost>1.5

/*HERE keeping the number of varieties constant
gen nshSale = -shSale
replace nshSale = 0 if nshSale == .
sort nshSale
gen n = _n
keep if n<=100
*/

*HERE
*replace cost_0_c = cost_0 if cost_0_c>cost_0

*HERE
*replace cost_0_c = 0.75 if cost_0_c!=.
*replace cost_0 = 1 if cost_0!=.


*generating ratios of costs
gen weighted_cost_c = cost_0_c*shSale
egen totalCost_c = sum(weighted_cost_c)
gen weighted_cost = cost_0*shSale*mu_0
egen totalCost = sum(weighted_cost)
gen weighted_cost_m = cost_0_c*shSale*mu_0
egen totalCost_m = sum(weighted_cost_m)

*Ratios of expenditures
gen ratio_last = totalCost_m/totalCost_c
gen ratio_all = totalCost/totalCost_c

*counterfactual price index - removing all markup
gen sumOver0 = (shSale^(rho))*((cost_0_c)^(1-rho))
egen sum0 = sum(sumOver0)
gen p0 = sum0^(1/(1-rho))
drop sum*

*removing only the last markup
gen sumOver1 = (shSale^(rho))*((cost_0)^(1-rho))
egen sum1 = sum(sumOver1)
gen p1 = sum1^(1/(1-rho))
drop sum*

*All markups
gen sumOver1_all = (shSale^(rho))*(((cost_0)*mu_0)^(1-rho))
egen sum1_all = sum(sumOver1_all)
gen p1_all = sum1_all^(1/(1-rho))
drop sum*

*counterfactual price index - removing all markup - No weights
gen sumOver2 = ((cost_0_c)^(1-rho))
egen sum2 = sum(sumOver2)
gen p2 = sum2^(1/(1-rho))
drop sum*

*removing only the last markup - No weights
gen sumOver3 = ((cost_0)^(1-rho))
egen sum3 = sum(sumOver3)
gen p3 = sum3^(1/(1-rho))
drop sum*

*All markups - No weights
gen sumOver3_all = (((cost_0)*mu_0)^(1-rho))
egen sum3_all = sum(sumOver3_all)
gen p3_all = sum3_all^(1/(1-rho))
drop sum*

*ETA counterfactual price index - removing all markup
gen sumOver4 = (shSale^(eta))*((cost_0_c)^(1-eta))
egen sum4 = sum(sumOver4)
gen p4 = sum4^(1/(1-eta))
drop sum*

*ETA removing only the last markup
gen sumOver5 = (shSale^(eta))*((cost_0)^(1-eta))
egen sum5 = sum(sumOver5)
gen p5 = sum5^(1/(1-eta))
drop sum*

*ETA all markups
gen sumOver5_all = (shSale^(eta))*(((cost_0)*mu_0)^(1-eta))
egen sum5_all = sum(sumOver5_all)
gen p5_all = sum5_all^(1/(1-eta))
drop sum*

*ETA counterfactual price index - removing all markup no weights
gen sumOver6 = ((cost_0_c)^(1-eta))
egen sum6 = sum(sumOver6)
gen p6 = sum6^(1/(1-eta))
drop sum*

*ETA removing only the last markup - no weights
gen sumOver7 = ((cost_0)^(1-eta))
egen sum7 = sum(sumOver7)
gen p7 = sum7^(1/(1-eta))
*drop sum*

*ETA all markups - no weights
gen sumOver7_all = (((cost_0)*mu_0)^(1-eta))
egen sum7_all = sum(sumOver7_all)
gen p7_all = sum7_all^(1/(1-eta))
*drop sum*

*Getting the number of varieties
replace n_c = . if n_c!=1
egen varieties = sum(n_c)

su p0 p1 p1_all p2 p3 p3_all p4 p5 p5_all p6 p7 p7_all

keep p0 p1 p1_all p2 p3 p3_all p4 p5 p5_all p6 p7 p7_all ratioCost cost_0_c cost_0 finalSale n_c rho beta eta mu_* ratio_all ratio_last totalCost_m totalCost totalCost_c varieties
keep if _n == 1
gen year = `y'

save "$data/009_calibration/${doNum}_welfare_`y'.dta", replace
}

use "$data/009_calibration/${doNum}_welfare_1976.dta", clear
forval y=1977/2016{
	append using "$data/009_calibration/${doNum}_welfare_`y'.dta"
	}

gen id = 1
xtset id year 
gen ratio_all_ma = (F.ratio_all + ratio_all + L.ratio_all)/3
replace ratio_all_ma = ratio_all if ratio_all_ma==.
twoway (scatter ratio_all_ma year, connect(direct) msymbol(O) mfcolor(white)) ///
		(scatter ratio_last year, connect(direct) msymbol(O) mfcolor(white)), ///
		xlabel(, labsize(large)) legend( ring(0) pos(11) col(1) order(1 "All markups" 2 "Only last markup") size(large)) ///
		ylabel(, labsize(large)) xtitle("") yline(1)
stop
*Use this graph	
graph export "$outputs/009_calibration/censoring.pdf", as(pdf) replace	
	
stop
*channels
	
gen ratio = totalCost/totalCost_m

scatter ratio year, connect(direct)

*share	
gen ratio_last_0 = p1/p0
gen ratio_all_0 = p1_all/p0	

gen ratio_last_2 = p3/p2
gen ratio_all_2 = p3_all/p2	

*share
gen ratio_last_4 = p5/p4
gen ratio_all_4 = p5_all/p4	

gen ratio_last_6 = p7/p6
gen ratio_all_6 = p7_all/p6	
	
sort year

twoway (scatter ratio_last_0 year if ratio_last_0<10, connect(direct)) ///
	(scatter ratio_all_0 year if ratio_all_0<10, connect(direct))
*Use this graph
graph export "$outputs/009_calibration/censoring_0.pdf", as(pdf) replace

twoway (scatter ratio_last_2 year, connect(direct)) ///
	(scatter ratio_all_2 year, connect(direct))
graph export "$outputs/009_calibration/censoring_2.pdf", as(pdf) replace
	
*Use this graph
gen id = 1
xtset id year
*gen ratio_last_4_ma = (0.05*F3.ratio_last_4 + 0.1*F2.ratio_last_4 + 0.2*F.ratio_last_4 + 0.3*ratio_last_4 + 0.2*L.ratio_last_4 + 0.1*L2.ratio_last_4 + 0.05*L3.ratio_last_4)
*gen ratio_all_4_ma = (0.05*F3.ratio_all_4 + 0.1*F2.ratio_all_4 + 0.2*F.ratio_all_4 + 0.3*ratio_all_4 + 0.2*L.ratio_all_4 + 0.1*L2.ratio_all_4 + 0.05*L3.ratio_all_4)
gen ratio_last_4_ma = (F.ratio_last_4 + ratio_last_4 + L.ratio_last_4)/3
gen ratio_all_4_ma = (F.ratio_all_4 + ratio_all_4 + L.ratio_all_4)/3
replace ratio_last_4_ma = ratio_last_4 if ratio_last_4_ma==.
replace ratio_all_4_ma = ratio_all_4 if ratio_all_4_ma==.

*Use this graph
twoway (scatter ratio_all_4_ma year, connect(direct) msymbol(O) mfcolor(white)) ///
	(scatter ratio_last_4_ma year, connect(direct) msymbol(O) mfcolor(white)), ///
	xlabel(, labsize(large)) ylabel(1(0.5)3.5 , labsize(large)) xtitle("") yline(1) legend( ring(0) pos(11) col(1) order(1 "All markups" 2 "Only last markup") size(large))
	
*twoway (scatter ratio_last_4 year, connect(direct)) ///
*	(scatter ratio_all_4 year, connect(direct))
graph export "$outputs/009_calibration/censoring_3.pdf", as(pdf) replace

gen diff = ratio_all_4_ma - ratio_last_4_ma
scatter diff year, connect(direct)

gen ratio_temp = ratio_all_4/ratio_last_4
scatter ratio_temp year

twoway (line p4 year) (line p5 year) (line p5_all year)

gen id = 1
xtset id year
*gen ratio_last_6_ma = (F2.ratio_last_6 + F.ratio_last_6 + ratio_last_6 + L.ratio_last_6 + L2.ratio_last_6)/3
*gen ratio_all_6_ma = (F2.ratio_all_6 + F.ratio_all_6 + ratio_all_6 + L.ratio_all_6 + L2.ratio_all_6)/3

twoway (scatter ratio_last_6 year, connect(direct)) ///
	(scatter ratio_all_6 year, connect(direct))
graph export "$outputs/009_calibration/censoring_4.pdf", as(pdf) replace
