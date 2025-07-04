clear all
capture log close
set more off

//create a dataset with board members
do "$script_path\Board.do" 

//create individual labor market data
do "$script_path\Individuals.do"

//create firm database
do "$script_path\Firms.do"

//Firm founding and dissolution
do "$script_path\FAD.do" 

//calculate industry uncertainty variables
do "$script_path\industry_dynamics"

//Get job data to identify active founders and co-owners
do "$script_path\job.do"

//Prepare CEO data
do "$script_path\ceo"

//Parepare data on directors' full career
do "$script_path\director_career"

//Draw the population of firms from FAD
frame create fad
cwf fad
use "$data_path\firm_dynamics"
destring Ar_Ny, replace
mdesc Ar_Ny
bys Lopnr_PeOrgNr: egen Ar_Ny2 = min(Ar_Ny)
replace Ar_Ny= Ar_Ny2
mdesc Ar_Ny Ar_Ny2
drop Ar_Ny2
drop if Kvar == "20" | Kvar == "30"  | Kvar == "50" | Kvar == "70" | Kvar == "80" | Kvar == "90" 
//when Kvar = 20-90, the firm no longer exist in the database. We will use a different method to identify dissolution
keep Lopnr_PeOrgNr year Ar_Ny
gduplicates drop
gsort Lopnr_PeOrgNr year
gen firmage=(year-Ar_Ny)+1 //Ar_Ny is the year of founding according to the FAD algorithm. See FAD documentation for details. 
lab var firmage "Firm age"
keep if Ar_Ny>=2004 //keep only ventures founded on or after 2004
gen startup_data=1
keep Lopnr_PeOrgNr year firmage startup_data
gunique Lopnr_PeOrgNr //how many firms are in the startup data?
local n_startups = r(unique)

//Next, get the data on directors in these firms - not all firms have a board
cwf default
use "$data_path\Board_micro", clear
keep Lopnr_PersonNr Lopnr_PeOrgNr year Director Kon FtgSni07
frlink m:1 Lopnr_PeOrgNr year, frame(fad)
frget firmage startup_data, from(fad)
frame drop fad
drop fad
mdesc startup_data
gunique Lopnr_PeOrgNr //how many firms are in the board data?
gunique Lopnr_PeOrgNr if startup_data==. //how many firms in the board data that are not startups?
keep if startup_data==1
drop startup_data
gunique Lopnr_PeOrgNr
local n_boards = r(unique)
keep if Director==1 //keep only directors in these firms
di abs(`n_startups' - `n_boards') //the difference between the number of firms in the startup data and in this data is the number of startups without a board 

//Identify foundations
frame create koncern
cwf koncern
odbc load, exec("select * from KCR_2004")dsn("P0833") clear /*import koncern data*/
keep P0833_Lopnr_peorgnrd P0833_Lopnr_peorgnrkoncmod
ren P0833_Lopnr_peorgnrd Lopnr_PeOrgNr
ren P0833_Lopnr_peorgnrkoncmod Lopnr_KoncernModer
gen year = 2004
tempfile koncern
save `koncern', replace
forvalues i = 2005/2020 {
    odbc load, exec("select * from KCR_`i'")dsn("P0833") clear /*import koncern data*/
	keep P0833_Lopnr_peorgnrd P0833_Lopnr_peorgnrkoncmod
	ren P0833_Lopnr_peorgnrd Lopnr_PeOrgNr
	ren P0833_Lopnr_peorgnrkoncmod Lopnr_KoncernModer
	gen year = `i'
	append using `koncern'
	save `koncern', replace
}
use `koncern', clear
gsort Lopnr_PeOrgNr year
cwf default
frlink m:1 Lopnr_PeOrgNr year, frame(koncern)
frget Lopnr_KoncernModer, from(koncern)
frame drop koncern
drop koncern

//BOARD AND VENTURE CONTROLS
//1. Board size
bys Lopnr_PeOrgNr year: gegen BoardSize=count(Lopnr_PersonNr) //includes founder-directors as well
lab var BoardSize "Board Size"
gen logboardsize=log(1+BoardSize)
lab var logboardsize "Log board size"

//2. venture size, industry and location 
frame create venture 
cwf venture
use "$data_path\Firms", clear
keep Lopnr_PeOrgNr year Org_Sni2002 Org_Sni2007 Org_AntalSys Org_BelKommun
gen siclevel = 2 //when siclevel = 1, this code will create individual's sni; if 2 (or 3 when pre-2001 data is used), firm's sni.
do "$script_path\sic"
lab var orgSIC "Venture industry"

//municipality
gen orgLAN=real(substr(Org_BelKommun, 1,2))
drop if orgLAN==99
lab var orgLAN "Venture municipality"
lab def orgLAN 01 "01. Stockholms län" 03 "03. Uppsala län" 04 "04. Södermanlands län" 05 "05. Östergötlands län" 06 "06. Jönköpings län" 07 "07. Kronobergs län" 08 "08. Kalmar län" ///
09 "09. Gotlands län" 10 "10. Blekinge län" 12 "12. Skåne län" 13 "13. Hallands län" 14 "14. Västra Götalands län" 17 "17. Värmlands län" 18 "18. Örebro län"  19 "19. Västmanlands län" ///
20 "20. Dalarnas län" 21 "21. Gävleborgs län" 22 "22. Västernorrlands län" 23 "23. Jämtlands län"  24 "24. Västerbottens län" 25 "25. Norrbottens län", modify
label values orgLAN orgLAN
keep Lopnr_PeOrgNr year Org_AntalSys orgSIC orgLAN
gsort Lopnr_PeOrgNr year
duplicates report Lopnr_PeOrgNr year

cwf default
frlink m:1 Lopnr_PeOrgNr year, frame(venture)
frget orgSIC orgLAN Org_AntalSys, from(venture)
frame drop venture

//DIRECTOR CONTROLS
frame create dcontrols
cwf dcontrols
do "$script_path\director controls"
frame change default
frlink m:1 Lopnr_PersonNr year, frame(dcontrols)
frget D_age D_Female D_Married D_edu1 D_edu2 D_edu3 D_edu4 D_MicroOcc D_SIC D_Swedenstart D_LabExp D_IndExp D_ENTexp, from(dcontrols)
*********************CAUTION - DATA EXCLUSION**************************
gunique Lopnr_PeOrgNr
drop if dcontrols==. //keep only those firms that are in the board data
gunique Lopnr_PeOrgNr
***********************************************************************
frame drop dcontrols
//code a second indicator for female directors using the gender info provided in the board data
gen D_Female2 = cond(Kon=="2",1,0)
sum D_Female D_Female2 //which one has more missing values?
replace D_Female = D_Female2
drop D_Female2

//FOUNDER DATABASE
frame create founders
cwf founders
*First, get all the firms in the board database and identify their founders from multiple sources
use Lopnr_PeOrgNr year using "$data_path\Board_micro", clear
gduplicates drop //now we have a panel data of firms with a board of directors
gen board_data=1

/*next, we need to identify founders in these firms. We can identify founders from LISA data
using YrkStalln variable*/
frame create yrk
cwf yrk
//All individuals and their employment status from LISA
use Lopnr_PersonNr year Lopnr_PeOrgNr YrkStalln using "$data_path\Individuals" if YrkStalln== "5", clear
frlink m:1 Lopnr_PeOrgNr year, frame(founders)
frget board_data, from(founders)
keep if board_data==1
frame drop founders
frame rename yrk founders

/*now the founders data has all firms in the board data and their founders whose main source of income is the focal firm.
We need to also identify founders in these firms whose main source of income is not the focal firm. This can be extracted from the jobb data*/
preserve
use "$data_path\job", clear
gen founder = cond(Faman == 1 | YrkStallnKU == "5",1,0) //if year<=2009, then Faman=1 & YrkStallnKU= 2; if year>=2010, then YrkStallnKU = 5
tab founder
keep if founder==1
drop founder
keep Lopnr_PersonNr year Lopnr_PeOrgNr
tempfile job 
save `job', replace
restore
merge 1:1 Lopnr_PersonNr year Lopnr_PeOrgNr using `job'
tab _merge
//now, we need to keep only those founder-firm combo which is in the board data
recode board_data(.=0) //this will be missing for _merge==2
bys Lopnr_PeOrgNr year: gegen board_firms = max(board_data)
drop board_data
drop if board_firms!=1 //drop founders that are not affiliated to firms in the board data
drop _merge
drop board_firms
keep Lopnr_PersonNr year Lopnr_PeOrgNr
gsort Lopnr_PersonNr year Lopnr_PeOrgNr
gen founder=1
save "$data_path\founders", replace //data of active founders of the firms in the board data

frame create fcontrols
cwf fcontrols
do "$script_path\founder controls"

//FAMILY TIE DATABASE
frame create family
cwf family
do "$script_path\family ties" //this creates a database that indicates whether a focal director(founder) has family connections to a founder(director) in the same firm and the type of relation
use "$data_path\famties", clear

//venture dissolution
frame create dissolve 
cwf dissolve
use "$data_path\firm_dynamics", clear
keep Lopnr_PeOrgNr year Kvar Ar_Ny
destring Ar_Ny, replace
mdesc Ar_Ny
bys Lopnr_PeOrgNr: egen Ar_Ny2 = min(Ar_Ny)
replace Ar_Ny= Ar_Ny2
mdesc Ar_Ny Ar_Ny2
drop Ar_Ny2
gsort Lopnr_PeOrgNr year
gen acquired=1 if  (Kvar=="10" | Kvar=="60")
recode acquired (.=0)
drop Kvar
bys Lopnr_PeOrgNr year: egen maxacquired = max(acquired)
replace acquired = maxacquired
lab var acquired "Venture acquisition"
gduplicates drop
gduplicates report Lopnr_PeOrgNr year

gsort Lopnr_PeOrgNr year
bys Lopnr_PeOrgNr: gen dissolution = 1 if Lopnr_PeOrgNr[_n+1]==.
recode dissolution(.=0)
lab var dissolution "Venture dissolution"
tab dissolution

keep Lopnr_PeOrgNr year dissolution acquired
gsort Lopnr_PeOrgNr year

cwf default
capture drop dissolution
frlink m:1 Lopnr_PeOrgNr year, frame(dissolve)
frget dissolution acquired, from(dissolve)
frame drop dissolve
frame dir

//DATA PREPARATION
//First, identify directors with family ties to be deleted later
unique Lopnr_PersonNr //there are xxxx unique directors
unique Lopnr_PeOrgNr //there are xxxx unique firms
order Lopnr_PersonNr Lopnr_PeOrgNr year D_age D_Female D_Married D_edu1 D_edu2 D_edu3 D_edu4 D_MicroOcc D_SIC D_LabExp D_IndExp D_ENTexp D_Swedenstart BoardSize logboardsize firmage Org_AntalSys orgSIC orgLAN 
sort Lopnr_PeOrgNr year Lopnr_PersonNr
frlink 1:1 Lopnr_PersonNr year Lopnr_PeOrgNr, frame(family)
frget famties, from(family) //famties data provides a dummy indicating whether a focal director has a family tie to a founder or vice versa in the same firm
drop if Director!=1
frlink 1:1 Lopnr_PersonNr year Lopnr_PeOrgNr, frame(founders)
frget founder, from(founders)
recode founder(.=0)

//Identify corporate ventures by coding firms that lack any founders
bys Lopnr_PeOrgNr year: egen founderidentified = max(founder)
gen startup = cond(firmage<=10,1,0)
bys founderidentified startup: sum Org_AntalSys //compare the size of firms with and without founder identified - does it make sense?
drop startup

drop if Director!=1 //now, keep only founders who sit on the board
 
unique Lopnr_PersonNr //there are xxxx unique directors (including founder-directors)
unique Lopnr_PeOrgNr //there are xxx unique firms

//get death data to code exit
frame create death
frame change death
odbc load, exec("select * from Doda")dsn("P0833") clear
ren P0833_LopNr_PersonNr Lopnr_PersonNr
gduplicates report Lopnr_PersonNr
gduplicates drop Lopnr_PersonNr, force
tostring DodDatum, replace
gen death_year= real(substr(DodDatum, 1, 4))
frame change default
frlink m:1 Lopnr_PersonNr, frame(death)
frget death_year, from(death)
gen Dead= cond(death_year == year,1,0)
drop death_year
lab var Dead "Died"
frame drop death

//get emigration data to code exit
frame create emigration
frame change emigration 
odbc load, exec("select * from In_Utvandring")dsn("P0833") clear
ren P0833_LopNr_PersonNr Lopnr_PersonNr
tostring InvUtvDatum, replace
gen year= real(substr(InvUtvDatum, 1, 4))
gen emigration_data = 1
duplicates drop Lopnr_PersonNr year, force //some individuals made multiple-emigrations in same year, which isn't important here.
frame change default
frlink m:1 Lopnr_PersonNr year, frame(emigration)
frget emigration_data, from(emigration)
frame drop emigration
gen emigrated= cond(emigration_data == 1,1,0) 
lab var emigrated "Emigrated"
drop emigration_data

//exit
sort Lopnr_PersonNr Lopnr_PeOrgNr year
bys Lopnr_PersonNr Lopnr_PeOrgNr: gen exit=1 if Lopnr_PeOrgNr[_n]!=Lopnr_PeOrgNr[_n+1]
bys Lopnr_PersonNr Lopnr_PeOrgNr: replace exit = 0 if Lopnr_PeOrgNr[_n]==Lopnr_PeOrgNr[_n+1]
replace exit=0 if Dead==1
replace exit=0 if emigrated==1
sum exit

//tenure
bys Lopnr_PersonNr Lopnr_PeOrgNr: gen tenure=_n

//integrate founder controls into the sample
cwf founders
frlink m:1 Lopnr_PersonNr year, frame(fcontrols)
frget F_age F_Female F_Married F_edu1 F_edu2 F_edu3 F_edu4 F_MicroOcc F_SIC F_Swedenstart F_LabExp F_IndExp F_ENTexp, from(fcontrols)
frame drop fcontrols
drop F_MicroOcc F_SIC
collapse F_age F_Female F_Married F_edu1 F_edu2 F_edu3 F_edu4 F_LabExp F_IndExp F_ENTexp, by(Lopnr_PeOrgNr year)
frame change default
frame copy founders fcontrols
frlink m:1 Lopnr_PeOrgNr year, frame(fcontrols)
frget F_age F_Female F_Married F_edu1 F_edu2 F_edu3 F_edu4 F_LabExp F_IndExp F_ENTexp, from(fcontrols)
frame drop fcontrols

frame dir

//CEO characteristics
frame create ceo
frame ceo: use "$data_path\ceo", clear 
cwf default
frlink m:1 Lopnr_PeOrgNr year, frame(ceo)
frget ceo_age ceo_female ceo_edulevel ceo_SIC ceo_IndExp ceo_ENTexp ceo_greg3, from(ceo)
mdesc ceo

*********************CAUTION - DATA EXCLUSION**************************
gunique Lopnr_PeOrgNr
drop if ceo==. //keep only those firms that are in the board data
gunique Lopnr_PeOrgNr
***********************************************************************

//get ethnicity data
frame create ethnicity
frame change ethnicity
odbc load, exec("select * from Fodelseland")dsn("P0833") clear 
ren P0833_LopNr_PersonNr Lopnr_PersonNr
gduplicates drop Lopnr_PersonNr, force
sort Lopnr_PersonNr
ren FodGrEg3 GrEg3 //rename to reflect old var name
destring GrEg3, replace
replace GrEg3=11 if GrEg3==.
cwf default
frlink m:1 Lopnr_PersonNr, frame(ethnicity)
frget GrEg3, from(ethnicity)
frame drop ethnicity

gen D_native=1 if GrEg3==0
recode D_native(.=0)
lab var D_native "Director is Sweden-born"

//Dissimilarity measures
//1. Country of origin
gen culture_dissimilar = 1 if GrEg3 != ceo_greg3 & GrEg3!=. & ceo_greg3!=.
replace culture_dissimilar = 0 if GrEg3 == ceo_greg3
lab var culture_dissimilar "Cultural dissimilarity"
tab culture_dissimilar
//2. Gender
gen gender_dissimilar = 1 if D_Female != ceo_female & D_Female !=. & ceo_female!=.
replace gender_dissimilar = 0 if D_Female == ceo_female
lab var gender_dissimilar "Gender dissimilarity"
tab gender_dissimilar
//3. Age
gen age_dissimilar = abs(D_age - ceo_age) if D_age!=. & ceo_age!=.
sum age_dissimilar if age_dissimilar!=.
gen maxi = r(max)
replace age_dissimilar = age_dissimilar/maxi
drop maxi
lab var age_dissimilar "Age dissimilarity"

//4. Education level
gen edulevel=1 if D_edu1==1
replace edulevel=2 if D_edu2==1
replace edulevel=3 if D_edu3==1
replace edulevel=4 if D_edu4==1
gen edu_dissimilar = 1 if edulevel != ceo_edulevel & edulevel !=. & ceo_edulevel!=.
replace edu_dissimilar = 0  if edulevel == ceo_edulevel
lab var edu_dissimilar "Education level dissimilarity"

//5. Industry experience
gen exp_dissimilar = abs(D_IndExp - ceo_IndExp) if D_IndExp!=. & ceo_IndExp!=.
sum exp_dissimilar if exp_dissimilar!=.
gen maxi = r(max)
replace exp_dissimilar = exp_dissimilar/maxi
drop maxi
lab var exp_dissimilar "Industry experience dissimilarity"

//6. Industry background
gen industry_dissimilar = 1 if D_SIC != ceo_SIC & D_SIC !=. & ceo_SIC !=.
replace industry_dissimilar = 0 if D_SIC == ceo_SIC
tab industry_dissimilar
lab var industry_dissimilar "Industry focus dissimilarity"

//7. entrepreneurship experience
gen entexp_dissimilar = abs(D_ENTexp - ceo_ENTexp) if D_ENTexp!=. & ceo_ENTexp!=.
sum entexp_dissimilar if entexp_dissimilar!=.
gen maxi = r(max)
replace entexp_dissimilar = entexp_dissimilar/maxi
drop maxi
lab var entexp_dissimilar "Entrepreneurship experience dissimilarity"

//dissimilarity measure for categorical variables
mdesc culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar exp_dissimilar industry_dissimilar entexp_dissimilar
//drop experience from the composite measure due to missing values

gen dissimilarity = (culture_dissimilar + gender_dissimilar + age_dissimilar + edu_dissimilar + industry_dissimilar + entexp_dissimilar)/6 ///
	if culture_dissimilar!=. ///
	& gender_dissimilar!=. ///
	& age_dissimilar!=. ///
	& edu_dissimilar!=. ///
	& industry_dissimilar!=. ///
	& entexp_dissimilar!=.
sum dissimilarity, detail
lab var dissimilarity "Overall dissimilarity"

//decompose dissimilarity into demographic and skills
gen dem_dissimilarity = (culture_dissimilar + gender_dissimilar + age_dissimilar)/3 ///
	if culture_dissimilar!=. ///
	& gender_dissimilar!=. ///
	& age_dissimilar!=.
sum dem_dissimilarity, detail
lab var dem_dissimilarity "Demographic dissimilarity" 

gen skill_dissimilarity = (edu_dissimilar + industry_dissimilar + entexp_dissimilar)/3 ///
	if edu_dissimilar!=. ///
	& industry_dissimilar!=. ///
	& entexp_dissimilar!=.
sum skill_dissimilarity, detail
lab var skill_dissimilarity "Knowledge dissimilarity" 

mdesc culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar

//calculate firm uncertainty variables
frame create performance
cwf performance
do "$script_path\performance"
cwf default
frlink m:1 Lopnr_PeOrgNr year, frame(performance)
frget profit DE_Ratio cash high_profit high_deratio high_cash, from(performance)
frame drop performance

//Get industry dynamics variables. Before merging industry dynamics variables, lag the variables
frame create indus_dynamics
cwf indus_dynamics
use "$data_path\ind_var_2003_2020", clear
gduplicates report orgSIC year
gduplicates drop
sort orgSIC year
bys orgSIC: gen complexity_lag= ind_comp[_n-1]
bys orgSIC: gen munificence_lag= ind_mun_def1[_n-1]
bys orgSIC: gen dynamics_lag= ind_dyn_def1[_n-1]
drop if year==2003
cwf default

frlink m:1 orgSIC year, frame(indus_dynamics)
frget complexity_lag munificence_lag dynamics_lag, from(indus_dynamics)
frame drop indus_dynamics

//Get board diversity (by EDs and NEDs)
frame copy default diversity
frame create ned
frame ned: use Lopnr_PersonNr Lopnr_PeOrgNr year NED using "$data_path\Board_micro"
cwf diversity
frlink 1:1 Lopnr_PersonNr Lopnr_PeOrgNr year, frame(ned)
frget NED, from(ned)
do "$script_path\diversity"
cwf default
frlink 1:1 Lopnr_PersonNr Lopnr_PeOrgNr year, frame(ned)
frget NED, from(ned)
frame drop ned
frlink m:1 Lopnr_PeOrgNr NED year, frame(diversity)
frget NatCultDiv GenderIQV AgeDiv EdulevelDiv IndDiv ExpDiv EntExpDiv, from(diversity)
frame drop diversity
mdesc NatCultDiv GenderIQV AgeDiv EdulevelDiv IndDiv ExpDiv EntExpDiv

egen cohort = group(Lopnr_PersonNr Lopnr_PeOrgNr)
capture drop _*
tsset cohort year
tsspell Lopnr_PeOrgNr
gen D_tenure = _seq //recode tenure as a single contiguous spell of a director in a firm with no gaps
tsset, clear
drop cohort _*

frame create legal
frame legal: use Lopnr_PeOrgNr year InstKod7 InstKod10 using "$data_path\Individuals"
cwf legal
gen InstKod = InstKod7
replace InstKod = InstKod10 if InstKod7== " "
gen legal_form = substr(InstKod,6,2)
tab legal_form
drop InstKod7 InstKod10 InstKod
gduplicates drop
gduplicates report Lopnr_PeOrgNr year
gduplicates drop Lopnr_PeOrgNr year, force
cwf default
frlink m:1 Lopnr_PeOrgNr year, frame(legal)
frget legal_form, from(legal)
drop legal
frame drop legal
tab legal_form
tab year

drop if legal_form == "10" | legal_form == "51" | legal_form == "61" | legal_form == "81" | legal_form == "82" | legal_form == "96" | legal_form == "99"
drop if orgSIC==13 | orgSIC==17 //non-profit or social security sectors
drop if Lopnr_KoncernModer!=. //venture is part of a family foundation

gunique Lopnr_PersonNr
gunique Lopnr_PeOrgNr

save "$data_path\p08_sample", replace

//******************************SAMPLING****************************************
cd "$project_path\Output"

//drop if the director has family tie to one of the founders 

forvalues  i=1/4 {
gen edu`i'=1 if ceo_edulevel==`i'
replace edu`i'=0 if edu`i'==.
}
replace edu1=. if ceo_edulevel==.
replace edu2=. if ceo_edulevel==.
replace edu3=. if ceo_edulevel==.
replace edu4=. if ceo_edulevel==.
ren edu1 ceo_edu1
lab var ceo_edu1 "Education<12 years"
ren edu2 ceo_edu2
lab var ceo_edu2 "Education=12 years"
ren edu3 ceo_edu3
lab var ceo_edu3 "Education >12, <=15 years"
ren edu4 ceo_edu4
lab var ceo_edu4 "Education>=16 years"

estpost sum culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar exp_dissimilar industry_dissimilar entexp_dissimilar dissimilarity ///
	D_tenure D_age D_Female D_edu2 D_edu3 D_edu4 D_IndExp D_ENTexp ceo_age ceo_female ceo_edu2 ceo_edu3 ceo_edu4 ceo_IndExp ceo_ENTexp logboardsize ///
	Org_AntalSys firmage dissolution acquired profit DE_Ratio cash if famties == 0
esttab using TABA0.rtf, cells("mean(fmt(3)) sd min max") replace label longtable nonumber nomtitle title(Non-family directors)
eststo clear

estpost sum culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar exp_dissimilar industry_dissimilar entexp_dissimilar dissimilarity ///
	D_tenure D_age D_Female D_edu2 D_edu3 D_edu4 D_IndExp D_ENTexp ceo_age ceo_female ceo_edu2 ceo_edu3 ceo_edu4 ceo_IndExp ceo_ENTexp logboardsize ///
	Org_AntalSys firmage dissolution acquired profit DE_Ratio cash if famties == 1
esttab using TABA0.rtf, cells("mean(fmt(3)) sd min max") append label longtable nonumber nomtitle title(Family directors)
eststo clear

drop if famties == 1 //drop family ties and examine the sample with and without executive_directors

//tabulate by executive and non-executive directors

estpost sum culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar exp_dissimilar industry_dissimilar entexp_dissimilar dissimilarity ///
	D_tenure D_age D_Female D_edu2 D_edu3 D_edu4 D_IndExp D_ENTexp logboardsize ///
	Org_AntalSys firmage dissolution acquired profit DE_Ratio cash if NED == 0
esttab using TABA0.rtf, cells("mean(fmt(3)) sd min max") append label longtable nonumber nomtitle title(Executive directors)
eststo clear

estpost sum culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar exp_dissimilar industry_dissimilar entexp_dissimilar dissimilarity ///
	D_tenure D_age D_Female D_edu2 D_edu3 D_edu4 D_IndExp D_ENTexp logboardsize ///
	Org_AntalSys firmage dissolution acquired profit DE_Ratio cash if NED == 1
esttab using TABA0.rtf, cells("mean(fmt(3)) sd min max") append label longtable nonumber nomtitle title(Non-executive directors)
eststo clear

drop Lopnr_KoncernModer famties
 
********************************************************************************
