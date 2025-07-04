
//Load data from SQL
odbc load, exec("select * from OpF_Funk_2004")dsn("P0833") clear
gen year=2004
tempfile Board_micro
save `Board_micro', replace
forvalues i = 2005/2020 {
	odbc load, exec("select * from OpF_Funk_`i'")dsn("P0833") clear
	gen year=`i'
	append using `Board_micro'
	save `Board_micro', replace
}

frame create points
frame change points
odbc load, exec("select * from OPF_2004")dsn("P0833") clear
gen year=2004
tempfile points
save `points', replace
forvalues i = 2005/2020 {
	odbc load, exec("select * from OPF_`i'")dsn("P0833") clear
	gen year=`i'
	append using `points'
	save `points', replace
}
replace AntalSyss= AntalSysC if AntalSyss==.
replace P0833_Lopnr_PeorgNr = P0833_Lopnr_PeOrgNr if P0833_Lopnr_PeorgNr==.
ren FtgSni02 Org_Sni2002
ren FtgSni07 Org_Sni2007
keep P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year Poang SektorKod AntalSyss Org_Sni2002 Org_Sni2007
mdesc AntalSyss Org_Sni2002 Org_Sni2007
order P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year Poang SektorKod AntalSyss Org_Sni2002 Org_Sni2007

frame change default
gduplicates report P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year
gduplicates drop
gduplicates report P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year // there is one duplicate observation with a member coded as both regular and deputy member
gduplicates tag P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year, gen(dup)
drop if dup == 1 & Funk1 == "SU"
gduplicates report P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year
drop dup
frlink 1:1 P0833_Lopnr_PersonNr P0833_Lopnr_PeorgNr year, frame(points)
frget Poang SektorKod AntalSyss Org_Sni2002 Org_Sni2007, from(points)
frame drop points

ren P0833_Lopnr_PersonNr Lopnr_PersonNr
ren P0833_Lopnr_PeorgNr Lopnr_PeOrgNr
duplicates drop Lopnr_PersonNr Lopnr_PeOrgNr year, force

//convert Poang to string and harmonize the string length
tostring Poang, replace
gen length = strlen(Poang)
replace Poang = "000000"+Poang if length==1
replace Poang = "00000"+Poang if length==2
replace Poang = "0000"+Poang if length==3
replace Poang = "000"+Poang if length==4
replace Poang = "00"+Poang if length==5
replace Poang = "0"+Poang if length==6


//label
/*	VD/EVD: President/CEO (1 000 000/100 000/ 10 000)
	Partner (1 000)
	VVD/EVVD: Vice President/Executive Vice President (800)
	OF: Chairperson (700)
	VOF: Vice Chairperson (600)
	VLE: Executive director (500)
	LE: Director (400)
	EFT: External authorized signatory (300)
	DELG: Legal counsel (200)
	SU: Deputy member (100)
	AK: Unknown and irrelevant (only 4 data points)
*/

gen CEO= cond((Funk1=="VD" | Funk2=="VD" | Funk3=="VD") | (Funk1=="EVD" | Funk2=="EVD" | Funk3=="EVD") ///
	| (substr(Poang,-7,1) == "1" | substr(Poang,-6,1) == "1" | substr(Poang,-5,1) == "1"),1,0)
lab var CEO "CEO/President"

gen Partner = cond(substr(Poang,-4,1) == "1",1,0)
lab var Partner "Partner in the company"

gen VP= cond((Funk1=="VVD" | Funk2=="VVD" | Funk3=="VVD") | (Funk1=="EVVD" | Funk2=="EVVD" | Funk3=="EVVD") | (substr(Poang,-3,1) == "8"),1,0)
lab var VP "Vice CEO/President"

gen Chair= cond((Funk1=="OF" | Funk2=="OF" | Funk3=="OF") | (substr(Poang,-3,1) == "7"),1,0)
lab var Chair "Chair Person"

gen ViceChair= cond(Funk1=="VOF" | Funk2=="VOF" | Funk3=="VOF" | substr(Poang,-3,1) == "6",1,0)
lab var ViceChair "Vice Chair Person"

gen ED= cond(Funk1=="VLE" | Funk2=="VLE" | Funk3=="VLE" | substr(Poang,-3,1) == "5",1,0) 
lab var ED "Executive Director"

gen Director= cond(Funk1=="LE" | Funk2=="LE" | Funk3=="LE" | substr(Poang,-3,1) == "4",1,0)
lab var Director "Director in the company"

gen Signatory= cond(Funk1=="EFT" | Funk2=="EFT" | Funk3=="EFT" | substr(Poang,-3,1) == "3",1,0)
lab var Signatory "External authorized signatory"

gen Counsel= cond(Funk1=="DELG" | Funk2=="DELG" | Funk3=="DELG" | substr(Poang,-3,1) == "2",1,0)
lab var Counsel "Legal counsel"

gen Deputy= cond(Funk1=="SU" | Funk2=="SU" | Funk3=="SU" | substr(Poang,-3,1) == "1",1,0)
lab var Deputy "Deputy Member"

keep Lopnr_PersonNr Lopnr_PeOrgNr year Kon CEO Partner VP Chair ViceChair ED Director Signatory Counsel Deputy SektorKod FtgSni07 
drop if Signatory | Counsel | Deputy 
drop Signatory Counsel Deputy

gen D_executive = cond((Director==1 & (Partner ==1 | CEO==1 | VP==1 | Chair==1 | ViceChair==1 | ED==1)),1,0)
tab D_executive
lab var D_executive "Executive director"
gen NED = cond(Director==1 & D_executive==0,1,0)
tab NED
lab var NED "Non-Executive Director"

save "$data_path\Board_micro", replace
