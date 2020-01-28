*************
***Can't believe how much is leftover
*************
clear all
program drop _all
set mem 500m
set more off
set matsize 800
pause on


use resid1
replace custname=CNAME
replace custname=trim(custname)
replace custname=upper(custname)
replace custname=subinstr(custname,"AM TEL &TEL","AT&T",.)
replace custname=subinstr(custname,"-","",.)
replace custname=subinword(custname,"CL","",.)
replace custname=subinword(custname,"A","",.)
replace custname=subinword(custname,"HLDG","",.)
replace custname=subinword(custname,"WARD","WD",.)
replace custname=subinword(custname,"MONTGOMERY","MONTGMY",.)
replace custname=subinstr(custname,"PR","",.)
replace custname=subinword(custname,"CORP","",.)
replace custname=subinword(custname,"CO","",.)
replace custname=subinword(custname,"CP","",.)
replace custname=subinword(custname,"INC","",.)
replace custname=subinword(custname,"DAIMLERCHRYSLER","DAIMLER",.)
replace custname=subinword(custname,"AG","",.)
replace custname=subinword(custname,"COMPUTER","CMP",.)
replace custname=subinword(custname,"EASTMAN","EASTMN",.)
replace custname=subinword(custname,"KODAK","KODK",.)
replace custname=subinword(custname,"MACHINES","MA",.)
replace custname=subinword(custname,"BUSINESS","BUS",.)
replace custname=subinword(custname,"MACH","MA",.)
replace custname=subinword(custname,"EQUIPMENT","EQ",.)
replace custname=subinword(custname,"PROCTER","PRCTR",.)
replace custname=subinword(custname,"GAMBLE","GM",.)
replace custname=subinword(custname,"GENERAL","GEN",.)
replace custname=subinword(custname,"MOTORS","MTR",.)
replace custname=subinword(custname,"MOTOR","MTR",.)
replace custname=subinword(custname,"FUNDING","",.)
replace custname=subinword(custname,"(J C)","(JC)",.)
replace custname=subinword(custname,"DOUGLAS","DG",.)
replace custname=subinword(custname,"MCDONNELL","MCDONNEL",.)
replace custname=subinword(custname,"STORES","",.)
replace custname=subinword(custname,"EXXON MOBIL","EXXON",.)
replace custname=subinword(custname,"SPRINT NEXTEL","SPRINT",.)
replace custname=subinword(custname,"INSTRUMENTS","INSTR",.)
replace custname=subinword(custname,"TEXAS","TX",.)
replace custname=subinword(custname,"DU PONT (E I) DE NEMOURS","DUPONT (EI)",.)
replace custname=subinword(custname,"MICRO","MICR",.)
replace custname=subinword(custname,"TECHNOLOGIES","TECHS",.)
replace custname=subinword(custname,"UNITED","UTD",.)
replace custname=subinword(custname,"COMPUTER","CMP",.)
replace custname=subinword(custname,"RICHFIELD","RIC",.)
replace custname=subinword(custname,"INTERNATIONAL","INTL",.)
replace custname=subinword(custname,"MACH","MA",.)
replace custname=subinword(custname,"ANHEUSER-BUSCH","ANHEUSR-BSH",.)
replace custname=subinword(custname,"LOCKHEED MARTIN","LOCKHEED",.)
replace custname=subinword(custname,"LOCKHD MART","LOCKHEED",.)
replace custname=subinword(custname,"LABORATORIES","LABS",.)
replace custname=subinword(custname,"AMERICAN","",.)
replace custname=subinword(custname,"TECHNOLOGYOLD","TEC",.)
replace custname=subinword(custname,"TECHNOLOGY","TEC",.)
replace custname=subinword(custname,"HOSPITAL","HOSP",.)
replace custname=subinword(custname,"SUPPLY","SUP",.)
replace custname=subinword(custname,"PHILIP","PHIL",.)
replace custname=subinword(custname,"MORRIS","MOR",.)
replace custname=subinword(custname,"NORTHROP GRUMMAN","NORTHROP",.)
replace custname=subinword(custname,"LOWE'S COMPANIES","LOWES COS",.)
replace custname=subinword(custname,"MARIETTA","MRTA",.)
replace custname=subinword(custname,"MICROSYSTEMS","MICRO",.)
replace custname=trim(custname)
sort custname year
save resid1ready, replace
**got to AM motors

use ../data/firmchar
gen custname=conm
gen custgvkey=gvkey
gen offcompustatname=conm
gen year=fyear
replace custname=trim(custname)
replace custname=upper(custname)
replace custname=subinstr(custname,"AM TEL &TEL","AT&T",.)
replace custname=subinstr(custname,"-","",.)
replace custname=subinword(custname,"CL","",.)
replace custname=subinword(custname,"A","",.)
replace custname=subinword(custname,"HLDG","",.)
replace custname=subinword(custname,"WARD","WD",.)
replace custname=subinword(custname,"MONTGOMERY","MONTGMY",.)
replace custname=subinstr(custname,"PR","",.)
replace custname=subinword(custname,"CORP","",.)
replace custname=subinword(custname,"CO","",.)
replace custname=subinword(custname,"CP","",.)
replace custname=subinword(custname,"INC","",.)
replace custname=subinword(custname,"DAIMLERCHRYSLER","DAIMLER",.)
replace custname=subinword(custname,"AG","",.)
replace custname=subinword(custname,"COMPUTER","CMP",.)
replace custname=subinword(custname,"EASTMAN","EASTMN",.)
replace custname=subinword(custname,"KODAK","KODK",.)
replace custname=subinword(custname,"MACHINES","MA",.)
replace custname=subinword(custname,"BUSINESS","BUS",.)
replace custname=subinword(custname,"MACH","MA",.)
replace custname=subinword(custname,"EQUIPMENT","EQ",.)
replace custname=subinword(custname,"PROCTER","PRCTR",.)
replace custname=subinword(custname,"GAMBLE","GM",.)
replace custname=subinword(custname,"GENERAL","GEN",.)
replace custname=subinword(custname,"MOTORS","MTR",.)
replace custname=subinword(custname,"MOTOR","MTR",.)
replace custname=subinword(custname,"FUNDING","",.)
replace custname=subinword(custname,"(J C)","(JC)",.)
replace custname=subinword(custname,"DOUGLAS","DG",.)
replace custname=subinword(custname,"MCDONNELL","MCDONNEL",.)
replace custname=subinword(custname,"STORES","",.)
replace custname=subinword(custname,"EXXON MOBIL","EXXON",.)
replace custname=subinword(custname,"SPRINT NEXTEL","SPRINT",.)
replace custname=subinword(custname,"INSTRUMENTS","INSTR",.)
replace custname=subinword(custname,"TEXAS","TX",.)
replace custname=subinword(custname,"DU PONT (E I) DE NEMOURS","DUPONT (EI)",.)
replace custname=subinword(custname,"MICRO","MICR",.)
replace custname=subinword(custname,"TECHNOLOGIES","TECHS",.)
replace custname=subinword(custname,"UNITED","UTD",.)
replace custname=subinword(custname,"COMPUTER","CMP",.)
replace custname=subinword(custname,"RICHFIELD","RIC",.)
replace custname=subinword(custname,"INTERNATIONAL","INTL",.)
replace custname=subinword(custname,"MACH","MA",.)
replace custname=subinword(custname,"ANHEUSER-BUSCH","ANHEUSR-BSH",.)
replace custname=subinword(custname,"LOCKHEED MARTIN","LOCKHEED",.)
replace custname=subinword(custname,"LOCKHD MART","LOCKHEED",.)
replace custname=subinword(custname,"LABORATORIES","LABS",.)
replace custname=subinword(custname,"AMERICAN","",.)
replace custname=subinword(custname,"TECHNOLOGYOLD","TEC",.)
replace custname=subinword(custname,"TECHNOLOGY","TEC",.)
replace custname=subinword(custname,"HOSPITAL","HOSP",.)
replace custname=subinword(custname,"SUPPLY","SUP",.)
replace custname=subinword(custname,"PHILIP","PHIL",.)
replace custname=subinword(custname,"MORRIS","MOR",.)
replace custname=subinword(custname,"NORTHROP GRUMMAN","NORTHROP",.)
replace custname=subinword(custname,"LOWE'S COMPANIES","LOWES COS",.)
replace custname=subinword(custname,"MARIETTA","MRTA",.)
replace custname=subinword(custname,"MICROSYSTEMS","MICRO",.)
replace custname=trim(custname)
sort custname year
save firmcharready, replace

use resid1ready, clear
merge custname year using firmcharready
sort _merge
save temp_mergepieces, replace
keep if _merge==3
drop if custname==""
destring custgvkey, replace
rename gvkey supp_gvkey
keep year supp_gvkey custgvkey CSALE
save additional_pieces, replace
erase resid1ready.dta
erase firmcharready.dta
