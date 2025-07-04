//set up paths
global project_path "\\micro.intra\Projekt\P0833$\P0833_Gem\Chanchal_Karl"
global data_path "$project_path\Data"
global script_path "$project_path\Scripts"
global output_path "$project_path\Output"

use Lopnr_PersonNr year Lopnr_PeOrgNr LonFInk YrkStallnKU using "$data_path\job" 
gduplicates report Lopnr_PersonNr year Lopnr_PeOrgNr
gduplicates drop Lopnr_PersonNr year Lopnr_PeOrgNr, force

frame create list
cwf list
use Lopnr_PersonNr using "$data_path\p08_sample", clear
gduplicates drop
cwf default
frlink m:1 Lopnr_PersonNr, frame(list)
drop if list==.
drop list
frame drop list
//now we have the job data of all directors in our master sample
keep Lopnr_PersonNr year Lopnr_PeOrgNr LonFInk YrkStallnKU
save "$data_path\director_job", replace