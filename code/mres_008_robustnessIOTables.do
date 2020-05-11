
/*******************************************************************************
	
	DESCRIPTION: Robustness of empirical exercise using input-output tables
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 11/05/2020
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
global data "$orig/Data_output/008_robustnessIOTables"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*do-file number, used to save outputs 
global doNum "008"					

*log
cap log close
log using "$log/${doNum}_robustnessIOTables", text append


/*******************************************************************************
	Robustness of statistics for introduction - Using IO tables
*******************************************************************************/

* 1963-1996

*Using the historical use tables
forval y = 1963/1996{
	qui{
		import excel "https://apps.bea.gov/industry/xls/io-annual/IOUse_Before_Redefinitions_PRO_1963-1996_Summary.xlsx", sheet("`y'") cellrange(A7) firstrow clear
		compress
		save "$data/${doNum}_orig`y'_use", replace
		*https://apps.bea.gov/industry/xls/io-annual/IOUse_Before_Redefinitions_PRO_1963-1996_Summary.xlsx
		foreach v of var * {
			local lbl : var label `v'
			local lbl = strtoname("`lbl'")
			rename `v' code`lbl'
			}
		ren codeCode Code
		ren codeCom Commodity_Description
		foreach v of varlist code_111CA-code_81{
			replace `v' = "" if `v' == "..."
			destring `v', replace
			}
			
		drop if Code == "GFG" | Code == "GFE" | Code == "GSLG" | Code == "GSLE" | Code == "Used" | Code == "Other" 
		local extraObs = _N+3
		set obs `extraObs'
	
		local extraObs = _N
		local extraObs_4 = `extraObs'-4
		local extraObs_2 = `extraObs'-2
		local extraObs_1 = `extraObs'-1
		
		replace Comm = "Count" in `extraObs_2'
		replace Comm = "Weight" in `extraObs_1'
		replace Comm = "Sum" in `extraObs'

		foreach v of varlist code_111CA-code_81{
			count if `v'!=. & `v'!=0 & Code!="T007"
			replace `v' = `r(N)' in `extraObs_2'
			replace `v' = `r(N)'* `v'[`extraObs_4'] in `extraObs'
			}
		egen rowsum = rowtotal(code_111CA-code_81)
		egen rowmean = rowmean(code_111CA-code_81)
		}
	global av`y' = rowsum[`extraObs']/rowsum[`extraObs_4']
	global av`y'_unweighted = rowmean[`extraObs_2']
	di ${av`y'}, ${av`y'_unweighted}
	}

clear
set obs 34
gen degree = .
gen degree_unweighted = .
gen y = .
forval y = 1963/1996{
	local pos = `y' - 1962
	replace degree = ${av`y'} in `pos'
	replace degree_unweighted = ${av`y'_unweighted} in `pos'
	replace y = `y' in `pos'
	}
save "$data/${doNum}_use_6396", replace
twoway (scatter degree y, connect(direct)) ///
	(scatter degree_unweighted y, connect(direct)) 


*Using the historical make tables
forval y = 1963/1996{
	qui{
		import excel "https://apps.bea.gov/industry/xls/io-annual/IOMake_Before_Redefinitions_1963-1996_Summary.xlsx", sheet("`y'") cellrange(A7) firstrow clear
		compress
		save "$data/${doNum}_orig`y'_make", replace
		foreach v of var * {
			local lbl : var label `v'
			local lbl = strtoname("`lbl'")
			rename `v' code`lbl'
			}
		ren codeCode Code
		ren codeIndustry Commodity_Description
		foreach v of varlist code_111CA-code_81{
			replace `v' = "" if `v' == "..."
			destring `v', replace
			}
			
		drop if Code == "GFG" | Code == "GFE" | Code == "GSLG" | Code == "GSLE" | Code == "Used" | Code == "Other" 
		local extraObs = _N+3
		set obs `extraObs'
	
		local extraObs = _N
		local extraObs_4 = `extraObs'-4
		local extraObs_2 = `extraObs'-2
		local extraObs_1 = `extraObs'-1
		
		replace Comm = "Count" in `extraObs_2'
		replace Comm = "Weight" in `extraObs_1'
		replace Comm = "Sum" in `extraObs'

		foreach v of varlist code_111CA-code_81{
			count if `v'!=. & `v'!=0 & Code!="T007"
			replace `v' = `r(N)' in `extraObs_2'
			replace `v' = `r(N)'* `v'[`extraObs_4'] in `extraObs'
			}
		egen rowsum = rowtotal(code_111CA-code_81)
		egen rowmean = rowmean(code_111CA-code_81)
		}
	global av`y' = rowsum[`extraObs']/rowsum[`extraObs_4']
	global av`y'_unweighted = rowmean[`extraObs_2']
	di ${av`y'}, ${av`y'_unweighted}
	}

gen degree = .
gen degree_unweighted = .
gen y = .
forval y = 1963/1996{
	local pos = `y' - 1962
	replace degree = ${av`y'} in `pos'
	replace degree_unweighted = ${av`y'_unweighted} in `pos'
	replace y = `y' in `pos'
	}
twoway (scatter degree y, connect(direct)) ///
	(scatter degree_unweighted y, connect(direct)) 	
	
*1997-2018
forval y=1997/2018{
	qui{
		import excel "$orig/Input Output tables 1997-2018/`y'.xls", cellrange(A6) firstrow clear
		drop BV-CV
		foreach v of var * {
			local lbl : var label `v'
			local lbl = strtoname("`lbl'")
			rename `v' code`lbl'
			}
		*dropping observations that are not present in the earlier input-output tables
		*drop if code == "441" | code == "445" |code == "452" |code == "4A0" |code == "HS" |code == "ORE" |code == "623"
		*drop code
		drop if codeCommodities == ""
		*drop code_441 code_445 code_452 code_4A0 codeHS codeORE code_623
		drop if _n == 1
		foreach v of varlist code_111CA-code_81{
			replace `v' = "" if `v' == "..."
			destring `v', replace
			}
			
		drop if code == "GFG" | code == "GFE" | code == "GSLG" | code == "GSLE" | code == "Used" | code == "Other" | /// 
			code == "GFGD" | code == "GFGN" | code == "V001" | code == "V002" | code == "V003" | ///
			code == "" & codeCommodities!="Total Value Added"
		
		local extraObs = _N+3
		set obs `extraObs'
	
		local extraObs = _N
		local extraObs_4 = `extraObs'-4
		local extraObs_2 = `extraObs'-2
		local extraObs_1 = `extraObs'-1
		
		replace codeComm = "Count" in `extraObs_2'
		replace codeComm = "Weight" in `extraObs_1'
		replace codeComm = "Sum" in `extraObs'

		foreach v of varlist code_111CA-code_81{
			count if `v'!=. & `v'!=0 & codeComm!="Total Value Added"
			replace `v' = `r(N)' in `extraObs_2'
			replace `v' = `r(N)'* `v'[`extraObs_4'] in `extraObs'
			}
		egen rowsum = rowtotal(code_111CA-code_81)
		egen rowmean = rowmean(code_111CA-code_81)
		}
	global av`y' = rowsum[`extraObs']/rowsum[`extraObs_4']
	global av`y'_unweighted = rowmean[`extraObs_2']
	di ${av`y'}, ${av`y'_unweighted}
	}

clear
set obs 22
gen degree = .
gen degree_unweighted = .
gen y = .
forval y = 1997/2018{
	local pos = `y' - 1996
	replace degree = ${av`y'} in `pos'
	replace degree_unweighted = ${av`y'_unweighted} in `pos'
	replace y = `y' in `pos'
	}
save "$data/${doNum}_use_9718", replace
twoway (scatter degree y, connect(direct)) ///
	(scatter degree_unweighted y, connect(direct)) 

use "$data/${doNum}_use_6396", clear
append using "$data/${doNum}_use_9718"
twoway (scatter degree y, connect(direct)) ///
	(scatter degree_unweighted y, connect(direct))





replace 

di Otherservicesexceptgovernmen[1]

rename Otherservicesexceptgovernmen `Otherservicesexceptgovernmen[1]'

replace 

*Using historical tables



forval y = 1976/2016{

qui{

*Adding a_ij's i.e. input expenditures as a share of sales
use "$wd/data/001_network/003_fullNet`y'.dta", clear
collapse (sum) salecs_supplier (mean) sales_customer (firstnm) comp_supplier comp_customer , by(Source Target year)
gen a = salecs_supplier/sales_customer
keep Source comp_supplier comp_customer Target /*year3*/ year a
*rename year3 year
replace a = 1 if a>1
save "$data/007_aij`y'.dta", replace

*Starting from the value chain
use "$wd/data/006_network&Markups/006_endPoint`y'_wide.dta", clear

*Getting the sales share of the end point
rename endPoint_0 gvkey
gen year = `y'
merge m:1 gvkey year using "$wd/data/006_network&Markups/006_markups`y'.dta", keepusing(mu_1 sale)
drop if _merge == 2
drop _merge

*Getting company names
merge m:1 gvkey year using "$wd/data/001_network/003_allcomp.dta", keepusing(conm)
drop if _merge == 2
drop _merge

rename sale finalSale
rename mu_1 mu_0

*Now including sales of shares and markups further up the value chain
rename gvkey Target 
rename endPoint_1 Source
merge m:1 Source Target year using "$data/007_aij`y'.dta", keepusing(a)
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
	merge m:1 gvkey year using "$wd/data/006_network&Markups/006_markups`y'.dta", keepusing(mu) //markups
	drop if _merge == 2
	drop _merge
	rename mu mu_`step'
	rename gvkey Target 
	rename endPoint_`nextStep' Source
	merge m:1 Source Target year using "$data/007_aij`y'.dta", keepusing(a)
	drop if _merge == 2
	drop _merge
	rename a a`nextStep'`step'
	rename Target endPoint_`step'
	rename Source endPoint_`nextStep'
	}
	
*e(q1, u1)

*Last endpoint
bys endPoint_0: gen n = _n
gen sales = finalSale if n==1
egen totSales = sum(sales)
gen salesSh = sales/totSales
gen sales_mu0 = sales/mu_0


*Shutting down all markups in the value chain
*generating product\mu_j^{a_ij}
gen a_ln_mu_1 = ln(mu_1)*a10
bys endPoint_0: egen ln_pi_1 = sum(a_ln_mu_1)
gen pi_1 = exp(ln_pi_1) if n == 1

*gen sales_mu0mu1 = sales/(mu_0*pi_1)
*egen totSales_mu0mu1 = sum(sales_mu0mu1)
*gen ratio_mu0mu1 = totSales/totSales_mu0mu1											//19%, looks credible

gen a_ln_mu_2 = ln(mu_2)*a10*a21
bys endPoint_0: egen ln_pi_2 = sum(a_ln_mu_2)
gen pi_2 = exp(ln_pi_2) if n == 1

gen a_ln_mu_3 = ln(mu_3)*a10*a21*a32
bys endPoint_0: egen ln_pi_3 = sum(a_ln_mu_3)
gen pi_3 = exp(ln_pi_3) if n == 1

gen a_ln_mu_4 = ln(mu_4)*a10*a21*a32*a43
bys endPoint_0: egen ln_pi_4 = sum(a_ln_mu_4)
gen pi_4 = exp(ln_pi_4) if n == 1

gen a_ln_mu_5 = ln(mu_5)*a10*a21*a32*a43*a54
bys endPoint_0: egen ln_pi_5 = sum(a_ln_mu_5)
gen pi_5 = exp(ln_pi_5) if n == 1

gen a_ln_mu_6 = ln(mu_6)*a10*a21*a32*a43*a54*a65
bys endPoint_0: egen ln_pi_6 = sum(a_ln_mu_6)
gen pi_6 = exp(ln_pi_6) if n == 1

gen a_ln_mu_7 = ln(mu_7)*a10*a21*a32*a43*a54*a65*a76
bys endPoint_0: egen ln_pi_7 = sum(a_ln_mu_7)
gen pi_7 = exp(ln_pi_7) if n == 1

gen a_ln_mu_8 = ln(mu_8)*a10*a21*a32*a43*a54*a65*a76*a87
bys endPoint_0: egen ln_pi_8 = sum(a_ln_mu_8)
gen pi_8 = exp(ln_pi_8) if n == 1


*Final welfare loss
gen denom = mu_0*pi_1*pi_2*pi_3*pi_4*pi_5*pi_6*pi_7*pi_8

*First step i  value chain
egen totSales_mu0 = sum(sales_mu0)
gen ratio_mu0 = totSales/totSales_mu0											//18%, looks credible 
su ratio_mu0
global mu0_`y' = `r(mean)'

gen sales_mu = sales/denom
egen totSales_mu = sum(sales_mu)
gen ratio_mu = totSales/totSales_mu											//18%, looks credible 
su ratio_mu
global mu_`y' = `r(mean)'

*Accounting for substitution of consumption
*Setting the quantity of the most commonly consumed good equal before and after the price increase
*(the expenses just decrease by the network-adjusted markup)
*Multiply each sales without markup by alpha/beta (sales share of numeraire/sales share of this product)

*Finding the numeraire (max sales shares)
*sort finalSale
*egen topSale = max(finalSale)
*gen alphaOverBeta = topSale/finalSale

*gen sales_mu_subs = (sales/denom)*(alphaOverBeta)
*egen totSales_mu_subs = sum(sales_mu_subs)
*gen ratio_mu_subs = totSales/totSales_mu_subs											//18%, looks credible 
*su ratio_mu_subs
*global mu_`y' = `r(mean)'

*equalising shares of expenditures
gen shInitial = finalSale/totSales
gen shFinal = sales_mu/totSales_mu
gen shInitial0 = finalSale/totSales
gen shFinal0 = sales_mu0/totSales_mu0
gen sales_mu_subs=sales_mu
gen sales_mu0_subs=sales_mu0


gen shFinal_subs = shFinal
gen shInitial_subs = shInitial if shFinal_subs!=.
gen shFinal_subs0 = shFinal0
gen shInitial_subs0 = shInitial0 if shFinal_subs0!=.

forval i=1/30{
replace sales_mu_subs=sales_mu_subs*0.99 if shFinal_subs>shInitial_subs & shFinal_subs!=.			//decrease expenditure on that good
egen totSales_mu_subs=sum(sales_mu_subs)
replace shFinal_subs=sales_mu_subs/totSales_mu_subs
drop totSales_mu_subs	

replace sales_mu_subs=sales_mu_subs*1.01 if shFinal_subs<shInitial_subs & shFinal_subs!=.			//increase expenditure on that good
egen totSales_mu_subs=sum(sales_mu_subs)
replace shFinal_subs=sales_mu_subs/totSales_mu_subs
drop totSales_mu_subs

replace sales_mu0_subs=sales_mu0_subs*0.99 if shFinal_subs0>shInitial_subs0 & shFinal_subs0!=.			//decrease expenditure on that good
egen totSales_mu0_subs=sum(sales_mu0_subs)
replace shFinal_subs0=sales_mu0_subs/totSales_mu0_subs
drop totSales_mu0_subs	

replace sales_mu0_subs=sales_mu0_subs*1.01 if shFinal_subs0<shInitial_subs0 & shFinal_subs0!=.			//increase expenditure on that good
egen totSales_mu0_subs=sum(sales_mu0_subs)
replace shFinal_subs=sales_mu0_subs/totSales_mu0_subs
drop totSales_mu0_subs

}
	
twoway (scatter shFinal_subs shInitial_subs) ///
	(scatter shFinal shInitial)

twoway (scatter shFinal_subs0 shInitial_subs0) ///
	(scatter shFinal shInitial)


*gen subs_ratio = shInitial/shFinal
*replace subs_ratio=4 if subs_ratio>4 & subs_ratio!=.

*gen sales_mu_subs = sales_mu*subs_ratio
egen totSales_mu_subs = sum(sales_mu_subs)
gen ratio_mu_subs = totSales/totSales_mu_subs											//18%, looks credible 
su ratio_mu_subs
global mu_`y'_subs = `r(mean)'

*gen sales_mu0_subs = sales_mu0*subs_ratio
egen totSales_mu0_subs = sum(sales_mu0_subs)
gen ratio_mu0_subs = totSales/totSales_mu0_subs											//18%, looks credible 
su ratio_mu0_subs
global mu0_`y'_subs = `r(mean)'

}
di "`y'"
di ${mu0_`y'}, ${mu_`y'}, ${mu0_`y'_subs}, ${mu_`y'_subs}
}

*graph
clear
set obs 41
gen y = 1975 + _n
gen mu0 = .
gen mu = .
gen mu0_subs = .
gen mu_subs = .
forval y = 1976/2016{
	replace mu0 = ${mu0_`y'} if y == `y'
	replace mu = ${mu_`y'} if y == `y'
	replace mu0_subs = ${mu0_`y'_subs} if y == `y'
	replace mu_subs = ${mu_`y'_subs} if y == `y'
	}

twoway (scatter mu0 y, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu y, msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.1)1.4) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
graph export "$outputs/007_welfare.pdf", as(pdf) replace

twoway (scatter mu0_subs y, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu_subs y, msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.1)1.7) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
graph export "$outputs/007_welfare_2.pdf", as(pdf) replace

	
	
	
	