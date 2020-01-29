
/*******************************************************************************
	
	DESCRIPTION: Do file merging the cleaned company names from Compustat and 
				the cleaned company names from Segment customer data
	
	INFILES:	- 001_supplierList.dta
				- 001_customerList.dta 
	
	OUTFILES:	- merge company name list
	
	LOG: Created 28/01/2020
	
*******************************************************************************/

/*******************************************************************************
	SETUP
*******************************************************************************/

clear all
set more off
macro drop _all
set scheme s1color
set matsize 10000

*Paths
global wd "C:/Users/dyevre/Documents/mres_paper"
global orig "$wd/orig"
global data "$wd/data/001_network"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"

*do-file number, used to save outputs 
global doNum "002"					

*log
cap log close
log using "$log/${doNum}_mergeCustomerSupplier", text append

/*******************************************************************************
	EXACT MERGE
*******************************************************************************/

*Keeping only supplier firms who have financial data
*use "$data/001_network/001_supplierList.dta", clear
*merge 1:1 gvkey comp using "$data/001_network/001_companyList_6119.dta"
*KEEPING ALL firms for now

*Customer to company exact merge
use "$data/001_customerList.dta", clear
merge 1:1 comp using "$data/001_companyList_6119.dta"					// 1 to many merge as several companies in Compustat have the same name but different Gvkeys 
count if _merge == 3
local merged = `r(N)'
count if _merge == 1
local master = `r(N)'
di `merged'/(`master'+`merged')													//6.00% merge

*Supplier to company exact merge
use "$data/001_supplierList.dta", clear
merge 1:1 /*gvkey*/ comp using "$data/001_companyList_6119.dta"
count if _merge == 3
local merged = `r(N)'
count if _merge == 1
local master = `r(N)'
di `merged'/(`master'+`merged')													//98.18% merge

/*******************************************************************************
	AHRS CLEANING ALGORITHM: SETUP AND PROGRAMS
*******************************************************************************/

*Using the cleaning algorithm from AHRS
use "$data/001_customerList.dta", clear
merge 1:1 comp using "$data/001_companyList_6119.dta"
gen origName = comp		
save "$data/tempmerge.dta", replace

*AHRS manual cleaning (re-used with permission given by Enghin Atalay, 03/12/2019)
/*Matched results will go in a file*/
keep if _merge==3
drop _merge
count
global merge_count = `r(N)'
save "$data/matched.dta", replace

use "$data/tempmerge", clear
keep if _merge==1 																//customer name only, no match in Compustat company list
keep comp origName
count
global resid1_count = `r(N)'
save "$data/resid1", replace

use "$data/tempmerge", clear
keep if _merge==2 																//official company names in Compustat only, these companies have not found a match in the segmnent data as reported
keep comp origName
count
global resid2_count = `r(N)'
save "$data/resid2", replace

di $merge_count/($resid1_count+$merge_count)

*Program automating the merge of the residual datasets after each cleaning step
*From http://www.stata.com/statalist/archive/2004-02/msg00246.html*/
cap program drop merge3
program merge3 
	qui{
		confirm file "$data/matched.dta"
		confirm file "$data/resid1.dta" 
		confirm file "$data/resid2.dta" 

		use "$data/resid1", clear 
		merge 1:1 comp using "$data/resid2"
		if _N==0{
			exit
			}
		save "$data/result.dta", replace

		keep if _merge==3
		drop _merge
		append using "$data/matched.dta"
		save "$data/matched.dta", replace

		use "$data/result.dta", clear 
		keep if _merge==1
		keep comp origName
		sort comp origName
		merge 1:1 comp using "$data/resid1"
		keep if _merge==3
		drop _merge
		sort comp
		save "$data/resid1", replace emptyok

		use "$data/result.dta", clear 
		keep if _merge==2
		keep comp origName
		sort comp origName
		merge 1:1 comp using "$data/resid2.dta" 
		keep if _merge==3
		drop _merge
		sort comp
		save "$data/resid2.dta" , replace emptyok

		erase "$data/result.dta"
		}
	end

*Calculating improvement in matching rate
cap program drop mergeRate
program mergeRate 
	qui{
		use "$data/matched", clear
		count
		global merge_count = `r(N)'
		use "$data/resid1", clear
		count
		global resid1_count = `r(N)'
		use "$data/resid2", clear
		count
		global resid2_count = `r(N)'
		}
	di $merge_count/($resid1_count+$merge_count)	
	end

/*******************************************************************************
	AHRS CLEANING ALGORITHM: IMPLEMENTATION IN SEVERAL ROUNDS OF MANUAL CLEANING
*******************************************************************************/

*1st round
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"CORP","",.)
replace comp=subinstr(comp,"COMPANIES","",.)
replace comp=subinstr(comp,"COMPANY","",.)
replace comp=subinstr(comp,"CONSOLIDATED","",.)
replace comp=subinword(comp,"CO","",.)
replace comp=subinstr(comp,"INC","",.)
replace comp=subinstr(comp,"LABORATORIES","LAB",.)
replace comp=subinstr(comp,"/"," ",.)
replace comp=subinstr(comp,"-"," ",.)
replace comp=subinstr(comp,"LP","",.)
replace comp=subinstr(comp,"LTD","",.)
replace comp=subinword(comp,"STORES","",.)
replace comp=subinword(comp,"MOTOR","MTR",.)
replace comp=subinstr(comp,"GENERAL","GENL",.)
replace comp=subinstr(comp,"GENL","GEN",.)
replace comp=subinword(comp,"MOBIL","",.)
replace comp=subinword(comp,"MICRO","MICR",.)
replace comp=subinword(comp,"UNITED","UTD",.)
replace comp=subinword(comp,"TECHNOLOGIES","TECHS",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"CORP","",.)
replace comp=subinstr(comp,"COMPANIES","",.)
replace comp=subinstr(comp,"COMPANY","",.)
replace comp=subinstr(comp,"CONSOLIDATED","",.)
replace comp=subinword(comp,"CO","",.)
replace comp=subinstr(comp,"INC","",.)
replace comp=subinstr(comp,"LABORATORIES","LAB",.)
replace comp=subinstr(comp,"/"," ",.)
replace comp=subinstr(comp,"-"," ",.)
replace comp=subinstr(comp,"LP","",.)
replace comp=subinstr(comp,"LTD","",.)
replace comp=subinword(comp,"STORES","",.)
replace comp=subinword(comp,"MOTOR","MTR",.)
replace comp=subinstr(comp,"GENERAL","GENL",.)
replace comp=subinstr(comp,"GENL","GEN",.)
replace comp=subinword(comp,"MOBIL","",.)
replace comp=subinword(comp,"MICRO","MICR",.)
replace comp=subinword(comp,"UNITED","UTD",.)
replace comp=subinword(comp,"TECHNOLOGIES","TECHS",.)
replace comp=trim(comp)
sort comp
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.09146594

*2nd
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"A T & T","AT&T",.)
replace comp=subinstr(comp,"GROUP","",.)
replace comp=subinstr(comp,"HEALTHCARE","HTHCR",.)
replace comp=subinstr(comp,"SPON ADR","",.)
replace comp=subinstr(comp,"ABF FREIGHT SYSTEM","ABF FREIGHT",.)
replace comp=subinstr(comp,"ABF FREIGHT","ABF",.)
replace comp=subinstr(comp,"PLC","",.)
replace comp=subinstr(comp,"HOLDINGS","",.)
replace comp=subinstr(comp,"ADR","",.)
replace comp=subinstr(comp,"INDUSTRIES","IND",.)
replace comp=subinstr(comp,"UNITED","UTD",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"A T & T","AT&T",.)
replace comp=subinstr(comp,"SPON ADR","",.)
replace comp=subinstr(comp,"PLC","",.)
replace comp=subinstr(comp,"GROUP","",.)
replace comp=subinstr(comp,"HEALTHCARE","HTHCR",.)
replace comp=subinstr(comp,"ABF FREIGHT SYSTEM","ABF FREIGHT",.)
replace comp=subinstr(comp,"ABF FREIGHT","ABF",.)
replace comp=subinstr(comp,"HOLDINGS","",.)
replace comp=subinstr(comp,"ADR","",.)
replace comp=subinstr(comp,"INDUSTRIES","IND",.)
replace comp=subinstr(comp,"UNITED","UTD",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.09685959

*3rd
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"TELECOMMUNICATIONS","TELEM",.)
replace comp=subinstr(comp,"CL A","",.)
replace comp=subinstr(comp,"MMUNICATIONS","MMUN",.)
replace comp=subinstr(comp,"ADVANCED MICRO DEVICES","AMD",.)
replace comp=subinstr(comp,"ADV MICRO DV","AMD",.)
replace comp=subinstr(comp,"CP","",.)
replace comp=subinstr(comp,"CMPTRS","MPUTERS",.)
replace comp=subinstr(comp,"AHA BETA","AHA BETA TECHNOLOGY",.)
replace comp=subinstr(comp,"PRDS&CH","PRODUCTS & CHEMICALS",.)
replace comp=subinstr(comp,"AIRTOUCH CM","AIRTOUCH COMMUNICATIONS",.)
replace comp=subinstr(comp,"INTERNATIONAL","INTL",.)
replace comp=subinstr(comp,"POWER","PWR",.)
replace comp=subinstr(comp,"'","",.)
replace comp=subinstr(comp," & ","",.)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"TELEMMUNICATIONS","TELEM",.)
replace comp=subinstr(comp,"MMUNICATIONS","MMUN",.)
replace comp=subinstr(comp,"ADVANCED MICRO DEVICES","AMD",.)
replace comp=subinstr(comp,"ADV MICRO DV","AMD",.)
replace comp=subinstr(comp,"CL A","",.)
replace comp=subinstr(comp,"CP","",.)
replace comp=subinstr(comp,"CMPTRS","MPUTERS",.)
replace comp=subinstr(comp,"AHA BETA","AHA BETA TECHNOLOGY",.)
replace comp=subinstr(comp,"PRDS&CH","PRODUCTS & CHEMICALS",.)
replace comp=subinstr(comp,"AIRTOUCH CM","AIRTOUCH COMMUNICATIONS",.)
replace comp=subinstr(comp,"INTERNATIONAL","INTL",.)
replace comp=subinstr(comp,"POWER","PWR",.)
replace comp=subinstr(comp,"'","",.)
replace comp=subinstr(comp," & ","",.)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.09804468

*4th
use "$data/resid1.dta", clear
replace comp=subinword(comp,"SA","",.)
replace comp=subinstr(comp,"PRODUCTS","PROD",.)
replace comp=subinstr(comp,"ELECTRONICS","ELECT",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinword(comp,"PRODUCTS","PROD",.)
replace comp=subinstr(comp,"ELECTRONICS","ELECT",.)
replace comp=subinword(comp,"SA","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10131343

*5th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"AMERICA","AMER",.)
replace comp=subinstr(comp,".","",.)
replace comp=subinstr(comp,"HYDRO ELECTRIC","HYD",.)
replace comp=subinstr(comp,"OLD","",.)
replace comp=subinstr(comp,"TRUST","TR",.)
replace comp=subinstr(comp,"BARCLAYS BANK","BARCLAYS",.)
replace comp=subinstr(comp," & ","&",.)
replace comp=subinstr(comp,"NOBLE","NOBL",.)
replace comp=subinstr(comp,"BANK","BK",.)
replace comp=subinstr(comp,"NEW","",.)
replace comp=subinstr(comp,"WRIGHT","WRGHT",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"AMERICA","AMER",.)
replace comp=subinstr(comp,".","",.)
replace comp=subinstr(comp,"HYDRO ELECTRIC","HYD",.)
replace comp=subinstr(comp,"OLD","",.)
replace comp=subinstr(comp,"TRUST","TR",.)
replace comp=subinstr(comp,"BARCLAYS BANK","BARCLAYS",.)
replace comp=subinstr(comp," & ","&",.)
replace comp=subinstr(comp,"NOBLE","NOBL",.)
replace comp=subinstr(comp,"BANK","BK",.)
replace comp=subinstr(comp,"NEW","",.)
replace comp=subinstr(comp,"WRIGHT","WRGHT",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate 	//.10332145

*6th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"A G","AG",.)
replace comp=subinstr(comp,"AEROSPACE","AEROSPAC",.)
replace comp=subinstr(comp,"(","",.)
replace comp=subinstr(comp,")","",.)
replace comp=subinstr(comp,"L L","LL",.)
replace comp=subinstr(comp,"STEARNS","STRNS",.)
replace comp=subinstr(comp,"DICKINSON &","DICK",.)
replace comp=subinstr(comp,"AIRCRAFT","AIRCR",.)
replace comp=subinstr(comp,"AIRCRFT","AIRCR",.)
replace comp=subinstr(comp,"CANADA","CDA",.)
replace comp=subinstr(comp,"PROJECTED","",.)
replace comp=subinstr(comp,"TELEM","TEL",.)
replace comp=subinstr(comp,"BETHLEHEM","BETHLHM",.)
replace comp=subinstr(comp,"STEEL","STL",.)
replace comp=subinstr(comp,"ENTERPRISES","ENT",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"A G","AG",.)
replace comp=subinstr(comp,"AEROSPACE","AEROSPAC",.)
replace comp=subinstr(comp,"(","",.)
replace comp=subinstr(comp,")","",.)
replace comp=subinstr(comp,"L L","LL",.)
replace comp=subinstr(comp,"STEARNS","STRNS",.)
replace comp=subinstr(comp,"DICKINSON &","DICK",.)
replace comp=subinstr(comp,"AIRCRAFT","AIRCR",.)
replace comp=subinstr(comp,"AIRCRFT","AIRCR",.)
replace comp=subinstr(comp,"CANADA","CDA",.)
replace comp=subinstr(comp,"PROJECTED","",.)
replace comp=subinstr(comp,"TELEM","TEL",.)
replace comp=subinstr(comp,"BETHLEHEM","BETHLHM",.)
replace comp=subinstr(comp,"STEEL","STL",.)
replace comp=subinstr(comp,"ENTERPRISES","ENT",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10360133

*7th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"BIG THREE","BIG THREE IND",.)
replace comp=subinstr(comp,"LLC","",.)
replace comp=subinstr(comp,"BORG WARNER","",.)
replace comp=subinstr(comp,"SCIENTIFIC","SCI",.)
replace comp=subinstr(comp,"ADS","BP",.)
replace comp=subinstr(comp,"BRIGGS&STRATTON","BRIGG&STRN",.)
replace comp=subinstr(comp,"MYERS SQUIBB","MYRS",.)
replace comp=subinstr(comp,"CA CL","CA LA",.)
replace comp=subinstr(comp,"GOLF","GF",.)
replace comp=subinstr(comp,"SOUP","SP",.)
replace comp=subinstr(comp,"CAMPBELL","CAMPBL",.)
replace comp=subinstr(comp,"FINANCIAL","FINL",.)
replace comp=subinstr(comp,"NATURAL GAS","NAT",.)
replace comp=subinstr(comp,"CANADIAN","CDN",.)
replace comp=subinstr(comp,"AIRCFT","AIRC",.)
replace comp=subinstr(comp,"AIRCR","AIRC",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"LLC","",.)
replace comp=subinstr(comp,"BORG WARNER","",.)
replace comp=subinstr(comp,"SCIENTIFIC","SCI",.)
replace comp=subinstr(comp,"BP   ADS","BP",.)
replace comp=subinstr(comp,"BRIGGS&STRATTON","BRIGG&STRN",.)
replace comp=subinstr(comp,"MYERS SQUIBB","MYRS",.)
replace comp=subinstr(comp,"CA CL","CA LA",.)
replace comp=subinstr(comp,"GOLF","GF",.)
replace comp=subinstr(comp,"SOUP","SP",.)
replace comp=subinstr(comp,"CAMPBELL","CAMPBL",.)
replace comp=subinstr(comp,"FINANCIAL","FINL",.)
replace comp=subinstr(comp,"NATURAL GAS","NAT",.)
replace comp=subinstr(comp,"CANADIAN","CDN",.)
replace comp=subinstr(comp,"AIRCFT","AIRC",.)
replace comp=subinstr(comp,"AIRCR","AIRC",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10459838

*8th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"ROEBK","",.)
replace comp=subinstr(comp,"ROEBUCK &","",.)
replace comp=subinstr(comp,"AIR LINES","AIRL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"ROEBK","",.)
replace comp=subinstr(comp,"ROEBUCK &","",.)
replace comp=subinstr(comp,"AIR LINES","AIRL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10460428


*9th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"SYSTEMS","SYS",.)
replace comp=subinstr(comp,"DU PONT EI DE NEMOURS","DUPONT EI",.)
replace comp=subinstr(comp,"EI","",.)
replace comp=subinstr(comp,"PRO FORMA","",.)
replace comp=subinstr(comp,"CREDIT","CR",.)
replace comp=subinstr(comp,"LIGHT","LT",.)
replace comp=subinstr(comp,"CHEMICAL","CHEMICL",.)
replace comp=subinstr(comp,"&","",.)
replace comp=subinstr(comp,"DISCREET","DISCRT",.)
replace comp=subinstr(comp,"LOGIC","LGC",.)
replace comp=subinstr(comp,"TELEKOM","TELE",.)
replace comp=subinstr(comp,"TLKOM","TELE",.)
replace comp=subinstr(comp,"DEUTSCHE","DTSCH",.)

replace comp=subinstr(comp,"PWRLIGHT","PL",.)
replace comp=subinstr(comp,"SUPERMARKETS","SUPERMKTS",.)
replace comp=subinstr(comp,"CAPITAL","CAP",.)
replace comp=subinstr(comp,"GRAND ICE CREAM","",.)
replace comp=subinstr(comp,"DREAMS","DRMS",.)
replace comp=subinstr(comp,"EMPORIUM","EMPORM",.)
replace comp=subinstr(comp,"HARDWAREGARDEN","HRDWR",.)
replace comp=subinstr(comp,"KODAK","KDK",.)
replace comp=subinstr(comp,"MAN","MN",.)
replace comp=subinstr(comp,"STORES","",.)
replace comp=subinstr(comp,"BROTHERS","BROS",.)
replace comp=subinstr(comp,"AG","",.)
replace comp=subinstr(comp,"ELECTRONIC","ELEC",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"SYSTEMS","SYS",.)
replace comp=subinstr(comp,"DU PONT EI DE NEMOURS","DUPONT EI",.)
replace comp=subinstr(comp,"EI","",.)
replace comp=subinstr(comp,"PRO FORMA","",.)
replace comp=subinstr(comp,"CREDIT","CR",.)
replace comp=subinstr(comp,"LIGHT","LT",.)
replace comp=subinstr(comp,"CHEMICAL","CHEMICL",.)
replace comp=subinstr(comp,"&","",.)
replace comp=subinstr(comp,"DISCREET","DISCRT",.)
replace comp=subinstr(comp,"LOGIC","LGC",.)
replace comp=subinstr(comp,"TELEKOM","TELE",.)
replace comp=subinstr(comp,"TLKOM","TELE",.)
replace comp=subinstr(comp,"DEUTSCHE","DTSCH",.)
replace comp=subinstr(comp,"GENERAL","GENL",.)
replace comp=subinstr(comp,"GENL","GEN",.)
replace comp=subinstr(comp,"PWRLIGHT","PL",.)
replace comp=subinstr(comp,"SUPERMARKETS","SUPERMKTS",.)
replace comp=subinstr(comp,"CAPITAL","CAP",.)
replace comp=subinstr(comp,"GRAND ICE CREAM","",.)
replace comp=subinstr(comp,"DREAMS","DRMS",.)
replace comp=subinstr(comp,"EMPORIUM","EMPORM",.)
replace comp=subinstr(comp,"HARDWAREGARDEN","HRDWR",.)
replace comp=subinstr(comp,"KODAK","KDK",.)
replace comp=subinstr(comp,"MAN","MN",.)
replace comp=subinstr(comp,"STORES","",.)
replace comp=subinstr(comp,"BROTHERS","BROS",.)
replace comp=subinstr(comp,"AG","",.)
replace comp=subinstr(comp,"ELECTRONIC","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10609787

*10th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"GAS","GS",.)
replace comp=subinstr(comp,"TOWN","TWN",.)
replace comp=subinstr(comp,"L M","",.)
replace comp=subinstr(comp,"LM","",.)
replace comp=subinstr(comp,"TELEFON","TEL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"GAS","GS",.)
replace comp=subinstr(comp,"TOWN","TWN",.)
replace comp=subinstr(comp,"L M","",.)
replace comp=subinstr(comp,"LM","",.)
replace comp=subinstr(comp,"TELEFON","TEL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.1062067

*11th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"ERICSSON TEL","ERCSON TELE",.)
replace comp=subinstr(comp,"WHEELER","WHLR",.)
replace comp=subinstr(comp,"FISHER","FISHR",.)
replace comp=subinstr(comp,"SCIEN","SCI",.)
replace comp=subinstr(comp,"INTL","",.)
replace comp=subinstr(comp,"FED EXPRESS","FEDEX",.)
replace comp=subinstr(comp,"WOOD","WD",.)
replace comp=subinstr(comp,"FLA ROCK","FLORIDA ROCK",.)
replace comp=subinstr(comp,"STONE","STN",.)
replace comp=subinstr(comp,"TIRERUBBER","TIR",.)
replace comp=subinstr(comp,"TIR","",.)
replace comp=subinstr(comp,"CENTER","CNTR",.)
replace comp=subinstr(comp,"","YR",.)
replace comp=subinstr(comp,"NSOLIDATED","",.)
replace comp=subinstr(comp,"MIC","MC",.)
replace comp=subinstr(comp,"ELECTRIC","ELEC",.)
replace comp=subinstr(comp,"ELEC","EL",.)
replace comp=subinstr(comp,"NSOL","",.)
replace comp=subinstr(comp,"PACIFIC","PAC",.)
replace comp=subinstr(comp,"W R","WR",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"ERICSSON TEL","ERCSON TELE",.)
replace comp=subinstr(comp,"WHEELER","WHLR",.)
replace comp=subinstr(comp,"FISHER","FISHR",.)
replace comp=subinstr(comp,"SCIEN","SCI",.)
replace comp=subinstr(comp,"INTL","",.)
replace comp=subinstr(comp,"FED EXPRESS","FEDEX",.)
replace comp=subinstr(comp,"WOOD","WD",.)
replace comp=subinstr(comp,"FLA ROCK","FLORIDA ROCK",.)
replace comp=subinstr(comp,"STONE","STN",.)
replace comp=subinstr(comp,"TIRERUBBER","TIR",.)
replace comp=subinstr(comp,"TIR","",.)
replace comp=subinstr(comp,"CENTER","CNTR",.)
replace comp=subinstr(comp,"","YR",.)
replace comp=subinstr(comp,"NSOLIDATED","",.)
replace comp=subinstr(comp,"MIC","MC",.)
replace comp=subinstr(comp,"ELECTRIC","ELEC",.)
replace comp=subinstr(comp,"ELEC","EL",.)
replace comp=subinstr(comp,"NSOL","",.)
replace comp=subinstr(comp,"PACIFIC","PAC",.)
replace comp=subinstr(comp,"W R","WR",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10918382

*12th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"METRO","MET",.)
replace comp=subinstr(comp,"TECHNOLOGIES","TECHNOL",.)
replace comp=subinstr(comp,"DATA MM","DATAM",.)
replace comp=subinstr(comp,"DATAMM","DATAM",.)
replace comp=subinstr(comp,"INSTRUMENT","INSTR",.)
replace comp=subinstr(comp,"INSTRMN","INSTR",.)
replace comp=subinstr(comp,"MOTORS","MTR",.)
replace comp=subinstr(comp,"INSTITUTE","INST",.)
replace comp=subinword(comp,"GENUINE","GENUIN",.)
replace comp=subinword(comp,"PARTS","PART",.)
replace comp=subinword(comp,"TEL","TE",.)
replace comp=subinword(comp,"GLOBALSTAR","GLBLSTR",.)
replace comp=subinstr(comp,",","",.)
replace comp=subinword(comp,"GOODYR E","GOODYR",.)
replace comp=subinword(comp,"W","",.)
replace comp=subinword(comp,"GRAINGER","GRAINGR",.)
replace comp=subinword(comp,"CHEMCL","CH",.)
replace comp=subinword(comp,"SP","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"METRO","MET",.)
replace comp=subinstr(comp,"TECHNOLOGIES","TECHNOL",.)
replace comp=subinstr(comp,"DATA MM","DATAM",.)
replace comp=subinstr(comp,"DATAMM","DATAM",.)
replace comp=subinstr(comp,"INSTRUMENT","INSTR",.)
replace comp=subinstr(comp,"INSTRMN","INSTR",.)
replace comp=subinstr(comp,"MOTORS","MTR",.)
replace comp=subinstr(comp,"INSTITUTE","INST",.)
replace comp=subinword(comp,"GENUINE","GENUIN",.)
replace comp=subinword(comp,"PARTS","PART",.)
replace comp=subinword(comp,"TEL","TE",.)
replace comp=subinword(comp,"GLOBALSTAR","GLBLSTR",.)
replace comp=subinstr(comp,",","",.)
replace comp=subinword(comp,"GOODYR E","GOODYR",.)
replace comp=subinword(comp,"W","",.)
replace comp=subinword(comp,"GRAINGER","GRAINGR",.)
replace comp=subinword(comp,"CHEMCL","CH",.)
replace comp=subinword(comp,"SP","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10952016

*13th
use "$data/resid1.dta", clear
replace comp=subinword(comp,"PACKARD","PCK",.)
replace comp=subinword(comp,"HOTELS","HTL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinword(comp,"PACKARD","PCK",.)
replace comp=subinword(comp,"HOTELS","HTL",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10952016

*14th
use "$data/resid1.dta", clear
replace comp=subinword(comp,"TROY","TR",.)
replace comp=subinword(comp,"MEYERS","MEYR",.)
replace comp=subinword(comp,"H J","HJ",.)
replace comp=subinword(comp,"HOTL","HTL",.)
replace comp=subinword(comp,"HEALTHDYNE","HLTHDNE",.)
replace comp=subinword(comp,"TECHNOL","TEC",.)
replace comp=subinword(comp,"CELANESE","",.)
replace comp=subinword(comp,"CEL","",.)
replace comp=subinword(comp,"MIFFLIN","MF",.)
replace comp=subinword(comp,"LTPWR","LP",.)
replace comp=subinword(comp,"HOST","HST",.)
replace comp=subinword(comp,"SUPPLY","SPLY",.)
replace comp=subinword(comp,"MATERIALS HNDLG","",.)
replace comp=subinword(comp,"SOLUTIONS","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinword(comp,"TROY","TR",.)
replace comp=subinword(comp,"MEYERS","MEYR",.)
replace comp=subinword(comp,"H J","HJ",.)
replace comp=subinword(comp,"HOTL","HTL",.)
replace comp=subinword(comp,"HEALTHDYNE","HLTHDNE",.)
replace comp=subinword(comp,"TECHNOL","TEC",.)
replace comp=subinword(comp,"CELANESE","",.)
replace comp=subinword(comp,"CEL","",.)
replace comp=subinword(comp,"MIFFLIN","MF",.)
replace comp=subinword(comp,"LTPWR","LP",.)
replace comp=subinword(comp,"HOST","HST",.)
replace comp=subinword(comp,"SUPPLY","SPLY",.)
replace comp=subinword(comp,"MATERIALS HNDLG","",.)
replace comp=subinword(comp,"SOLUTIONS","",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3 
mergeRate	//.10985419

*15th
use "$data/resid1.dta", clear
replace comp=subinword(comp,"CHASE","CHSE",.)
replace comp=subinword(comp,"J P MORGAN","JPMORGAN",.)
replace comp=subinword(comp,"CIRCUIT","CRCT",.)
replace comp=subinword(comp,"NTROLS","CNTL",.)
replace comp=subinword(comp,"JOHNSONJOHNSON","JOHNSNJHNS",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinword(comp,"CHASE","CHSE",.)
replace comp=subinword(comp,"J P MORGAN","JPMORGAN",.)
replace comp=subinword(comp,"CIRCUIT","CRCT",.)
replace comp=subinword(comp,"NTROLS","CNTL",.)
replace comp=subinword(comp,"JOHNSONJOHNSON","JOHNSNJHNS",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.10986044

*16th
use "$data/resid1.dta", clear
replace comp=subinstr(comp,"AM TEL &TEL","AT&T",.)
replace comp=subinstr(comp,"-","",.)
replace comp=subinword(comp,"CL","",.)
replace comp=subinword(comp,"A","",.)
replace comp=subinword(comp,"HLDG","",.)
replace comp=subinword(comp,"WARD","WD",.)
replace comp=subinword(comp,"MONTGOMERY","MONTGMY",.)
replace comp=subinstr(comp,"PR","",.)
replace comp=subinword(comp,"CORP","",.)
replace comp=subinword(comp,"CO","",.)
replace comp=subinword(comp,"CP","",.)
replace comp=subinword(comp,"INC","",.)
replace comp=subinword(comp,"DAIMLERCHRYSLER","DAIMLER",.)
replace comp=subinword(comp,"AG","",.)
replace comp=subinword(comp,"COMPUTER","CMP",.)
replace comp=subinword(comp,"EASTMAN","EASTMN",.)
replace comp=subinword(comp,"KODAK","KODK",.)
replace comp=subinword(comp,"MACHINES","MA",.)
replace comp=subinword(comp,"BUSINESS","BUS",.)
replace comp=subinword(comp,"MACH","MA",.)
replace comp=subinword(comp,"EQUIPMENT","EQ",.)
replace comp=subinword(comp,"PROCTER","PRCTR",.)
replace comp=subinword(comp,"GAMBLE","GM",.)
replace comp=subinword(comp,"GENERAL","GEN",.)
replace comp=subinword(comp,"MOTORS","MTR",.)
replace comp=subinword(comp,"MOTOR","MTR",.)
replace comp=subinword(comp,"FUNDING","",.)
replace comp=subinword(comp,"(J C)","(JC)",.)
replace comp=subinword(comp,"DOUGLAS","DG",.)
replace comp=subinword(comp,"MCDONNELL","MCDONNEL",.)
replace comp=subinword(comp,"STORES","",.)
replace comp=subinword(comp,"EXXON MOBIL","EXXON",.)
replace comp=subinword(comp,"SPRINT NEXTEL","SPRINT",.)
replace comp=subinword(comp,"INSTRUMENTS","INSTR",.)
replace comp=subinword(comp,"TEXAS","TX",.)
replace comp=subinword(comp,"DU PONT (E I) DE NEMOURS","DUPONT (EI)",.)
replace comp=subinword(comp,"MICRO","MICR",.)
replace comp=subinword(comp,"TECHNOLOGIES","TECHS",.)
replace comp=subinword(comp,"UNITED","UTD",.)
replace comp=subinword(comp,"COMPUTER","CMP",.)
replace comp=subinword(comp,"RICHFIELD","RIC",.)
replace comp=subinword(comp,"INTERNATIONAL","INTL",.)
replace comp=subinword(comp,"MACH","MA",.)
replace comp=subinword(comp,"ANHEUSER-BUSCH","ANHEUSR-BSH",.)
replace comp=subinword(comp,"LOCKHEED MARTIN","LOCKHEED",.)
replace comp=subinword(comp,"LOCKHD MART","LOCKHEED",.)
replace comp=subinword(comp,"LABORATORIES","LABS",.)
replace comp=subinword(comp,"AMERICAN","",.)
replace comp=subinword(comp,"TECHNOLOGYOLD","TEC",.)
replace comp=subinword(comp,"TECHNOLOGY","TEC",.)
replace comp=subinword(comp,"HOSPITAL","HOSP",.)
replace comp=subinword(comp,"SUPPLY","SUP",.)
replace comp=subinword(comp,"PHILIP","PHIL",.)
replace comp=subinword(comp,"MORRIS","MOR",.)
replace comp=subinword(comp,"NORTHROP GRUMMAN","NORTHROP",.)
replace comp=subinword(comp,"LOWE'S COMPANIES","LOWES COS",.)
replace comp=subinword(comp,"MARIETTA","MRTA",.)
replace comp=subinword(comp,"MICROSYSTEMS","MICRO",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinstr(comp,"AM TEL &TEL","AT&T",.)
replace comp=subinstr(comp,"-","",.)
replace comp=subinword(comp,"CL","",.)
replace comp=subinword(comp,"A","",.)
replace comp=subinword(comp,"HLDG","",.)
replace comp=subinword(comp,"WARD","WD",.)
replace comp=subinword(comp,"MONTGOMERY","MONTGMY",.)
replace comp=subinstr(comp,"PR","",.)
replace comp=subinword(comp,"CORP","",.)
replace comp=subinword(comp,"CO","",.)
replace comp=subinword(comp,"CP","",.)
replace comp=subinword(comp,"INC","",.)
replace comp=subinword(comp,"DAIMLERCHRYSLER","DAIMLER",.)
replace comp=subinword(comp,"AG","",.)
replace comp=subinword(comp,"COMPUTER","CMP",.)
replace comp=subinword(comp,"EASTMAN","EASTMN",.)
replace comp=subinword(comp,"KODAK","KODK",.)
replace comp=subinword(comp,"MACHINES","MA",.)
replace comp=subinword(comp,"BUSINESS","BUS",.)
replace comp=subinword(comp,"MACH","MA",.)
replace comp=subinword(comp,"EQUIPMENT","EQ",.)
replace comp=subinword(comp,"PROCTER","PRCTR",.)
replace comp=subinword(comp,"GAMBLE","GM",.)
replace comp=subinword(comp,"GENERAL","GEN",.)
replace comp=subinword(comp,"MOTORS","MTR",.)
replace comp=subinword(comp,"MOTOR","MTR",.)
replace comp=subinword(comp,"FUNDING","",.)
replace comp=subinword(comp,"(J C)","(JC)",.)
replace comp=subinword(comp,"DOUGLAS","DG",.)
replace comp=subinword(comp,"MCDONNELL","MCDONNEL",.)
replace comp=subinword(comp,"STORES","",.)
replace comp=subinword(comp,"EXXON MOBIL","EXXON",.)
replace comp=subinword(comp,"SPRINT NEXTEL","SPRINT",.)
replace comp=subinword(comp,"INSTRUMENTS","INSTR",.)
replace comp=subinword(comp,"TEXAS","TX",.)
replace comp=subinword(comp,"DU PONT (E I) DE NEMOURS","DUPONT (EI)",.)
replace comp=subinword(comp,"MICRO","MICR",.)
replace comp=subinword(comp,"TECHNOLOGIES","TECHS",.)
replace comp=subinword(comp,"UNITED","UTD",.)
replace comp=subinword(comp,"COMPUTER","CMP",.)
replace comp=subinword(comp,"RICHFIELD","RIC",.)
replace comp=subinword(comp,"INTERNATIONAL","INTL",.)
replace comp=subinword(comp,"MACH","MA",.)
replace comp=subinword(comp,"ANHEUSER-BUSCH","ANHEUSR-BSH",.)
replace comp=subinword(comp,"LOCKHEED MARTIN","LOCKHEED",.)
replace comp=subinword(comp,"LOCKHD MART","LOCKHEED",.)
replace comp=subinword(comp,"LABORATORIES","LABS",.)
replace comp=subinword(comp,"AMERICAN","",.)
replace comp=subinword(comp,"TECHNOLOGYOLD","TEC",.)
replace comp=subinword(comp,"TECHNOLOGY","TEC",.)
replace comp=subinword(comp,"HOSPITAL","HOSP",.)
replace comp=subinword(comp,"SUPPLY","SUP",.)
replace comp=subinword(comp,"PHILIP","PHIL",.)
replace comp=subinword(comp,"MORRIS","MOR",.)
replace comp=subinword(comp,"NORTHROP GRUMMAN","NORTHROP",.)
replace comp=subinword(comp,"LOWE'S COMPANIES","LOWES COS",.)
replace comp=subinword(comp,"MARIETTA","MRTA",.)
replace comp=subinword(comp,"MICROSYSTEMS","MICRO",.)
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

merge3
mergeRate	//.1110953

*17th
use "$data/resid1.dta", clear
replace comp=subinword(comp,"MCDONNELL","MCDONNEL",.)
replace comp=subinword(comp,"DOUGLAS","DG",.)
replace comp = subinstr(comp, " ", "", .)									//BLUNT way of improving match, remove white space
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid1.dta", replace

use "$data/resid2.dta", clear
replace comp=subinword(comp,"MCDONNELL","MCDONNEL",.)
replace comp=subinword(comp,"DOUGLAS","DG",.)
replace comp = subinstr(comp, " ", "", .)									//BLUNT way of improving match, remove white space
replace comp=trim(comp)
sort comp 
gen count=0
collapse count (firstnm) origName, by(comp)
drop count
save "$data/resid2.dta", replace

/*******************************************************************************
	REMOVING USELESS CUSTOMER FIELDS
*******************************************************************************/

use "$data/resid1", clear
gen tag=(strpos(origName, " CUSTOMER")!=0 | strpos(origName, " COSTOMER" | strpos(origName, " CUSTOMRES")!=0 ///
	| strpos(origName, " CUSTOMER")!=0 )

replace tag=1 if strpos(origName, " DISTRIBUTOR")!=0

replace comp = "20THCENTURYFOX" if strpos(origName, "20TH CENT")!=0

/*******************************************************************************
	SOUNDEX
*******************************************************************************/
stop

*Matching the remaining firms by soundex
	*As done in Cohen & Frazzini (2008)
	*And Atalay, Hortacsu, Roberts & Syverson (2011)

ssc install freqindex
ssc install matchit
	
use "$data/resid1", clear
gen id1 = _n
save "$data/resid1_fuzzyStr", replace

use "$data/resid2", clear
gen id2 = _n
save "$data/resid2_fuzzyStr", replace

use "$data/resid1_fuzzyStr", clear
*drop if _n>100
matchit id1 comp using "$data/resid2_fuzzyStr.dta", idusing(id2) txtusing(comp) override
	
use "$data/resid1", clear
gen scomp=soundex(comp)
rename comp comp1
save "$data/resid1_soundex", replace

use "$data/resid2", clear
gen scomp=soundex(comp)
rename comp comp2
save "$data/resid2_soundex", replace

use "$data/resid1_soundex", clear
merge m:m scomp using "$data/resid2_soundex"

if _N==0{
	exit
	}
save "$data/result.dta", replace

keep if _merge==3
drop _merge
append using "$data/matched.dta"
save "$data/matched.dta", replace

use "$data/result.dta", clear 
keep if _merge==1
keep comp origName
sort comp origName
merge 1:1 comp using "$data/resid1"
keep if _merge==3
drop _merge
sort comp
save "$data/resid1", replace emptyok

use "$data/result.dta", clear 
keep if _merge==2
keep comp origName
sort comp origName
merge 1:1 comp using "$data/resid2.dta" 
keep if _merge==3
drop _merge
sort comp
save "$data/resid2.dta" , replace emptyok

erase "$data/result.dta"

merge3
mergeRate	//.11509919

log close
