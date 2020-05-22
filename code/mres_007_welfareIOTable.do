
/*******************************************************************************
	
	DESCRIPTION: Calculating welfare losses using input-output matrices
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 12/05/2020
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
global data "$orig/Data_output/007_welfare"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*do-file number, used to save outputs 
global doNum "007"					

*log
cap log close
log using "$log/${doNum}_welfare_IOTables", text append


/*******************************************************************************
	Getting all the supply chains leading to final demand
*******************************************************************************/

*Production going to final use: "Total Final Uses (GDP)"
*Production going to intermediate use: "Total intermediate"

*1997 to 2016
forval y = 1997/2016{
	
	qui{
	
		*Building datasets of average markups of the Source this year
		use "$orig/Data_output/006_network&Markups/006_markups`y'.dta", clear
		replace sale_D = round(sale_D, 1)
		forval i=2/4{
			preserve
			collapse mu_1 [fw=sale_D], by(ind`i'd)
			rename ind temp
			tostring temp, gen(NAICS)
			drop temp
			compress
			gen Source = NAICS
			drop if strlen(NAICS)<`i'
			save "$data/${doNum}_mu_ind`i'd_`y'.dta", replace
			restore
			}
		
		*Getting the shares of production for final consumption (GDP)
		import excel "$orig/Input Output tables 1997-2018/`y'.xls", cellrange(A6) firstrow clear
		label var BV "Sum of Intermediate Selected"
		label var BW "Intermediate not Selected"
		label var BX "Total Intermediate"
		label var CS "Sum of Final Uses1"		// "Sum of Final Uses (GDP) Selected"
		label var CT "Sum of Final Uses2"		// "Sum of Final Uses (GDP) Not Selected"
		label var CU "Final Uses (GDP)"
		label var CV "Total Commodity Output"
		
		foreach v of var * {
			local lbl : var label `v'
			local lbl = strtoname("`lbl'")
			rename `v' code`lbl'
			}
		
		drop if codeCommodities == ""
		drop if _n == 1
		foreach v of varlist code_111CA-codeTotal_Commodity_Output{
			replace `v' = "" if `v' == "..."
			destring `v', replace
			replace `v' = . if `v' == 0
			}
		
		*getting the input expenditures by industries
		gen codeTemp = code if code<"A"
		gen shFinal=codeFinal_Uses__GDP_/codeTotal_Commodity_Output
		sort shFinal
		replace shFinal = 0 if shFinal<0
		
		*Generating total sales to final consumer
		gen finalSale = codeFinal_Uses__GDP_
		replace finalSale = 0 if finalSale<0

		*Dropping unecessary rows
		sort code
		drop if code=="" & codeCommodities!="Total Industry Output" & codeCommodities!="Total Value Added"
		drop if code>"A" & code!=""
		
		*Getting the expenditure shares
		sort code codeComm
		foreach v of varlist code_111CA-code_81{
			su `v' if codeComm == "Total Industry Output"
			replace `v' = `v'/`r(mean)'
			}
		drop if code == ""
		drop codeGFGD-codeTotal_Commodity_Output
		rename code NAICS
		reshape long code_, i(NAICS codeComm shFinal) j(customer) string
		rename code_ expShare
		drop if expShare == .
		rename NAICS Source
		rename customer Target
		
		*Cleaning the NAICS names into simple 2-, 3- or 4-digit names
		foreach v of varlist Source Target{
			rename `v' temp
			egen `v' = sieve(temp), keep(numeric)
			drop temp
			}
		
		*Merging with markup data at all NAICS levels
		foreach naics in "ind2d" "ind3d" "ind4d"{
			merge m:1 Source using "$data/${doNum}_mu_`naics'_`y'.dta", keepusing(mu_1) update
			drop if _merge == 2
			drop _merge
			}
		
		*Replacing missing markup information by the average markup this year
		su mu_1
		replace mu_1 = `r(mean)' if mu_1==.
		
		*Getting the value chains
		drop codeComm codeHS-codeORE
		compress
		save "$data/${doNum}_IO_`y'.dta", replace 
		
		rename Target Target0
		rename mu_1 mu_10
		rename expShare expShare0
		rename Source Target 
		
		*Getting markups of the last firm
		rename Target0 Source 
		foreach naics in "ind2d" "ind3d" "ind4d"{
			merge m:1 Source using "$data/${doNum}_mu_`naics'_`y'.dta", keepusing(mu_1) update
			drop if _merge == 2
			drop _merge
			}
		su mu_1
		replace mu_1 = `r(mean)' if mu_1==.
		rename mu_1 mu_0
		rename Source Target0
		
		*Merging the subsequent suppliers
		forval i = 1/10{
			merge m:m Target using "$data/${doNum}_IO_`y'.dta", keepusing(expShare mu_1 Source)
			keep if _merge!= 2
			drop _merge
			rename expShare expshare`i'
			rename Target Target`i'
			rename mu_1 mu_1`i'
			rename Source Target
			}
		rename Target Target11
		
		*Shutting down all markups in the value chain
		bys Target0: gen n = _n
		
		*generating product\mu_j^{a_ij}
		rename expShare0 expshare0
		foreach v of varlist expshare*{											// replacing negative expenditure shares as this can blow up markups smaller than 1
			replace `v'=0 if `v'<0
			}
			
		forval i=0/10{
			local supplier = `i'+1
			if `i'==0 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0 if Target`i'!=Target`supplier'
				}		//IMPORTANT: I am assuming that industries do not charge markups to each other
			if `i'==1 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1 if Target`i'!=Target`supplier'
				}
			if `i'==2 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2 if Target`i'!=Target`supplier'
				}
			if `i'==3 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3 if Target`i'!=Target`supplier'
				}
			if `i'==4 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4 if Target`i'!=Target`supplier'
				}
			if `i'==5 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5 if Target`i'!=Target`supplier'
				}
			if `i'==6 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6 if Target`i'!=Target`supplier'
				}
			if `i'==7 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7 if Target`i'!=Target`supplier'
				}
			if `i'==8 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8 if Target`i'!=Target`supplier'
				}
			if `i'==9 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8*expshare9 if Target`i'!=Target`supplier'
				}
			if `i'==10 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8*expshare9*expshare10 if Target`i'!=Target`supplier'
				}
			bys Target0: egen ln_pi_`i' = sum(a_ln_mu_`i')
			gen pi_`i' = exp(ln_pi_`i') if n == 1
			}
			
		
		*Final welfare loss
		gen denom = mu_0*pi_0*pi_1*pi_2*pi_3*pi_4*pi_5*pi_6*pi_7*pi_8
		replace denom=10 if denom>10 & denom!=.
		sort denom
		br mu_0 denom pi_*
		
		*e(q1, u1)
		
		*Last endpoint
		gen sales = finalSale if n==1
		egen totSales = sum(sales)
		gen salesSh = sales/totSales
		gen sales_mu0 = sales/mu_0
		
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
		
		*equalising shares of expenditures
		drop shFinal
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
			
		*twoway (scatter shFinal_subs shInitial_subs) ///
		*	(scatter shFinal shInitial)
		
		*twoway (scatter shFinal_subs0 shInitial_subs0) ///
		*	(scatter shFinal shInitial)
		
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
		
		compress
		save "$data/${doNum}_welfareIOTable_`y'.dta", replace
		}
	di "`y'"
	di ${mu0_`y'}, ${mu_`y'}, ${mu0_`y'_subs}, ${mu_`y'_subs}
	}

*graph
clear
set obs 41
gen y = 1996 + _n
gen mu0 = .
gen mu = .
gen mu0_subs = .
gen mu_subs = .
forval y = 1997/2016{
	replace mu0 = ${mu0_`y'} if y == `y'
	replace mu = ${mu_`y'} if y == `y'
	replace mu0_subs = ${mu0_`y'_subs} if y == `y'
	replace mu_subs = ${mu_`y'_subs} if y == `y'
	}

	gen diff = mu_subs - mu0_subs
	scatter diff y if y<=2016, connect(direct)
	
twoway (scatter mu0 y if y<2016, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu y if y<2016, msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.1)1.4) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
*graph export "$outputs/007_welfare_IOTables.pdf", as(pdf) replace

twoway (scatter mu0_subs y if y<2016, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu_subs y if y<2016, msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.1)1.7) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
*graph export "$outputs/007_welfare_2_IOTables.pdf", as(pdf) replace


********************************************************************************
*	1963-1996

forval y = 1963/1996{
	qui{
		*Building datasets of average markups of the Source this year
		use "$orig/Data_output/006_network&Markups/006_markups`y'.dta", clear
		replace sale_D = round(sale_D, 1)
		forval i=2/4{
			preserve
			collapse mu_1 [fw=sale_D], by(ind`i'd)
			rename ind temp
			tostring temp, gen(NAICS)
			drop temp
			compress
			gen Source = NAICS
			drop if strlen(NAICS)<`i'
			save "$data/${doNum}_mu_ind`i'd_`y'.dta", replace
			restore
			}
		
		*Getting the shares of production for final consumption (GDP)
		import excel "https://apps.bea.gov/industry/xls/io-annual/IOUse_Before_Redefinitions_PRO_1963-1996_Summary.xlsx", sheet("`y'") cellrange(A7) firstrow clear
		/*label var BV "Sum of Intermediate Selected"
		label var BW "Intermediate not Selected"
		label var BX "Total Intermediate"
		label var CS "Sum of Final Uses1"		// "Sum of Final Uses (GDP) Selected"
		label var CT "Sum of Final Uses2"		// "Sum of Final Uses (GDP) Not Selected"
		label var CU "Final Uses (GDP)"
		label var CV "Total Commodity Output"*/
		
		foreach v of var * {
			local lbl : var label `v'
			local lbl = strtoname("`lbl'")
			rename `v' code`lbl'
			}
		
		drop if codeCommodity == ""
		*drop if _n == 1
		foreach v of varlist code_111CA-codeT007{
			replace `v' = "" if `v' == "..."
			destring `v', replace
			replace `v' = . if `v' == 0
			}
		
		*MODIFIED
		*getting the input expenditures by industries
		*gen shFinal= codeT004/codeT007 if codeCode<"A"		
		*sort shFinal
		*replace shFinal = 0 if shFinal<0
		
		*MODIFIED
		*getting total sales to the final consumer
		gen finalSale=codeT004
		replace finalSale = 0 if finalSale<0
		
		*Dropping unecessary rows
		sort codeCode
		drop if codeCode=="" & codeCommodity!="Total Industry Output" & codeCommodity!="Total Value Added"
		drop if codeCode>"A" & codeCommodity!="Total Industry Output" & codeCommodity!="Total Value Added"
		
		*Getting the expenditure shares
		sort codeCode codeComm
		foreach v of varlist code_111CA-code_81{
			su `v' if codeComm == "Total Industry Output"
			replace `v' = `v'/`r(mean)'
			}
		drop if codeCode == ""
		drop codeGFG-codeT007
		rename codeCode NAICS
		
		*MODIFIED
		reshape long code_, i(NAICS codeComm finalSale) j(customer) string
		
		rename code_ expShare
		drop if expShare == .
		rename NAICS Source
		rename customer Target
		
		*MODIFIED
		drop if codeComm == "Total Value Added" | codeComm=="Total Industry Output"
		
		*Cleaning the NAICS names into simple 2-, 3- or 4-digit names
		foreach v of varlist Source Target{
			rename `v' temp
			egen `v' = sieve(temp), keep(numeric)
			drop temp
			}
		
		*Merging with markup data at all NAICS levels
		foreach naics in "ind2d" "ind3d" "ind4d"{
			merge m:1 Source using "$data/${doNum}_mu_`naics'_`y'.dta", keepusing(mu_1) update
			drop if _merge == 2
			drop _merge
			}
		
		*Replacing missing markup information by the average markup this year
		su mu_1
		replace mu_1 = `r(mean)' if mu_1==.
		
		*Getting the value chains
		drop codeComm
		compress
		
		*MODIFIED
		*Adding the Target sales to the final consumer
		preserve
			bys Source: gen n=_n
			keep if n==1
			keep Source finalSale
			compress
			rename Source Target												//for merge later on
			save "$data/${doNum}_finalSale_`y'.dta", replace
		restore
		drop finalSale
		merge m:1 Target using "$data/${doNum}_finalSale_`y'.dta"
		drop if _merge==2
		drop _merge
		
		save "$data/${doNum}_IO_`y'.dta", replace 
		
		rename Target Target0
		rename mu_1 mu_10
		rename expShare expShare0
		rename Source Target 
		
		*Getting markups of the last firm
		rename Target0 Source 
		foreach naics in "ind2d" "ind3d" "ind4d"{
			merge m:1 Source using "$data/${doNum}_mu_`naics'_`y'.dta", keepusing(mu_1) update
			drop if _merge == 2
			drop _merge
			}
		su mu_1
		replace mu_1 = `r(mean)' if mu_1==.
		rename mu_1 mu_0
		rename Source Target0
		
		*Merging the subsequent suppliers
		forval i = 1/10{
			merge m:m Target using "$data/${doNum}_IO_`y'.dta", keepusing(expShare mu_1 Source)
			keep if _merge!= 2
			drop _merge
			rename expShare expshare`i'
			rename Target Target`i'
			rename mu_1 mu_1`i'
			rename Source Target
			}
		rename Target Target11
		
		*Shutting down all markups in the value chain
		bys Target0: gen n = _n
		
		*generating product\mu_j^{a_ij}
		rename expShare0 expshare0
		foreach v of varlist expshare*{											// replacing negative expenditure shares as this can blow up markups smaller than 1
			replace `v'=0 if `v'<0
			}
			
		forval i=0/10{
			local supplier = `i'+1
			if `i'==0 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0 if Target`i'!=Target`supplier'
				}		//IMPORTANT: I am assuming that industries do not charge markups to each other
			if `i'==1 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1 if Target`i'!=Target`supplier'
				}
			if `i'==2 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2 if Target`i'!=Target`supplier'
				}
			if `i'==3 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3 if Target`i'!=Target`supplier'
				}
			if `i'==4 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4 if Target`i'!=Target`supplier'
				}
			if `i'==5 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5 if Target`i'!=Target`supplier'
				}
			if `i'==6 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6 if Target`i'!=Target`supplier'
				}
			if `i'==7 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7 if Target`i'!=Target`supplier'
				}
			if `i'==8 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8 if Target`i'!=Target`supplier'
				}
			if `i'==9 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8*expshare9 if Target`i'!=Target`supplier'
				}
			if `i'==10 {
				gen a_ln_mu_`i' = ln(mu_1`i')*expshare0*expshare1*expshare2*expshare3*expshare4*expshare5*expshare6*expshare7*expshare8*expshare9*expshare10 if Target`i'!=Target`supplier'
				}
			*MODIFIED
			replace a_ln_mu_`i'=0 if a_ln_mu_`i'<-0.01
			bys Target0: egen ln_pi_`i' = sum(a_ln_mu_`i')
			gen pi_`i' = exp(ln_pi_`i') if n == 1
			}
			
		
		*Final welfare loss
		gen denom = mu_0*pi_0*pi_1*pi_2*pi_3*pi_4*pi_5*pi_6*pi_7*pi_8
		sort denom
		replace denom=10 if denom>10 & denom!=.
		*br mu_0 denom pi_*
		
		*e(q1, u1)
		
		*Last endpoint
		gen sales = finalSale if n==1
		egen totSales = sum(sales)
		gen salesSh = sales/totSales
		gen sales_mu0 = sales/mu_0
		
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
			
		*twoway (scatter shFinal_subs shInitial_subs) ///
		*	(scatter shFinal shInitial)
		
		*twoway (scatter shFinal_subs0 shInitial_subs0) ///
		*	(scatter shFinal shInitial)
		
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
		compress
		save "$data/${doNum}_welfareIOTable_`y'.dta", replace
		}
	di "`y'"
	di ${mu0_`y'}, ${mu_`y'}, ${mu0_`y'_subs}, ${mu_`y'_subs}
	}


*graph
clear
set obs 60
gen y = 1962 + _n
gen mu0 = .
gen mu = .
gen mu0_subs = .
gen mu_subs = .
forval y = 1963/2016{
	replace mu0 = ${mu0_`y'} if y == `y'
	replace mu = ${mu_`y'} if y == `y'
	replace mu0_subs = ${mu0_`y'_subs} if y == `y'
	replace mu_subs = ${mu_`y'_subs} if y == `y'
	}

twoway (scatter mu0 y, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu y, msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.2)2) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
graph export "$outputs/007_welfare_IOTables.pdf", as(pdf) replace

twoway (scatter mu0_subs y, msymbol(O) mfcolor(white) connect(direct)) ///
	(scatter mu_subs y , msymbol(O) mfcolor(white) connect(direct)), ///
	ylabel(1(0.2)2.4) xtitle("Year") subtitle("Ratio of expenditure functions", pos(11)) ///
	yline(1) legend( ring(0) pos(11) col(1) order(1 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {&mu}{subscript:0}=0)" 2 "e(q{superscript:1},u{superscript:1})/e(q{superscript:0},u{superscript:1} | {bf:{&mu}} = 0)"))
*graph export "$outputs/007_welfare_2.pdf", as(pdf) replace
gen diff = mu_subs - mu0_subs
line diff y

stop
twoway (scatter mu0 y if y<2016, msymbol(O) mfcolor(white) connect(direct))

use "$data/${doNum}_welfareIOTable_1986.dta", clear

sort denom
sort shFinal
br sales_mu0_subs mu_0 shFinal_subs shFinal denom pi_* mu_* //if sales_mu0_subs!=.
su mu_0 denom pi_* mu_* if sales_mu0_subs!=.

use "$data/${doNum}_welfareIOTable_1998.dta", clear
br sales_mu0_subs mu_0 shFinal_subs shFinal denom pi_* mu_* //if sales_mu0_subs!=.
sort shFinal
su mu_0 denom pi_* mu_* if sales_mu0_subs!=. & pi_0<10

hist denom

