

//age and gender of founders 
use "$data_path\founders", clear
keep Lopnr_PersonNr
gduplicates drop
tempfile founderlist
save `founderlist', replace

use Lopnr_PersonNr Lopnr_PeOrgNr year Alder Kon Civil SenInvAr FodelseAr Sun2000niva Ssyk3 AstSNI2002 AstSNI2007 YrkStalln using "$data_path\Individuals", clear
keep if year>=2004
merge m:1 Lopnr_PersonNr using `founderlist', keep(match) //this will keep only founders in the data
drop _merge

//Age
//impute missing values of age
bysort Lopnr_PersonNr: replace Alder=Alder[_n-1]+1 if Alder==. /*impute missing values of age*/
bysort Lopnr_PersonNr: replace Alder=Alder[_n+1]-1 if Alder==. /*impute missing values of age*/
gen F_age=Alder
lab var F_age "Age of the founder"

//gender
gen F_Female=1 if Kon=="2"
replace F_Female=. if Kon==" "
recode F_Female(.=0)
lab var F_Female "Founder is a female" 

//Marital status
gen F_Married=0
replace F_Married=1 if Civil=="G" | Civil=="RP"
lab var F_Married "Founder is married"

//education of founders

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
gduplicates report Lopnr_PersonNr year
gduplicates drop Lopnr_PersonNr year, force

tsset Lopnr_PersonNr year

tsspell Lopnr_PeOrgNr

gegen spell=group(Lopnr_PersonNr Lopnr_PeOrgNr)

bys spell: gegen maxedulevel=max(edulevel)

bys spell: gegen edu1count=count(edulevel) if edulevel==1
bys spell: gegen edu1countmax=max(edu1count)

bys spell: gegen edu2count=count(edulevel) if edulevel==2
bys spell: gegen edu2countmax=max(edu2count)

bys spell: gegen edu3count=count(edulevel) if edulevel==3
bys spell: gegen edu3countmax=max(edu3count)

bys spell: gegen edu4count=count(edulevel) if edulevel==4
bys spell: gegen edu4countmax=max(edu4count)

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
ren edu1 F_edu1
lab var F_edu1 "Education<12 years"
ren edu2 F_edu2
lab var F_edu2 "Education=12 years"
ren edu3 F_edu3
lab var F_edu3 "Education >12, <=15 years"
ren edu4 F_edu4
lab var F_edu4 "Education>=16 years"

//primary occupation of founder

gen F_MicroOcc=real(substr(Ssyk3, 1,3))
recode F_MicroOcc (112=121) (11=121) (111=121) (123 131 =122) (223=222) (232 233 234 235=231) (314 315=313) (323=322) (332=331) (345=344) (412 413 414 415 419 421 422 =411) (512 513 514 515 =511) (522=521) (612 613 614 615 = 611) (712 713 714 721 722 723 724 731 732 733 734 741 742 743 744 =711) (812 813 814 815 816 817 821 822 823 824 825 826 827 828 829 831 832 833 834 =811) (912 913 914 915 919 =911) (931 932 933 =921)
recode F_MicroOcc(.=0)
lab var F_MicroOcc "Founder's micro occupation"

label def F_MicroOcc 121 "Senior Managers" 122 "Managers" 211 "Physical science professionals" 212 "Mathematicians" ///
213 "Computing professionals" 214 "Architects and engineers" 221 "Life science professionals" 222 "Health professionals" 231 "Teaching professionals" ///
241 "Business professionals" 242 "Legal professionals" 243 "Information professionals" 244 "Social science professionals" ///
245 "Writers & artists" 246 "Religious professionals" 247 "Public service admin professionals" 248 "Admin professionals of special orgs" 249 "Psychologists and social work professionals" ///
311 "Physcial science associates" 312 "Computer technicians" 313 "Engg. technicians" 321 "Agronomy and forestry technicians" 322 "Health associates" 324 "Life science technicians" ///
331 "Teaching associates" 341 "Finance and sales associates" 342 "Business service associates" 343 "Admin associate" 344 "Law enforcement associate" 346 "Social work associate" ///
347 "Entertainment & sports associates" 348 "Religious associates" 411 "Clerks" 511 "Service workers" 521 "Sales workers" 611 "Agri & fishery workers" 711 "Craft workers" ///
811 "Machine operators" 911 "Elementary occupation" 921 "Labourers" 0 "Unknown"

label values F_MicroOcc F_MicroOcc

tab F_MicroOcc

//primary industry of founder
gen siclevel=1
do "$script_path\sic"
ren astSIC F_SIC
lab var F_SIC "Founder's SIC"

//year since living in Sweden (for natives, this will be year of birth)
preserve
odbc load, exec("select * from Fodelseland")dsn("P0833") clear
ren P0833_LopNr_PersonNr Lopnr_PersonNr
keep Lopnr_PersonNr FodGrEg3
ren FodGrEg3 GrEg3 //rename to reflect old var name
duplicates drop Lopnr_PersonNr, force
tempfile greg
save `greg'
restore
merge m:1 Lopnr_PersonNr using `greg', keep(match)
drop _merge
gen F_Swedenstart = SenInvAr if GrEg3!="0"
replace F_Swedenstart=FodelseAr if GrEg3=="0"

//3. Labor market experience of founders
do "$script_path\LM experience" 
ren LabExp F_LabExp
lab var F_LabExp "Founder's labor market experience"
ren IndExp F_IndExp
lab var F_IndExp "Founder's experience in focal industry"

preserve
/*construct prior entrepreneurial experience of founders from individual data*/
odbc load, exec("select * from individ_1990")dsn("P0833") clear
gen year= "1990"
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
keep Lopnr_PersonNr year YrkStalln 
sort Lopnr_PersonNr year
destring year, replace
tempfile entexp
save `entexp', replace

forvalues i = 1991/2020 {
	odbc load, exec("select * from individ_`i'")dsn("P0833") clear
	gen year="`i'"
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	keep Lopnr_PersonNr year YrkStalln 
	sort Lopnr_PersonNr year
	destring year, replace
	append using `entexp'
	save `entexp', replace
}

merge m:1 Lopnr_PersonNr using `founderlist', keep(match) //this will keep only founders in the data
drop _merge

gen ENTexp=0 
replace ENTexp=1 if YrkStalln=="4"|YrkStalln=="5"
bysort Lopnr_PersonNr (year): replace ENTexp=sum(ENTexp)
duplicates report Lopnr_PersonNr year
duplicates drop Lopnr_PersonNr year, force
drop if year<2004
save `entexp', replace
restore

merge m:1 Lopnr_PersonNr year using `entexp', keep(match)
drop _merge
ren ENTexp F_ENTexp
lab var F_ENTexp "Founder's entrepreneurship experience"

keep Lopnr_PersonNr Lopnr_PeOrgNr year F_age F_Female F_Married F_edu1 F_edu2 F_edu3 F_edu4 F_MicroOcc F_SIC F_Swedenstart F_LabExp F_IndExp F_ENTexp
duplicates report Lopnr_PersonNr Lopnr_PeOrgNr year
duplicates drop Lopnr_PersonNr Lopnr_PeOrgNr year, force 




