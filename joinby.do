
//calculate the number of directors in the firm that are included in the sample

frame put Lopnr_PersonNr year greg3 female age edulevel SIC ENTexp, into(features)
cwf features
gduplicates drop
gduplicates report Lopnr_PersonNr year //there are 18 observations where education information from CEO and board data differs
bys Lopnr_PersonNr year: egen maxedu = max(edulevel)
replace edulevel = maxedu
gduplicates drop
cwf default

preserve 
keep Lopnr_PersonNr Lopnr_PeOrgNr year
tempfile distance
save `distance'
ren Lopnr_PersonNr Lopnr_PersonNrA
joinby Lopnr_PeOrgNr year using `distance'
ren Lopnr_PersonNr Lopnr_PersonNrB
drop if Lopnr_PersonNrA==Lopnr_PersonNrB
save `distance', replace
restore

frame create distance
cwf distance
use `distance'
ren Lopnr_PersonNrA Lopnr_PersonNr
frlink m:1 Lopnr_PersonNr year, frame(features)
frget greg3 female age edulevel SIC ENTexp, from(features)
ren greg3 GrEg3A
ren female GenderA
ren age AgeA
ren edulevel edulevelA
ren SIC SICA
ren ENTexp ENTexpA
drop features
ren Lopnr_PersonNr Lopnr_PersonNrA

ren Lopnr_PersonNrB Lopnr_PersonNr
frlink m:1 Lopnr_PersonNr year, frame(features)
frget greg3 female age edulevel SIC ENTexp, from(features)
ren greg3 GrEg3B
ren female GenderB
ren age AgeB
ren edulevel edulevelB
ren SIC SICB
ren ENTexp ENTexpB
drop features
ren Lopnr_PersonNr Lopnr_PersonNrB

ren Lopnr_PersonNrA Lopnr_PersonNr

//now, we have a director-director dyad dataset with their features. Next we need to calculate their difference along key variables as in Boone et al (2004)
//1.age distance
gen age_difference = abs(AgeA-AgeB)
gen age_difference2 = age_difference^2
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen sigma_agediff2 = total(age_difference2)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen n_1 = count(Lopnr_PersonNrB)
gen age_distance = sqrt(sigma_agediff2/n_1)
drop n_1 sigma_agediff2 age_difference2 age_difference AgeB AgeA 

/*Blau index is a group level measure, so we follow Boone et al. (2004) to 
calculate the squared proportion of others with the same category and subtract it from 1 for individual level distance measure*/
//2. cultural distance 
gen same_culture = cond(GrEg3A==GrEg3B,1,0)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen proportion_samecult = mean(same_culture)
gen proportion_samecult2 = proportion_samecult^2
gen Blau_culture = 1 - proportion_samecult2
drop same_culture proportion_samecult proportion_samecult2

//3. Gender
gen same_gender = cond(GenderA==GenderB,1,0)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen proportion_samegender = mean(same_gender)
gen proportion_samegender2 = proportion_samegender^2
gen Blau_gender = 1 - proportion_samegender2
drop same_gender proportion_samegender proportion_samegender2 

//4. Education
gen same_edu = cond(edulevelA==edulevelB,1,0)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen proportion_sameedu = mean(same_edu)
gen proportion_sameedu2 = proportion_sameedu^2
gen Blau_edu = 1 - proportion_sameedu2
drop same_edu proportion_sameedu proportion_sameedu2

//5. Industry background
gen same_sic = cond(SICA==SICB,1,0)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen proportion_samesic = mean(same_sic)
gen proportion_samesic2 = proportion_samesic^2
gen Blau_sic = 1 - proportion_samesic2
drop same_sic proportion_samesic proportion_samesic2

//6. Entrepreneurship experience 
gen entexp_difference = abs(ENTexpA-ENTexpB)
gen entexp_difference2 = entexp_difference^2
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen sigma_entexpdiff2 = total(entexp_difference2)
bys Lopnr_PersonNr Lopnr_PeOrgNr year: gegen n_1 = count(Lopnr_PersonNrB)
gen entexp_distance = sqrt(sigma_entexpdiff2/n_1)
drop n_1 sigma_entexpdiff2 entexp_difference2 entexp_difference ENTexpA ENTexpB 

//Overall dissimilarity
egen std_age_distance = std(age_distance)
egen std_Blau_culture = std(Blau_culture)
egen std_Blau_gender = std(Blau_gender)
egen std_Blau_edu = std(Blau_edu)
egen std_Blau_sic = std(Blau_sic)
egen std_entexp_distance = std(entexp_distance)
gen dissimilar = (std_age_distance + std_Blau_culture + std_Blau_gender + std_Blau_edu + std_Blau_sic + std_entexp_distance)/6

gen demographic_dissimilar = (std_age_distance + std_Blau_culture + std_Blau_gender)/3
gen skill_dissimilar = (std_Blau_edu + std_Blau_sic + std_entexp_distance)/3

drop Lopnr_PersonNrB GrEg3A GenderA edulevelA SICA GrEg3B GenderB edulevelB SICB
collapse age_distance Blau_culture Blau_gender Blau_edu Blau_sic entexp_distance dissimilar demographic_dissimilar skill_dissimilar, by(Lopnr_PersonNr Lopnr_PeOrgNr year)
cwf default
frame drop features

frlink 1:1 Lopnr_PersonNr Lopnr_PeOrgNr year, frame(distance)
frget age_distance Blau_culture Blau_gender Blau_edu Blau_sic entexp_distance dissimilar demographic_dissimilar skill_dissimilar, from(distance)
frame drop distance

replace age_dissimilar = age_distance 
replace culture_dissimilar = Blau_culture 
replace gender_dissimilar = Blau_gender 
replace edu_dissimilar = Blau_edu 
replace industry_dissimilar = Blau_sic 
replace entexp_dissimilar = entexp_distance
replace dissimilarity = dissimilar
replace dem_dissimilarity = demographic_dissimilar
replace skill_dissimilarity = skill_dissimilar

