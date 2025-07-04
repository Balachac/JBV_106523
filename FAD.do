
clear all
//identify new firms
odbc load, exec("select * from FAD_FORETAG2004")dsn("P0833") clear
ren P0833_LopNr_PeOrgNr2 Lopnr_PeOrgNr 
gen year=2004
keep P0833_LopNr_FAD_F_ID Lopnr_PeOrgNr Ar_Ny year Kvar
save "$data_path\firm_dynamics", replace

forvalues i = 2005/2020 {
	odbc load, exec("select * from FAD_FORETAG`i'")dsn("P0833") clear
	ren P0833_LopNr_PeOrgNr2 Lopnr_PeOrgNr
	gen year=`i'
	keep P0833_LopNr_FAD_F_ID Lopnr_PeOrgNr Ar_Ny year Kvar
	append using "$data_path\firm_dynamics"
	save "$data_path\firm_dynamics", replace
}
//identify firm dissolution
odbc load, exec("select * from FAD_NEDL_FTG2004")dsn("P0833") clear
gen year = 2004
ren P0833_LopNr_FAD_F_Id P0833_LopNr_FAD_F_ID
keep P0833_LopNr_FAD_F_ID Kvar year
tab Kvar
keep if Kvar == "10" | Kvar == "20" | Kvar == "30"  | Kvar == "50" | Kvar == "60" | Kvar == "70" | Kvar == "80" | Kvar == "90"
gduplicates report P0833_LopNr_FAD_F_ID
gduplicates drop P0833_LopNr_FAD_F_ID, force
merge 1:1 P0833_LopNr_FAD_F_ID year using "$data_path\firm_dynamics"
drop _merge
save "$data_path\firm_dynamics", replace

forvalues i = 2005/2020 {
	odbc load, exec("select * from FAD_NEDL_FTG`i'")dsn("P0833") clear
	gen year=`i'
	ren P0833_LopNr_FAD_F_Id P0833_LopNr_FAD_F_ID
	keep P0833_LopNr_FAD_F_ID Kvar year
	tab Kvar
	gduplicates report P0833_LopNr_FAD_F_ID
	gduplicates drop P0833_LopNr_FAD_F_ID, force
	merge 1:1 P0833_LopNr_FAD_F_ID year using "$data_path\firm_dynamics"
	drop _merge
	save "$data_path\firm_dynamics", replace
}
use "$data_path\firm_dynamics", clear
sort P0833_LopNr_FAD_F_ID year
replace Lopnr_PeOrgNr= Lopnr_PeOrgNr[_n-1] if Lopnr_PeOrgNr==. & P0833_LopNr_FAD_F_ID== P0833_LopNr_FAD_F_ID[_n-1]
drop if Lopnr_PeOrgNr==.
save "$data_path\firm_dynamics", replace

