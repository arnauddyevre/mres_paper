
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
global outputs "$wd/outputs/008_robustnessIOTables"
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
		*compress
		*save "$data/${doNum}_orig`y'_use", replace
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
			
		drop if Code == "GFG" | Code == "GFE" | Code == "GSLG" | Code == "GSLE" | Code == "Used" | Code == "Other" | ///
			Code == "T005" | Code == "T008" 
		local extraObs = _N+3
		set obs `extraObs'
	
		local extraObs = _N
		local extraObs_4 = `extraObs'-4
		local extraObs_3 = `extraObs'-3
		local extraObs_2 = `extraObs'-2
		local extraObs_1 = `extraObs'-1
		
		replace Comm = "Count" in `extraObs_2'
		replace Comm = "Weight" in `extraObs_1'
		replace Comm = "Sum" in `extraObs'

		foreach v of varlist code_111CA-code_81{
			count if `v'!=. & `v'!=0 & Code!="T006"
			replace `v' = `r(N)' in `extraObs_2'
			replace `v' = `r(N)'* `v'[`extraObs_3'] in `extraObs'
			}
		egen rowsum = rowtotal(code_111CA-code_81)
		egen rowmean = rowmean(code_111CA-code_81)
		}
	global av`y' = rowsum[`extraObs']/rowsum[`extraObs_3']
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


/*Using the historical make tables
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
			
		drop if Code == "GFG" | Code == "GFE" | Code == "GSLG" | Code == "GSLE" | Code == "Used" | Code == "Other" | ///
			Code == "T005" | Code == "T008"
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
*/
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
		
		drop if code == "GFG" | code == "GFE" | code == "GSLG" | code == "GSLE" | /*code == "Used" | code == "Other" |*/ /// 
			code == "GFGD" | code == "GFGN" | code == "V001" | code == "V002" | code == "V003" | ///
			code == "" & codeCommodities!="Total Value Added"
		
		local extraObs = _N+3
		set obs `extraObs'
	
		local extraObs = _N
		local extraObs_4 = `extraObs'-4
		local extraObs_3 = `extraObs'-3
		local extraObs_2 = `extraObs'-2
		local extraObs_1 = `extraObs'-1
		
		replace codeComm = "Count" in `extraObs_2'
		replace codeComm = "Weight" in `extraObs_1'
		replace codeComm = "Sum" in `extraObs'

		foreach v of varlist code_111CA-code_81{
			count if `v'!=. & `v'!=0 & codeComm!="Total Value Added"
			replace `v' = `r(N)' in `extraObs_2'
			replace `v' = `r(N)'* `v'[`extraObs_3'] in `extraObs'
			}
		egen rowsum = rowtotal(code_111CA-code_81)
		egen rowmean = rowmean(code_111CA-code_81)
		}
	global av`y' = rowsum[`extraObs']/rowsum[`extraObs_3']
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
twoway (scatter degree y if y<=1996, connect(direct)) ///
	(scatter degree y if y>1996, connect(direct))

*2007 and 2012 405 commodities input-output tables
forval y=2007(5)2012{
	qui{
		import excel "https://apps.bea.gov/industry/xls/io-annual/IOUse_Before_Redefinitions_PRO_DET.xlsx", sheet("`y'") cellrange(A6) firstrow clear
		drop S00500-PQ
				foreach v of var * {
					local lbl : var label `v'
					local lbl = strtoname("`lbl'")
					rename `v' code`lbl'
					}
				drop if codeCommodity == ""
				
				drop if codeCode > "A" & codeCode!= "T006"
				drop if codeCode == ""
				
		
				local extraObs = _N+3
				set obs `extraObs'
			
				local extraObs = _N
				local extraObs_4 = `extraObs'-4
				local extraObs_2 = `extraObs'-2
				local extraObs_1 = `extraObs'-1
				
				replace codeComm = "Count" in `extraObs_2'
				replace codeComm = "Weight" in `extraObs_1'
				replace codeComm = "Sum" in `extraObs'
		
				foreach v of varlist code_1111A0-code_814000{
					count if `v'!=. & `v'!=0 & codeCode!="T006"
					replace `v' = `r(N)' in `extraObs_2'
					replace `v' = `r(N)'* `v'[`extraObs_4'] in `extraObs'
					}
				egen rowsum = rowtotal(code_1111A0-code_814000)
				egen rowmean = rowmean(code_1111A0-code_814000)
			}
		global av`y' = rowsum[`extraObs']/rowsum[`extraObs_4']
		global av`y'_unweighted = rowmean[`extraObs_2']
		di ${av`y'}, ${av`y'_unweighted}
		}
clear
set obs 20
gen degree = .
gen degree_unweighted = .
gen y = .
forval y = 2007/2012{
	local pos = `y' - 2006
	replace degree = ${av`y'} in `pos'
	replace degree_unweighted = ${av`y'_unweighted} in `pos'
	replace y = `y' in `pos'
	}
drop if y!=2007 & y!=2012
gen full = 1
save "$data/${doNum}_use_0712", replace

use "$data/${doNum}_use_0712", clear

append using "$data/${doNum}_use_6396"
append using "$data/${doNum}_use_9718"
twoway (scatter degree y if y<=1996 & full!=1, connect(direct) msymbol(O) mfcolor(white)) ///
	(scatter degree y if y>1996 & full!=1, connect(direct) msymbol(O) mfcolor(white)), ///
	legend( ring(0) pos(5) col(1) order(1 "Historical I-O data (SIC)" 2 "Current I-O data (NAICS)")) ///
	xlabel(1960(5)2020) xtitle("") ytitle("") subtitle("Average number of suppliers per sector", pos(11))
graph export "$outputs/${doNum}_suppliersOverTime.pdf", as(pdf) replace
	
	
