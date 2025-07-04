
preserve

*Labor market experience
odbc load, exec("select * from individ_1990")dsn("P0833") clear
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
keep Lopnr_PersonNr AstSNI92 
sort Lopnr_PersonNr
gen year=1990
order Lopnr_PersonNr year
tempfile experience
save `experience', replace
forvalues i = 1991/2001 {
    odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	keep Lopnr_PersonNr AstSNI92 
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using `experience'
	save `experience', replace
}
forvalues i = 2002/2007 {
    odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	keep Lopnr_PersonNr AstSNI2002 
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using `experience'
	save `experience', replace
}
forvalues i = 2008/2018 {
    odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	keep Lopnr_PersonNr AstSNI2007 
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using `experience'
	save `experience', replace
}

use `experience', clear
bysort Lopnr_PersonNr: gen LabExp=_n
lab var LabExp "Labor force experience"

*Industry experience
gen sni92=real(substr(AstSNI92, 1,2))
gen sni2002=real(substr(AstSNI2002, 1,2))
gen sni2007 = real(substr(AstSNI2007,1,2))
gen sni=sni92 if year<2002
replace sni=sni2002 if year >=2002 & year<=2007
replace sni=sni2007 if year >=2008
drop AstSNI92 sni92 AstSNI2002 sni2002
duplicates drop Lopnr_PersonNr year, force
bysort Lopnr_PersonNr sni: gen IndExp=_n
replace IndExp=. if sni==0 | sni==.
lab var IndExp "Experience in focal industry"
keep Lopnr_PersonNr year LabExp IndExp
drop if year<2004
save `experience', replace

restore 

merge m:1 Lopnr_PersonNr year using `experience', keep(match)
drop _merge
