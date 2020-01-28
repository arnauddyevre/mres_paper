/*Nathan Chan
Last updated: July 20, 2009
Analyze Compustat
Data sets needed:
1. segcust
2. 303508617 (which is Compustat data on operating income and sales)
*/
clear all
program drop _all
set mem 500m
set more off
set matsize 800
pause on

/*Try different approach from soundex*/
/* Prepare compustat data for merge */
use "../data/303508617"
destring gvkey, replace
gen year=fyear
sort gvkey year
save opandsales, replace
gen custname=trim(conm) /*trim string so exactly like the segment file*/
replace custname=upper(custname)
rename conm offcompustat_custname
rename gvkey custgvkey
rename oibdp cust_oibdp
rename sale cust_sales
sort custname year
save opandsalesc, replace
clear all

***Now prepare segments file
use "../data/segcust"
rename GVKEY gvkey
gen custname=trim(CNAME)
replace custname=upper(custname)
gen year=SRCYR
sort gvkey year

***Merge suppliers financial data
merge gvkey year using opandsales /*this merges suppliers with their financial data*/
keep if _merge==3
drop _merge
rename oibdp supp_oibdp
rename sale supp_sale
sort custname year


****
**File being saved
****
save segwsupp, replace

/*
Now we will use an iterative procedure to merge. 
First, we see if there are any perfect customer matches
Should do this by supplier
*/
merge custname year using opandsalesc //ensures the merging is done by supplier
save tempmerge, replace

/*Matched results will go in a file*/
keep if _merge==3
drop _merge
save matched, replace

use tempmerge, clear
keep if _merge==1 //These are all observations with supplier financial information and the segment customer information that have not yet been merged
keep custname year
sort custname year
merge custname year using segwsupp
keep if _merge==3 
drop _merge
save resid1, replace

use tempmerge, clear
keep if _merge==2 //These are all the observations on operations and sales of potential customer companies that have not been matched
keep custname year
sort custname year
merge custname year using opandsalesc
keep if _merge==3
drop _merge
save resid2, replace

/* having finished the "perfect" match, set up program, found at: http://www.stata.com/statalist/archive/2004-02/msg00246.html*/
program merge3 
                confirm file matched.dta
                confirm file resid1.dta 
                confirm file resid2.dta 

                use resid1, clear 
                merge custname year using resid2 
                if _N==0 {
                        exit
                }
                save result, replace

                keep if _merge==3
                drop _merge
                append using matched
                save matched, replace

                use result, clear 
                keep if _merge==1
                keep custname year
			sort custname year
                merge custname year using resid1
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


use matched, clear
drop if custname==""
drop if custname=="CDA"
drop if custname=="ISRAEL"
drop if custname=="MMERCIAL"
save matched, replace

/*
****
**RETURN OF THE soundex!!!
****
use resid1, clear
gen scustname=soundex(custname)
rename custname Ucustname
sort scustname year
save resid1, replace

use resid2, clear
egen scustname=soundex(custname)
rename custname Mcustname
sort scustname year
save resid2, replace

merge scustname year using resid1

sort _merge
sort CNAME
save tempresid, replace
*/
erase opandsales.dta
erase opandsalesc.dta
erase tempmerge.dta

use resid1, clear
sort CNAME
by CNAME: egen count=count(1)
egen tag=tag(CNAME)
sort count
save resid1, replace

use resid2, clear
sort offcompustat_custname
by offcompustat_custname: egen count=count(1)
egen tag=tag(offcompustat_custname)
save resid2, replace

