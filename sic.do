

if siclevel == 1 {
    //replace AstSNI2002 = AstSNI2007. Most changes in SNI occurs to disaggregated level of coding
    replace AstSNI2002 = AstSNI2007 if year>=2008 & AstSNI2002== ""
	local sic AstSNI2002
	local level ast
}
else if siclevel==2 {
	replace Org_Sni2002 = Org_Sni2007 if year>=2008 & Org_Sni2002== ""
	//Most changes in SNI occurs to disaggregated level of coding
	local sic Org_Sni2002
	local level org
}
else if siclevel==3 {
    replace Org_Sni2002 = Org_Sni92 if  year<=2001 & Org_Sni2002== "" //this code applies to industry_dynamics.do
	replace Org_Sni2002 = Org_Sni2007 if year>=2008 & Org_Sni2002== ""
	//Most changes in SNI occurs to disaggregated level of coding
	local sic Org_Sni2002
	local level org
}
else {
	di "check code!"
}
//GENERATE SIC CODES

capture drop `level'SIC

gen `level'SIC=1 if (real(substr(`sic',1,2))>=10& real(substr(`sic',1,2))<=14) //Mining and Quarrying

replace `level'SIC=2 if (real(substr(`sic',1,2))>=15 & real(substr(`sic',1,2))<=37) & `level'SIC==. //Manufacturing

replace `level'SIC=3 if (real(substr(`sic',1,2))==40 | real(substr(`sic',1,2))==41 | real(substr(`sic',1,2))==90) & `level'SIC==. //Utility

replace `level'SIC=4 if real(substr(`sic',1,2))==45 & `level'SIC==. //Construction

replace `level'SIC=5 if (real(substr(`sic',1,2))==50|real(substr(`sic',1,2))==51|real(substr(`sic',1,2))==52) & `level'SIC==. //Retail

replace `level'SIC=6 if real(substr(`sic',1,2))==55 & `level'SIC==. //Hotels and Restaurants

replace `level'SIC=7 if (real(substr(`sic',1,2))==60|real(substr(`sic',1,2))==61|real(substr(`sic',1,2))==62|real(substr(`sic',1,2))==63) & `level'SIC==. //Transport

replace `level'SIC=8 if real(substr(`sic',1,2))==64 & `level'SIC==. //Information and Communication

replace `level'SIC=9 if (real(substr(`sic',1,2))==65|real(substr(`sic',1,2))==66|real(substr(`sic',1,2))==67) & `level'SIC==. //Finance

replace `level'SIC=10 if real(substr(`sic',1,2))==70 & `level'SIC==. //real estate

replace `level'SIC=11 if (real(substr(`sic',1,3))>=721) & (real(substr(`sic',1,3))<=744) & `level'SIC==. //Professional, Scientific and Technical
replace `level'SIC=11 if (real(substr(`sic',1,5))>=74811) & (real(substr(`sic',1,5))<=74814) & `level'SIC==. //Professional, Scientific and Technical
replace `level'SIC=11 if (real(substr(`sic',1,5))==74871) & (real(substr(`sic',1,5))==74872) & `level'SIC==. //Professional, Scientific and Technical
replace `level'SIC=11 if (real(substr(`sic',1,2))>=69 & real(substr(`sic',1,2))<=75) & `level'SIC==. //Professional, Scientific and Technical

replace `level'SIC=12 if (real(substr(`sic',1,3))>=711) & (real(substr(`sic',1,3))<=714) & `level'SIC==. //Admin & Support service
replace `level'SIC=12 if (real(substr(`sic',1,3))>=745) & (real(substr(`sic',1,3))<=747) & `level'SIC==. //Admin & Support service
replace `level'SIC=12 if (real(substr(`sic',1,4))>=7482) & (real(substr(`sic',1,4))<=7486) & `level'SIC==. //Admin & Support service
replace `level'SIC=12 if (real(substr(`sic',1,5))>=74873) & (real(substr(`sic',1,5))<=74879) & `level'SIC==. //Admin & Support service

replace `level'SIC=13 if real(substr(`sic',1,2))==75 & `level'SIC==. //Public Administration, Defense and Social Security
replace `level'SIC=13 if real(substr(`sic',1,2))==84 & `level'SIC==. //Public Administration, Defense and Social Security

replace `level'SIC=14 if real(substr(`sic',1,2))==80 & `level'SIC==. //Education
replace `level'SIC=14 if real(substr(`sic',1,2))==85 & `level'SIC==. //Education

replace `level'SIC=15 if real(substr(`sic',1,2))==85 & `level'SIC==. //Health and Social Work
replace `level'SIC=15 if (real(substr(`sic',1,2))>=86&real(substr(`sic',1,2))<=88) & `level'SIC==. //Health and Social Work

replace `level'SIC=16 if (real(substr(`sic',1,5))>=92110) & (real(substr(`sic',1,5))<=92729) & `level'SIC==. //Arts, Entertainment and Recreation
replace `level'SIC=16 if (real(substr(`sic',1,2))>=90) & (real(substr(`sic',1,2))<=93) & `level'SIC==. //Arts, Entertainment and Recreation

replace `level'SIC=17 if real(substr(`sic',1,2))==91 & `level'SIC==. //Associations, Trade Unions, Religious & Political Organisations
replace `level'SIC=17 if real(substr(`sic',1,2))==94 & `level'SIC==. //Associations, Trade Unions, Religious & Political Organisations

replace `level'SIC=18 if (real(substr(`sic',1,5))>=93011) & (real(substr(`sic',1,5))<=93050) & `level'SIC==. //Other service activities
replace `level'SIC=18 if real(substr(`sic',1,2))==95 & `level'SIC==. //Other service activities

replace `level'SIC=19 if `level'SIC==. //NEC

lab def `level'SIC 1 "1.Mining" 2 "2.Manufacturing" 3 "3.Utility" 4 "4.Construction" 5 "5.Retail" 6 "6.Hotels and Restaurants" 7 "7.Transport" 8 "8.Inf. and Comm." 9 "9.Finance" ///
10 "10.Real Estate" 11 "11.Professional" 12 "12.Admin & Support Service" 13 "13.PA, Def. & Social Security" 14 "14.Education" ///
15 "15.Health & Social Work" 16 "16.Ent. & Recreation" 17 "17.Non-Profit Assc." 18 "18.Other service" 19 "19.NEC", modify 
label values `level'SIC `level'SIC

drop siclevel
