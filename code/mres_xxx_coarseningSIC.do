
/*******************************************************************************
	
	DESCRIPTION:	Transforning the sic codes into granular ones for 
					visualisation
	
	INFILES:	- file with sic integer variable
	
	OUTFILES:	- same file with new variable containing 10 coarse sectors
	
	LOG: 		Created 24/03/2020
	
*******************************************************************************/

gen tempSIC = floor(sic/100)

gen coarseSIC = 0 if tempSIC <=9												// Agriculture, forestry and fishing
replace coarseSIC = 1 if tempSIC >=10 & tempSIC<=14									// Mining
replace coarseSIC = 2 if tempSIC >=15 & tempSIC<=17									// Construction
replace coarseSIC = 3 if tempSIC >=20 & tempSIC<=39									// Manufacturing
replace coarseSIC = 4 if tempSIC >=40 & tempSIC<=49									// Transportation, communications, electric, gas, and sanitary services
replace coarseSIC = 5 if tempSIC >=50 & tempSIC<=51									// Wholesale trade
replace coarseSIC = 6 if tempSIC >=52 & tempSIC<=59									// Retail trade
replace coarseSIC = 7 if tempSIC >=60 & tempSIC<=67									// Finance, insurance and real estate
replace coarseSIC = 8 if tempSIC >=70 & tempSIC<=89									// Services
replace coarseSIC = 9 if tempSIC >=91 & tempSIC<=99									// Public administration






