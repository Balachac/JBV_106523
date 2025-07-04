

//set up paths
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"


/*Structure of the program
Run the do files in the following order. The sub-sections indicates the do files that are called from within the parent file. First set of files will prepare the data (1.*). Second set of files will perform analysis (2.*)


1. P08BD_Data_Micro.do
	1.1 Board.do
	1.2 Individuals.do
	1.3 Firms.do
	1.4 FAD.do
	1.5 industry_dynamics.do
		1.5.1 sic.do
	1.6. job.do
	1.7 ceo.do
		1.7.1 sic.do
		1.7.2 LM experience.do
	1.8 director_career.do
	1.9 sic.do
	1.10 director controls.do
		1.10.1 sic.do
		1.10.2 LM experience.do
	1.11 founder controls
		1.11.1 sic.do
		1.11.2 LM experience.do
	1.12 family ties.do
	1.12 performance.do
		1.12.1 sic.do
	1.13 diversity.do
		1.13.1 EthnicGroups
		
2. P08BD_Models.do
	2.1 director_destination
		2.1.1 CPI.do
		2.2.2 CPI.do
	2.2 joinby.do
*/

//1. prepare data
do "$script_path\P08BD_Data_Micro.do"

//2. analyze
do "$script_path\P08BD_Models"

