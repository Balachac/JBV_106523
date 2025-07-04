

odbc load P0833_Lopnr_PersonNr P0833_Lopnr_PersonNr_Partner, exec("select * from Partner_2004")dsn("P0833") clear
ren P0833_Lopnr_PersonNr Lopnr_PersonNr
ren P0833_Lopnr_PersonNr_Partner LopNr_Partner
gen year=2004
tempfile family
save `family', replace
forvalues i = 2005/2020 {
    odbc load P0833_Lopnr_PersonNr P0833_Lopnr_PersonNr_Partner, exec("select * from Partner_`i'")dsn("P0833") clear
	ren P0833_Lopnr_PersonNr Lopnr_PersonNr
	ren P0833_Lopnr_PersonNr_Partner LopNr_Partner
	gen year=`i'
	append using `family'
	save `family', replace
}
odbc load, exec("select * from FlerGen_Bioforaldrar")dsn("P0833") clear
ren P0833_LopNr_PersonNr Lopnr_PersonNr
ren P0833_LopNr_PersonNrFar LopNr_PersonNrFar
ren P0833_LopNr_PersonNrMor LopNr_PersonNrMor
gduplicates report Lopnr_PersonNr LopNr_PersonNrFar LopNr_PersonNrMor
gduplicates report Lopnr_PersonNr
gduplicates drop Lopnr_PersonNr, force
merge 1:m Lopnr_PersonNr using `family', keep(match)
drop _merge
ren Lopnr_PersonNr Lopnr_PersonNrA
gduplicates report Lopnr_PersonNrA year
//if a person has more than one partner during a focal year, force drop (randomly) except one. They are likely to be very rare
gduplicates drop Lopnr_PersonNrA year, force 
save `family', replace


/*create an individual matrix of board members and founders to compare with family data*/
use "$data_path\Board_micro", clear
keep if Director==1 //includes founders except those who don't sit on their boards
keep Lopnr_PersonNr Lopnr_PeOrgNr year Director
tempfile director
save `director', replace

use "$data_path\founders", clear
keep Lopnr_PersonNr Lopnr_PeOrgNr year founder
merge 1:m Lopnr_PersonNr Lopnr_PeOrgNr year using `director'
//now the file contains all founders and directors in the sample
tab _merge
drop _merge
gduplicates report Lopnr_PersonNr Lopnr_PeOrgNr year
gduplicates drop Lopnr_PersonNr Lopnr_PeOrgNr year, force
keep Lopnr_PersonNr year Lopnr_PeOrgNr 
order Lopnr_PeOrgNr year Lopnr_PersonNr
tempfile ind_matrix
save `ind_matrix', replace

use `ind_matrix', clear
ren Lopnr_PersonNr Lopnr_PersonNrA
joinby Lopnr_PeOrgNr year using `ind_matrix'
ren Lopnr_PersonNr Lopnr_PersonNrB
merge m:1 Lopnr_PersonNrA year using `family'
drop if _merge==2
drop _merge
save `family', replace

/*when the alter in a venture do not match with any of the family id, recode family id with missing - to indicate that the family member is not in the venture*/
replace LopNr_PersonNrFar=. if Lopnr_PersonNrB!=LopNr_PersonNrFar
replace LopNr_PersonNrMor=. if Lopnr_PersonNrB!=LopNr_PersonNrMor
replace LopNr_Partner=. if Lopnr_PersonNrB!=LopNr_Partner

/*create a variable for each family member that indicates whether they sit on the board or is a founder - where all obervations for that firm-year corresponds to the family id*/
bysort Lopnr_PeOrgNr year Lopnr_PersonNrA: gegen Far=min(LopNr_PersonNrFar) /*min() because max()==. */
bysort Lopnr_PeOrgNr year Lopnr_PersonNrA: gegen Mor=min(LopNr_PersonNrMor)
bysort Lopnr_PeOrgNr year Lopnr_PersonNrA: gegen Part=min(LopNr_Partner)

drop Lopnr_PersonNrB LopNr_PersonNrFar LopNr_PersonNrMor LopNr_Partner
gcollapse Far Mor Part, by(Lopnr_PeOrgNr year Lopnr_PersonNrA)
/*After the above procedures, if either of the family member id is non-missing, that means that family member is present in the venture as a founder or director*/
save "$data_path\famties", replace

/*code if a  member has either father, mother or partner in the same venture*/
use `ind_matrix', clear
keep Lopnr_PersonNr year Lopnr_PeOrgNr 
ren Lopnr_PersonNr Lopnr_PersonNrA
merge m:1 Lopnr_PersonNrA year Lopnr_PeOrgNr using "$data_path\famties"
drop if _merge==2
drop _merge
gen famties=1 if (Far!=.|Mor!=.|Part!=.)
recode famties(.=0)
lab var famties "Family tie dummy"
gen parentties=1 if (Far!=.|Mor!=.)
recode parentties(.=0)
lab var parentties "Parent ties dummy"
gen partnerties=1 if Part!=.
recode partnerties(.=0)
lab var partnerties "Partner ties dummy"

ren Lopnr_PersonNrA Lopnr_PersonNr
drop Far Mor Part
gduplicates drop Lopnr_PersonNr year Lopnr_PeOrgNr, force 
keep Lopnr_PersonNr Lopnr_PeOrgNr year famties parentties partnerties
save "$data_path\famties", replace

*Sibling - from father
use `family', clear
keep LopNr_PersonNrFar Lopnr_PersonNrA
gduplicates drop
sort LopNr_PersonNrFar Lopnr_PersonNrA 
bysort LopNr_PersonNrFar:gen j=_n
drop if LopNr_PersonNrFar==.
greshape wide Lopnr_PersonNrA, i(LopNr_PersonNrFar) j(j)
drop LopNr_PersonNrFar
ren Lopnr_PersonNrA1 Lopnr_PersonNr
sort Lopnr_PersonNr
merge 1:m Lopnr_PersonNr using `ind_matrix'
drop if _merge!=3 /*keep only observations that are common to both board data and sibling data*/
drop if Lopnr_PersonNrA2==. /*keep only individuals with siblings - if the first sibling info is missing then the individual has no reported siblings*/
drop _merge
keep Lopnr_PersonNr Lopnr_PersonNrA2
gduplicates drop Lopnr_PersonNr, force
greshape long Lopnr_PersonNrA, i(Lopnr_PersonNr) j(j)
drop if Lopnr_PersonNrA==.
drop j
ren Lopnr_PersonNrA LopNr_Sibling
lab var Lopnr_PersonNr "Personal number"
lab var LopNr_Sibling "Sibling ID"
tempfile sibling
save `sibling', replace

*Sibling - from mother
use `family', clear
keep LopNr_PersonNrMor Lopnr_PersonNrA
gduplicates drop
sort LopNr_PersonNrMor Lopnr_PersonNrA 
bysort LopNr_PersonNrMor:gen j=_n
drop if LopNr_PersonNrMor==.
greshape wide Lopnr_PersonNrA, i(LopNr_PersonNrMor) j(j)
drop LopNr_PersonNrMor
ren Lopnr_PersonNrA1 Lopnr_PersonNr
sort Lopnr_PersonNr
merge 1:m Lopnr_PersonNr using `ind_matrix'
drop if _merge!=3 /*keep only observations that are common to both venture data and sibling data*/
drop if Lopnr_PersonNrA2==. /*keep only individuals with siblings - if the first sibling info is missing then the individual has no reported siblings*/
drop _merge
keep Lopnr_PersonNr Lopnr_PersonNrA2
gduplicates drop Lopnr_PersonNr, force
greshape long Lopnr_PersonNrA, i(Lopnr_PersonNr) j(j)
drop if Lopnr_PersonNrA==.
drop j 
ren Lopnr_PersonNrA LopNr_Sibling
lab var Lopnr_PersonNr "Personal number"
lab var LopNr_Sibling "Sibling ID"
merge 1:1 Lopnr_PersonNr LopNr_Sibling using `sibling'
drop _merge
save `sibling', replace

*Integrate sibling info into family tie data
use `ind_matrix', clear
ren Lopnr_PersonNr Lopnr_PersonNrA
joinby Lopnr_PeOrgNr year using `ind_matrix'
ren Lopnr_PersonNr Lopnr_PersonNrB
ren Lopnr_PersonNrA Lopnr_PersonNr
merge m:m Lopnr_PersonNr using `sibling'
drop if _merge==2
drop _merge
gen siblingties=1 if Lopnr_PersonNrB== LopNr_Sibling
recode siblingties(.=0)
lab var siblingties "Sibling ties dummy"
drop Lopnr_PersonNrB LopNr_Sibling
bysort Lopnr_PersonNr year Lopnr_PeOrgNr: gen dup=_n
bysort Lopnr_PersonNr year Lopnr_PeOrgNr: gegen duplicate=max(dup)
drop dup
drop if duplicate>1 & sibling==0
drop duplicate
recode siblingties(.=0)
gduplicates drop
merge 1:m Lopnr_PersonNr year Lopnr_PeOrgNr using "$data_path\famties"
tab _merge
drop _merge
replace famties=1 if famties==0 & siblingties==1
save "$data_path\famties", replace






