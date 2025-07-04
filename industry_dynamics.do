//set up paths
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"


odbc load, exec("select * from FTG1997")dsn("P0833") clear
ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
keep Lopnr_PeOrgNr Ftg_Nettoomsattning Ftg_Arets_resultat Org_Sni92
gen year = 1997
tempfile firm_sales
save `firm_sales', replace

forvalues i = 1998/2001 {
	odbc load, exec("select * from FTG`i'")dsn("P0833") clear
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	keep Lopnr_PeOrgNr Ftg_Nettoomsattning Ftg_Arets_resultat Org_Sni92
	gen year = `i'
	append using `firm_sales'
	save `firm_sales', replace
}

forvalues i = 2002/2007 {
	odbc load, exec("select * from FTG`i'")dsn("P0833") clear
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	keep Lopnr_PeOrgNr Ftg_Nettoomsattning Ftg_Arets_resultat Org_Sni2002
	gen year = `i'
	append using `firm_sales'
	save `firm_sales', replace
}
forvalues i = 2008/2014 {
	odbc load, exec("select * from FTG`i'")dsn("P0833") clear
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	keep Lopnr_PeOrgNr Ftg_Nettoomsattning Ftg_Arets_resultat Org_Sni2007
	gen year = `i'
	append using `firm_sales'
	save `firm_sales', replace
}	
forvalues i = 2015/2020 {
	odbc load, exec("select * from FTG`i'")dsn("P0833") clear
	ren P0833_Lopnr_PeOrgNr Lopnr_PeOrgNr
	ren Org_SNI2007 Org_Sni2007
	keep Lopnr_PeOrgNr Ftg_Nettoomsattning Ftg_Arets_resultat Org_Sni2007
	gen year = `i'
	append using `firm_sales'
	save `firm_sales', replace
}


use `firm_sales', clear
capture drop siclevel
gen siclevel = 3
do "$script_path\sic.do"
tab orgSIC
drop if orgSIC == 13 | orgSIC==17 | orgSIC==19
lab def `level'SIC 1 "1.Mining" 2 "2.Manufacturing" 3 "3.Utility" 4 "4.Construction" 5 "5.Retail" 6 "6.Hotels and Restaurants" 7 "7.Transport" 8 "8.Inf. and Comm." 9 "9.Finance" ///
10 "10.Real Estate" 11 "11.Professional" 12 "12.Admin & Support Service" 14 "14.Education" ///
15 "15.Health & Social Work" 16 "16.Ent. & Recreation" 18 "18.Other service", modify 
label values orgSIC orgSIC

save `firm_sales', replace


* Def.1 munificence & dynamism (Bradley et al.)

foreach year of numlist 2003/2020 {
	di `year'
	use `firm_sales', clear
	sort orgSIC year
	keep if year>=`year'-5 & year<=`year'
	keep orgSIC year
	duplicates tag year orgSIC, gen(tag)
	by orgSIC: egen tag2=min(tag)
	drop if tag2<10
	drop tag*
	duplicates drop
	duplicates tag orgSIC, gen(tag)
	drop if tag<4
	drop tag
	merge 1:m orgSIC year using `firm_sales', keep(match)
	drop _merge
	replace year=`year'-year+1
	xtset Lopnr_PeOrgNr year
	egen group = group(orgSIC)
	gen growth_sales=.
	gen instability_sales=.
	sort group year
	tab year, gen(year)
	sum year
	local armax = r(max)
	levelsof group, local(levels)
	di "`levels'"
	foreach i of local levels {
		di `i'
		forvalues j = 2/`armax' {
			xtreg Ftg_Nettoomsattning year2-year`armax' if group==`i'
			replace growth_sales = (_b[year`j']) if year==`j' & group==`i'
			replace instability_sales = (_se[year`j']) if year==`j' & group==`i'
		}	
	}
	
	sort orgSIC
	forvalues j = 2/`armax' {
		by orgSIC: egen m_sales_`j' = mean(Ftg_Nettoomsattning) if year == `j'
	}
	
	gen m_sales = m_sales_2
	forvalues j = 3/`armax' {
		replace m_sales = m_sales_`j' if m_sales==.
	}
	drop m_sales_*

	gen growth_sales_avg=growth_sales/m_sales
	gen instability_sales_avg=instability_sales/m_sales

	egen ind_mun = filter(growth_sales_avg), lags(0/3) normalise
	egen ind_dyn = filter(instability_sales_avg), lags(0/3) normalise

	sort orgSIC
		by orgSIC : egen ind_mun_def1=mean(ind_mun)
		by orgSIC : egen ind_dyn_def1=mean(ind_dyn)

	keep if ind_mun != .
	keep orgSIC ind_mun_def1 ind_dyn_def1
	duplicates drop 
	gen year = `year'
	tempfile ind_var_`year'
	save `ind_var_`year'', replace
}

use `ind_var_2003', clear
append using `ind_var_2004' `ind_var_2005' `ind_var_2006' `ind_var_2007' `ind_var_2008' `ind_var_2009' `ind_var_2010' `ind_var_2011' `ind_var_2012' `ind_var_2013' `ind_var_2014' `ind_var_2015'  `ind_var_2016' `ind_var_2017' `ind_var_2018' `ind_var_2019' `ind_var_2020'
save "$data_path\ind_var_2003_2020", replace


capture {

/*
* generate profitability
cd "\\micro.intra\projekt\P0679$\P0679_bauma\00_variables\"
use "firm_sales.dta"
	keep if year>=2001
	sort year firm_sni4 
	by year firm_sni4 : egen ind_prof = mean(Ftg_Arets_resultat)
	keep firm_sni4 year ind_prof
	duplicates drop
	by year firm_sni4 : replace ind_prof = ln(ind_prof)
	merge 1:1 firm_sni4 year using ind_var
	drop _merge
save ind_var, replace
*/
}
* generate complexity

use `firm_sales', clear
	keep if year>=2003
	sort year orgSIC 
	by year orgSIC : egen ind_comp_temp = sum(Ftg_Nettoomsattning)
	by year orgSIC : replace ind_comp_temp = (Ftg_Nettoomsattning/ind_comp_temp)^2
	by year orgSIC : egen ind_comp = sum(ind_comp_temp)
	keep ind_comp orgSIC year
	duplicates drop 
	merge 1:1 orgSIC year using "$data_path\ind_var_2003_2020", keep(match)
	drop _merge
save "$data_path\ind_var_2003_2020", replace

