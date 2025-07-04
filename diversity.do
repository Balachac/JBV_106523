
//calculate the diversity by executive and non-executive directors
tab Director // make sure there are only directors in the sample

//Board diversity in national culture
do "$script_path\EthnicGroups" //code ethnic groups
bysort Lopnr_PeOrgNr NED year : gegen N_Swedish=total(Swedish)
bysort Lopnr_PeOrgNr NED year: gegen N_Scandi=total(Scandi)
bysort Lopnr_PeOrgNr NED year: gegen N_Euro=total(Euro)
bysort Lopnr_PeOrgNr NED year: gegen N_European=total(European)
bysort Lopnr_PeOrgNr NED year: gegen N_African=total(African)
bysort Lopnr_PeOrgNr NED year: gegen N_NA=total(NA)
bysort Lopnr_PeOrgNr NED year: gegen N_SA=total(SA)
bysort Lopnr_PeOrgNr NED year: gegen N_Asian=total(Asian)
bysort Lopnr_PeOrgNr NED year: gegen N_Oceania=total(Oceania)
bysort Lopnr_PeOrgNr NED year: gegen N_Russian=total(Russian)

seg N_Swedish N_Scandi N_Euro N_European N_African N_NA N_SA N_Asian N_Oceania N_Russian, h by(Lopnr_PeOrgNr year) nodisplay generate(h I_Entropy e D_Entropy)
drop I_Entropy N_Swedish N_Scandi N_Euro N_European N_African N_NA N_SA N_Asian N_Oceania N_Russian Swedish Scandi Euro European African NA SA Asian Oceania Russian
ren D_Entropy NatCultDiv
lab var NatCultDiv "National Cultural Diversity"

//Board diversity in Gender
bysort Lopnr_PeOrgNr NED year: gegen FemaleRatio=sum(D_Female)
replace FemaleRatio=FemaleRatio/BoardSize

gen MaleRatio= 1-FemaleRatio 
bysort Lopnr_PeOrgNr NED year: gen GenderIQV=(2*((MaleRatio+FemaleRatio)^2-(MaleRatio^2+FemaleRatio^2)))/(((MaleRatio+FemaleRatio)^2)*(2-1)) /*calculate gender diversity*/
label variable GenderIQV "Gender diversity" 
drop FemaleRatio MaleRatio

//Board divesity in age
bysort Lopnr_PeOrgNr NED year: gegen AgeDiv=sd(D_age) //missing if board size==1
sum D_age, detail
sum AgeDiv, detail
mdesc AgeDiv
lab var AgeDiv "Age Diversity"
sum year

//Board diversity in education level
bysort Lopnr_PeOrgNr NED year: gegen N_L1= total(D_edu1)
bysort Lopnr_PeOrgNr NED year: gegen N_L2= total(D_edu2)
bysort Lopnr_PeOrgNr NED year: gegen N_L3= total(D_edu3)
bysort Lopnr_PeOrgNr NED year: gegen N_L4= total(D_edu4)

seg N_L1-N_L4, h by(Lopnr_PeOrgNr NED year) nodisplay generate(h I_Entropy e D_Entropy)
ren D_Entropy EdulevelDiv
lab var EdulevelDiv "Diversity in education level"
drop N_L1-N_L4 I_Entropy

//Board diversity in industry background
xi i.D_SIC
gen _ID_SIC_1= cond( D_SIC==1,1,0 ) //the command xi does not create the base category dummy, so create manually
levelsof D_SIC, local(siclevel)
foreach i of local siclevel {
	bysort Lopnr_PeOrgNr NED year: gegen N_SIC`i'= total(_ID_SIC_`i')
}
qui sum D_SIC 
seg N_SIC`r(min)' -N_SIC`r(max)', h by(Lopnr_PeOrgNr NED year) nodisplay generate(h I_Entropy e D_Entropy)
ren D_Entropy IndDiv
lab var IndDiv "Diversity in industry affiliation"
drop N_SIC1-N_SIC19 I_Entropy _ID_SIC_*

//Board diversity industry experience
bysort Lopnr_PeOrgNr NED year: gegen ExpDiv=sd(D_IndExp) //missing if board size==1
sum ExpDiv
misstable sum ExpDiv
lab var ExpDiv "Diversity in industry experience"

//Board diversity in entrepreneurship experience
bysort Lopnr_PeOrgNr NED year: gegen EntExpDiv=sd(D_ENTexp) //missing if board size==1
sum EntExpDiv
misstable sum EntExpDiv
lab var EntExpDiv "Diversity in entrepreneurship experience"

keep Lopnr_PeOrgNr NED year NatCultDiv GenderIQV AgeDiv EdulevelDiv IndDiv ExpDiv EntExpDiv
gsort Lopnr_PeOrgNr NED year
collapse NatCultDiv GenderIQV AgeDiv EdulevelDiv IndDiv ExpDiv EntExpDiv,by(Lopnr_PeOrgNr NED year)
 