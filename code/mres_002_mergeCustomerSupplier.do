
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
merge 1:m comp using "$data/001_companyList_6119.dta"					// 1 to many merge as several companies in Compustat have the same name but different Gvkeys 
count if _merge == 3
local merged = `r(N)'
count if _merge == 1
local master = `r(N)'
di `merged'/(`master'+`merged')													//6.30% merge

*Supplier to company exact merge
use "$data/001_supplierList.dta", clear
merge 1:1 gvkey comp using "$data/001_companyList_6119.dta"
count if _merge == 3
local merged = `r(N)'
count if _merge == 1
local master = `r(N)'
di `merged'/(`master'+`merged')													//98.18% merge

/*******************************************************************************
	AHRS CLEANING ALGORITHM
*******************************************************************************/

*Using the cleaning algorithm from AHRS
use "$data/001_customerList.dta", clear
merge 1:m comp using "$data/001_companyList_6119.dta"		
save "$data/tempmerge.dta", replace

*AHRS manual cleaning (re-used with permission given by Enghin Atalay, 03/12/2019)
/*Matched results will go in a file*/
keep if _merge==3
drop _merge
save "$data/matched.dta", replace

use "$data/tempmerge", clear
keep if _merge==1 																//customer name only, no match in Compustat company list
keep comp
save "$data/resid1", replace

use "$data/tempmerge", clear
keep if _merge==2 																//official company names in Compustat only, these companies have not found a match in the segmnent data as reported
keep comp
save "$data/resid2", replace

*Program automating the merge of the residual datasets after each cleaning step
*From http://www.stata.com/statalist/archive/2004-02/msg00246.html*/
program merge3 
	confirm file "$data/matched.dta"
	confirm file "$data/resid1.dta" 
	confirm file "$data/resid2.dta" 

	use "$data/resid1", clear 
	merge comp using "$data/resid2"
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
	keep comp
	sort comp
	merge comp using "$data/result.dta"
	keep if _merge==3
	drop _merge
	sort custname year
	save resid1, replace emptyok

	use result, clear 
	keep if _merge==2
	keep custname year
sort custname year
	merge custname year using resid2
	keep if _merge==3
	drop _merge
	sort custname year
	save resid2, replace emptyok

	erase result.dta
	end

use resid1, clear
replace custname=subinstr(custname,"CORP","",.)
replace custname=subinstr(custname,"COMPANIES","",.)
replace custname=subinstr(custname,"COMPANY","",.)
replace custname=subinstr(custname,"CONSOLIDATED","",.)
replace custname=subinword(custname,"CO","",.)
replace custname=subinstr(custname,"INC","",.)
replace custname=subinstr(custname,"LABORATORIES","LAB",.)
replace custname=subinstr(custname,"/"," ",.)
replace custname=subinstr(custname,"-"," ",.)
replace custname=subinstr(custname,"LP","",.)
replace custname=subinstr(custname,"LTD","",.)
replace custname=subinword(custname,"STORES","",.)
replace custname=subinword(custname,"MOTOR","MTR",.)
replace custname=subinstr(custname,"GENERAL","GENL",.)
replace custname=subinstr(custname,"GENL","GEN",.)
replace custname=subinword(custname,"MOBIL","",.)
replace custname=subinword(custname,"MICRO","MICR",.)
replace custname=subinword(custname,"UNITED","UTD",.)
replace custname=subinword(custname,"TECHNOLOGIES","TECHS",.)

replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"CORP","",.)
replace custname=subinstr(custname,"COMPANIES","",.)
replace custname=subinstr(custname,"COMPANY","",.)
replace custname=subinstr(custname,"CONSOLIDATED","",.)
replace custname=subinword(custname,"CO","",.)
replace custname=subinstr(custname,"INC","",.)
replace custname=subinstr(custname,"LABORATORIES","LAB",.)
replace custname=subinstr(custname,"/"," ",.)
replace custname=subinstr(custname,"-"," ",.)
replace custname=subinstr(custname,"LP","",.)
replace custname=subinstr(custname,"LTD","",.)
replace custname=subinword(custname,"STORES","",.)
replace custname=subinword(custname,"MOTOR","MTR",.)
replace custname=subinstr(custname,"GENERAL","GENL",.)
replace custname=subinstr(custname,"GENL","GEN",.)
replace custname=subinword(custname,"MOBIL","",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

***Second set of string modifications
use resid1, clear
replace custname=subinstr(custname,"A T & T","AT&T",.)
replace custname=subinstr(custname,"GROUP","",.)
replace custname=subinstr(custname,"HEALTHCARE","HTHCR",.)
replace custname=subinstr(custname,"SPON ADR","",.)
replace custname=subinstr(custname,"ABF FREIGHT SYSTEM","ABF FREIGHT",.)
replace custname=subinstr(custname,"ABF FREIGHT","ABF",.)
replace custname=subinstr(custname,"PLC","",.)
replace custname=subinstr(custname,"HOLDINGS","",.)
replace custname=subinstr(custname,"ADR","",.)
replace custname=subinstr(custname,"INDUSTRIES","IND",.)
replace custname=subinstr(custname,"UNITED","UTD",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"A T & T","AT&T",.)
replace custname=subinstr(custname,"SPON ADR","",.)
replace custname=subinstr(custname,"PLC","",.)
replace custname=subinstr(custname,"GROUP","",.)
replace custname=subinstr(custname,"HEALTHCARE","HTHCR",.)
replace custname=subinstr(custname,"ABF FREIGHT SYSTEM","ABF FREIGHT",.)
replace custname=subinstr(custname,"ABF FREIGHT","ABF",.)
replace custname=subinstr(custname,"HOLDINGS","",.)
replace custname=subinstr(custname,"ADR","",.)
replace custname=subinstr(custname,"INDUSTRIES","IND",.)
replace custname=subinstr(custname,"UNITED","UTD",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

***Third set of string modifications
use resid1, clear
replace custname=subinstr(custname,"TELECOMMUNICATIONS","TELEM",.)
replace custname=subinstr(custname,"CL A","",.)
replace custname=subinstr(custname,"MMUNICATIONS","MMUN",.)
replace custname=subinstr(custname,"ADVANCED MICRO DEVICES","AMD",.)
replace custname=subinstr(custname,"ADV MICRO DV","AMD",.)
replace custname=subinstr(custname,"CP","",.)
replace custname=subinstr(custname,"CMPTRS","MPUTERS",.)
replace custname=subinstr(custname,"AHA BETA","AHA BETA TECHNOLOGY",.)
replace custname=subinstr(custname,"PRDS&CH","PRODUCTS & CHEMICALS",.)
replace custname=subinstr(custname,"AIRTOUCH CM","AIRTOUCH COMMUNICATIONS",.)
replace custname=subinstr(custname,"INTERNATIONAL","INTL",.)
replace custname=subinstr(custname,"POWER","PWR",.)
replace custname=subinstr(custname,"'","",.)
replace custname=subinstr(custname," & ","",.)

sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"TELEMMUNICATIONS","TELEM",.)
replace custname=subinstr(custname,"MMUNICATIONS","MMUN",.)
replace custname=subinstr(custname,"ADVANCED MICRO DEVICES","AMD",.)
replace custname=subinstr(custname,"ADV MICRO DV","AMD",.)
replace custname=subinstr(custname,"CL A","",.)
replace custname=subinstr(custname,"CP","",.)
replace custname=subinstr(custname,"CMPTRS","MPUTERS",.)
replace custname=subinstr(custname,"AHA BETA","AHA BETA TECHNOLOGY",.)
replace custname=subinstr(custname,"PRDS&CH","PRODUCTS & CHEMICALS",.)
replace custname=subinstr(custname,"AIRTOUCH CM","AIRTOUCH COMMUNICATIONS",.)
replace custname=subinstr(custname,"INTERNATIONAL","INTL",.)
replace custname=subinstr(custname,"POWER","PWR",.)
replace custname=subinstr(custname,"'","",.)
replace custname=subinstr(custname," & ","",.)
sort custname year
save resid2, replace
merge3

****
*Fourth String Modification
****
use resid1, clear
replace custname=subinword(custname,"SA","",.)
replace custname=subinstr(custname,"PRODUCTS","PROD",.)
replace custname=subinstr(custname,"ELECTRONICS","ELECT",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinword(custname,"PRODUCTS","PROD",.)
replace custname=subinstr(custname,"ELECTRONICS","ELECT",.)
replace custname=subinword(custname,"SA","",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

********
***Fifth string modification
********
use resid1, clear
replace custname=subinstr(custname,"AMERICA","AMER",.)
replace custname=subinstr(custname,".","",.)
replace custname=subinstr(custname,"HYDRO ELECTRIC","HYD",.)
replace custname=subinstr(custname,"OLD","",.)
replace custname=subinstr(custname,"TRUST","TR",.)
replace custname=subinstr(custname,"BARCLAYS BANK","BARCLAYS",.)
replace custname=subinstr(custname," & ","&",.)
replace custname=subinstr(custname,"NOBLE","NOBL",.)
replace custname=subinstr(custname,"BANK","BK",.)
replace custname=subinstr(custname,"NEW","",.)
replace custname=subinstr(custname,"WRIGHT","WRGHT",.)
replace custname=trim(custname)
sort custname year
save resid1, replace


use resid2, clear
replace custname=subinstr(custname,"AMERICA","AMER",.)
replace custname=subinstr(custname,".","",.)
replace custname=subinstr(custname,"HYDRO ELECTRIC","HYD",.)
replace custname=subinstr(custname,"OLD","",.)
replace custname=subinstr(custname,"TRUST","TR",.)
replace custname=subinstr(custname,"BARCLAYS BANK","BARCLAYS",.)
replace custname=subinstr(custname," & ","&",.)
replace custname=subinstr(custname,"NOBLE","NOBL",.)
replace custname=subinstr(custname,"BANK","BK",.)
replace custname=subinstr(custname,"NEW","",.)
replace custname=subinstr(custname,"WRIGHT","WRGHT",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

*********
**Fifth String Mod
*********
use resid1, clear
replace custname=subinstr(custname,"A G","AG",.)
replace custname=subinstr(custname,"AEROSPACE","AEROSPAC",.)
replace custname=subinstr(custname,"(","",.)
replace custname=subinstr(custname,")","",.)
replace custname=subinstr(custname,"L L","LL",.)
replace custname=subinstr(custname,"STEARNS","STRNS",.)
replace custname=subinstr(custname,"DICKINSON &","DICK",.)
replace custname=subinstr(custname,"AIRCRAFT","AIRCR",.)
replace custname=subinstr(custname,"AIRCRFT","AIRCR",.)
replace custname=subinstr(custname,"CANADA","CDA",.)
replace custname=subinstr(custname,"PROJECTED","",.)
replace custname=subinstr(custname,"TELEM","TEL",.)
replace custname=subinstr(custname,"BETHLEHEM","BETHLHM",.)
replace custname=subinstr(custname,"STEEL","STL",.)
replace custname=subinstr(custname,"ENTERPRISES","ENT",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"A G","AG",.)
replace custname=subinstr(custname,"AEROSPACE","AEROSPAC",.)
replace custname=subinstr(custname,"(","",.)
replace custname=subinstr(custname,")","",.)
replace custname=subinstr(custname,"L L","LL",.)
replace custname=subinstr(custname,"STEARNS","STRNS",.)
replace custname=subinstr(custname,"DICKINSON &","DICK",.)
replace custname=subinstr(custname,"AIRCRAFT","AIRCR",.)
replace custname=subinstr(custname,"AIRCRFT","AIRCR",.)
replace custname=subinstr(custname,"CANADA","CDA",.)
replace custname=subinstr(custname,"PROJECTED","",.)
replace custname=subinstr(custname,"TELEM","TEL",.)
replace custname=subinstr(custname,"BETHLEHEM","BETHLHM",.)
replace custname=subinstr(custname,"STEEL","STL",.)
replace custname=subinstr(custname,"ENTERPRISES","ENT",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

***6
use resid1, clear
replace custname=subinstr(custname,"BIG THREE","BIG THREE IND",.)
replace custname=subinstr(custname,"LLC","",.)
replace custname=subinstr(custname,"BORG WARNER","",.)
replace custname=subinstr(custname,"SCIENTIFIC","SCI",.)
replace custname=subinstr(custname,"ADS","BP",.)
replace custname=subinstr(custname,"BRIGGS&STRATTON","BRIGG&STRN",.)
replace custname=subinstr(custname,"MYERS SQUIBB","MYRS",.)
replace custname=subinstr(custname,"CA CL","CA LA",.)
replace custname=subinstr(custname,"GOLF","GF",.)
replace custname=subinstr(custname,"SOUP","SP",.)
replace custname=subinstr(custname,"CAMPBELL","CAMPBL",.)
replace custname=subinstr(custname,"FINANCIAL","FINL",.)
replace custname=subinstr(custname,"NATURAL GAS","NAT",.)
replace custname=subinstr(custname,"CANADIAN","CDN",.)
replace custname=subinstr(custname,"AIRCFT","AIRC",.)
replace custname=subinstr(custname,"AIRCR","AIRC",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"LLC","",.)
replace custname=subinstr(custname,"BORG WARNER","",.)
replace custname=subinstr(custname,"SCIENTIFIC","SCI",.)
replace custname=subinstr(custname,"BP   ADS","BP",.)
replace custname=subinstr(custname,"BRIGGS&STRATTON","BRIGG&STRN",.)
replace custname=subinstr(custname,"MYERS SQUIBB","MYRS",.)
replace custname=subinstr(custname,"CA CL","CA LA",.)
replace custname=subinstr(custname,"GOLF","GF",.)
replace custname=subinstr(custname,"SOUP","SP",.)
replace custname=subinstr(custname,"CAMPBELL","CAMPBL",.)
replace custname=subinstr(custname,"FINANCIAL","FINL",.)
replace custname=subinstr(custname,"NATURAL GAS","NAT",.)
replace custname=subinstr(custname,"CANADIAN","CDN",.)
replace custname=subinstr(custname,"AIRCFT","AIRC",.)
replace custname=subinstr(custname,"AIRCR","AIRC",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinstr(custname,"ROEBK","",.)
replace custname=subinstr(custname,"ROEBUCK &","",.)
replace custname=subinstr(custname,"AIR LINES","AIRL",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"ROEBK","",.)
replace custname=subinstr(custname,"ROEBUCK &","",.)
replace custname=subinstr(custname,"AIR LINES","AIRL",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3
use matched, clear
drop if custname==""
*****
**Seventh string mod
*****

use resid1, clear
replace custname=subinstr(custname,"SYSTEMS","SYS",.)
replace custname=subinstr(custname,"DU PONT EI DE NEMOURS","DUPONT EI",.)
replace custname=subinstr(custname,"EI","",.)
replace custname=subinstr(custname,"PRO FORMA","",.)
replace custname=subinstr(custname,"CREDIT","CR",.)
replace custname=subinstr(custname,"LIGHT","LT",.)
replace custname=subinstr(custname,"CHEMICAL","CHEMICL",.)
replace custname=subinstr(custname,"&","",.)
replace custname=subinstr(custname,"DISCREET","DISCRT",.)
replace custname=subinstr(custname,"LOGIC","LGC",.)
replace custname=subinstr(custname,"TELEKOM","TELE",.)
replace custname=subinstr(custname,"TLKOM","TELE",.)
replace custname=subinstr(custname,"DEUTSCHE","DTSCH",.)

replace custname=subinstr(custname,"PWRLIGHT","PL",.)
replace custname=subinstr(custname,"SUPERMARKETS","SUPERMKTS",.)
replace custname=subinstr(custname,"CAPITAL","CAP",.)
replace custname=subinstr(custname,"GRAND ICE CREAM","",.)
replace custname=subinstr(custname,"DREAMS","DRMS",.)
replace custname=subinstr(custname,"EMPORIUM","EMPORM",.)
replace custname=subinstr(custname,"HARDWAREGARDEN","HRDWR",.)
replace custname=subinstr(custname,"KODAK","KDK",.)
replace custname=subinstr(custname,"MAN","MN",.)
replace custname=subinstr(custname,"STORES","",.)
replace custname=subinstr(custname,"BROTHERS","BROS",.)
replace custname=subinstr(custname,"AG","",.)
replace custname=subinstr(custname,"ELECTRONIC","ELEC",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"SYSTEMS","SYS",.)
replace custname=subinstr(custname,"DU PONT EI DE NEMOURS","DUPONT EI",.)
replace custname=subinstr(custname,"EI","",.)
replace custname=subinstr(custname,"PRO FORMA","",.)
replace custname=subinstr(custname,"CREDIT","CR",.)
replace custname=subinstr(custname,"LIGHT","LT",.)
replace custname=subinstr(custname,"CHEMICAL","CHEMICL",.)
replace custname=subinstr(custname,"&","",.)
replace custname=subinstr(custname,"DISCREET","DISCRT",.)
replace custname=subinstr(custname,"LOGIC","LGC",.)
replace custname=subinstr(custname,"TELEKOM","TELE",.)
replace custname=subinstr(custname,"TLKOM","TELE",.)
replace custname=subinstr(custname,"DEUTSCHE","DTSCH",.)
replace custname=subinstr(custname,"GENERAL","GENL",.)
replace custname=subinstr(custname,"GENL","GEN",.)
replace custname=subinstr(custname,"PWRLIGHT","PL",.)
replace custname=subinstr(custname,"SUPERMARKETS","SUPERMKTS",.)
replace custname=subinstr(custname,"CAPITAL","CAP",.)
replace custname=subinstr(custname,"GRAND ICE CREAM","",.)
replace custname=subinstr(custname,"DREAMS","DRMS",.)
replace custname=subinstr(custname,"EMPORIUM","EMPORM",.)
replace custname=subinstr(custname,"HARDWAREGARDEN","HRDWR",.)
replace custname=subinstr(custname,"KODAK","KDK",.)
replace custname=subinstr(custname,"MAN","MN",.)
replace custname=subinstr(custname,"STORES","",.)
replace custname=subinstr(custname,"BROTHERS","BROS",.)
replace custname=subinstr(custname,"AG","",.)
replace custname=subinstr(custname,"ELECTRONIC","",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinstr(custname,"GAS","GS",.)
replace custname=subinstr(custname,"TOWN","TWN",.)
replace custname=subinstr(custname,"L M","",.)
replace custname=subinstr(custname,"LM","",.)
replace custname=subinstr(custname,"TELEFON","TEL",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"GAS","GS",.)
replace custname=subinstr(custname,"TOWN","TWN",.)
replace custname=subinstr(custname,"L M","",.)
replace custname=subinstr(custname,"LM","",.)
replace custname=subinstr(custname,"TELEFON","TEL",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinstr(custname,"ERICSSON TEL","ERCSON TELE",.)
replace custname=subinstr(custname,"WHEELER","WHLR",.)
replace custname=subinstr(custname,"FISHER","FISHR",.)
replace custname=subinstr(custname,"SCIEN","SCI",.)
replace custname=subinstr(custname,"INTL","",.)
replace custname=subinstr(custname,"FED EXPRESS","FEDEX",.)
replace custname=subinstr(custname,"WOOD","WD",.)
replace custname=subinstr(custname,"FLA ROCK","FLORIDA ROCK",.)
replace custname=subinstr(custname,"STONE","STN",.)
replace custname=subinstr(custname,"TIRERUBBER","TIR",.)
replace custname=subinstr(custname,"TIR","",.)
replace custname=subinstr(custname,"CENTER","CNTR",.)
replace custname=subinstr(custname,"YEAR","YR",.)
replace custname=subinstr(custname,"NSOLIDATED","",.)
replace custname=subinstr(custname,"MIC","MC",.)
replace custname=subinstr(custname,"ELECTRIC","ELEC",.)
replace custname=subinstr(custname,"ELEC","EL",.)
replace custname=subinstr(custname,"NSOL","",.)
replace custname=subinstr(custname,"PACIFIC","PAC",.)
replace custname=subinstr(custname,"W R","WR",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"ERICSSON TEL","ERCSON TELE",.)
replace custname=subinstr(custname,"WHEELER","WHLR",.)
replace custname=subinstr(custname,"FISHER","FISHR",.)
replace custname=subinstr(custname,"SCIEN","SCI",.)
replace custname=subinstr(custname,"INTL","",.)
replace custname=subinstr(custname,"FED EXPRESS","FEDEX",.)
replace custname=subinstr(custname,"WOOD","WD",.)
replace custname=subinstr(custname,"FLA ROCK","FLORIDA ROCK",.)
replace custname=subinstr(custname,"STONE","STN",.)
replace custname=subinstr(custname,"TIRERUBBER","TIR",.)
replace custname=subinstr(custname,"TIR","",.)
replace custname=subinstr(custname,"CENTER","CNTR",.)
replace custname=subinstr(custname,"YEAR","YR",.)
replace custname=subinstr(custname,"NSOLIDATED","",.)
replace custname=subinstr(custname,"MIC","MC",.)
replace custname=subinstr(custname,"ELECTRIC","ELEC",.)
replace custname=subinstr(custname,"ELEC","EL",.)
replace custname=subinstr(custname,"NSOL","",.)
replace custname=subinstr(custname,"PACIFIC","PAC",.)
replace custname=subinstr(custname,"W R","WR",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinstr(custname,"METRO","MET",.)
replace custname=subinstr(custname,"TECHNOLOGIES","TECHNOL",.)
replace custname=subinstr(custname,"DATA MM","DATAM",.)
replace custname=subinstr(custname,"DATAMM","DATAM",.)
replace custname=subinstr(custname,"INSTRUMENT","INSTR",.)
replace custname=subinstr(custname,"INSTRMN","INSTR",.)
replace custname=subinstr(custname,"MOTORS","MTR",.)
replace custname=subinstr(custname,"INSTITUTE","INST",.)
replace custname=subinword(custname,"GENUINE","GENUIN",.)
replace custname=subinword(custname,"PARTS","PART",.)
replace custname=subinword(custname,"TEL","TE",.)
replace custname=subinword(custname,"GLOBALSTAR","GLBLSTR",.)
replace custname=subinstr(custname,",","",.)
replace custname=subinword(custname,"GOODYR E","GOODYR",.)
replace custname=subinword(custname,"W","",.)
replace custname=subinword(custname,"GRAINGER","GRAINGR",.)
replace custname=subinword(custname,"CHEMCL","CH",.)
replace custname=subinword(custname,"SP","",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinstr(custname,"METRO","MET",.)
replace custname=subinstr(custname,"TECHNOLOGIES","TECHNOL",.)
replace custname=subinstr(custname,"DATA MM","DATAM",.)
replace custname=subinstr(custname,"DATAMM","DATAM",.)
replace custname=subinstr(custname,"INSTRUMENT","INSTR",.)
replace custname=subinstr(custname,"INSTRMN","INSTR",.)
replace custname=subinstr(custname,"MOTORS","MTR",.)
replace custname=subinstr(custname,"INSTITUTE","INST",.)
replace custname=subinword(custname,"GENUINE","GENUIN",.)
replace custname=subinword(custname,"PARTS","PART",.)
replace custname=subinword(custname,"TEL","TE",.)
replace custname=subinword(custname,"GLOBALSTAR","GLBLSTR",.)
replace custname=subinstr(custname,",","",.)
replace custname=subinword(custname,"GOODYR E","GOODYR",.)
replace custname=subinword(custname,"W","",.)
replace custname=subinword(custname,"GRAINGER","GRAINGR",.)
replace custname=subinword(custname,"CHEMCL","CH",.)
replace custname=subinword(custname,"SP","",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinword(custname,"PACKARD","PCK",.)
replace custname=subinword(custname,"HOTELS","HTL",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinword(custname,"PACKARD","PCK",.)
replace custname=subinword(custname,"HOTELS","HTL",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinword(custname,"TROY","TR",.)
replace custname=subinword(custname,"MEYERS","MEYR",.)
replace custname=subinword(custname,"H J","HJ",.)
replace custname=subinword(custname,"HOTL","HTL",.)
replace custname=subinword(custname,"HEALTHDYNE","HLTHDNE",.)
replace custname=subinword(custname,"TECHNOL","TEC",.)
replace custname=subinword(custname,"CELANESE","",.)
replace custname=subinword(custname,"CEL","",.)
replace custname=subinword(custname,"MIFFLIN","MF",.)
replace custname=subinword(custname,"LTPWR","LP",.)
replace custname=subinword(custname,"HOST","HST",.)
replace custname=subinword(custname,"SUPPLY","SPLY",.)
replace custname=subinword(custname,"MATERIALS HNDLG","",.)
replace custname=subinword(custname,"SOLUTIONS","",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinword(custname,"TROY","TR",.)
replace custname=subinword(custname,"MEYERS","MEYR",.)
replace custname=subinword(custname,"H J","HJ",.)
replace custname=subinword(custname,"HOTL","HTL",.)
replace custname=subinword(custname,"HEALTHDYNE","HLTHDNE",.)
replace custname=subinword(custname,"TECHNOL","TEC",.)
replace custname=subinword(custname,"CELANESE","",.)
replace custname=subinword(custname,"CEL","",.)
replace custname=subinword(custname,"MIFFLIN","MF",.)
replace custname=subinword(custname,"LTPWR","LP",.)
replace custname=subinword(custname,"HOST","HST",.)
replace custname=subinword(custname,"SUPPLY","SPLY",.)
replace custname=subinword(custname,"MATERIALS HNDLG","",.)
replace custname=subinword(custname,"SOLUTIONS","",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

use resid1, clear
replace custname=subinword(custname,"CHASE","CHSE",.)
replace custname=subinword(custname,"J P MORGAN","JPMORGAN",.)
replace custname=subinword(custname,"CIRCUIT","CRCT",.)
replace custname=subinword(custname,"NTROLS","CNTL",.)
replace custname=subinword(custname,"JOHNSONJOHNSON","JOHNSNJHNS",.)
replace custname=trim(custname)
sort custname year
save resid1, replace

use resid2, clear
replace custname=subinword(custname,"CHASE","CHSE",.)
replace custname=subinword(custname,"J P MORGAN","JPMORGAN",.)
replace custname=subinword(custname,"CIRCUIT","CRCT",.)
replace custname=subinword(custname,"NTROLS","CNTL",.)
replace custname=subinword(custname,"JOHNSONJOHNSON","JOHNSNJHNS",.)
replace custname=trim(custname)
sort custname year
save resid2, replace

merge3

use resid1, clear
replace custname=subinword(custname,"MCDONNELL","MCDONNEL",.)
replace custname=subinword(custname,"DOUGLAS","DG",.)

REMOVE WHITESPACES HERE

use matched, clear
drop if custname==""
drop if custname=="CDA"
drop if custname=="ISRAEL"
drop if custname=="MMERCIAL"
save matched, replace	

log close
