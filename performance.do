
//Import finance variables
use "$data_path\Firms", clear
keep Lopnr_PeOrgNr year Ftg_T27 Ftg_T26 Ftg_T18 Org_Sni2002 Org_Sni2007
gen siclevel = 2
do "$script_path\sic"
drop Org_Sni2002 Org_Sni2007
gsort Lopnr_PeOrgNr year
sum year Ftg_T27 Ftg_T27
ren Ftg_T27 profit
lab var profit "Profit margin"
ren Ftg_T26 DE_Ratio
lab var DE_Ratio "Debt to equity ratio"
ren Ftg_T18 cash
lab var cash "Cash reserves"

//PROFIT MARGIN
//impute profit from t-1 and t+1 of the same firm if profit data is missing
tsset Lopnr_PeOrgNr year
replace profit = f.profit if profit==.
replace profit = l.profit if profit==.
//calculate percent missing
sum year
local full = r(N)
sum profit
local miss = r(N)
di (`full'-`miss')/`full'

replace profit = f.profit if profit==.
replace profit = l.profit if profit==.

//again, calculate percent missing
sum year
local full = r(N)
sum profit
local miss = r(N)
di (`full'-`miss')/`full'

//DEBT-EQUITY RATIO
//impute equity capital from t-1 and t+1 of the same firm if equity capital data is missing
replace DE_Ratio = f.DE_Ratio if DE_Ratio==.
replace DE_Ratio = l.DE_Ratio if DE_Ratio==.
//calculate percent missing
sum year
local full = r(N)
sum DE_Ratio
local miss = r(N)
di (`full'-`miss')/`full'

replace DE_Ratio = f.DE_Ratio if DE_Ratio==.
replace DE_Ratio = l.DE_Ratio if DE_Ratio==.

//again, calculate percent missing
sum year
local full = r(N)
sum DE_Ratio
local miss = r(N)
di (`full'-`miss')/`full'

//CASH RESERVES 
//impute cash reserves from t-1 and t+1 of the same firm if cash reserves data is missing
replace cash = f.cash if cash==.
replace cash = l.cash if cash==.
//calculate percent missing
sum year
local full = r(N)
sum cash
local miss = r(N)
di (`full'-`miss')/`full'

replace cash = f.cash if cash==.
replace cash = l.cash if cash==.

//again, calculate percent missing
sum year
local full = r(N)
sum cash
local miss = r(N)
di (`full'-`miss')/`full'


//MEASURES
gegen p50=pctile(profit) if profit!=., p(50) by(year orgSIC)
gen high_profit=1 if profit>p50 & profit!=.
replace high_profit=0 if profit<=p50 & profit!=.
lab var high_profit "High profit"
drop p50

gegen p50=pctile(DE_Ratio), p(50) by(year orgSIC)
gen high_deratio=1 if DE_Ratio>p50 & DE_Ratio!=.
replace high_deratio=0 if DE_Ratio<=p50 & DE_Ratio!=.
lab var high_deratio "High debt-equity ratio"
drop p50

gegen p50=pctile(cash), p(50) by(year orgSIC)
gen high_cash=1 if cash>p50 & cash!=.
replace high_cash=0 if cash<=p50 & cash!=.
lab var high_cash "High cash reserves"
drop p50

keep Lopnr_PeOrgNr year profit DE_Ratio cash high_profit high_deratio high_cash
