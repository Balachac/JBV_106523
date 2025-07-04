
//Load data
odbc load, exec("select * from FTG2004")dsn("P0833") clear
keep P0833_Lopnr_PeOrgNr Org_BelKommun Org_Sni2002 Org_Typ Org_AntalSys Org_AntalPers Ftg_T18 Ftg_T26 Ftg_T27 Ftg_Nettoomsattning Ftg_Arets_resultat
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
sort Lopnr_PeOrgNr
gen year=2004
order Lopnr_PeOrgNr year
save "$data_path\Firms.dta", replace

forvalues i = 2005/2007 {
odbc load, exec("select * from FTG`i'")dsn("P0833") clear
keep P0833_Lopnr_PeOrgNr Org_BelKommun Org_Sni2002 Org_Typ Org_AntalSys Org_AntalPers Ftg_T18 Ftg_T26 Ftg_T27 Ftg_Nettoomsattning Ftg_Arets_resultat
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
sort Lopnr_PeOrgNr
gen year=`i'
order Lopnr_PeOrgNr year
append using "$data_path\Firms.dta"
save "$data_path\Firms.dta", replace
}
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Timur_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"

forvalues i = 2008/2014 {
odbc load, exec("select * from FTG`i'")dsn("P0833") clear
keep P0833_Lopnr_PeOrgNr Org_BelKommun Org_Sni2007 Org_Typ Org_AntalSys Org_AntalPers Ftg_T18 Ftg_T26 Ftg_T27 Ftg_Nettoomsattning Ftg_Arets_resultat
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
sort Lopnr_PeOrgNr
gen year=`i'
order Lopnr_PeOrgNr year
append using "$data_path\Firms.dta"
save "$data_path\Firms.dta", replace
}

forvalues i = 2015/2018 {
odbc load, exec("select * from FTG`i'")dsn("P0833") clear
keep P0833_Lopnr_PeOrgNr Org_BelKommun Org_SNI2007 Org_Typ Org_AntalSys Org_AntalPers Ftg_T18 Ftg_T26 Ftg_T27 Ftg_Nettoomsattning Ftg_Arets_resultat
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
ren Org_SNI2007 Org_Sni2007
sort Lopnr_PeOrgNr
gen year=`i'
order Lopnr_PeOrgNr year
append using "$data_path\Firms.dta"
save "$data_path\Firms.dta", replace
}

forvalues i = 2019/2020 {
odbc load, exec("select * from FTG`i'")dsn("P0833") clear
keep P0833_Lopnr_PeOrgNr Org_BelKommun Org_SNI2007 Org_Typ Org_AntalSys Org_AntalPers Ftg_T18 Ftg_T26 Ftg_T27 Ftg_Nettoomsattning Ftg_Arets_resultat
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
ren Org_SNI2007 Org_Sni2007
sort Lopnr_PeOrgNr
gen year=`i'
order Lopnr_PeOrgNr year
append using "$data_path\Firms.dta"
save "$data_path\Firms.dta", replace
}

**Label Variables**
label variable Lopnr_PeOrgNr "Organization number"
label variable year "year"
label variable Org_BelKommun "Municipality of largest site"
*label variable Org_SateKommun "Registered municipality"
label variable Org_Sni2002 "Industry classification 2002"
label variable Org_Sni2007 "Industry classification 2007"
*label variable Org_InstKod "Sector code"
*label variable Org_InstKod7 "Sector code (7 digits)"
*label variable Org_Sektorkod "Firm sector code"
label variable Org_Typ "Multiworkplace firm"
label variable Org_AntalSys "Number of employees"
label variable Org_AntalPers "Number of people with KU during the year"
label variable Ftg_T18 "Cash_Bank_shortterm investment per net turnover"
label variable Ftg_T26 "Gearing ratio per debt to equity ratio"
label variable Ftg_T27 "Profit margin"
label variable Ftg_Nettoomsattning "Net turnover"
label variable Ftg_Arets_resultat "Yearly result"
order Lopnr_PeOrgNr year Org_BelKommun Org_Sni2002 Org_Sni2007

save "$data_path\Firms.dta", replace

