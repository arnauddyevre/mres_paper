
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
global data "$wd/data"
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
	DATA CLEANING
*******************************************************************************/

*Keeping only supplier firms who have financial data
*use "$data/001_network/001_supplierList.dta", clear
*merge 1:1 gvkey comp using "$data/001_network/001_companyList_6119.dta"
*KEEPING ALL firms for now

*Exact merge
use "$data/001_network/001_customerList.dta", clear
merge 1:m comp using "$data/001_network/001_supplierList.dta"					// 1 to many merge as several companies in Compustat have the same name but different Gvkeys 
		//4.1% merge 


		

log close
