
//Director's destination
frame create all
cwf all
use "$data_path\Board_micro"
keep Lopnr_PersonNr year Lopnr_PeOrgNr FtgSni07 Director
egen cohort = group(Lopnr_PersonNr Lopnr_PeOrgNr)
gsort cohort year
tsset cohort year
tsspell cohort
ren _seq tenure
bys Lopnr_PersonNr year: egen any_board = mean(Director)
replace any_board = 1 if any_board>0
frame put Lopnr_PersonNr year any_board, into(future_board)
cwf future_board
gduplicates drop
tsset Lopnr_PersonNr year
gen f_director = f.any_board
recode f_director(.=0)
keep Lopnr_PersonNr year f_director
cwf all
keep Lopnr_PersonNr Lopnr_PeOrgNr year tenure
frlink m:1 Lopnr_PersonNr year, frame(future_board)
frget f_director, from(future_board)
frame drop future_board
drop future_board

cwf default
drop tenure //the tenure variable in the main data does not account for gaps in appointment
frlink 1:1 Lopnr_PersonNr Lopnr_PeOrgNr year, frame(all)
frget tenure f_director, from(all)
gen exit_to_director = cond(f_director==1 & exit==1,1,0)
tab exit_to_director
lab var exit_to_director "Exit with other directorships"
drop all //drop the linkage to the frame "all"

cwf all
use "$data_path\director_job", clear
keep if YrkStallnKU== "2" //first, consider only salaried employment 
bys Lopnr_PersonNr year: egen total_income = total(LonFInk)
collapse total_income, by(Lopnr_PersonNr year)
tsset Lopnr_PersonNr year
gen f_total_income = f.total_income
tsset, clear

//Adjust for inflation using 2004 base 
frame create cpi
cwf cpi 
do "$script_path\CPI"
cwf all
frlink m:1 year, frame(cpi)
frget CPI_2004 CPI_2004base, from(cpi)
drop cpi
frame drop cpi
gen real_income = total_income*(CPI_2004/CPI_2004base)
gen real_f_income = f_total_income*(CPI_2004/CPI_2004base)

cwf default
frlink m:1 Lopnr_PersonNr year, frame(all)
frget real_income real_f_income, from(all)

gen exit_to_employment = cond(real_f_income!=0 & real_f_income!=. & f_director==0 & exit==1,1,0)
lab var exit_to_employment "Exit to employment"
drop all //this will drop the linkage

cwf all
use "$data_path\director_job", clear
keep if YrkStallnKU != "2" //second, consider self-employment 
bys Lopnr_PersonNr year: egen total_income = total(LonFInk)
collapse total_income, by(Lopnr_PersonNr year)
tsset Lopnr_PersonNr year
gen f_total_income = f.total_income
tsset, clear

//Adjust for inflation using 2004 base 
frame create cpi
cwf cpi 
do "$script_path\CPI"
cwf all
frlink m:1 year, frame(cpi)
frget CPI_2004 CPI_2004base, from(cpi)
drop cpi
frame drop cpi
gen real_se_income = total_income*(CPI_2004/CPI_2004base)
gen real_se_f_income = f_total_income*(CPI_2004/CPI_2004base)

cwf default
frlink m:1 Lopnr_PersonNr year, frame(all)
frget real_se_income real_se_f_income, from(all)

gen exit_to_selfemployment = cond(real_se_f_income!=. & exit_to_employment==0 & f_director==0 & exit==1,1,0)
lab var exit_to_selfemployment "Exit to self-employment" 

replace real_income =  real_se_income if real_income==. //combine salaried and self-employment income into one variable
replace  real_f_income = real_se_f_income if real_f_income==. //combine salaried and self-employment income into one variable
drop real_se_income real_se_f_income

gen exit_to_inactivity = cond(exit_to_director==0 & exit_to_employment==0 & exit_to_selfemployment==0 & exit==1,1,0) //since exit is coded as zero when the director retires or emigrates abroad, the only other option is exit to inactivity
lab var exit_to_inactivity "Exit to unemployment/inactivity"

gen exit_type = 1 if exit_to_director==1
replace exit_type = 2 if exit_to_employment==1
replace exit_type = 3 if exit_to_selfemployment==1
replace exit_type = 4 if exit_to_inactivity == 1
replace exit_type = 0 if exit==0 & exit_type==.
lab def exit_type 0 "Remain as director" 1 "Exit to other directorships" 2 "Exit to employment" 3 "Exit to self-employment" 4 "Exit to inactivity"
lab values exit_type exit_type
tab exit_type