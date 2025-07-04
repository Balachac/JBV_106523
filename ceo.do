
//set up paths
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"

//Get CEO data from board data 
use Lopnr_PersonNr Lopnr_PeOrgNr year CEO Kon using "$data_path\Board_micro" if CEO==1
gduplicates report Lopnr_PeOrgNr year
gduplicates drop Lopnr_PeOrgNr year, force //there are 72 firms with two CEOs - drop them for simplicity
drop CEO 

//next code country of origin, gender, age, education, industry, occupation 
//gender
gen ceo_female=1 if Kon=="2"
replace ceo_female=. if Kon==" "
recode ceo_female(.=0)
lab var ceo_female "CEO is a female" 

//get the other background data from lisa data
frame create background
cwf background
use "$data_path\Individuals", clear
keep Lopnr_PersonNr Lopnr_PeOrgNr year Alder Civil SenInvAr FodelseAr Sun2000niva Ssyk3 AstSNI2002 AstSNI2007
gduplicates drop Lopnr_PersonNr year, force
mdesc Alder FodelseAr

//Age
mdesc Alder FodelseAr
destring FodelseAr, replace
replace Alder = year-FodelseAr if Alder==.
gen ceo_age=Alder
lab var ceo_age "Age of the CEO"

//education of CEOs

/*LESS THAN OR EQUAL TO 11: 1
12 Ars: 2
>12 AND <=15 : 3
GREATER THAN (>)15: 4
*/

gen edulevel=1 if substr(Sun2000niva,1,2)=="00" | substr(Sun2000niva,1,2)=="10" | substr(Sun2000niva,1,2)=="20" | substr(Sun2000niva,1,2)=="31" | substr(Sun2000niva,1,2)=="32"
replace edulevel=2 if substr(Sun2000niva,1,2)=="33"
replace edulevel=3 if substr(Sun2000niva,1,2)=="41" | substr(Sun2000niva,1,2)=="52" | substr(Sun2000niva,1,2)=="53" | substr(Sun2000niva,1,2)=="54" | substr(Sun2000niva,1,2)=="55"
replace edulevel=4 if substr(Sun2000niva,1,2)=="60" | substr(Sun2000niva,1,2)=="62" | substr(Sun2000niva,1,2)=="64"
//FOLLOWING CODE CORRECTS EDUCATION LEVELS 
tsset Lopnr_PersonNr year

tsspell Lopnr_PeOrgNr

egen spell=group(Lopnr_PersonNr Lopnr_PeOrgNr)

bys spell: egen maxedulevel=max(edulevel)

bys spell: egen edu1count=count(edulevel) if edulevel==1
bys spell: egen edu1countmax=max(edu1count)

bys spell: egen edu2count=count(edulevel) if edulevel==2
bys spell: egen edu2countmax=max(edu2count)

bys spell: egen edu3count=count(edulevel) if edulevel==3
bys spell: egen edu3countmax=max(edu3count)

bys spell: egen edu4count=count(edulevel) if edulevel==4
bys spell: egen edu4countmax=max(edu4count)

replace edu4countmax=0 if edu4countmax==. 
replace edu3countmax=0 if edu3countmax==. 
replace edu2countmax=0 if edu2countmax==. 
replace edu1countmax=0 if edu1countmax==. 

replace edulevel=1 if edu1countmax>=edu2countmax & edu1countmax>=edu3countmax & edu1countmax>=edu4countmax 
replace edulevel=2 if edu2countmax>=edu1countmax & edu2countmax>=edu3countmax & edu2countmax>=edu4countmax
replace edulevel=3 if edu3countmax>=edu2countmax & edu3countmax>=edu1countmax & edu3countmax>=edu4countmax
replace edulevel=4 if edu4countmax>=edu3countmax & edu4countmax>=edu2countmax & edu4countmax>=edu1countmax 
 
drop maxedulevel edu1count edu1countmax edu2count edu2countmax edu3count edu3countmax edu4count edu4countmax

forvalues  i=1/4 {
gen edu`i'=1 if edulevel==`i'
replace edu`i'=0 if edu`i'==.
}
replace edu1=. if edulevel==.
replace edu2=. if edulevel==.
replace edu3=. if edulevel==.
replace edu4=. if edulevel==.
ren edu1 ceo_edu1
lab var ceo_edu1 "Education<12 years"
ren edu2 ceo_edu2
lab var ceo_edu2 "Education=12 years"
ren edu3 ceo_edu3
lab var ceo_edu3 "Education >12, <=15 years"
ren edu4 ceo_edu4
lab var ceo_edu4 "Education>=16 years"
ren edulevel ceo_edulevel

//primary industry of CEO
gen siclevel=1
do "$script_path\sic"
ren astSIC ceo_SIC
lab var ceo_SIC "CEO's SIC"

//3. Industry experience of ceo
do "$script_path\LM experience" 
ren IndExp ceo_IndExp
lab var ceo_IndExp "CEO's experience in focal industry"

/*construct prior entrepreneurial experience of ceo from individual data*/
preserve
odbc load, exec("select * from individ_1990")dsn("P0833") clear
gen year= 1990
keep P0833_Lopnr_PersonNr year YrkStalln
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
sort Lopnr_PersonNr year
destring YrkStalln, replace
tempfile entexp
save `entexp', replace

forvalues i = 1991/2020 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	gen year=`i'
	keep P0833_Lopnr_PersonNr year YrkStalln
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr	
	sort Lopnr_PersonNr year
	destring YrkStalln, replace
	append using `entexp'
	save `entexp', replace
}
gen ENTexp=0 
replace ENTexp=1 if YrkStalln==4|YrkStalln==5
bysort Lopnr_PersonNr (year): replace ENTexp=sum(ENTexp)
duplicates report Lopnr_PersonNr year
duplicates drop Lopnr_PersonNr year, force
drop if year<2004
save `entexp', replace
restore

merge m:1 Lopnr_PersonNr year using `entexp'
drop if _merge == 2
drop _merge
ren ENTexp ceo_ENTexp
lab var ceo_ENTexp "CEO's entrepreneurship experience"

preserve
//CEO country of origin
odbc load, exec("select * from Fodelseland")dsn("P0833") clear
ren P0833_LopNr_PersonNr Lopnr_PersonNr
duplicates drop Lopnr_PersonNr, force
sort Lopnr_PersonNr
destring FodGrEg3, replace
replace FodGrEg3=11 if FodGrEg3==.
ren FodGrEg3 ceo_greg3
tempfile greg3
save `greg3', replace

restore 
merge m:1 Lopnr_PersonNr using `greg3'
drop if _merge==2
drop _merge

//match with ceo data
cwf default
frlink m:1 Lopnr_PersonNr year, frame(background)
frget ceo_age ceo_edulevel ceo_SIC ceo_IndExp ceo_ENTexp ceo_greg3, from(background)
mdesc ceo_age ceo_female ceo_edulevel ceo_SIC ceo_IndExp ceo_ENTexp ceo_greg3
gunique Lopnr_PersonNr, by(Lopnr_PeOrgNr year) gen(n_ceos)
tab n_ceos 

lab var ceo_age "Age of CEO"
lab var ceo_female "CEO is female"
lab var ceo_edulevel "CEO's educational level"
lab var ceo_SIC "CEO's industry" 
lab var ceo_IndExp "CEO's industry experience"
lab var ceo_ENTexp "CEO's entrepreneurship experience"
lab var ceo_greg3 "CEO's country of origin"

frame drop background
drop background
frame dir
save "$data_path\ceo", replace