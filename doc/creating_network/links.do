/*
Building links file
Two files needed: matched and additional_pieces
*/
clear all
set mem 300m

use matched
drop if custname==""
drop if custname=="ALLIED"
drop if custname=="TRANSMISSION"
drop if custname=="VENTURE"
drop if custname=="YORK"
drop if custname=="GENERATION"
drop if custname=="PWR"
drop if custname=="INTL"
drop if custname=="TECHNOLOGY"
drop if custname=="RM"
drop if custname=="TE"
drop if custname=="AL"
drop if custname=="ELT"
drop if custname=="ENERGY"
drop if custname=="LES"
drop if custname=="SPECIALTY"
drop if custname=="STEIN"
drop if custname=="WASHINGTON"
drop if custname=="F"
drop if custname=="G"
drop if custname=="GENERATION"
drop if custname=="MAR"
drop if custname=="NO"
drop if custname=="YORK"

rename gvkey supp_gvkey
save matched_pruned, replace
keep year supp_gvkey custgvkey CSALE
append using additional_pieces
save links, replace

*******
***Attach sales percentages to links file
*******

use links, clear
rename supp_gvkey gvkey
sort gvkey year
save templinks, replace

use ../data/firmchar, clear
rename fyear year
destring gvkey, replace
sort gvkey year
save tempfirmchar, replace

use templinks, replace
merge gvkey year using tempfirmchar

**Generate variable that is percentage of CSALE over total sales
gen per_total_sales=CSALE/sale
keep if _merge==3
rename gvkey supp_gvkey
keep year supp_gvkey CSALE custgvkey per_total_sales
save linkswper, replace

cap erase templinks
cap erase tempfirmchar
