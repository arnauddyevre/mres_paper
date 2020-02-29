
/*******************************************************************************
	
	DESCRIPTION: Do file building yearly networks of firms, using the cleaning
				procedure of 002
	
	INFILES:	- 
	
	OUTFILES:	- 
	
	LOG: Created 28/02/2020
	
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
global orig "C:/Users/dyevre/Downloads/mres_paper_orig"							// I'm using a different orig folder so as not to commit large datasets to GitHub
global data "$wd/data/001_network"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"

*do-file number, used to save outputs 
global doNum "003"					

*log
cap log close
log using "$log/${doNum}_buildYearlyNetworks", text append

/*******************************************************************************
	GETTING THE WHOLE COMPUSTAT COMPANY DATA WITH GVKEYs
*******************************************************************************/

import delimited "$orig/compustat_quarterly_61_19.csv", clear
collapse fqtr, by(gvkey conm) fast
drop fqtr
duplicates tag gvkey, gen(tag)													// No duplicates, good
tab tag, mi
drop tag


*Applying the cleaning algorithm used in 002
gen comp = conm

*1st round
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

*2nd
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

*3rd
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

*4th
replace comp=subinword(comp,"SA","",.)
replace comp=subinstr(comp,"PRODUCTS","PROD",.)
replace comp=subinstr(comp,"ELECTRONICS","ELECT",.)
replace comp=trim(comp)

*5th
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

*6th
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

*7th
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

*8th
replace comp=subinstr(comp,"ROEBK","",.)
replace comp=subinstr(comp,"ROEBUCK &","",.)
replace comp=subinstr(comp,"AIR LINES","AIRL",.)
replace comp=trim(comp)

*9th
replace comp=subinstr(comp,"SYSTEMS","SYS",.)
replace comp=subinstr(comp,"DU PONT EI DE NEMOURS","DUPONT EI",.)
*replace comp=subinstr(comp,"EI","",.)
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

*10th
replace comp=subinstr(comp,"GAS","GS",.)
replace comp=subinstr(comp,"TOWN","TWN",.)
replace comp=subinstr(comp,"L M","",.)
replace comp=subinstr(comp,"LM","",.)
replace comp=subinstr(comp,"TELEFON","TEL",.)
replace comp=trim(comp)

*11th
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

*12th
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

*13th
replace comp=subinword(comp,"PACKARD","PCK",.)
replace comp=subinword(comp,"HOTELS","HTL",.)
replace comp=trim(comp)

*14th
replace comp=subinword(comp,"TROY","TR",.)
replace comp=subinword(comp,"MEYERS","MEYR",.)
replace comp=subinword(comp,"H J","HJ",.)
replace comp=subinword(comp,"HOTL","HTL",.)
replace comp=subinword(comp,"HEALTHDYNE","HLTHDNE",.)
replace comp=subinword(comp,"TECHNOL","TEC",.)
*replace comp=subinword(comp,"CELANESE","",.)
replace comp=subinword(comp,"CEL","",.)
replace comp=subinword(comp,"MIFFLIN","MF",.)
replace comp=subinword(comp,"LTPWR","LP",.)
replace comp=subinword(comp,"HOST","HST",.)
replace comp=subinword(comp,"SUPPLY","SPLY",.)
replace comp=subinword(comp,"MATERIALS HNDLG","",.)
replace comp=subinword(comp,"SOLUTIONS","",.)
replace comp=trim(comp)

*15th
replace comp=subinword(comp,"CHASE","CHSE",.)
replace comp=subinword(comp,"J P MORGAN","JPMORGAN",.)
replace comp=subinword(comp,"CIRCUIT","CRCT",.)
replace comp=subinword(comp,"NTROLS","CNTL",.)
replace comp=subinword(comp,"JOHNSONJOHNSON","JOHNSNJHNS",.)
replace comp=trim(comp)

*16th
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

*17th
replace comp=subinword(comp,"MCDONNELL","MCDONNEL",.)
replace comp=subinword(comp,"DOUGLAS","DG",.)
replace comp = subinstr(comp, " ", "", .)									//BLUNT way of improving match, remove white space
replace comp=trim(comp)

duplicates tag comp, gen(tag)
br if tag!=0
sort comp tag

*Reshaping dataset in wide format, with all gvkeys and alternative names
drop if comp==""
bys comp: gen n = _n
drop tag
reshape wide conm gvkey, i(comp) j(n)											// 32,193 companies
sort comp
gen n = _n
save "$data/${doNum}_netCompList.dta", replace

/*******************************************************************************
	USING THE CUSTOMER DATA AND GETTING SHARES OF INPUT/SALES
*******************************************************************************/

import delimited "$orig/compustat_segment_customer_76_19.csv", clear
gen year = floor(srcdate/10000)
