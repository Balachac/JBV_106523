use "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl\Data\CPI Sweden.dta" 
//this data is based on 1980 base year. Splice the series to make 2004 as base year 
gen CPI_2004 = CPI if Ar==2004 //first, take the 2004 value of 1980 series
recode CPI_2004(.=0)
egen CPI_2004_ = max(CPI_2004)
drop CPI_2004
ren CPI_2004_ CPI_2004 //now we have a scalar with 2004 value of 1980 CPI series
gen CPI_2004base = CPI*CPI_2004/100 //create a new series with 2004 as base 
drop CPI_2004
//next, create a new variable that identifies the new CPI base year to multiply in the final equation
gen CPI_2004 = CPI_2004base if Ar==2004 //first, take the 2004 value of 1980 series
recode CPI_2004(.=0)
egen CPI_2004_ = max(CPI_2004)
drop CPI_2004
ren CPI_2004_ CPI_2004 //this is the CPI of base year in the 2004 series 
ren Ar year
