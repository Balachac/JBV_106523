
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"

odbc load P0833_LopNr_PersonNr P0833_LopNr_PeOrgNr StatusF Faman YrkStallnKU LonFInk, exec("select * from JOBB2004")dsn("P0833") clear
gen year=2004
destring LonFInk, replace
tempfile job 
save `job'

forvalues i = 2005/2009 {
	odbc load P0833_LopNr_PersonNr P0833_LopNr_PeOrgNr StatusF Faman YrkStallnKU LonFInk, exec("select * from JOBB`i'")dsn("P0833") clear
	gen year= `i'
	destring LonFInk, replace
	append using `job'
	save `job', replace
}

forvalues i = 2010/2018 {
	odbc load P0833_LopNr_PersonNr P0833_LopNr_PeOrgNr StatusF YrkStallnKU LonFInk, exec("select * from JOBB`i'")dsn("P0833") clear
	gen year= `i'
	destring LonFInk, replace
	append using `job'
	save `job', replace
}

forvalues i = 2019/2020 {
	odbc load P0833_LopNr_PersonNr P0833_LopNr_PeOrgNr StatusF YrkStallnAGI ArsLonFInk, exec("select * from JOBB`i'")dsn("P0833") clear
	gen year= `i'
	tostring YrkStallnAGI, replace
	ren YrkStallnAGI YrkStallnKU
	ren ArsLonFInk LonFInk
	destring LonFInk, replace
	append using `job'
	save `job', replace
}

ren P0833_LopNr_PersonNr Lopnr_PersonNr
ren P0833_LopNr_PeOrgNr Lopnr_PeOrgNr
sort Lopnr_PersonNr year Lopnr_PeOrgNr 
order Lopnr_PersonNr year Lopnr_PeOrgNr 
save "$data_path\job", replace