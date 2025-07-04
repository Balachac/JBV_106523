
replace GrEg3=. if GrEg3==11 //recode unknown categories as missing
gen Swedish= cond(GrEg3==0,1,0)
gen Scandi= cond(GrEg3==1,1,0)
gen Euro= cond(GrEg3==2,1,0)
gen European=cond(GrEg3==3,1,0)
gen African=cond(GrEg3==4,1,0)
gen NA=cond(GrEg3==5,1,0)
gen SA=cond(GrEg3==6,1,0)
gen Asian=cond(GrEg3==7,1,0)
gen Oceania=cond(GrEg3==8,1,0)
gen Russian=cond(GrEg3==9,1,0)




