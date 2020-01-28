
/*******************************************************************************
	
	DESCRIPTION:	Cleaning company names -> Giving somewhat homogeneous names
					across datasets
	
	INFILES:	- any string variable with the name toClean
	
	OUTFILES:	- cleaned company name
	
	LOG: 		Created 03/12/2019
	
*******************************************************************************/

*White spaces, capital letters and punctuations
replace toClean = trim(toClean)
foreach word in "CORP" "INC" "LTD" ".COM" "PLC" " TRUST" " CO"{
	replace toClean = subinstr(toClean, " `word'", "", .)
	}

*Punctuation
strip toClean, of("'`!£$%^&*()-_+=][}{#;~@:/.,?><\|") gen(toClean2)
drop toClean
rename toClean2 toClean

*White space
replace toClean = subinstr(toClean, " ", "", .)

*Upper case
replace toClean=upper(toClean)

*From Atalay, Hortacsu, Roberts, and Syverson's code (2011)
