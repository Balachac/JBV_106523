global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"

//variables to import
odbc load, exec("select * from individ_2004")dsn("P0833") clear
keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod ///
	AstSNI2002 AntFlyttTot Civil FamStF SenInvAr Sun2000niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk3 ///
	AstKommun KU1Ink KU2Ink KU3Ink KU1YrkStalln KU2YrkStalln KU3YrkStalln LoneInk KapInk OpFtgLedare
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
ren P0833_Lopnr_CfarNr Lopnr_CfarNr
ren P0833_Lopnr_FamId Lopnr_FamId
sort Lopnr_PersonNr
gen year=2004
order Lopnr_PersonNr year
save "$data_path\Individuals.dta", replace

forvalues i = 2005/2007 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod ///
	AstSNI2002 AntFlyttTot Civil FamStF SenInvAr Sun2000niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk4 ///
	AstKommun KU1Ink KU2Ink KU3Ink KU1YrkStalln KU2YrkStalln KU3YrkStalln LoneInk KapInk OpFtgLedare
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren P0833_Lopnr_CfarNr Lopnr_CfarNr
	ren P0833_Lopnr_FamId Lopnr_FamId
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using "$data_path\Individuals.dta"
	save "$data_path\Individuals.dta", replace
}

forvalues i = 2008/2013 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod ///
	AstSNI2007 AntFlyttTot Civil FamStF SenInvAr Sun2000niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk4 ///
	AstKommun KU1Ink KU2Ink KU3Ink KU1YrkStalln KU2YrkStalln KU3YrkStalln LoneInk KapInk OpFtgLedare
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren P0833_Lopnr_CfarNr Lopnr_CfarNr
	ren P0833_Lopnr_FamId Lopnr_FamId
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using "$data_path\Individuals.dta"
	save "$data_path\Individuals.dta", replace
}

forvalues i = 2014/2015 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod ///
	AstSNI2007 AntFlyttTot Civil FamStF SenInvAr Sun2000niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk4_2012 ///
	AstKommun KU1Ink KU2Ink KU3Ink KU1YrkStalln KU2YrkStalln KU3YrkStalln LoneInk KapInk OpFtgLedare
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren P0833_Lopnr_CfarNr Lopnr_CfarNr
	ren P0833_Lopnr_FamId Lopnr_FamId
	ren Ssyk4_2012 Ssyk4
	destring LoneInk, replace //LoneInk string in 2016
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using "$data_path\Individuals.dta"
	save "$data_path\Individuals.dta", replace
}

forvalues i = 2017/2018 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod ///
	AstSNI2007 AntFlyttTot Civil FamStF SenInvAr Sun2000niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk4_2012_J16 ///
	AstKommun KU1Ink KU2Ink KU3Ink KU1YrkStalln KU2YrkStalln KU3YrkStalln LoneInk KapInk OpFtgLedareJ
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren P0833_Lopnr_CfarNr Lopnr_CfarNr
	ren P0833_Lopnr_FamId Lopnr_FamId
	ren Ssyk4_2012_J16 Ssyk4
	ren OpFtgLedareJ OpFtgLedare
	destring LoneInk KapInk KU1Ink KU2Ink KU3Ink, replace
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using "$data_path\Individuals.dta"
	save "$data_path\Individuals.dta", replace
}

forvalues i = 2019/2020 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PeOrgNr P0833_Lopnr_CfarNr P0833_Lopnr_FamId FodelseAr Alder Kon Kommun InstKod AstSNI2007 AntFlyttTot 	Civil FamStF SenInvAr Sun2020niva Sun2000Inr Sun2000Grp ExamAr YrkStalln YrkStallnKomb Ssyk4_2012_J16 AstKommun LoneInk KapInk OpFtgLedareJ
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren P0833_Lopnr_CfarNr Lopnr_CfarNr
	ren P0833_Lopnr_FamId Lopnr_FamId
	ren Ssyk4_2012_J16 Ssyk4
	ren OpFtgLedareJ OpFtgLedare
	destring LoneInk KapInk, replace
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using "$data_path\Individuals.dta"
	save "$data_path\Individuals.dta", replace
}

label variable Lopnr_PersonNr "Personal number"
label variable year "Year"
label variable Lopnr_PeOrgNr "Org. number"
label variable Lopnr_CfarNr "Workplace number"
label variable Lopnr_FamId "Family ID"
label variable FodelseAr "Year of birth"
label variable Alder "Age"
label variable Kon "Gender"
label variable Kommun "Municipality of residence"
*label variable Forsamling "Parish residency (church)"
label variable AntFlyttTot "Geographic mobility (count)"
label variable Civil "Marital status"
label variable FamStF "Family status"
label variable SenInvAr "Year of immigration"
*label variable FodelseLan "County of birth"
*label variable MedbGrEg "Citizenship EU15"
label variable Sun2000niva "Highest degree (post2000)"
label variable Sun2020niva "Highest degree (post2018)"
label variable Sun2000Inr "Disciplinary focus"
label variable Sun2000Grp "Education group"
label variable ExamAr "Year of highest degree"
*label variable SyssStat "Employment Status 1993-2003"
label variable YrkStalln "Professional status"
label variable YrkStallnKomb "Multiple professional status"
label variable AstKommun "Workplace municipality"
*label variable InstKod "Sector_Ownership_Legal_code"
label variable AstSNI2002 "Industry classification 2002"
label variable KU1Ink "Income from the primary source"
label variable KU1YrkStalln "Primary source of income"
label variable KU2Ink "Income from the secondary source"
label variable KU2YrkStalln "Secondary source of income"
label variable KU3Ink "Income from tertiary source"
label variable KU3YrkStalln "Tertiary source of income"
label variable LoneInk "Gross wage"
label variable KapInk "Income from captial"
label variable Ssyk3 "Occupational code (SSYK 3 digit)"
label variable Ssyk4 "Occupational code (SSYK 4 digit)"
lab var OpFtgLedare "CEO"

save "$data_path\Individuals.dta", replace


//Import partner data and merge with Individuals.dta (also in familyties.do)
odbc load, exec("select * from Partner_2004")dsn("P0833") clear
keep P0833_Lopnr_PersonNr P0833_Lopnr_PersonNr_Partner
ren P0833_Lopnr_PersonNr_Partner LopNr_Partner
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
sort Lopnr_PersonNr
gen year=2004
order Lopnr_PersonNr year
tempfile partner
save `partner', replace

forvalues i = 2005/2020 {
	odbc load, exec("select * from Partner_`i'")dsn("P0833") clear
	keep P0833_Lopnr_PersonNr P0833_Lopnr_PersonNr_Partner
	ren P0833_Lopnr_PersonNr_Partner LopNr_Partner
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	sort Lopnr_PersonNr
	gen year=`i'
	order Lopnr_PersonNr year
	append using `partner'
	save `partner', replace
}
use "$data_path\Individuals.dta", clear
merge 1:m Lopnr_PersonNr year using  `partner', keep(match)
drop _merge
save "$data_path\Individuals.dta", replace

clear

