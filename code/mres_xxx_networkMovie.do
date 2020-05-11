

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
global data "$wd/data/006_network&Markups"
global outputs "$wd/outputs"
global doc "$wd/doc"
global code "$wd/code"
global log "$wd/log"
global DLEU "$orig/Data DLEU"

*Movie
use "$wd/data/001_network/003_fullNet1980.dta", clear
nwset Source Target Weight, name(fullNet1980) edgelist
nwsummarize fullNet1980
use "$wd/data/001_network/003_fullNet1983.dta", clear
nwset Source Target Weight, name(fullNet1983) edgelist
nwsummarize fullNet1983
use "$wd/data/001_network/003_fullNet1986.dta", clear
nwset Source Target Weight, name(fullNet1986) edgelist
nwsummarize fullNet1986

nwmovie fullNet1980 fullNet1983 fullNet1986
