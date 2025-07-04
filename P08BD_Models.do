
//set up paths
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"

capture log close
clear all
use "$data_path\p08_sample", clear 
drop ceo

//get data on co-ownership of directors
preserve
use "$data_path\job", clear
gen co_ownership = 1 if Faman==1
replace co_ownership = 1 if YrkStallnKU == "5" & year>2009
drop if co_ownership!=1
keep Lopnr_PersonNr year Lopnr_PeOrgNr co_ownership
gduplicates report Lopnr_PersonNr year Lopnr_PeOrgNr 
tempfile job
save `job'
restore
merge 1:1 Lopnr_PersonNr year Lopnr_PeOrgNr using `job'
drop if _merge==2
drop _merge
recode co_ownership(.=0)
tab co_ownership
lab var co_ownership "Co-ownership in the venture"

//include data on director destination
do "$script_path\director_destination.do"

//income from employment
sum real_income
replace real_income=0 if real_income<0 
gen logincome = log(1+real_income)
lab var logincome "Log real income from employment"

//tenure in the board
gen logtenure = log(tenure)
lab var logtenure "Log board tenure"

corr logtenure firmage 

//include ceos into the data to calculate the distance
preserve
keep Lopnr_PeOrgNr year
gduplicates drop
tempfile ceo
save `ceo'
use Lopnr_PeOrgNr year Lopnr_PersonNr using "$data_path\ceo", clear
gen ceo = 1
merge m:1 Lopnr_PeOrgNr year using `ceo', keep(match using)
drop _merge
save `ceo', replace
restore
merge 1:1 Lopnr_PeOrgNr year Lopnr_PersonNr using `ceo'
recode ceo(.=0)
sort Lopnr_PeOrgNr year ceo_age
bys Lopnr_PeOrgNr: replace ceo_age = ceo_age[_n-1] if ceo_age==.
bys Lopnr_PeOrgNr: replace ceo_female = ceo_female[_n-1] if ceo_female==.
bys Lopnr_PeOrgNr: replace ceo_edulevel =  ceo_edulevel[_n-1] if ceo_edulevel==.
bys Lopnr_PeOrgNr: replace ceo_SIC =  ceo_SIC[_n-1] if ceo_SIC==.
bys Lopnr_PeOrgNr: replace ceo_ENTexp  =  ceo_ENTexp[_n-1] if ceo_ENTexp ==.
bys Lopnr_PeOrgNr: replace ceo_greg3  =  ceo_greg3[_n-1] if ceo_greg3==.

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
ren D_Female D_female
ren GrEg3 D_greg3
ren edulevel D_edulevel

foreach var in "age" "female" "edulevel" "SIC" "ENTexp" "greg3" {
	gen `var' = D_`var'
	replace `var' = ceo_`var' if  `var'==. & ceo==1
}

drop if edulevel==. //there are 42 observations ithout education information. Drop them

lab var age "Age"
lab var female "Female"
lab var edulevel "Education level"
lab var SIC "Industry"
lab var ENTexp "Entrepreneurship experience"
lab var greg3 "Country of birth"

drop if year==2020 //drop last year as DV will be missing
gen executive_director = cond(NED==0,1,0)

//scale cash and profit into 100,000 SEK (measures already in 100SEK)
replace profit=profit/1000
replace cash=cash/1000
gen ED_Ratio = 1/DE_Ratio
lab var ED_Ratio "Equity-Debt Ratio"
ren dynamics_lag dynamism_lag

*drop if BoardSize<3 //boards with 2 or less members are leftovers after removing family members. Consider them as family firms and drop

sum profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag
sum profit
replace profit = r(mean) if profit==.
sum ED_Ratio
replace ED_Ratio = r(mean) if ED_Ratio==.
sum cash
replace cash = r(mean) if cash==.
sum complexity_lag
replace complexity_lag = r(mean) if complexity_lag==.
sum munificence_lag
replace munificence_lag = r(mean) if munificence_lag==.
sum dynamism_lag
replace dynamism_lag = r(mean) if dynamism_lag==.

*drop if profit==. | ED_Ratio==. | cash==. | complexity_lag==. | munificence_lag==. | dynamism_lag==.

gen profit_raw = profit
gen ED_Ratio_raw = ED_Ratio 
gen cash_raw = cash
gen complexity_raw = complexity_lag 
gen munificence_raw = munificence_lag 
gen dynamism_raw = dynamism_lag

sum profit_raw ED_Ratio_raw cash_raw complexity_raw munificence_raw dynamism_raw

center profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag, replace

sum profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag 
//Are all the variables mean centered? Some doesn't seem to. Perform the calculation manually for those variables whose mean is not yet zero

foreach var of varlist profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag {
	sum `var'
	if r(mean)!=0 {
		replace `var' = `var' - r(mean)
	}
}

sum profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag //unless the mean reaches zero, the loop doesn't stop.

//high-low 
*1. complexity
sum complexity_lag
local mean r(mean)
gen complexity_high=1 if complexity_lag> `mean'
replace complexity_high=0 if complexity_lag<=`mean'
*2. munificence
sum munificence_lag
local mean r(mean)
gen munificence_high=1 if munificence_lag> `mean'
replace munificence_high=0 if munificence_lag<=`mean'
*3. dynamism
sum dynamism_lag
local mean r(mean)
gen dynamism_high=1 if dynamism_lag> `mean'
replace dynamism_high=0 if dynamism_lag<=`mean'
*4. profit
sum profit
local mean r(mean)
gen profit_high=1 if profit> `mean'
replace profit_high=0 if profit<=`mean'
*4. cash
sum cash
local mean r(mean)
gen cash_high=1 if cash> `mean'
replace cash_high=0 if cash<=`mean'
*5. ED_Ratio
sum ED_Ratio
local mean r(mean)
gen ED_Ratio_high=1 if ED_Ratio> `mean'
replace ED_Ratio_high=0 if ED_Ratio<=`mean'

winsor profit, gen(wprofit) p(0.01)
winsor ED_Ratio, gen(w_edratio) p(0.01)
winsor cash, gen(wcash) p(0.01)
winsor complexity_lag, gen(wcomplex) p(0.01) 
winsor munificence_lag, gen(wmunificence) p(0.01)
winsor dynamism_lag, gen(wdynamism) p(0.01)

sum profit ED_Ratio cash complexity_lag munificence_lag dynamism_lag
sum wprofit w_edratio wcash wcomplex wmunificence wdynamism
replace profit = wprofit
replace ED_Ratio = w_edratio
replace cash = wcash
replace complexity_lag = wcomplex
lab var complexity_lag "Industry complexity"
replace munificence_lag = wmunificence
lab var munificence_lag "Industry munificence"
replace dynamism_lag = wdynamism
lab var dynamism_lag "Industry dynamism"

drop wprofit w_edratio wcash wcomplex wmunificence wdynamism

do "$script_path\joinby"

lab var exit "Exit"
lab var dissimilarity "Dissimilarity to other directors"
lab var dem_dissimilarity "Demographic dissimilarity"
lab var skill_dissimilarity "Expertise dissimilarity"
lab var D_age "Age"
lab var D_female "Female" 
lab var D_ENTexp "Entrepreneurship experience"
lab var executive_director "Executive director"

drop if famties==1 //drop directors with family ties to one of the founders
drop famties
drop if executive_director==1
drop executive_director
drop if ceo==1
tab co_ownership

cd "$output_path"
egen cohort = group(Lopnr_PersonNr Lopnr_PeOrgNr)
local var1 dissimilarity
local var1a dem_dissimilarity 
local var1b skill_dissimilarity
local var1c culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar dissimilarity
local var2 profit
local var3 ED_Ratio
local var4 cash
local var5 complexity_lag     
local var6 munificence_lag 
local var7 dynamism_lag
local print_options2 varlabels stats(b_dfdx se_dfdx) summstat(N\ll\AIC\r2_M\Wald_chi2\Wald_p) margstars bdec(3) starloc(1) landscape
local controls D_age D_female D_edu2 D_edu3 D_edu4 D_ENTexp logboardsize Org_AntalSys firmage acquired dissolution
local c D_age D_female D_edu2 D_edu3 D_edu4 D_ENTexp logboardsize Org_AntalSys firmage acquired dissolution
local dummies i.orgSIC i.orgLAN i.year
local option vce(cluster Lopnr_PeOrgNr)

foreach var of varlist exit culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar dissimilarity `var1' `var1a' `var1b' `var2' `var3' `var4' `var5' `var6' `var7' `c' {
	drop if `var'==.
}


//Tables
//Summary stats
eststo clear
estpost sum `var1a' `var1b' `var1c' 
esttab using TAB1.rtf, cells("mean(fmt(3)) sd min max") replace label longtable nonumber nomtitle title("Table 1. Director Dissimilarity to the Board")
eststo clear
estpost sum exit `var1' `var2'  `var3'  `var4' `var5' `var6' `var7' `c'
esttab using TAB2.rtf, cells("mean(fmt(3)) sd min max") replace label longtable nonumber nomtitle title("Table 2. Descriptive Statistics")
estpost sum exit profit_raw ED_Ratio_raw cash_raw complexity_raw munificence_raw dynamism_raw
esttab using TAB2.rtf, cells("mean(fmt(3)) sd min max") append label longtable nonumber nomtitle title("Table 2. Descriptive Statistics of raw moderation variables")

//Correlations
eststo clear
estpost correlate exit `var1' `var1a' `var1b' `var1c' `var2'  `var3'  `var4' `var5' `var6' `var7' `c', matrix
esttab using TABA1.rtf, not unstack compress replace label longtable nonumbers nostar b(2) title ("Table A1. Correlation Matrix")
eststo clear

eststo clear
estpost correlate exit `var1' `var1a' `var1b' `var1c' `var2'  `var3'  `var4' `var5' `var6' `var7' co_ownership logincome logtenure `c', matrix
esttab using TABA1B.rtf, not unstack compress replace label longtable nonumbers nostar b(2) title ("Table A1B. Correlation Matrix")
eststo clear

//MODELS

//Internal and external uncertainty
logit exit `controls' `dummies', `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`controls')
outreg using TAB3, `print_options2' title("Logistic regression on director exit in Swedish NVBs, 2005-2008:" "The role of internal and external uncertainty") replace

logit exit  `var1' `controls' `dummies', `option'
test `var1' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx( `var1' `controls')
outreg using TAB3, `print_options2' replace

logit exit  `var1'  `var2'  `var3' `var4' `controls' `dummies', `option'
test `var2'  `var3' `var4' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3' `var4' `controls') atmeans
outreg using TAB3, `print_options2' merge


logit exit  `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies', `option'
test `var5' `var6' `var7' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans
outreg using TAB3, `print_options2' merge

//INTERACTIONS
gen var1var2 = `var1'*`var2'
lab var var1var2 "Dissimilarity x Profit"
gen var1var3 = `var1'*`var3'
lab var var1var3 "Dissimilarity x Equity-Debt ratio"
gen var1var4 = `var1'*`var4'
lab var var1var4 "Dissimilarity x Cash"
gen var1var5 = `var1'*`var5'
lab var var1var5 "Dissimilarity x Industry complexity"
gen var1var6 = `var1'*`var6'
lab var var1var6 "Dissimilarity x Industry munificence"
gen var1var7 = `var1'*`var7'
lab var var1var7 "Dissimilarity x Industry dynamism"

*model 4
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 `controls' `dummies', `option'
test var1var2 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 `controls') atmeans
outreg using TAB3, `print_options2' merge

*model 5
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 `controls' `dummies', `option'
test var1var3 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 `controls') atmeans
outreg using TAB3, `print_options2' merge

*model 6
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 `controls' `dummies', `option'
test var1var4 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 `controls') atmeans
outreg using TAB3, `print_options2' merge

*model 7
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 `controls' `dummies', `option'
test var1var5 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_p
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 `controls') atmeans
outreg using TAB3, `print_options2' merge

*model 8
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6  `controls' `dummies', `option'
test var1var6 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 `controls') atmeans
outreg using TAB3, `print_options2' merge

*model 9
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7  `controls' `dummies', `option'
test var1var7 //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7 `controls') atmeans
outreg using TAB3, `print_options2' merge

 
//*MARGINSPLOT
sum `var1'
/*
gen disscat = 1 if dissimilarity <= (r(mean)-(2*r(sd)))
replace disscat = 2 if dissimilarity > (r(mean)-(2*r(sd))) & dissimilarity <= r(mean)
replace disscat = 3 if dissimilarity > r(mean) & dissimilarity <= (r(mean)+(2*r(sd)))
replace disscat = 4 if dissimilarity > (r(mean)+(2*r(sd)))
*/

gen disscat = 0 if dissimilarity <= r(mean)
replace disscat = 1 if dissimilarity > r(mean)
lab def disscat 0 "Low dissimilarity" 1 "High dissimilarity", modify
lab values disscat disscat

logit exit c.`var1'##(c.`var2' c.`var3' c.`var4' c.`var5' c.`var6' c.`var7') `controls' `dummies', `option'

*Profit
sum `var2'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var2'=(`min'(`sd')`max')) 
marginsplot, xlabel(minmax) title("Profit") name(a, replace)

*Equity-Debt ratio
sum `var3'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var3'=(`min'(`sd')`max')) 
marginsplot, xlabel(minmax) title("Equity-Debt Ratio") name(b, replace)

*Cash
sum `var4'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var4'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Cash reserves") name(c, replace)

*complexity
sum `var5'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var5'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Industry complexity") name(d, replace)

*munificence
sum `var6'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var6'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Industry munificence") name(e, replace)

*dynamism
sum `var7'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1') over(r.disscat) at(`var7'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Industry dynamism") name(f, replace)

cd "$output_path"
grc1leg a b c d e f, legendfrom(a) rows(2) title("Internal and external uncertainty and director exit")
graph save Graph "$output_path\fig1.gph", replace

//POST-HOC ANALYSIS

//Table 4. demographic and expertise diversity
logit exit  `var2'  `var3'  `var4' `var5' `var6' `var7'  `controls' `dummies', `option'
test `var2'  `var3'  `var4' `var5' `var6' `var7' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var2'  `var3'  `var4' `var5' `var6' `var7' `controls')
outreg using TAB4, title("Table 4. Post-hoc analysis: Decomposition into demographic and expertise dissimilarity") `print_options2' replace

logit exit  `var1a' `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies', `option'
test `var1a' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx( `var1a' `var2'  `var3'  `var4' `var5' `var6' `var7' `controls')
outreg using TAB4, `print_options2' replace

logit exit  `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies', `option'
test `var1b' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx( `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `controls')
outreg using TAB4, `print_options2' merge

//Table 4. Environmental interactions
gen var1a_var2 = `var1a'*`var2'
lab var var1a_var2 "Demographic Dissimilarity x Profit"
gen var1b_var2 = `var1b'*`var2'
lab var var1b_var2 "Expertise Dissimilarity x Profit"
local interact1 var1a_var2 var1b_var2

gen var1a_var3 = `var1a'*`var3'
lab var var1a_var3 "Demographic Dissimilarity x Equity-Debt ratio"
gen var1b_var3 = `var1b'*`var3'
lab var var1b_var3 "Expertise Dissimilarity x Equity-Debt ratio"
local interact2 var1a_var3 var1b_var3

gen var1a_var4 = `var1a'*`var4'
lab var var1a_var4 "Demographic Dissimilarity x Cash"
gen var1b_var4 = `var1b'*`var4'
lab var var1b_var4 "Expertise Dissimilarity x Cash"
local interact3 var1a_var4 var1b_var4

gen var1a_var5 = `var1a'*`var5'
lab var var1a_var5 "Demographic Dissimilarity x Industry complexity"
gen var1b_var5 = `var1b'*`var5'
lab var var1b_var5 "Expertise Dissimilarity x Industry complexity"
local interact4 var1a_var5 var1b_var5

gen var1a_var6 = `var1a'*`var6'
lab var var1a_var6 "Demographic Dissimilarity x Industry munificence"
gen var1b_var6 = `var1b'*`var6'
lab var var1b_var6 "Expertise Dissimilarity x Industry munificence"
local interact5 var1a_var6 var1b_var6

gen var1a_var7 = `var1a'*`var7'
lab var var1a_var7 "Demographic Dissimilarity x Industry dynamism"
gen var1b_var7 = `var1b'*`var7'
lab var var1b_var7 "Expertise Dissimilarity x Industry dynamism"
local interact6 var1a_var7 var1b_var7

logit exit `var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `controls' `dummies', `option'
test `interact1' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `controls') atmeans
outreg using TAB4, `print_options2' merge

logit exit `var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `controls' `dummies', `option'
test `interact2' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `controls') atmeans
outreg using TAB4, `print_options2' merge

logit exit `var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `controls' `dummies', `option'
test `interact3' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_p
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `controls') atmeans
outreg using TAB4, `print_options2' merge

logit exit `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `controls' `dummies', `option'
test `interact4' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `controls') atmeans
outreg using TAB4, `print_options2' merge

logit exit `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `controls' `dummies', `option'
test `interact5' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `controls') atmeans
outreg using TAB4, `print_options2' merge

logit exit `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' `dummies', `option'
test `interact6' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls') atmeans
outreg using TAB4, `print_options2' merge


//Table 5. UNPACKING THE EXPERTISE DISSIMILARITY
local var1b1 edu_dissimilar 
local var1b2 industry_dissimilar 
local var1b3 entexp_dissimilar

gen var1b1_var2 = `var1b1'*`var2'
lab var var1b1_var2 "Education Dissimilarity x Profit"
gen var1b2_var2 = `var1b2'*`var2'
lab var var1b2_var2 "Industry Dissimilarity x Profit"
gen var1b3_var2 = `var1b3'*`var2'
lab var var1b3_var2 "Entrepreneurship exp. Dissimilarity x Profit"
local interact1 var1b1_var2 var1b2_var2 var1b3_var2 

gen var1b1_var3 = `var1b1'*`var3'
lab var var1b1_var3 "Education Dissimilarity x Equity-Debt Ratio"
gen var1b2_var3 = `var1b2'*`var3'
lab var var1b2_var3 "Industry Dissimilarity x Equity-Debt Ratio"
gen var1b3_var3 = `var1b3'*`var3'
lab var var1b3_var3 "Entrepreneurship exp. Dissimilarity x Equity-Debt Ratio"
local interact2 var1b1_var3 var1b2_var3 var1b3_var3

gen var1b1_var4 = `var1b1'*`var4'
lab var var1b1_var4 "Education Dissimilarity x Cash"
gen var1b2_var4 = `var1b2'*`var4'
lab var var1b2_var4 "Industry Dissimilarity x Cash"
gen var1b3_var4 = `var1b3'*`var4'
lab var var1b3_var4 "Entrepreneurship exp. Dissimilarity x Cash"
local interact3 var1b1_var4 var1b2_var4 var1b3_var4

gen var1b1_var5 = `var1b1'*`var5'
lab var var1b1_var5 "Education Dissimilarity x Industry complexity"
gen var1b2_var5 = `var1b2'*`var5'
lab var var1b2_var5 "Industry Dissimilarity x Industry complexity"
gen var1b3_var5 = `var1b3'*`var5'
lab var var1b3_var5 "Entrepreneurship exp. Dissimilarity x Industry complexity"
local interact4 var1b1_var5 var1b2_var5 var1b3_var5

gen var1b1_var6 = `var1b1'*`var6'
lab var var1b1_var6 "Education Dissimilarity x Industry munificence"
gen var1b2_var6 = `var1b2'*`var6'
lab var var1b2_var6 "Industry Dissimilarity x Industry munificence"
gen var1b3_var6 = `var1b3'*`var6'
lab var var1b3_var6 "Entrepreneurship exp. Dissimilarity x Industry munificence"
local interact5 var1b1_var6 var1b2_var6 var1b3_var6

gen var1b1_var7 = `var1b1'*`var7'
lab var var1b1_var7 "Education Dissimilarity x Industry dynamism"
gen var1b2_var7 = `var1b2'*`var7'
lab var var1b2_var7 "Industry Dissimilarity x Industry dynamism"
gen var1b3_var7 = `var1b3'*`var7'
lab var var1b3_var7 "Entrepreneurship exp. Dissimilarity x Industry dynamism"
local interact6 var1b1_var7 var1b2_var7 var1b3_var7

logit exit `var1b1' `var1b2' `var1b3'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies', `option'
test `var1b1' `var1b2' `var1b3' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans
outreg using TAB5, title("Table 5. Post-hoc analysis: Unpacking the role of expertise dissimilarity") `print_options2' replace

logit exit `var1b1' `var1b2' `var1b3'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `controls' `dummies', `option'
test `interact1' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `controls') atmeans
outreg using TAB5, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `controls' `dummies', `option'
test `interact2' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `controls') atmeans
outreg using TAB5, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `controls' `dummies', `option'
test `interact3' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `controls') atmeans
outreg using TAB5, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `controls' `dummies', `option'
test `interact4' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3'  `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `controls') atmeans
outreg using TAB5, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `controls' `dummies', `option'
test `interact5' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `controls') atmeans
outreg using TAB5, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' `dummies', `option'
test `interact6' //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls') atmeans
outreg using TAB5, `print_options2' merge


//APPENDIX

//Table A3. Dissimilarity measures
logit exit culture_dissimilar `controls' `dummies', `option'
test culture_dissimilar // Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar `controls') atmeans
outreg using TABA3, title("Table A3. Decomposition of director dissimilarity into separate components") `print_options2' keep(culture_dissimilar) replace

logit exit culture_dissimilar gender_dissimilar `controls' `dummies', `option'
test gender_dissimilar //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar gender_dissimilar `controls') atmeans
outreg using TABA3, `print_options2' keep(culture_dissimilar gender_dissimilar) merge

logit exit culture_dissimilar gender_dissimilar age_dissimilar `controls' `dummies', `option'
test age_dissimilar //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar gender_dissimilar age_dissimilar `controls') atmeans
outreg using TABA3, `print_options2' keep(culture_dissimilar gender_dissimilar age_dissimilar) merge

logit exit culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar `controls' `dummies', `option'
test edu_dissimilar //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar `controls') atmeans
outreg using TABA3, `print_options2' keep(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar) merge

logit exit culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar `controls' `dummies', `option'
test industry_dissimilar //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar `controls') atmeans
outreg using TABA3, `print_options2' keep(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar) merge

logit exit culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar `controls' `dummies', `option'
test entexp_dissimilar //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar `controls') atmeans
outreg using TABA3, `print_options2' keep(culture_dissimilar gender_dissimilar age_dissimilar edu_dissimilar industry_dissimilar entexp_dissimilar) merge

//Table A4. EFFECT SIZES OVER LIFECYCLE
gen venture_lifecycle = 1 if firmage<=5
replace venture_lifecycle = 2 if firmage>5 & firmage<=10
replace venture_lifecycle = 3 if firmage>10
lab def venture_lifecycle 1 "1-5" 2 "6-10" 3 "11+"
lab values venture_lifecycle venture_lifecycle

logit exit  `var1' `controls' `dummies' if venture_lifecycle==1, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx( `var1' `controls')
outreg using TABA4, title("Effect sizes over lifecycle") `print_options2' replace

logit exit  `var1' `controls' `dummies' if venture_lifecycle==2, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx( `var1' `controls')
outreg using TABA4, `print_options2' merge

logit exit  `var1' `controls' `dummies' if venture_lifecycle==3, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx( `var1' `controls')
outreg using TABA4, `print_options2' merge

//Table A5. sensitiveness to firm size distribution
logit exit  `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies' if Org_AntalSys>1, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans noestimcheck
outreg using TABA5, title("Sensitiveness to firm size distribution") `print_options2' replace

logit exit  `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies' if Org_AntalSys<=150, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans noestimcheck
outreg using TABA5, `print_options2' merge

logit exit  `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies' if Org_AntalSys<=50, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans
outreg using TABA5, `print_options2' merge

logit exit  `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls' `dummies' if Org_AntalSys<=10, `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' `controls') atmeans noestimcheck
outreg using TABA5, `print_options2' merge

//EFFECT SIZES OVER INDUSTRIES
logit exit  c.`var1' c.`var1'#i.orgSIC `controls' `dummies', `option'
margins, dydx(`var1') at(`var1'=(0(0.2)1)) over(orgSIC)
marginsplot
graph save Graph "$output_path\effect_sizes_sic.gph", replace

//FURTHER ROBUSTNESS CHECKS

sum `var1b2'

gen disscat2 = 0 if `var1b2' <= r(mean)
replace disscat2 = 1 if `var1b2' > r(mean)
lab def disscat2 0 "Low industry dissimilarity" 1 "High industry dissimilarity", modify
lab values disscat2 disscat2

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' `dummies', `option'
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls') atmeans

*Cash
sum `var4'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1b2') at(`var4'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Cash reserves") name(a, replace)

*complexity
sum `var5'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1b2') at(`var5'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Industry complexity") name(b, replace)

*dynamism
sum `var7'
local sd = r(sd)
local min = r(mean)-(2*r(sd))
local max = r(mean)+(2*r(sd))

margins, dydx(`var1b2') over(r.disscat) at(`var7'=(`min'(`sd')`max'))
marginsplot, xlabel(minmax) title("Industry dynamism") name(c, replace)

grc1leg a b c, legendfrom(a) rows(1)
graph save Graph "$output_path\fig2.gph", replace

//Tables 6 and 7. Frquency tables of post-hoc tests
asdoc tabulate exit_type, cocf replace
asdoc tabulate exit_type D_female, col cocf append
asdoc tabulate exit_type D_native, col cocf append

//now tabulate based on director dissimilarity to the board
sum culture_dissimilar, detail
gen culture_dissimilar_dummy = cond(culture_dissimilar>=r(mean),1,0)
tab culture_dissimilar_dummy
lab var culture_dissimilar_dummy "Cultural dissimilaity (low/high)"

sum gender_dissimilar, detail
gen gender_dissimilar_dummy = cond(gender_dissimilar>=r(mean),1,0)
tab gender_dissimilar_dummy
lab var gender_dissimilar_dummy "Gender dissimilarity (low/high)"

sum age_dissimilar, detail
gen age_dissimilar_dummy = cond(age_dissimilar>=r(mean),1,0)
tab age_dissimilar_dummy
lab var age_dissimilar_dummy "Age dissimilarity (low/high)"

sum edu_dissimilar, detail
gen edu_dissimilar_dummy = cond(edu_dissimilar>=r(mean),1,0)
tab edu_dissimilar_dummy
lab var edu_dissimilar_dummy "Education dissimilaity (low/high)"

sum industry_dissimilar, detail
gen industry_dissimilar_dummy = cond(industry_dissimilar>=r(mean),1,0)
tab industry_dissimilar_dummy
lab var industry_dissimilar_dummy "Industry background dissimilaity (low/high)"

sum entexp_dissimilar, detail
gen entexp_dissimilar_dummy = cond(entexp_dissimilar>=r(mean),1,0)
tab entexp_dissimilar_dummy
lab var entexp_dissimilar_dummy "Entrepreneurship exp dissimilarity (low/high)"

//exit destination and director dissimilarity to the board
asdoc tabulate exit_type culture_dissimilar_dummy, col cocf append
asdoc tabulate exit_type gender_dissimilar_dummy, col cocf append
asdoc tabulate exit_type age_dissimilar_dummy, col cocf append
asdoc tabulate exit_type edu_dissimilar_dummy, col cocf append
asdoc tabulate exit_type industry_dissimilar_dummy, col cocf append
asdoc tabulate exit_type entexp_dissimilar_dummy, col cocf append

//t-test of salary
preserve
keep if exit_type==1|exit_type==2
asdoc ttest real_income==real_f_income, append
bys D_female: asdoc ttest real_income==real_f_income, rowappend
bys D_native: asdoc ttest real_income==real_f_income, rowappend

asdoc ttest real_income==real_f_income, append
bys culture_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
bys gender_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
bys age_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
bys edu_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
bys industry_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
bys entexp_dissimilar_dummy: asdoc ttest real_income==real_f_income, rowappend
restore


//Additional regressions that control for ownership, tenure, and salary

//Table 3 replication
logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7  `controls' `dummies', `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7 `controls') atmeans
outreg using TABA8, `print_options2' title("Logistic regression on director exit in Swedish NVBs, 2005-2008:" "Robustness check with additional controls") replace

logit exit `var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7  `controls' co_ownership logincome logtenure `dummies', `option'
test co_ownership logincome logtenure //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1'  `var2'  `var3'  `var4' `var5' `var6' `var7' var1var2 var1var3 var1var4 var1var5 var1var6 var1var7 `controls' co_ownership logincome logtenure) atmeans
outreg using TABA8, `print_options2' merge

//Table 4 replication
logit exit `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' `dummies', `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls') atmeans
outreg using TABA8, `print_options2' merge

logit exit `var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' co_ownership logincome logtenure `dummies', `option'
test co_ownership logincome logtenure //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1a' `var1b' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' co_ownership logincome logtenure) atmeans
outreg using TABA8, `print_options2' merge

//Table 5 replication
logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' `dummies', `option'
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls') atmeans
outreg using TABA8, `print_options2' merge

logit exit `var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' co_ownership logincome logtenure `dummies', `option'
test co_ownership logincome logtenure //Wald test
scalar wald_chi2 = r(chi2)
scalar wald_p = r(p)
fitstat
estadd scalar r2_M = r(r2_mf)
estadd scalar AIC = r(aic)
estadd scalar Wald_chi2 = wald_chi2
estadd scalar Wald_p = wald_p
margins, dydx(`var1b1' `var1b2' `var1b3' `var2'  `var3'  `var4' `var5' `var6' `var7' `interact1' `interact2' `interact3' `interact4' `interact5' `interact6' `controls' co_ownership logincome logtenure) atmeans
outreg using TABA8, `print_options2' merge


	