
/*******************************************************************************
	
	DESCRIPTION: Do file generating markups at the firm level
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 01/05/2020
			Last modified 02/05/2020
	
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
global data "$wd/data/005_markups"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*do-file number, used to save outputs 
global doNum "005"					

*log
cap log close
log using "$log/${doNum}_markups", text append


/*******************************************************************************
	SECTOR-SPECIFIC DEFLATORS FROM PETE
*******************************************************************************/

import delimited "$orig/Deflators Pete/deflators/def_clean.csv", clear 
drop if naics == "ND" | naics == "MN" | naics == "DM"
replace measure_title = "capIn" if measure_title== "Price of Capital Input"
replace measure_title = "combIn" if measure_title== "Price of Combined Inputs"
replace measure_title = "enIn" if measure_title== "Price of Energy Input"
replace measure_title = "inIn" if measure_title== "Price of Intermediate Input"
replace measure_title = "labIn" if measure_title== "Price of Labor Input"
replace measure_title = "matIn" if measure_title== "Price of Materials Input"
replace measure_title = "serIn" if measure_title== "Price of Purchased Business Services Input"
replace measure_title = "sectOut" if measure_title== "Price of Sectoral Output"
*replace year = substr(year, 2, .)
*destring year, replace
drop v1 naics

foreach v of varlist naics2 naics3 naics4


drop if naics2 == "NA"
keep naics2 measure_title year index
reshape wide index, i(naics2 year) j(measure_title) string


/*******************************************************************************
	Following the guidance of code made available by DLEU (2020)
	Harvard Dataverse, doi: 10.7910/DVN/5GH8XO
*******************************************************************************/

/* Use stata file downloaded Compustat using protocol:
Access compustat (WRDS KU Leuven FEB)
> Compustat - Capital IQ from Standard & Poor's
> NORTH AMERICA
> FUNDAMENTALS ANNUAL
> DATE RANGE 1955 - 2016
> GVKEY CODE - search the entire database
> CONSOLIDATED ACCOUNTS, FORMAT INDL AND FS (BELOW DROP FS IF REPORTED BOTH), DOMESTIC POPULATION SOURCE, DATA FORMAT STD, 
>> DATA SELECTED:
	SALE, COGS, XLR, XSGA, PPEGT, PPENT, INTAN, XRD, XAD, EMP, MKVALT, DVT, INDUSTRY INFO (NAICS), PRCC_F, CSHO, oibdp
	additional data for robustness: foreign incorp code, company name, 
	*/

*Create_Data.do

cd "$DLEU/"
use "datafile.dta", clear

qui {
sort gvkey fyear
rename fyear year
bysort gvkey year : gen nrobs = _N
* Keep only observation for one industry (some firms are in several industries) 
drop if (nrobs == 2 | nrobs == 3) & indfmt == "FS"
sort gvkey year
drop if gvkey==gvkey[_n-1] & year==year[_n-1]

* Drop firms without industry information
keep if naics~=""
* Take into account obs with industry code obs for which only d-1 digits in the d-category!!!
forvalues i =2/4 {
gen ind`i'd 								= substr(naics,1,`i')
destring ind`i'd, replace
egen nrind`i' = group(ind`i'd)
}

* write code to put all $ vars into comparable units!!!! 
gen newmk2 = prcc_f * csho
label var newmk2 " fiscal year market value prior 1998
replace mkvalt  = newmk2 if mkvalt==.

* use following variables:
keep gvkey year naics ind* sale cogs xsga xlr xrd xad dvt ppegt intan emp mkvalt oibdp
replace sale	= sale*1000
replace xlr		= xlr*1000
replace oibdp	=oibdp*1000
replace cogs	= cogs*1000
replace xsga 	= xsga*1000
replace mkvalt 	= mkvalt*1000
replace dvt 	= dvt*1000
replace ppegt	= ppegt*1000
*replace ppent 	= ppent*1000
replace intan	= intan*1000

/* Macro vars: - Merge in Usercost and US GDP deflator
- deflator: use US-wide for main specification, industry specific deflators dating back to 1955 scattered across industry classification changes
 comment: no impact for markup measure, up to estimation of output elasticity! Robustness deflators see appendix.
- User cost of capital computed using FRED nominal interest rate, inflation and calibrated depreciation (See text)
*/
sort year
merge m:1 year using "macro_vars.dta", gen(macro)
keep if macro==3
* Deflated values
gen sale_D		= (sale/USGDP)*100
gen cogs_D 		= (cogs/USGDP)*100
gen xsga_D 		= (xsga/USGDP)*100
gen mkvalt_D 	= (mkvalt/USGDP)*100
gen dividend_D	= (dvt/USGDP)*100
gen capital_D   = (ppegt/USGDP)*100
*gen capital2_D  = (ppent/USGDP)*100
gen intan_D		= (intan/USGDP)*100
gen xlr_D 		= (xlr/USGDP)*100
gen kexp		= (usercost*capital_D)
gen mat1 		= ((sale-xlr-oibdp)/USGDP)*100
* materials is generated from sales, wagebill and operating income bdp, as in Keller and Yeaple (Restat)

* TRIM : no negative values
drop if sale_D<0 
drop if cogs_D<0
drop if xsga<0
* trim on sales-cogs ratio as mu_0 is simply 0.85*sales/cogs
gen s_g = sale/cogs
keep if s_g>0
gen trim=0
keep if year>1949

* save files to temp directory
* main results for 1% trim (below)
* robustness for appendix: change to p(x) p(y) with x=2-5 and y=95-98
* robustness 2% and 5%
forvalues t=1/5 {
bysort year: egen s_g_p_`t'  = pctile(s_g), p(`t')
}
forvalues s=95/99 {
bysort year: egen s_g_p_`s'  = pctile(s_g), p(`s')
}
* label vars:
label var cogs "Costs directly allocated to production, such as material, labor and overhead.
label var emp "Nr people employed by the company and its consolidated subsidiaries in thousands
foreach var of varlist sale cogs xsga mkvalt intan xlr {
label var `var'_D "Deflated `x'
}
label var dividend_D "Deflated Dvt
label var capital_D "Deflated cap
label var kexp "real capital expenditure

label var ind2d "2 digit NAICS
label var ind3d "3 digit NAICS
label var ind4d "4 digit NAICS
label var usercost "usercost (i-delf+deprc)
label var kexp "capital expenses
label var mat1 "material cost imputed
label var s_g "sale-cogs ratio
sort gvkey year

preserve
keep if s_g> s_g_p_1 & s_g< s_g_p_99
replace trim = 1
drop s_g_p* macro trim indfmt
save "$data/data_main_upd_trim_1.dta", replace
restore

* switch on for higher trim
forvalues t=2/5 {
preserve
keep if s_g> s_g_p_2 & s_g< s_g_p_98
replace trim = `t'
save "$data/data_main_upd_trim_`t'.dta", replace
drop s_g_p* macro trim 
restore
}
}
*--------------------------------------------------*
* data created 


*Create_Temp.do

/* DE LOECKER - EECKHOUT - UNGER
The rise of market power and the macroeconomic implications
Quarterly Journal of Economics
* Analysis: prep file for output
*/
* Use trimmed sample p=1-5 [main results for p=1]
forvalues p=1/1{
use "$data/data_main_upd_trim_`p'.dta", clear
}


egen id	= group(gvkey)
drop if id==.

gen costshare0 = .85
label var costshare0 "calibrated 0.85 (fig 1 NBER)
gen costshare1 = cogs_D/(cogs_D+kexp)
label var costshare1 "cogs_D/(cogs_D+kexp)
gen costshare2 = cogs_D/(cogs_D+xsga_D+kexp)
label var costshare2 "cogs_D/(cogs_D+xsga_D+kexp)
gen costshare3 = xsga_D/(cogs_D+xsga_D+kexp)
label var costshare3 "sga_D/(cogs_D+xsga_D+kexp)
gen costshare4 = kexp/(cogs_D+xsga_D+kexp)
label var costshare4 " capital cost share
forvalues s=0/2 {
gen mu_`s' = costshare`s'*(sale_D/cogs_D)
label var mu_`s' "markup firm-level costshare `s'
}

* trim on costshares
forvalues s=1/2 {
bysort year: egen cs`s'_p1=pctile(costshare`s'), p(1)
bysort year: egen cs`s'_p99=pctile(costshare`s'), p(99)
drop if costshare`s'==0 | costshare`s'==.
drop if costshare`s' > cs`s'_p99 
drop if costshare`s' < cs`s'_p1
}

* sample summary statistics : Appendix B.1
*log using "output/tables/sumstat.smcl", replace
tabstat sale_D cogs capital_D xlr_D emp xsga_D  , stat(mean median N) 
* for the xlr data
tabstat sale_D cogs capital_D xlr_D emp xsga_D if xlr_D~=. , stat(mean median N) 
*log close

*** OUTPUT ELASTICITIES VIA NP ESTIMATE COST SHARE, MEDIAN(COSTSHARE)

forvalues m= 2/4 {
forvalues c = 1/2 {
bysort ind`m'd year: egen cs`c'_med_`m'dt = median(costshare`c')
gen mu`c'_med_`m' = cs`c'_med_`m'dt*(sale_D/cogs_D)
}
}

forvalues m= 2/4 {
bysort ind`m'd year: egen cs3_med_`m'dt = median(costshare3)
gen mu3_med_`m' = cs3_med_`m'dt*(sale_D/xsga_D)
}

forvalues m= 2/4 {
bysort ind`m'd year: egen cs4_med_`m'dt = median(costshare4)
gen mu4_med_`m' = cs4_med_`m'dt*(sale_D/kexp)
}

rename mu1_med_2  mu_3
label var mu_3 "markup median costshare 2d (cogs+rk)
rename mu1_med_3  mu_4
label var mu_4 "markup median costshare 3d (cogs+rk)
rename mu1_med_4  mu_5
label var mu_5 "markup median costshare 4d (cogs+rk)
rename mu2_med_2  mu_6
label var mu_6 "markup median costshare 2d (cogs+rk+sga)
rename mu2_med_3  mu_7
label var mu_7 "markup median costshare 3d (cogs+rk+sga)
rename mu2_med_4  mu_8
label var mu_8 "markup median costshare 4d (cogs+rk+sga)


* OUTPUT ELASTICITIES ESTIMATED VIA PF ESTIMATION - PULL PARAMETERS
* F(COGS, K) BY PERIOD-INDUSTRY

sort ind2d
merge ind2d using "$DLEU/theta_ALLsectors.dta", _merge(theta_CDs)
gen mu_9 = theta_c*(sale_D/cogs_D)
label var mu_9 "markup PF CD-sector (RED)
sort ind2d year
merge ind2d year using "$DLEU/theta_W_s_window.dta", _merge(theta_Wtime)
gen mu_10 = theta_WI1_ct*(sale_D/cogs_D)
label var mu_10 "markup PF CD-sector-time (RED)
gen mu_11 = theta_WI2_ct*(sale_D/cogs_D)
label var mu_11 "markup PF CD-sector-time (BLUE)

* check FOC on sga
gen mu_12 = theta_WI2_xt*(sale_D/xsga_D)
label var mu_12 "markup (sga FOC) PF CD-sector-time (BLUE)
rename mu3_med_2 mu_13
label var mu_13 "markup (sga FOC) CS 2 digit (BLUE)
gen mu_14 = costshare3*(sale_D/xsga_D)
label var mu_14 "markup (sga FOC) CS firm (BLUE)
gen mu_cap = theta_WI1_kt*(sale_D/kexp)
label var mu_cap "markup (k FOC) PF CD-sector-time (RED)

sort ind2d year
merge ind2d year using "$DLEU/theta_ms_window.dta", _merge(theta_pass)
gen mu_15 =  	theta_CM1_ct*(sale_D/cogs_D)
gen mu_16 =		theta_CM2_ct*(sale_D/cogs_D)
label var mu_15 "markup S,T window (passthr-RED)
label var mu_16 "markup S,T window (passthr-BLUE)

gen totcost1 = cogs_D + kexp
gen totcost2 = cogs_D + xsga_D + kexp

bysort year:  	egen TOTSALES 	= sum(sale_D)
bysort year:	egen TOTCOST1	= sum(totcost1)
bysort year:	egen TOTCOST2	= sum(totcost2)
bysort year:	egen TOTEMP		= sum(emp)

bysort year:	egen TOTCOGS	= sum(cogs_D)
bysort year:	egen TOTSGA		= sum(xsga_D)
bysort year:	egen TOTK		= sum(capital_D)
bysort year:	egen TOTrK		= sum(kexp)

gen cs_red_tot = TOTCOGS/TOTCOST1
gen cs_blue_tot	= TOTCOGS/TOTCOST2
gen cs_red_k_tot = TOTK/TOTCOST1
gen cs_red_rk_tot = TOTrK/TOTCOST1
gen cs_blue_k_tot = TOTK/TOTCOST2
gen cs_blue_rk_tot = TOTrK/TOTCOST2
gen cs_blue_x_tot = TOTSGA/TOTCOST2
gen m_totcost = totcost2/TOTCOST2 

*--------------------------------------------------------------------------------------------------------------------*
* RTS using cost share a la Syverson
bysort ind2d year: egen cogstot = sum(cogs_D)
bysort ind2d year: egen xtot = sum(xsga_D)
bysort ind2d year: egen ktot = sum(kexp)
bysort ind2d year: egen totcost = sum(xsga_D+cogs_D+kexp)
bysort ind2d year: egen totsales = sum(sale_D)
gen CS_TOT_C = cogstot/totcost
gen CS_TOT_X = xtot/totcost
gen CS_TOT_K = 1-CS_TOT_C -CS_TOT_X
gen INPUT1 = (cogs_D^costshare2)*(xsga_D^costshare3)*(capital_D^(1-costshare2-costshare3))
gen input1 = ln(INPUT1)
gen INPUT2 = (cogs_D^CS_TOT_C)*(xsga_D^CS_TOT_X)*(capital_D^(1-CS_TOT_C-CS_TOT_X))
gen input2 = ln(INPUT2)
gen gamma_RTS1 = .
gen gamma_RTS2 = .
gen y = ln(sale_D)
forvalues s= 1/2 {
forvalues t = 1955 /2016 {
reg y input`s' [aw=totsales] if `t'==year 
replace gamma_RTS`s' = _b[input`s'] if `t'==year 
}
}
preserve
keep year gamma_RTS* 
sort year
drop if year==year[_n-1]
save "$data/gamma_syverson.dta", replace
restore
*--------------------------------------------------------------------------------------------------------------------*
gen share_firm_agg 				= sale_D/TOTSALES
gen pr  = (sale_D - cogs_D - xsga_D - kexp)/sale_D
gen pr_alt  = (sale_D - cogs_D - xsga_D - .1*capital_D)/sale_D
bysort year: egen F = sum(xsga_D+kexp)
*1  WEIGHTED
	* 2.1.1 costshares
forvalues c=1/3 {
gen costshare`c'_w 					= costshare`c'*share_firm_agg
bysort year: egen COSTSHARE`c'_AGG 	= sum(costshare`c'_w)
}
	*2.1.2 theta's
bysort year: 	egen thetaW1_c = sum(share_firm_agg*theta_WI1_ct)  
bysort year:	egen thetaW1_k = sum(share_firm_agg*theta_WI1_kt) 

bysort year: 	egen thetaW2_c = sum(share_firm_agg*theta_WI2_ct)  
bysort year:	egen thetaW2_x = sum(share_firm_agg*theta_WI2_xt)
bysort year:	egen thetaW2_k = sum(share_firm_agg*theta_WI2_kt) 

bysort year:	egen theta_cs_c = sum(share_firm_agg*cs1_med_2dt)
bysort year:	egen theta_cs_x = sum(share_firm_agg*cs3_med_2dt)

gen rts_w1 = thetaW1_c + thetaW1_k
gen rts_w2 = thetaW2_c + thetaW2_k + thetaW2_x

gen RTS_W1 = thetaW1_c +thetaW1_k	
gen RTS_W2 = thetaW2_c+ thetaW2_x +thetaW2_k	

gen mkval_ms_agg 				= share_firm_agg*mkvalt_D
bysort year: egen MKVAL			= sum(mkvalt_D)

gen MKVAL_AGG 	= MKVAL/TOTSALES
*replace MKVAL_AGG= . if MKVAL_AGG==0
label var MKVAL_AGG " Market Value/Sales 

gen div_ms_agg 					= share_firm_agg*dividend_D
bysort year: egen DIV_AGG 		= sum(dividend_D)
replace DIV_AGG					= DIV_AGG/TOTSALES
label var DIV_AGG "Dividend/Sales

* generate associated theta's
forvalues s=0/2 {
gen theta_`s' = costshare`s'	
}
gen theta_3 = cs1_med_2dt
gen theta_4 = cs1_med_3dt
gen theta_5 = cs1_med_4dt
gen theta_6 = cs2_med_2dt
gen theta_7 = cs2_med_3dt
gen theta_8 = cs2_med_4dt	
gen theta_9 = theta_c
gen theta_10 = theta_WI1_ct
gen theta_11 = theta_WI2_ct
gen theta_12 = theta_WI2_xt
gen theta_13 = cs3_med_2dt
gen theta_14 = costshare3
*--------------------------------------------------------------------------------*
* 2.2 MARKUPS	
	
	* 2.2.A SALES WEIGHTS
forvalues i=0/16{
bysort year: egen MARKUP`i'_AGG 	= sum(share_firm_agg*mu_`i')
label var MARKUP`i'_AGG "Markup `i'[w=s]
}
	*2.2.A. harmonic sales
forvalues i=0/16 {
bysort year: egen MARKUPh`i'_AGG 	= sum(share_firm_agg/mu_`i')
replace MARKUPh`i'_AGG = 1/MARKUPh`i'_AGG
label var MARKUPh`i'_AGG "Markup `i'[w=h(s)]
}

	* 2.2.B INPUT WEIGHTS
gen input_w1 = totcost1/TOTCOST1
gen input_w2 = totcost2/TOTCOST2
gen input_w3 = emp/TOTEMP
gen input_w4 = cogs_D/TOTCOGS
gen input_w5 = capital_D/TOTK
gen input_w6 = xsga_D/TOTSGA
	
	forvalues i=0/16 {
	forvalues n=1/6{
bysort year: egen MARKUP`i'_AGG_w`n' 	= sum(input_w`n'*mu_`i')
label var MARKUP`i'_AGG_w`n' "Markup `i'[w=c`n']
}
}

* profit rates
gen pi1	= (sale_D - cogs_D - kexp)
gen pi2 = (sale_D - cogs_D - xsga_D - kexp)
gen pi3 = (sale_D - cogs_D - xsga_D - .1*capital_D)
gen pi4	= (sale_D - cogs_D - .1*capital_D)

gen pi_rate1 = pi1/sale_D
gen pi_rate2 = pi2/sale_D
gen pi_rate3 = pi3/sale_D
gen pi_rate4 = pi4/sale_D

gen pi_k = pi2/capital_D

bysort year: egen PI = sum(pi2)
bysort year: egen tK = sum(capital_D)
gen PI_k = PI/tK
bysort year: egen PI_ks = sum(pi_k*share_firm_agg)

forvalues i=1/4 {
bysort year: egen TOTPI`i' =sum(pi`i')
gen profitrate`i' = TOTPI`i'/TOTSALES
}
label var profitrate1 "sales-weighted agg Profit Rate (cogs+rK)
label var profitrate2 "sales-weighted agg Profit Rate (cogs+sga+rK)
label var profitrate3 "sales-weighted agg Profit Rate (cogs+sga+.1*K)
label var profitrate4 "sales-weighted agg Profit Rate (cogs+.1*K)


*1. OUTPUT ELASTICITIES BASED ON COST SHARES
*	COST SHARES: COST1: (COGS,K) vs COST2: (COGS,K, SGA): median and share-weighted

forvalues i=1/2{
bysort year: egen cs`i'_med = median(costshare`i')
}

*2 AGG MARKUPS

label var MARKUP0_AGG "MARKUP AGG CALIBRATED (.85, NBER)
label var MARKUP1_AGG "MARKUP AGG CS FIRMS (RED)
label var MARKUP2_AGG "MARKUP AGG CS FIRMS (BLUE)
label var MARKUP3_AGG "MARKUP AGG CS MED2d (RED)
label var MARKUP4_AGG "MARKUP AGG CS MED3d (RED)
label var MARKUP5_AGG "MARKUP AGG CS MED4d (RED)
label var MARKUP6_AGG "MARKUP AGG CS MED2d (BLUE)
label var MARKUP7_AGG "MARKUP AGG CS MED3d (BLUE)
label var MARKUP8_AGG "MARKUP AGG CS MED4d (BLUE)
label var MARKUP9_AGG "MARKUP AGG PF-SECTOR (RED)
label var MARKUP10_AGG "MARKUP AGG PF-SECTOR-TIME (RED)
label var MARKUP11_AGG "MARKUP AGG PF-SECTOR-TIME (BLUE)
label var MARKUP12_AGG "MARKUP AGG PF-SGA-SECTOR-TIME (BLUE)
label var MARKUP13_AGG "MARKUP AGG CS-SGA-MED2D (BLUE)
label var MARKUP14_AGG "MARKUP AGG CS FIRMS-SGA (BLUE)
label var MARKUP15_AGG "MARKUP AGG PF-SECTOR-TIME-PS (RED)
label var MARKUP16_AGG "MARKUP AGG PF-SECTOR-TIME-PS (BLUE)


gen mu_spec1	= mu_10
label var mu_spec1 "markup red tech 
gen mu_spec2 	= mu_11
label var mu_spec2 "markup blue tech
gen MARKUP_spec1 = MARKUP10_AGG
label var MARKUP_spec1 "AGG MARKUP (Trad. PF)
gen MARKUP_spec2 = MARKUP11_AGG
label var MARKUP_spec2 "AGG MARKUP (Mod. PF)
gen MARKUP_spec1_w = MARKUP10_AGG_w1
label var MARKUP_spec1_w "AGG MARKUP (Trad. PF w=input)
gen MARKUP_spec2_w = MARKUP11_AGG_w2
label var MARKUP_spec2_w "AGG MARKUP (Mod. PF w=input)
bysort year: egen MARKUP_cal_s 	= sum(.85*share_firm_agg*sale_D/cogs_D)
bysort year: egen MARKUP_cal_tc = sum(.85*m_totcost*sale_D/cogs_D)
gen MARKUP_spec1_wtc = MARKUP10_AGG_w6
label var MARKUP_spec1_wtc "AGG MARKUP (Mod. PF w=totcost)


* model-based aggregate profits

gen pi_1_spec1 				= 1 - (theta_WI1_ct/mu_spec1) - (xsga_D/sale_D) - (kexp/sale_D)
gen prms1 					= pi_1_spec1*share_firm_agg
bysort year: egen PR_1_AGG 	= sum(prms1)

gen pi_2_spec2 				= 1 - (theta_WI2_ct/mu_spec2) - (xsga_D/sale_D)- (kexp/sale_D)
gen prms2 					= pi_2_spec2*share_firm_agg
bysort year: egen PR_2_AGG 	= sum(prms2)

gen pi_1_spec1_noK			= 1 - (theta_WI1_ct/mu_spec1) - (xsga_D/sale_D)
gen prms1_noK				= pi_1_spec1_noK*share_firm_agg
bysort year: egen PR_1noK_AGG = sum(prms1_noK)

* sales weighted markup percentiles

forvalues r=1/2 {
bysort year (mu_spec`r'): gen ms_cum_mu_`r' 		= sum(share_firm_agg) 
bysort year (mu_spec`r'): gen ms90_`r' = 1 if ms_cum_mu_`r'<.9
bysort year (mu_spec`r'): gen ms75_`r' = 1 if ms_cum_mu_`r'<.75
bysort year (mu_spec`r'): gen ms50_`r' = 1 if ms_cum_mu_`r'<.5
bysort year (mu_spec`r'): gen ms25_`r' = 1 if ms_cum_mu_`r'<.25
bysort year (mu_spec`r'): gen ms10_`r' = 1 if ms_cum_mu_`r'<.1

bysort year (mu_spec`r'): egen mu_`r'_ms90 =	max(mu_spec`r') if ms90_`r'==1
bysort year (mu_spec`r'): egen mu_`r'_ms75 =	max(mu_spec`r') if ms75_`r'==1
bysort year (mu_spec`r'): egen mu_`r'_ms50 =	max(mu_spec`r') if ms50_`r'==1
bysort year (mu_spec`r'): egen mu_`r'_ms25 =	max(mu_spec`r') if ms25_`r'==1
bysort year (mu_spec`r'): egen mu_`r'_ms10 =	max(mu_spec`r') if ms10_`r'==1

label var mu_`r'_ms90 "p90 (ms)
label var mu_`r'_ms75 "p75 (ms)
label var mu_`r'_ms50 "p50 (ms)
label var mu_`r'_ms25 "p25 (ms)
}

* time series properties 
gen rho_t_spec1 =. 
gen rho_t_spec2 =. 

forvalues r=1/2 {
gen lmu`r' = ln(mu_spec`r')
xtset id year, yearly
forvalues t=1960/2016 {
xtset id year, yearly
reg lmu`r' L.lmu`r' i.ind2 if year==`t'
replace rho_t_spec`r' = _b[L.lmu`r'] if year==`t' 
predict res`t'_`r' if year==`t', res
bysort year: egen mu_`t'_`r'_sd = sd(res`t'_`r') if year==`t'
label var mu_`t'_`r'_sd "Std(Markup spec `r')
}
}
gen mu_t_1_sd = .
forvalues t=1960/2016 {
replace mu_t_1_sd = mu_`t'_1_sd if year==`t'
}
rename mu_t_1_sd sd_mu_t

gen ls= ln(sale_D)
gen l = ln(emp)
forvalues t=1960/2016 {
xtset id year, yearly
reg ls L.ls   i.ind2 if year==`t'
predict res`t'_s if year==`t', res
reg l L.l   i.ind2 if year==`t'
predict res`t'_l if year==`t', res
bysort year: egen s`t'_sd = sd(res`t'_s)
bysort year: egen l`t'_sd = sd(res`t'_l)
}

gen sd_l_t = .
gen sd_s_t = .
forvalues t=1960/2016 {
replace sd_l = l`t'_sd if year==`t'
replace sd_s = s`t'_sd if year==`t'
}

forvalues d=2/4 {
bysort ind`d'd year: egen TOTSALES_IND_`d' = sum(sale_D)
gen share_IND`d' = TOTSALES_IND_`d'/TOTSALES
gen share_ind_`d'  = sale_D/TOTSALES_IND_`d'
forvalues r= 1/2 {
bysort ind`d'd year	: egen MARKUP_sp`r'_IND_`d' = sum(share_ind_`d'*mu_spec`r')
bysort ind`d'd year : egen ThetaW`r'_c_IND`d' 	= sum(share_ind_`d'*theta_WI`r'_ct)  
preserve
keep ind`d'd year MARKUP_sp`r'_IND_`d' share_IND`d' MARKUP_spec`r' ThetaW`r'_c_IND`d'
sort ind`d'd year
drop if year==year[_n-1] & ind`d'd==ind`d'd[_n-1]
xtset ind`d'd year, yearly 
gen delta_mu_`r'_IND`d'_st		= 	MARKUP_sp`r'_IND_`d' - L10.MARKUP_sp`r'_IND_`d'
gen within_`r'_IND`d'_st		=	L10.share_IND`d' *delta_mu_`r'_IND`d'_st
gen delta_sh_`r'_IND`d'_st		=	share_IND`d' -L10.share_IND`d' 
gen between_`r'_IND`d'_st		=	L10.MARKUP_sp`r'_IND_`d'*delta_sh_`r'_IND`d'_st	
gen realloc_`r'_IND`d'_st		=	(delta_mu_`r'_IND`d'_st)*(delta_sh_`r'_IND`d'_st)
gen DMARKUP_spec`r' 			= 	MARKUP_spec`r' - L10.MARKUP_spec`r'
gen DTheta_spec`r'_IND`d' 		=	ThetaW`r'_c_IND`d' - L10.ThetaW`r'_c_IND`d' 
bysort year: egen WITHIN`r'_IND`d'_st	= sum(within_`r'_IND`d'_st)
bysort year: egen BETWEEN`r'_IND`d'_st	= sum(between_`r'_IND`d'_st)
bysort year: egen REALLOC`r'_IND`d'_st	= sum(realloc_`r'_IND`d'_st)
bysort year: egen DTHETA_`r'_IND_`d'	= sum(DTheta_spec`r'_IND`d')
keep if year==1966 | year==1976 | year==1986 | year==1996 | year==2006 | year==2016
save "$data/Table1_data_spec`r'_digit_`d'.dta", replace
restore
}
}
label var year " 
label var MARKUP_spec1 "Agg Markup (Benchmark) 
label var MARKUP0_AGG "Agg Markup (Constant Elasticity .85)
label var MARKUP1_AGG_w2 "Agg Markup (Input Weight Total Cost)
label var MARKUP10_AGG_w2 "Agg Markup (Input Weight Total Cost)
label var MARKUP1_AGG_w4 "Agg Markup (Input Weight COGS)
label var MARKUP_spec2 "Agg Markup PF2
label var MARKUP11_AGG_w4 "Agg Markup PF2 (Input Weight COGS)
label var MARKUP10_AGG_w3 "Agg Markup (Input Weight Employment)
label var MARKUP11_AGG_w3 "Agg Markup PF2 (Input Weight Employment)
save "$data/temp_file.dta", replace

* temp file created

*Create_Output.do
use "$data/temp_file.dta", clear

preserve
sort year
drop if year==year[_n-1]
sort year
scatter MARKUP_spec1 year, c(l) lcolor(red ) lpattern(solid) symbol(none) lwidth(thick) ytitle("") xlabel(1960 1970 1980 1990 2000 2010) xtitle("") legend(ring(0)  pos(5) ) 
graph export Fig1.eps, replace
scatter MARKUP_spec1 year, c(l) lcolor(black ) lpattern(solid) symbol(none) lwidth(thick) ytitle("") xlabel(1960 1970 1980 1990 2000 2010) xtitle("") legend(ring(0)  pos(5) ) 
graph export BW/Fig1.eps, replace
