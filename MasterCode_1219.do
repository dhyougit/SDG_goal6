*********************************************************  Master do file  ***** 


clear all
set more off
use Graph_data.dta

**************** Initial code for basic analysis 
** 0. Database review 
drop *notused*
drop  piped_used_* surface_used_* sewer_used_* shared_used_* opendefecation_used_*
drop source 
drop if country_file==""
sort country_file

egen freqwat=count(totalimprovedwat_used_t) , by(country_file)
egen freqsan=count(totalimprovedsan_used_t) , by(country_file)
egen freqwatU=count(totalimprovedwat_used_u) , by(country_file)
egen freqsanU=count(totalimprovedsan_used_u) , by(country_file)
egen freqwatR=count(totalimprovedwat_used_r) , by(country_file)
egen freqsanR=count(totalimprovedsan_used_r) , by(country_file)
order country_file code year totalimprovedwat_used_t totalimprovedsan_used_t totalimprovedwat_used_u totalimprovedwat_used_r totalimprovedsan_used_u totalimprovedsan_used_r  freqwat freqsan freqwatU freqwatR freqsanU freqsanR	
save "/./Desktop/3files/Graph_data_clearFreq.dta", replace

collapse (count)  totalimprovedwat_used_t totalimprovedsan_used_t  (mean) meanwat= totalimprovedwat_used_t meansan= totalimprovedsan_used_t  (sd) sdwat= totalimprovedwat_used_t sdsan= totalimprovedsan_used_t , by(country_file)
gen freqsanCat="San_>10" if  freqsan>10
replace freqsanCat="5<San_<10" if  freqsan>5&freqsan<=10
replace freqsanCat="San_<5" if  freqsan<=5
replace  freqsanCat="a.San_<5" if  freqsanCat=="San_<5"
replace  freqsanCat="b.5<San_<10" if  freqsanCat=="5<San_<10"
replace  freqsanCat="c.San_>10" if  freqsanCat=="San_>10"

gen freqwatCat="Wat_>10" if  freqwat>10
replace freqwatCat="5<Wat_<10" if  freqwat>5&freqwat<=10
replace freqwatCat="Wat_<5" if  freqwat<=5
replace  freqwatCat="a.Wat_<5" if  freqwatCat=="Wat_<5"
replace  freqwatCat="b.5<Wat_<10" if  freqwatCat=="5<Wat_<10"
replace  freqwatCat="c.Wat_>10" if  freqwatCat=="Wat_>10"

///// Recommend: Do not run below code unless it is the final calculation purpose or labeling 
list  country_file freq* if  freqwat==0 | freqsan==0
gen data_drop=""
replace data_drop="No observe" if freqwat==0 | freqsan==0
drop if data_drop=="No observe"
replace data_drop="No observ_water" if freqwatU==0 | freqwatR==0
drop if data_drop=="No observ_water"
replace data_drop="No observ_san" if freqsanU==0 | freqsanR==0
drop if data_drop=="No observ_san"
list  country_file freq* if  freqwatU==0 |freqwatR==0 | freqsanU==0 |freqsanR==0
egen saturation=rowmean(totalimprovedwat_used_t totalimprovedsan_used_t totalimprovedwat_used_u totalimprovedsan_used_u totalimprovedwat_used_r totalimprovedsan_used_r )
replace data_drop="near 100" if saturation>98 &saturation!=. 
drop if data_drop=="near 100"
replace data_drop="Before 1990" if year<1990
tab data_drop

 // Using individual value and combination of "OR |" command loses average 600 data points per indicator => Use the rowmean command. 
 // Do not use this method (Use the rowmean and define >98 for least data lost 
 //replace data_drop="near 100" if totalimprovedwat_used_t>98&totalimprovedwat_used_t!=.
 //replace data_drop="near 100" if totalimprovedsan_used_t>98&totalimprovedsan_used_t!=.
 //replace data_drop="near 100" if totalimprovedwat_used_u>98&totalimprovedwat_used_u!=.
 //replace data_drop="near 100" if totalimprovedwat_used_r>98&totalimprovedwat_used_r!=.
 //replace data_drop="near 100" if totalimprovedsan_used_u>98&totalimprovedsan_used_u!=.
 //replace data_drop="near 100" if totalimprovedsan_used_r>98&totalimprovedsan_used_r!=.


** 1. Graph building per country 
do graphbuilding.do // Generates initial plots 
do AlternativeCountingCode.do // Database N check for reference 


*ver 0720: Generate to append the year value up to 2020 
use Graph_data_original.dta
tabstat year, by(country_file) s(max, min) // copy value to excel and generate as dta file.
clear
br

use "/./Dropbox/2016_WASH/3files/yearAppend_Original.dta"

//generate base variables
rename var1 country_file
rename var2 yearmax
rename var3 yearmin


//generate space for wide form
quietly forvalues j = 1(1)40 {
			generate country`j'=country_file if country_file=="Afghanistan'"
			}			

// fill country name for each year slate  
levelsof country_file, local(levels) 
 foreach i of local levels {
 forvalues j = 1(1)40 {
	replace country`j'=country_file if country_file=="`i'" 
}
}

//reshape to long to create space for "predicted year" N: Whatever last year of data observation to 2020 
gen n=_n
reshape long country, i(n) j(year_n)
gen year_predict= year_n+ yearmax
drop if year_predict>2020


drop if year_n>5
drop n  year_n  country
gen code="year_Predict" if year_predict!=.
rename year_predict year

save year_predict5.dta


drop if year_n>3
drop n  year_n  country
gen code="year_Predict" if year_predict!=.
rename year_predict year

save year_predict2.dta



** 2. Year appending for forecasting database preparation 
		do yearAppend.do  /// Generates extra 5 or 2 years for the forecasting 
		gen yearmin=.
		gen yearmax=.
		
		//append using year_predict // Use this for year forecasting till 2020
		append using year_predict5   // Use this for year forecating +5
		save Graph_data_Yearappend5.dta,replace
		bys country_file: egen yearmin = min(year)
		sort country_file year
		replace yearmin=. if code=="year_Predict"
		drop yearmin
		drop yearmax
		save "/./Dropbox/2016_WASH/3files/Graph_data_5year.dta" ,replace
		
		append using year_predict2 // Use this for year forecating +2
		save Graph_data_Yearappend2.dta,replace
		bys country_file: egen yearmin = min(year)
		sort country_file year
		replace yearmin=. if code=="year_Predict"
		drop yearmin
		drop yearmax
		save "/./Dropbox/2016_WASH/3files/Graph_data_2year.dta" ,replace


** 3. Subsample random selection and sensitivity check (measurement: RMSE) 
do 90_75_50_SamplingRMSEcomparison.do 

** 4. OLS,Piecewaise, quadratic
do OLS_piecewise_quadratic.do // OLS,Poecewaise, quadratic Graph building 
do OLS_piecewise_quadratic_faster.do // OLS,Poecewaise, quadratic Graph building 
do OLS_piecewise_quadratic_faster_Extrapolation.do // mipolate forward method applied 

** 5. Nonlinear fit method sensitivity check (measurement: RMSE) 
do RMSE_comparison_NonlinearFit.do 

** 6. Extrapolation method check (measurement : difference of last know value vs last extrapolated value )
do ExtrapolationValueCheck.do


***************************graphbuilding.do**********************************************************************

* ver 7.14
* Ver 7.15 : Total grpah into urban & rural // Change the country title starting with capital letter // Change graph background 
use Graph_data.dta


********************* TOTAL graph *******************************************
foreach i in argentina   aruba   barbados   belize   bolivia   brazil   chile   colombia   costa_rica   cuba   dominica   dominican_republic   ecuador   el_salvador   french_guiana   guadeloupe   guatemala   guyana   haiti   honduras   jamaica   martinique   mexico   nicaragua   panama   paraguay   peru   puerto_rico   reunion   saint_kitts_and_nevis   saint_lucia   south_sudan   st_vincent_and_grenad   suriname   united_states_virgin_islands   uruguay   venezuela  {
	
		sum freqwat if country_file=="`i'" 
		scatter  totalimprovedwat_used_t  year if  country_file=="`i'", ysc(range(0 110) extend) ytick(9) title("`i'") ylabel(#5) ymtick(##10) ytitle("Total Improved water (used)") caption("N=`r(mean)'") saving(water_`i') 
		
		sum freqsan if country_file=="`i'" 
		scatter  totalimprovedsan_used_t  year if  country_file=="`i'", ysc(range(0 110) extend) ytick(9) title("`i'") ylabel(#5) ymtick(##10) ytitle("Total Improved sanitation (used)") caption("N=`r(mean)'") graphregion(color(white)) bgcolor(white) msymbol(O) mlcolor(gs5) mfcolor(gs14) saving(sanitation_`i') 
		graph combine water_`i'.gph sanitation_`i'.gph, col(2) iscale(0.8) ycommon xsize(10)
		graph export `i'.png, replace
	
		}
	
	
	
	foreach i in Arab_emirates_united   Armenia   Australia   Austria   Azerbaijan   Bahamas   Bahrain   Bangladesh   Belarus   Belgium   Benin   Bhutan   Bosnia_herzegovina   Botswana   British_Virgin_Islands   Bulgaria   Burkina_Faso   Burundi   Cambodia   Cameroon   Canada   Cape_Verde   Cayman_islands   Central_african_rep   Chad   China   Comoros   Congo   Congo_dem_rep_of   Cook_islands   Cote_d_Ivoire   Croatia Cyprus   Czech_rep   Denmark   Djibouti   Egypt   Eritrea   Estonia   Ethiopia   Fiji   Finland   France   Gabon   Gambia   Georgia   Germany   Ghana   Greece   Greenland   Grenada   Guam   Guinea   Guinea_Bissau    Hungary   Iceland   India   Indonesia   Iran_islamic_rep_of   Iraq   Ireland   Israel   Italy   Japan   Jordan   Kazakhstan   Kenya   Kiribati   Korea_dem_peoples_rep_of   Korea_rep_of   Kuwait   Kyrgyzstan   Lao_people_dem_rep   Latvia   Lebanon   Lesotho   Liberia   Libyan_arab_jamahiriya   Lithuania   Luxembourg   Macedonia_TFYR   Madagascar   Malawi   Malaysia   Maldives   Mali   Malta   Mariana_islands_northern   Marshall_islands   Mauritania   Mauritius   Mayotte   Micronesia_fed_states_of   Moldova_rep_of   Monaco   Mongolia   Montenegro   Montserrat   Morocco   Mozambique   Myanmar   Namibia   Nauru   Nepal   Netherlands    New_Zealand   New_caledonia   Niger   Nigeria   Niue   Norway   Oman   Pakistan   Palau   Palestine   Papua_new_guinea   Philippines   Poland   Polynesia_french   Portugal   Qatar   Romania   Russian_fed   Rwanda   Samoa   Samoa_american   Sao_tome_and_principe   Saudi_arabia   Senegal   Serbia   Seychelles   Sierra_Leone   Singapore   Slovakia   Slovenia   Solomon_islands   Somalia   South_Africa   Spain   Sri_lanka   Sudan   Swaziland   Sweden   Switzerland   Syrian_arab_rep   Tajikistan   Tanzania_united_rep_of   Thailand   Timor_leste_Dem_rep_of   Togo   Tokelau   Tonga   Trinidad_and_Tobago   Tunisia   Turkey   Turkmenistan   Turks_and_Caicos_Islands   Tuvalu   Uganda   Ukraine   United_kingdom   Uzbekistan   Vanuatu   Viet_Nam   Yemen   Zambia   Zimbabwe   {
	
		sum freqwat if country_file=="`i'" 
		scatter  totalimprovedwat_used_t  year if  country_file=="`i'", ysc(range(0 110) extend) ytick(9) title("`i'") ylabel(#5) ymtick(##10) ytitle("Total Improved water (used)") caption("N=`r(mean)'") saving(water_`i') 
		
		sum freqsan if country_file=="`i'" 
		scatter  totalimprovedsan_used_t  year if  country_file=="`i'", ysc(range(0 110) extend) ytick(9) title("`i'") ylabel(#5) ymtick(##10) ytitle("Total Improved sanitation (used)") caption("N=`r(mean)'") graphregion(color(white)) bgcolor(white) msymbol(O) mlcolor(gs5) mfcolor(gs14) saving(sanitation_`i') 
		graph combine water_`i'.gph sanitation_`i'.gph, col(2) iscale(0.8) ycommon xsize(10)
		graph export `i'.png, replace
	
		}
		
		
		
		
********************* URBAN + RURAL  graph *******************************************
foreach i in  Arab_emirates_united   Armenia   Australia   Austria   Azerbaijan   Bahamas   Bahrain   Bangladesh   Belarus   Belgium   Benin   Bhutan   Bosnia_herzegovina   Botswana   British_Virgin_Islands   Bulgaria   Burkina_Faso   Burundi   Cambodia   Cameroon   Canada   Cape_Verde   Cayman_islands   Central_african_rep   Chad   China   Comoros   Congo   Congo_dem_rep_of   Cook_islands   Cote_d_Ivoire   Croatia Cyprus   Czech_rep   Denmark   Djibouti   Egypt   Eritrea   Estonia   Ethiopia   Fiji   Finland   France   Gabon   Gambia   Georgia   Germany   Ghana   Greece   Greenland   Grenada   Guam   Guinea   Guinea_Bissau    Hungary   Iceland   India   Indonesia   Iran_islamic_rep_of   Iraq   Ireland   Israel   Italy   Japan   Jordan   Kazakhstan   Kenya   Kiribati   Korea_dem_peoples_rep_of   Korea_rep_of   Kuwait   Kyrgyzstan   Lao_people_dem_rep   Latvia   Lebanon   Lesotho   Liberia   Libyan_arab_jamahiriya   Lithuania   Luxembourg   Macedonia_TFYR   Madagascar   Malawi   Malaysia   Maldives   Mali   Malta   Mariana_islands_northern   Marshall_islands   Mauritania   Mauritius   Mayotte   Micronesia_fed_states_of   Moldova_rep_of   Monaco   Mongolia   Montenegro   Montserrat   Morocco   Mozambique   Myanmar   Namibia   Nauru   Nepal   Netherlands    New_Zealand   New_caledonia   Niger   Nigeria   Niue   Norway   Oman   Pakistan   Palau   Palestine   Papua_new_guinea   Philippines   Poland   Polynesia_french   Portugal   Qatar   Romania   Russian_fed   Rwanda   Samoa   Samoa_american   Sao_tome_and_principe   Saudi_arabia   Senegal   Serbia   Seychelles   Sierra_Leone   Singapore   Slovakia   Slovenia   Solomon_islands   Somalia   South_Africa   Spain   Sri_lanka   Sudan   Swaziland   Sweden   Switzerland   Syrian_arab_rep   Tajikistan   Tanzania_united_rep_of   Thailand   Timor_leste_Dem_rep_of   Togo   Tokelau   Tonga   Trinidad_and_Tobago   Tunisia   Turkey   Turkmenistan   Turks_and_Caicos_Islands   Tuvalu   Uganda   Ukraine   United_kingdom   Uzbekistan   Vanuatu   Viet_Nam   Yemen   Zambia   Zimbabwe  	 Argentina Aruba Barbados Belize Bolivia Brazil Chile Colombia Costa_Rica Cuba Dominica Dominican_Republic Ecuador El_Salvador French_Guiana Guadeloupe Guatemala Guyana Haiti Honduras Jamaica Martinique Mexico Nicaragua Panama Paraguay Peru Puerto_Rico Reunion Saint_Kitts_And_Nevis Saint_Lucia South_Sudan St_Vincent_And_Grenad Suriname United_States_Virgin_Islands Uruguay Venezuela {

		sum freqwatU if country_file=="`i'" 
		scatter  totalimprovedwat_used_u  year if  country_file=="`i'",  xscale(r(1980 2020)) xlab(1985 1995 2005 2015) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved water") subtitle("Urban",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue)  saving(Wat_`i'_urban) 
		sum freqwatR if country_file=="`i'" 
		scatter  totalimprovedwat_used_r  year if  country_file=="`i'", xscale(r(1980 2020)) xlab(1985 1995 2005 2015) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved water") subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(Wat_`i'_rural)
		
		sum freqsanU if country_file=="`i'" 
		scatter  totalimprovedsan_used_u  year if  country_file=="`i'", xscale(r(1980 2020)) xlab(1985 1995 2005 2015) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved sanitation") subtitle("Urban",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue)  saving(San_`i'_urban) 
		sum freqsanR if country_file=="`i'" 
		scatter  totalimprovedsan_used_r  year if  country_file=="`i'", xscale(r(1980 2020)) xlab(1985 1995 2005 2015) ysc(range(0 110) extend)  ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved sanitation") subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(San_`i'_rural)

		graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.8) ycommon  xsize(5) ysize(8) title("`i'")
		graph export `i'.png, replace
		}
		
		
*************************************** use yearAppend.do***********************************************************************************************************

*ver 0720: Generate to append the year value up to 2020 

use Graph_data_original.dta
tabstat year, by(country_file) s(max, min) // copy value to excel and generate as dta file.
clear
br

use "/./Dropbox/2016_WASH/3files/yearAppend_Original.dta"

*generate base variables
rename var1 country_file
rename var2 yearmax
rename var3 yearmin


* generate space for wide form
quietly forvalues j = 1(1)40 {
			generate country`j'=country_file if country_file=="Afghanistan'"
			}			

* fill country name for each year slate  
levelsof country_file, local(levels) 
 foreach i of local levels {
 forvalues j = 1(1)40 {
	replace country`j'=country_file if country_file=="`i'" 
}
}

* reshape to long to create space for "predicted year" N: Whatever last year of data observation to 2020 
gen n=_n
reshape long country, i(n) j(year_n)
gen year_predict= year_n+ yearmax
drop if year_predict>2020


drop if year_n>5
drop n  year_n  country
gen code="year_Predict" if year_predict!=.
rename year_predict year

save year_predict5.dta


drop if year_n>3
drop n  year_n  country
gen code="year_Predict" if year_predict!=.
rename year_predict year

save year_predict2.dta



**************************** simpleLM.do // simple linear regression 
* Ver.0719 
*Objective: Add simple LM fit line on graph from graphbuilding.do
clear all
set more off

use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta"


** A. Regression and extrapoliation 
levelsof country_file, local(levels) 
foreach i of local levels   {
**foreach i in Afghanistan Algeria Angola Bangladesh Belize Bolivia  {
		display "`i'"
		**water
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture noisily predict yhat_wat_u if country_file=="`i'"
		sum freqwatU if country_file=="`i'" 
		capture graph twoway line yhat_wat_u year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict", stdf lstyle(solid) lcolor(gs5)|| scatter totalimprovedwat_used_u  year if  country_file=="`i'",  xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved water") subtitle("Urban",pos(11)) caption("N=`r(mean)'" )  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) saving(Wat_`i'_urban, replace) legend(off)
		
		capture noisily regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture noisily predict yhat_wat_r if country_file=="`i'"
		sum freqwatR if country_file=="`i'" 
		capture graph twoway  line yhat_wat_r year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict", stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedwat_used_r  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)   subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(Wat_`i'_rural, replace) legend(off)
		
		**sanitation
		capture noisily regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture noisily predict yhat_san_u if country_file=="`i'"
		sum freqsanU if country_file=="`i'" 
		capture graph twoway  line yhat_san_u year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict",stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedsan_used_u  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved sanitation") subtitle("Urban",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) saving(San_`i'_urban, replace)  legend(off)
		
		capture noisily regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture noisily predict yhat_san_r if country_file=="`i'"
		sum freqsanR if country_file=="`i'"
		capture graph twoway line yhat_san_r year if  country_file=="`i'" , lpattern("-") lcolor(gs10)||lfitci totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict",stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedsan_used_r  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend)  ytick(9)  ylabel(#5) ymtick(##10)   subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(San_`i'_rural, replace) legend(off)
		
		capture drop *hat*
		**graph combining 
		graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'")
		graph export `i'.png, replace
		
		}

	
**  B. compare RMSE **		
	clear
	use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta" //make sure to use the orignal dataset NOT the forecast dataset 	
	** use freq* as reference to check N% degrease from the original dataset 
	drop *rmse *_N
	gen wat_u_rmse=.
	gen wat_r_rmse=.
	gen san_u_rmse=.
	gen san_r_rmse=.
	gen wat_u_N=.
	gen wat_r_N=.
	gen san_u_N=.
	gen san_r_N=.
	
	**foreach i in Afghanistan Algeria Angola Bangladesh Belize Bolivia  {
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		display "`i'"
		**water
		capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture  replace wat_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture  replace wat_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_r_N=e(N) if country_file=="`i'"
		
		**sanitation
		capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture  replace san_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture  replace san_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_r_N=e(N) if country_file=="`i'"
		}
		
		tabstat wat_u_N wat_r_N san_u_N san_r_N wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse, by(country_file) format(%9.2fc)  

	

		
** C.  Bootstrap CI **
		
		
***** Bootstrap CI 
levelsof country_file, local(levels) 
		foreach i of local levels   {
		
foreach i in Zambia Zimbabwe{
		display "`i'"
capture regress totalimprovedsan_used_t year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3, vce(bootstrap, reps(1000)) level(95) nodots
capture predict yhat_`i' if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3,xb 
capture predict se_`i' if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3,stdp 
capture gen uci_`i'=yhat_`i'+(1.96*se_`i') if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3
capture gen lci_`i'=yhat_`i'-(1.96*se_`i') if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3
**sort uci_`i' lci_`i'
sort uci_`i'

graph twoway  (lfitci totalimprovedsan_used_t year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3, stdp lstyle(solid) lcolor(black)) (line lci_`i' year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3,lpattern("-") lcolor(red) lwidth(thick))(line uci_`i' year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_t!=.&freqsan>3,lpattern("-") lcolor(red) lwidth(thick))(scatter totalimprovedsan_used_t year if country_file=="`i'"&freqsan>3, title("`i'") legend(off))
graph export `i'_CI_comparison.png, replace
capture drop  uci_`i' lci_`i' yhat_`i' se_`i'
}	


** D.  Combination of bootstrap CI & extrapolation 
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 
drop if country_file=="America_United_S"
**foreach i in Afghanistan Bangladesh Bolivia  {

levelsof country_file, local(levels) 
		foreach i of local levels   {


		display "`i'"
		**water - urban
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		capture noisily predict yhat_wat_u if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture noisily predict forc_yhat_wat_u if country_file=="`i'"
		
		capture regress totalimprovedwat_used_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, /*
		*/vce(bootstrap, reps(1000)) level(95) nodots
		capture predict yhat_`i'_wat_u if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,xb //freqsan *correct condition. freqsan has tightest freq among 4 
		capture predict se_`i'_wat_u if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,stdp 
		
		capture gen uci_`i'_wat_u=yhat_`i'_wat_u+(1.96*se_`i'_wat_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		capture gen lci_`i'_wat_u=yhat_`i'_wat_u-(1.96*se_`i'_wat_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		capture graph twoway line uci_`i'_wat_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line lci_`i'_wat_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line forc_yhat_wat_u year if country_file=="`i'",lpattern("-") lcolor(orange)||  /*
		*/line yhat_wat_u year if  country_file=="`i'"&code!="year_Predict", lpattern(solid) lcolor(gs5) lwidth(thick)|| /*
		*/scatter totalimprovedwat_used_u  year if  country_file=="`i'",  /*
		*/xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  /*
		*/ytitle("Total Improved water") subtitle("Urban",pos(11))  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) /*
		*/ legend(off) saving(Wat_`i'_urban, replace)
	
		**water - rural 
		capture noisily regress totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		capture noisily predict yhat_wat_r if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		capture noisily regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture noisily predict forc_yhat_wat_r if country_file=="`i'"
		capture regress totalimprovedwat_used_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,/*
		*/ vce(bootstrap, reps(1000)) level(95) nodots
		capture predict yhat_`i'_wat_r if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,xb //freqsan *correct condition. freqsan has tightest freq among 4 
		capture predict se_`i'_wat_r if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,stdp 
		capture gen uci_`i'_wat_r=yhat_`i'_wat_r+(1.96*se_`i'_wat_r) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		capture gen lci_`i'_wat_r=yhat_`i'_wat_r-(1.96*se_`i'_wat_r) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		capture graph twoway line uci_`i'_wat_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line lci_`i'_wat_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line forc_yhat_wat_r year if country_file=="`i'",lpattern("-") lcolor(orange)||/*
		*/  line yhat_wat_r year if  country_file=="`i'"&code!="year_Predict", lpattern(solid) lcolor(gs5) lwidth(thick)||/*
		*/ scatter totalimprovedwat_used_r  year if  country_file=="`i'",  /*
		*/xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  /*
		*/ytitle("Total Improved water") subtitle("Rural",pos(11))  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(red) /*
		*/ legend(off) saving(Wat_`i'_rural, replace)

		**sanitation-urban
		capture noisily regress totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		capture noisily predict yhat_san_u if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		capture noisily regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture noisily predict forc_yhat_san_u if country_file=="`i'"
		capture regress totalimprovedsan_used_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,/*
		*/ vce(bootstrap, reps(1000)) level(95) nodots
		capture predict yhat_`i'_san_u if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,xb //freqsan *correct condition. freqsan has tightest freq among 4 
		capture predict se_`i'_san_u if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,stdp 
		capture gen uci_`i'_san_u=yhat_`i'_san_u+(1.96*se_`i'_san_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		capture gen lci_`i'_san_u=yhat_`i'_san_u-(1.96*se_`i'_san_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		capture graph twoway line uci_`i'_san_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs1)||/*
		*/ line lci_`i'_san_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line forc_yhat_san_u year if country_file=="`i'",lpattern("-") lcolor(orange)||  /*
		*/line yhat_san_u year if  country_file=="`i'"&code!="year_Predict", lpattern(solid) lcolor(gs5) lwidth(thick)||/*
		*/ scatter totalimprovedsan_used_u  year if  country_file=="`i'", /*
		*/ xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10) /*
		*/ ytitle("Total Improved sanitation") subtitle("Urban",pos(11))  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue)  /*
		*/legend(off) saving(San_`i'_urban, replace)

		**sanitation-rural
		capture noisily regress totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		capture noisily predict yhat_san_r if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		capture noisily regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture noisily predict forc_yhat_san_r if country_file=="`i'"
		capture regress totalimprovedsan_used_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3, /*
		*/vce(bootstrap, reps(1000)) level(95) nodots
		capture predict yhat_`i'_san_r if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,xb //freqsan *correct condition. freqsan has tightest freq among 4 
		capture predict se_`i'_san_r if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,stdp 
		capture gen uci_`i'_san_r=yhat_`i'_san_r+(1.96*se_`i'_san_r) if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		capture gen lci_`i'_san_r=yhat_`i'_san_r-(1.96*se_`i'_san_r) if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		capture graph twoway line uci_`i'_san_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line lci_`i'_san_r year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,lpattern(dot) lcolor(gs1)|| /*
		*/line forc_yhat_san_r year if country_file=="`i'",lpattern("-") lcolor(orange)|| /*
		*/ line yhat_san_r year if  country_file=="`i'"&code!="year_Predict", lpattern(solid) lcolor(gs5) lwidth(thick)|| /*
		*/scatter totalimprovedsan_used_r  year if  country_file=="`i'", /*
		*/ xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)/*
		*/  ytitle("Total Improved sanitation") subtitle("Rural",pos(11))  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(red)  /*
		*/legend(off) saving(San_`i'_rural, replace)

		capture drop yhat*	forc_yhat* se* *uci* *lci*  
		
		**graph combining 
		capture graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'")
		capture graph export `i'.png, replace
		}	

			
		
	****test code
	
	
	foreach i in America_United_S Afghanistan  {
		display "`i'"
		**water
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"
		capture noisily predict yhat_wat_u if country_file=="`i'"&code!="year_Predict"
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture noisily predict forc_yhat_wat_u if country_file=="`i'"
		sum freqwatU if country_file=="`i'" 
	
	
		capture regress totalimprovedwat_used_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, vce(bootstrap, reps(1000)) level(95) nodots
		capture predict yhat_`i'_wat_u if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,xb //freqsan *correct condition. freqsan has tightest freq among 4 
		capture predict se_`i'_wat_u if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,stdp 
		capture gen uci_`i'_wat_u=yhat_`i'_wat_u+(1.96*se_`i'_wat_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		capture gen lci_`i'_wat_u=yhat_`i'_wat_u-(1.96*se_`i'_wat_u) if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		
	**	graph twoway   (line lci_`i' year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs10) )(line uci_`i' year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs10) )
	
		capture graph twoway line uci_`i'_wat_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs5)|| line lci_`i'_wat_u year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,lpattern(dot) lcolor(gs5)|| line forc_yhat_wat_u year if country_file=="`i'",lpattern("-") lcolor(orange)||  line yhat_wat_u year if  country_file=="`i'"&code!="year_Predict", lpattern(solid) lcolor(gs5) lwidth(thick)|| scatter totalimprovedwat_used_u  year if  country_file=="`i'",  xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved water") subtitle("Urban",pos(11)) caption("N=`r(mean)'" )  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue)  legend(off)
	
		capture drop  uci_`i' lci_`i' yhat_`i' se_`i'	*hat*	
		}


** 3. Subsample random selection and sensitivity check (measurement: RMSE) 
*************************************** 90_75_50_SamplingRMSEcomparison.do ***********************************************************************************************************
////////////////////////////////////////////////////////////// 100% of original dataset ////////////////////////////////
use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta"
gen wat_u_rmse=.
gen wat_r_rmse=.
gen san_u_rmse=.
gen san_r_rmse=.
gen wat_u_N=.
gen wat_r_N=.
gen san_u_N=.
gen san_r_N=.

levelsof country_file, local(levels) 
foreach i of local levels   {

		display "`i'"
		///water
		capture noisily regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture noisily predict yhat_wat_u if country_file=="`i'"
		sum freqwatU if country_file=="`i'" 
		capture graph twoway line yhat_wat_u year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict", stdf lstyle(solid) lcolor(gs5)|| scatter totalimprovedwat_used_u  year if  country_file=="`i'",  xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved water") subtitle("Urban",pos(11)) caption("N=`r(mean)'" )  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) saving(Wat_`i'_urban, replace) legend(off)
		replace wat_u_rmse=e(rmse) if country_file=="`i'"
		replace wat_u_N=e(N) if country_file=="`i'"
		
		capture noisily regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture noisily predict yhat_wat_r if country_file=="`i'"
		sum freqwatR if country_file=="`i'" 
		capture graph twoway  line yhat_wat_r year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict", stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedwat_used_r  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)   subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(Wat_`i'_rural, replace) legend(off)
		replace wat_r_rmse=e(rmse) if country_file=="`i'"
		replace wat_r_N=e(N) if country_file=="`i'"
		
		///sanitation
		capture noisily regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture noisily predict yhat_san_u if country_file=="`i'"
		sum freqsanU if country_file=="`i'" 
		capture graph twoway  line yhat_san_u year if  country_file=="`i'", lpattern("-") lcolor(gs10)||lfitci totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict",stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedsan_used_u  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10)  ytitle("Total Improved sanitation") subtitle("Urban",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) saving(San_`i'_urban, replace)  legend(off)
		replace san_u_rmse=e(rmse) if country_file=="`i'"
		replace san_u_N=e(N) if country_file=="`i'"
		
		capture noisily regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture noisily predict yhat_san_r if country_file=="`i'"
		sum freqsanR if country_file=="`i'"
		capture graph twoway line yhat_san_r year if  country_file=="`i'" , lpattern("-") lcolor(gs10)||lfitci totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict",stdf lstyle(solid) lcolor(gs5)|| scatter  totalimprovedsan_used_r  year if  country_file=="`i'", xscale(r(1980 2030)) xlab(1985 1995 2005 2015 2025) ysc(range(0 110) extend)  ytick(9)  ylabel(#5) ymtick(##10)   subtitle("Rural",pos(11)) caption("N=`r(mean)'")  graphregion(color(white)) bgcolor(white) msymbol(Th) mlcolor(red) saving(San_`i'_rural, replace) legend(off)
		replace san_r_rmse=e(rmse) if country_file=="`i'"
		replace san_r_N=e(N) if country_file=="`i'"
		
		capture drop *hat*
		
		///graph combining 
		graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'")
		graph export `i'.png, replace
		
		}

		tabstat wat_u_N wat_r_N san_u_N san_r_N wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse, by(country_file) format(%9.2fc)  

//////////////////////// Random sampling of 50%, 75%, 90% of original dataset & compare RMSE /////////////// 		
	
///////////////////////// 90% /////////////////////////////////////////////////////////////////////////////
	clear
	use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta" //make sure to use the orignal dataset NOT the forecast dataset 	
	sample 90,by(country_file)
	// use freq* as reference to check N% degrease from the original dataset 
	drop *rmse *_N
	gen wat_u_rmse=.
	gen wat_r_rmse=.
	gen san_u_rmse=.
	gen san_r_rmse=.
	gen wat_u_N=.
	gen wat_r_N=.
	gen san_u_N=.
	gen san_r_N=.
	
	
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		display "`i'"
		///water
		capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture  replace wat_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture  replace wat_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_r_N=e(N) if country_file=="`i'"
		
		///sanitation
		capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture  replace san_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture  replace san_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_r_N=e(N) if country_file=="`i'"
		}
		scatter wat_u_rmse wat_u_N, graphregion(color(white)) bgcolor(white) saving(water_urban, replace)
		scatter wat_r_rmse wat_r_N, graphregion(color(white)) bgcolor(white) saving(water_rural, replace)
		scatter san_u_rmse san_u_N, graphregion(color(white)) bgcolor(white) saving(sanit_urban, replace)
		scatter san_r_rmse san_r_N, graphregion(color(white)) bgcolor(white) saving(sanit_rural, replace)
		
		graph combine water_urban.gph water_rural.gph sanit_urban.gph sanit_rural.gph, col(2) row(2) iscale(0.7) ycommon ysize(10) xsize(15) title("LM _100%sample_RMSE ")
		graph export LM _100%sample_RMSE.png, replace
		
		tabstat wat_u_N wat_r_N san_u_N san_r_N wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse, by(country_file) format(%9.2fc)  

		
///////////////////////// 75% /////////////////////////////////////////////////////////////////////////////
	clear
	use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta" //make sure to use the orignal dataset NOT the forecast dataset 	
	sample 75,by(country_file)
	// use freq* as reference to check N% degrease from the original dataset 
	drop *rmse *_N
	gen wat_u_rmse=.
	gen wat_r_rmse=.
	gen san_u_rmse=.
	gen san_r_rmse=.
	gen wat_u_N=.
	gen wat_r_N=.
	gen san_u_N=.
	gen san_r_N=.
	
	
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		display "`i'"
		///water
		capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture  replace wat_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture  replace wat_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_r_N=e(N) if country_file=="`i'"
		
		///sanitation
		capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture  replace san_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture  replace san_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_r_N=e(N) if country_file=="`i'"
		}
		scatter wat_u_rmse wat_u_N, graphregion(color(white)) bgcolor(white) saving(water_urban, replace)
		scatter wat_r_rmse wat_r_N, graphregion(color(white)) bgcolor(white) saving(water_rural, replace)
		scatter san_u_rmse san_u_N, graphregion(color(white)) bgcolor(white) saving(sanit_urban, replace)
		scatter san_r_rmse san_r_N, graphregion(color(white)) bgcolor(white) saving(sanit_rural, replace)
		
		graph combine water_urban.gph water_rural.gph sanit_urban.gph sanit_rural.gph, col(2) row(2) iscale(0.7) ycommon ysize(10) xsize(15) title("LM _100%sample_RMSE ")
		graph export LM _100%sample_RMSE.png, replace
		
		tabstat wat_u_N wat_r_N san_u_N san_r_N wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse, by(country_file) format(%9.2fc)  

		
		
///////////////////////// 50% /////////////////////////////////////////////////////////////////////////////
	clear
	use "/./Dropbox/2016_WASH/3files/Graph_data_cleanFreq.dta" //make sure to use the orignal dataset NOT the forecast dataset 	
	sample 50,by(country_file)
	// use freq* as reference to check N% degrease from the original dataset 
	drop *rmse *_N
	gen wat_u_rmse=.
	gen wat_r_rmse=.
	gen san_u_rmse=.
	gen san_r_rmse=.
	gen wat_u_N=.
	gen wat_r_N=.
	gen san_u_N=.
	gen san_r_N=.
	
	
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		display "`i'"
		///water
		capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"
		capture  replace wat_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"
		capture  replace wat_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace wat_r_N=e(N) if country_file=="`i'"
		
		///sanitation
		capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"
		capture  replace san_u_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_u_N=e(N) if country_file=="`i'"
		
		capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"
		capture  replace san_r_rmse=e(rmse) if country_file=="`i'"
		capture  replace san_r_N=e(N) if country_file=="`i'"
		}
		scatter wat_u_rmse wat_u_N, graphregion(color(white)) bgcolor(white) saving(water_urban, replace)
		scatter wat_r_rmse wat_r_N, graphregion(color(white)) bgcolor(white) saving(water_rural, replace)
		scatter san_u_rmse san_u_N, graphregion(color(white)) bgcolor(white) saving(sanit_urban, replace)
		scatter san_r_rmse san_r_N, graphregion(color(white)) bgcolor(white) saving(sanit_rural, replace)
		
		graph combine water_urban.gph water_rural.gph sanit_urban.gph sanit_rural.gph, col(2) row(2) iscale(0.7) ycommon ysize(10) xsize(15) title("LM _100%sample_RMSE ")
		graph export LM _100%sample_RMSE.png, replace
		
		tabstat wat_u_N wat_r_N san_u_N san_r_N wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse, by(country_file) format(%9.2fc)  


	



** 4. OLS,Piecewaise, quadratic
*************************************** OLS_piecewise_quadratic.do // OLS,Poecewaise, quadratic Graph building 
///// . Ver 0805
///// component A : testing for smoothness 
///// component B : combined nonlinear fitting including OLS, mspline, LOWESS
///// component C : combined nonlinear fitting including OLS, quadratic, 3 knots spline, LOWESS



clear
cd "/./Dropbox/2016_WASH/3files"
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 
//drop if country_file=="America_United_S"
set more off

Dominican_Republic


************************ Test for  smoothness check 	 	
//LOWESS
levelsof country_file, local(levels) 
		foreach i of local levels   {

 forvalues j = 1(2)9 {
		display "`i'"
		capture graph twoway /*
		*/scatter totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, lpattern(dot) lc(gs0) ||/*
		*/lowess totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, bwidth(.`j') mean  lc(blue) lpattern(solid) legend(off) /*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved water") caption("LOWESS bandwith: `j' " "" )	saving(`i'_`j',replace)
			}
		graph combine  `i'_1.gph `i'_3.gph `i'_5.gph `i'_7.gph  `i'_9.gph, col(3) row(2)  title(" `i' urban LOWESS check") graphregion(color(white))
		capture graph export LOWESS_water_Urban_`i'.png, replace						
}

// mspline 
levelsof country_file, local(levels) 
		foreach i of local levels   {

 forvalues j = 1(2)9 {
		display "`i'"
		capture graph twoway /*
		*/scatter totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, lpattern(dot) lc(gs0) ||/*
		*/mspline totalimprovedwat_used_u  year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3 , bands(`j') lc(red) lpattern(solid) /*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved water")   caption("mspline band: `j' " "" )	saving(`i'_`j',replace)
		}
		graph combine  `i'_1.gph `i'_3.gph `i'_5.gph `i'_7.gph  `i'_9.gph, col(3) row(2)  title(" `i' urban M.Spline check") graphregion(color(white))
		capture graph export Mspline_water_Urban_`i'.png, replace		
				
}

//// End of Test for  smoothness check


*********************** mspine lowess (Black dots, red/blue line)
levelsof country_file, local(levels) 
		foreach i of local levels   {

		display "`i'"
			
		capture graph twoway /*
		*/scatter totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, lpattern(dot) lc(gs0) ||/*
		*/mspline totalimprovedwat_used_u  year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3 , bands(8) lc(red) lpattern(solid) || /*
		*/lowess totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3/*
		*/,bwidth(.8) mean  lc(blue)  /*
		*/lpattern(solid) legend( rowgap(0.5)  forcesize colgap(1.0) pos(5) ring(0) col(1) region(fc(none) lcolor(none)  ) size(vsmall) holes(2) label(1 "Data") label(2 "OLS")label(3 "mspline")  label(4 "LOWESS")) /*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved water") subtitle("Urban",pos(11))  saving(Wat_`i'_urban, replace)
		
		capture graph twoway /*
		*/scatter totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,  lpattern(dot) lc(gs0)||/*
		*/mspline totalimprovedwat_used_r  year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3 , bands(8) lc(red) lpattern(solid) || /*
		*/lowess totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3/*
		*/,bwidth(.8) mean   lc(blue)  /*
		*/lpattern(solid) legend(off)/*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved water") subtitle("Rural",pos(11))  saving(Wat_`i'_rural, replace)
		
		capture graph twoway /*
		*/scatter totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,  lpattern(dot) lc(gs0)||/*
		*/mspline totalimprovedsan_used_u  year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3 , bands(8) lc(red) lpattern(solid) || /*
		*/lowess totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3/*
		*/,bwidth(.8) mean    lc(blue)  /*
		*/lpattern(solid) legend(off)/*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved sanitation") subtitle("Urban",pos(11))  saving(San_`i'_urban, replace)

		capture graph twoway /*
		*/scatter totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,  lpattern(dot) lc(gs0)||/*
		*/mspline totalimprovedsan_used_r  year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3 , bands(8) lc(red) lpattern(solid) || /*
		*/lowess totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3/*
		*/,bwidth(.8) mean    lc(blue)  /*
		*/lpattern(solid) legend(off) /*
		*/graphregion(color(white)) bgcolor(white)  ytitle("Total Improved sanitation") subtitle("Rural",pos(11))  saving(San_`i'_rural, replace)
		
		capture graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'") graphregion(color(white))
		capture graph export `i'_NonLinear_msplineLOWESS.png, replace
		
		capture drop fitted*
		capture drop  year_spline*
		}
	
		
//// End of multiple Spline 



********************** 3 knots piecewise 
levelsof country_file, local(levels) 
		foreach i of local levels   {
		

		display "`i'"
		* Water- Urban

		capture capture mkspline year_spline= year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3 , cubic nknots(3) displayknots
		capture capture regress totalimprovedwat_used_u year_spline1-year_spline2 if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		gen fitted=0
		capture predict fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
		capture replace fitted=fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3

		capture graph twoway /*
		*/scatter totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3,  msymbol(O) mlcolor(blue) || /*
		*/lfit totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3, lpattern("-") ||/*
		*/qfit totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3 ,lpattern("-") ||/*
		*/line fitted year  if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3||/*
		*/lowess totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3/*
		*/,bwidth(.8) mean   /*
		*/lcolor(green)  lpattern(solid) legend( rowgap(0.5)  forcesize colgap(1.0) pos(5) ring(0) col(1) region(fc(none) lcolor(none)  ) size(vsmall) holes(2) label(1 "Data") label(2 "OLS")label(3 "Quadratic") label(4 "Piecewise") label(5 "LOWESS")) /*
		*/graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) ytitle("Total Improved water") subtitle("Urban",pos(11))  saving(Wat_`i'_urban, replace)
		
		* Water - Rural 
		capture drop fitted
		capture drop  year_spline*
		capture mkspline year_spline= year if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3 , cubic nknots(3) displayknots
		capture regress totalimprovedwat_used_r year_spline1-year_spline2 if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		gen fitted=0
		capture predict fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
		capture replace fitted=fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3

		capture graph twoway /*
		*/scatter totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3,  msymbol(O) mlcolor(blue) || /*
		*/lfit totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3, lpattern("-") ||/*
		*/qfit totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3 ,lpattern("-") ||/*
		*/line fitted year  if country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3||/*
		*/lowess totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3/*
		*/,bwidth(.8) mean  /*
		*/lcolor(green)  lpattern(solid) legend(off)/*
		*/graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) ytitle("Total Improved water") subtitle("Rural",pos(11))  saving(Wat_`i'_rural, replace)
		
		
		* Sanitation - Urban
		capture drop fitted
		capture drop  year_spline*
		capture mkspline year_spline= year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3 , cubic nknots(3) displayknots
		capture regress totalimprovedsan_used_u year_spline1-year_spline2 if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		gen fitted=0
		capture predict fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
		capture replace fitted=fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3

		capture graph twoway /*
		*/scatter totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3,  msymbol(O) mlcolor(blue) || /*
		*/lfit totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3, lpattern("-") ||/*
		*/qfit totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3 ,lpattern("-") ||/*
		*/line fitted year  if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3||/*
		*/lowess totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3/*
		*/,bwidth(.8) mean   /*
		*/lcolor(green)  lpattern(solid) legend(off)/*
		*/graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) ytitle("Total Improved sanitation") subtitle("Urban",pos(11))  saving(San_`i'_urban, replace)

		
		* Sanitation - Rural
		capture drop fitted
		capture drop  year_spline*
		capture mkspline year_spline= year if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3 , cubic nknots(3) displayknots
		capture regress totalimprovedsan_used_r year_spline1-year_spline2 if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		gen fitted=0
		capture predict fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
		capture replace fitted=fittedmk if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3

		capture graph twoway /*
		*/scatter totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3,  msymbol(O) mlcolor(blue) || /*
		*/lfit totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3, lpattern("-") ||/*
		*/qfit totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3 ,lpattern("-") ||/*
		*/line fitted year  if country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3||/*
		*/lowess totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3/*
		*/,bwidth(.8) mean   /*
		*/lcolor(green)  lpattern(solid) legend(off) /*
		*/graphregion(color(white)) bgcolor(white) msymbol(Oh) mlcolor(blue) ytitle("Total Improved sanitation") subtitle("Rural",pos(11))  saving(San_`i'_rural, replace)
		
		capture graph combine Wat_`i'_urban.gph Wat_`i'_rural.gph San_`i'_urban.gph San_`i'_rural.gph, col(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'")
		capture graph export `i'_NonLinearAlt.png, replace
		
		capture drop fitted*
		capture drop  year_spline*
		}

		
//// End of 3 knots piecewise

*************************************** OLS_piecewise_quadratic_faster_Extrapolation.do // mipolate forward method applied 
///// . Ver 0813
///// component A : use forward interpolated value for fitting

clear
cd "/./Dropbox/2016_WASH/3files"
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 

*********************** mspine lowess (Black dots, red/blue line)
levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		display "`i'"
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		
		// generate forward interpolated 
		mipolate totalimproved`j'  year if  country_file=="`i'", forward gen(forward_totalimproved`j') 
		
		//use interpolated value for graph fitting 
		
		capture graph twoway /*
		*/scatter totalimproved`j'  year if  country_file=="`i'",  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimproved`j'  year if  country_file=="`i'", lpattern(dot) lc(gs0) ||/*
		*/lfit forward_totalimproved`j'  year if  country_file=="`i'", lpattern(solid) lc(gs10) ||/*
		*/mspline forward_totalimproved`j'  year if country_file=="`i'" , bands(8) lc(red) lpattern(solid) || /*
		*/lowess forward_totalimproved`j'  year if  country_file=="`i'",bwidth(.8) mean  lc(blue) lpattern(solid) /*
		/*
		*/legend( rowgap(0.5)  forcesize colgap(1.0) pos(5) ring(0) col(1) region(fc(none) lcolor(none)  ) size(vsmall) holes(2) /*
		*/label(1 "Data") label(2 "OLS") label(3 "Forecasting")  label(4 "mspline_forecasting")  label(5 "LOWESS forecasting")) /*
		*/
		*/ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10) /*
		*/legend(off) graphregion(color(white)) bgcolor(white)  ytitle("Total Improved `j'")  saving(`i'_`j', replace)
		capture drop  forward_totalimproved`j'
		}
		capture graph combine `i'_wat_used_u.gph `i'_wat_used_r.gph `i'_san_used_u.gph `i'_san_used_r.gph , /*
		*/col(2) row(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'") graphregion(color(white))  /*
		*/ caption("Red: Spline" "Blue: LOWESS" "Grey:OLS") 
		capture graph export `i'_extrapolation.png, replace
		//capture drop fitted*	
	}
 *********************************************  OLS_piecewise_quadratic_faster_Extrapolation_noMipolate.do /// Forecasting without using the mipolate method
 ///// . Ver 0813
///// component A : use forward interpolated value for fitting

clear
cd "/./Dropbox/2016_WASH/3files"
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 


append using year_predict2 // Use this for year forecating +3
		save Graph_data_Yearappend2.dta,replace
		bys country_file: egen yearmin = min(year)
		sort country_file year
		replace yearmin=. if code=="year_Predict"
		
egen yearmax=max(year) if code=="year_Predict",by(country_file) 
drop if year==yearmax
drop yearmax
save Graph_data_extrapolation.dta,replace

*********************** mspine lowess (Black dots, red/blue line)
levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		display "`i'"
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		
		// generate forward interpolated 
		mipolate totalimproved`j'  year if  country_file=="`i'", forward gen(forward_totalimproved`j') 
		
		//use interpolated value for graph fitting 
		
		capture graph twoway /*
		*/scatter totalimproved`j'  year if  country_file=="`i'",  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
		*/lfit totalimproved`j'  year if  country_file=="`i'", lpattern(dot) lc(gs0) ||/*
		*/lfit forward_totalimproved`j'  year if  country_file=="`i'", lpattern(solid) lc(gs10) ||/*
		*/mspline forward_totalimproved`j'  year if country_file=="`i'" , bands(8) lc(red) lpattern(solid) || /*
		*/lowess forward_totalimproved`j'  year if  country_file=="`i'",bwidth(.8) mean  lc(blue) lpattern(solid) /*
		/*
		*/legend( rowgap(0.5)  forcesize colgap(1.0) pos(5) ring(0) col(1) region(fc(none) lcolor(none)  ) size(vsmall) holes(2) /*
		*/label(1 "Data") label(2 "OLS") label(3 "Forecasting")  label(4 "mspline_forecasting")  label(5 "LOWESS forecasting")) /*
		*/
		*/ysc(range(0 110) extend) ytick(9)  ylabel(#5) ymtick(##10) /*
		*/legend(off) graphregion(color(white)) bgcolor(white)  ytitle("Total Improved `j'")  saving(`i'_`j', replace)
		capture drop  forward_totalimproved`j'
		}
		capture graph combine `i'_wat_used_u.gph `i'_wat_used_r.gph `i'_san_used_u.gph `i'_san_used_r.gph , /*
		*/col(2) row(2) iscale(0.7) ycommon ysize(10) xsize(15) title("`i'") graphregion(color(white))  /*
		*/ caption("Red: Spline" "Blue: LOWESS" "Grey:OLS") 
		capture graph export `i'_extrapolation.png, replace
		//capture drop fitted*	
	}

** 5. Nonlinear fit method sensitivity check (measurement: RMSE) 
*************************************** RMSE_comparison_NonlinearFit.do 
//// RMSE comparison of different fitline
//// 25% exclusion (=75%) for RMSE comparison 
//// Extrapolation for spline method 

clear
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 
set more off
		
		/////// OLS ////////////////////////
					gen wat_u_N=.
					gen wat_r_N=.
					gen san_u_N=.
					gen san_r_N=.
					gen wat_u_rmse=.
					gen wat_r_rmse=.
					gen san_u_rmse=.
					gen san_r_rmse=.
					
		levelsof country_file, local(levels) 
					foreach i of local levels   {
								display "`i'"
							///water
								///OLS
								capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
								capture  predict yhat_wat_u if country_file=="`i'"
								replace wat_u_rmse=e(rmse) if country_file=="`i'"
								replace wat_u_N=e(N) if country_file=="`i'"
		
								///OLS
								capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
								capture  predict yhat_wat_r if country_file=="`i'"
								replace wat_r_rmse=e(rmse) if country_file=="`i'"
								replace wat_r_N=e(N) if country_file=="`i'"
			
							///sanitation
								///OLS
								capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
								capture  predict yhat_san_u if country_file=="`i'"
								replace san_u_rmse=e(rmse) if country_file=="`i'"
								replace san_u_N=e(N) if country_file=="`i'"
		
								///OLS
								capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
								capture  predict yhat_san_r if country_file=="`i'"
								replace san_r_rmse=e(rmse) if country_file=="`i'"
								replace san_r_N=e(N) if country_file=="`i'"
		
								capture drop *hat*
								}
								
								tabstat wat_u_N wat_r_N san_u_N san_r_N ,by(country_file) format(%9.2fc)   
								tabstat wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse ,by(country_file) format(%9.2fc)   					
								drop  *rmse* *N
	   ////////////////// End of OLS RMSE comparison //////////////////////							
		
				
		
		////// LOWESS /////////////////////////
		/*
use "/./Dropbox/2016_WASH/3files/Graph_data_5year.dta", clear
drop if  freq_wat_used_u<4
drop if  freq_wat_used_r<4
drop if  freq_san_used_u<4
drop if  freq_san_used_r<4

drop if freqsan==.
drop if freqwat==.

rename  freqwatU freq_wat_used_u
rename  freqwatR freq_wat_used_r
rename  freqsanU freq_san_used_u
rename  freqsanR freq_san_used_r
*/

use "/./Dropbox/2016_WASH/3files/Graph_data_5year_forRMSEcpmtn.dta",clear

	//drop hat* rmse*

	
	gen hat_wat_used_u=.
	gen hat_wat_used_r=.
	gen hat_san_used_u=.
	gen hat_san_used_r=.

	gen rmse_wat_used_u=.
	gen rmse_wat_used_r=.
	gen rmse_san_used_u=.
	gen rmse_san_used_r=.		
	
	//foreach i in  Afghanistan   {
	
					
		levelsof country_file, local(levels) 
					foreach i of local levels   {
	foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	quietly gen rmse_strg_`j'=""	
display "`i'"
	capture quietly   mlowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3, bwidth(.8) gen(hat_strg_`j')   nograph 
	//capture  generate   hat_strg_`j'=. if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'<=3
	capture  replace   hat_`j'=hat_strg_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly rmse      totalimproved`j'  hat_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly replace rmse_strg_`j'=r(hat_`j') if country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly destring rmse_strg_`j',replace 
	quietly sum		 rmse_strg_`j'
	quietly replace rmse_`j'=r(mean) if  country_file=="`i'"
	drop hat_strg_`j' rmse_strg_`j'
	}
}	
tabstat  rmse_wat_used_u rmse_wat_used_r rmse_san_used_u rmse_san_used_r, by(country_file)
				
		/////////////////////////////////////////////////////// 
		
		



** 6. Extrapolation method check (measurement : difference of last know value vs last extrapolated value )
*************************************** ExtrapolationValueCheck.do

// ver 0819 
// component A. Generate extrpolated data for each extrapolation method 
// component B. Generate graphs for each explt method
// component C. Compare last known value vs last explt value for method-wise comparison
clear
cd "/./Dropbox/2016_WASH/3files"
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 


append using year_predict2 // Use this for year forecating +3
		save Graph_data_Yearappend2.dta,replace
		bys country_file: egen yearmin = min(year)
		sort country_file year
		replace yearmin=. if code=="year_Predict"
		
egen yearmax=max(year) if code=="year_Predict",by(country_file) 
drop if year==yearmax
drop yearmax
save Graph_data_extrapolation.dta,replace

use Graph_data_extrapolation.dta 








// component A.
levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		display "`i'"
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u  {

			capture mipolate  totalimproved`j'  year if country_file=="`i'", forward gen(miplt`i'`j')
			capture nnipolate  totalimproved`j'  year if country_file=="`i'",  gen(nniplt`i'`j')
			capture ipolate  totalimproved`j'  year if country_file=="`i'",  gen(iplt`i'`j') epolate
			capture pchipolate  totalimproved`j'  year if country_file=="`i'",  gen(piplt`i'`j')
			capture quietly: regress totalimproved`j'  year if country_file=="`i'"
			capture predict olsplt`i'`j' if country_file=="`i'"
		}
} 



// Component A support 
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u  {
			egen miextplt_`j'=rowmean(miplt*) // combine extplt value from all countries into one variable 
			egen nniextplt_`j'=rowmean(nniplt*)
			egen iextplt_`j'=rowmean(iplt*)
			egen pchiextplt_`j'=rowmean(piplt*)
			egen olsextplt_`j'=rowmean(olsplt*)
		}
		drop miplt* nniplt* piplt* olsplt* iplt*


// component B.
levelsof country_file, local(levels) 
	foreach i of local levels   {
		foreach j in wat_used_u  {
			
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'")|| /*
		*/(lfit miextplt_`j' year  if country_file=="`i'", lc(red))||/*
		*/(lfit nniextplt_`j' year if country_file=="`i'",lc(blue))||/*
		*/(lfit pchiextplt_`j' year if country_file=="`i'", lc(khaki))||/*
		*/(lfit iextplt_`j' year if country_file=="`i'", lc(magenta))||/*
		*/(lfit totalimproved`j'  year if country_file=="`i'",lpattern(dot) lc(gs10))|| /*
		*/(line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
	*/ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/    title("linear regression") saving(lfit`i'`j',replace) legend(off) graphregion(color(white)) )
		
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'") ||/*
		*/(mspline miextplt_`j' year  if country_file=="`i'",bands(8)  lc(red))||/*
		*/(mspline nniextplt_`j' year if country_file=="`i'",bands(8) lc(blue))||/*
		*/(mspline pchiextplt_`j' year if country_file=="`i'",bands(8)  lc(khaki))||/*
		*/(mspline iextplt_`j' year if country_file=="`i'" ,bands(8) lc(magenta))||/*
		*/ (line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
		*/ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/   title("mspline") saving(mspline`i'`j',replace) legend(off) graphregion(color(white)) )
		
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'") ||/*
		*/(lowess miextplt_`j' year  if country_file=="`i'",bwidth(.8) mean lc(red))||/*
		*/(lowess nniextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(blue))||/*
		*/(lowess pchiextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(khaki) )||/*
		*/(lowess iextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(magenta) )||/*
		*/ (line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
		 */ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/    title("lowess") saving(lowess`i'`j',replace) legend(off) graphregion(color(white)) )

		
		capture  graph combine lfit`i'`j'.gph    mspline`i'`j'.gph     lowess`i'`j'.gph , /*
		*/row(1)  iscale(0.7) ycommon ysize(10) xsize(15) title("`i' (Total improved `j')") graphregion(color(white))  /*
		*/caption("Red:mipolate forward"  "Blue:nearest neighborhood extrapolation"  "Khaki:piecewise extrapolation"  "Magenta:ipolate extp" "Black:Extrapolated OLS") 
		capture graph export `i'_extrapolationMethodCheck.png, replace
			}
		} 
		
		
		
		
		

// component C.
/////// Compare last known value & last extrapolated value  per each extrapolation method and the spline method 


egen yearmax=max(year) if code!="year_Predict",by(country_file)
egen frcstyearmax=max(year) if code=="year_Predict",by(country_file) 


foreach k in olsextplt miextplt nniextplt iextplt pchiextplt  {
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u {
		
		gen basecmrs`k'_`j'= `k'_`j' if year==yearmax 
		gen topcmrs`k'_`j'= `k'_`j' if year==frcstyearmax
		
		egen base`k'_`j'= max(basecmrs`k'_`j'),by(country_file)
		egen top`k'_`j'= max(topcmrs`k'_`j'),by(country_file)
		//egen diff_`k'_`j'=diff( base`k'_`j' top`k'_`j') 
		egen diff_`k'=diff( base`k'_`j' top`k'_`j') 
		}
	}
	
tabstat  diff_*,by(country_file) s(mean) labelwidth(20)
drop *base* *top*



*************************** RMSE_basecalculation.do 


* Object : Compute cross-model RMSE median. 
* Ver 28082016 .
* Componenet A: LM RMSE  => Variable save
* Componenet B: LOWESS RMSE => Variable save 
* Componenet C: Piecewise RMSE  => Variable save 
* Componenet D: Pool variables together 
* Iterate Componenet A - D for subset (100%, 90%, 75%, 50%, 25%, 10%) 
* Calcuate median RMSE (Final) 


******************  Iterate Componenet A - D for subset (100%, 90%, 75%, 50%, 25%, 10%)    *********************************************
clear
use Graph_data_extrapolation.dta 

rename  freqwatU freq_wat_used_u
rename  freqwatR freq_wat_used_r
rename  freqsanU freq_san_used_u
rename  freqsanR freq_san_used_r
drop if  freq_wat_used_u<4
drop if  freq_wat_used_r<4
drop if  freq_san_used_u<4
drop if  freq_san_used_r<4
drop if freqsan==.
drop if freqwat==.



//sample 90,by(country_file)



************************  component A. LM RMSE calculation  ***********************************************************
capture quietly:generate rmse_LM_wat_used_u=.
capture quietly:generate rmse_LM_wat_used_r=.
capture quietly:generate rmse_LM_san_used_u=.
capture quietly:generate rmse_LM_san_used_r=.
 
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
			display "`i' & `j'" 
			capture quietly: regress totalimproved`j'  year if country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
			capture quietly:replace rmse_LM_`j'=e(rmse) if country_file=="`i'"
		}
} 
************************ Componenet B: LOWESS RMSE ****************************************

	capture quietly:gen hat_wat_used_u=.
	capture quietly:gen hat_wat_used_r=.
	capture quietly:gen hat_san_used_u=.
	capture quietly:gen hat_san_used_r=.

	capture quietly:gen rmse_LW_wat_used_u=.
	capture quietly:gen rmse_LW_wat_used_r=.
	capture quietly:gen rmse_LW_san_used_u=.
	capture quietly:gen rmse_LW_san_used_r=.		

	levelsof country_file, local(levels) 
	foreach i of local levels   {
	foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	quietly gen rmse_strg_`j'=""	
	display "`i' & `j'" 
	capture quietly   mlowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3, bwidth(.8) gen(hat_strg_`j')   nograph 
	//capture  generate   hat_strg_`j'=. if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'<=3
	capture  replace   hat_`j'=hat_strg_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly rmse      totalimproved`j'  hat_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly replace rmse_strg_`j'=r(hat_`j') if country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly destring rmse_strg_`j',replace 
	quietly sum		 rmse_strg_`j'
	quietly replace rmse_LW_`j'=r(mean) if  country_file=="`i'"
	drop hat_strg_`j' rmse_strg_`j'
	}
}

************************ Componenet C: Piecewise RMSE ****************************************
	capture quietly:gen rmse_CS_wat_used_u=.
	capture quietly:gen rmse_CS_wat_used_r=.
	capture quietly:gen rmse_CS_san_used_u=.
	capture quietly:gen rmse_CS_san_used_r=.	

	levelsof country_file, local(levels) 
	foreach i of local levels   {
	foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	display "`i' & `j'" 
	set graphics off
	capture quietly: rcspline totalimproved`j'  year if country_file=="`i'"&code!="year_Predict" &totalimproved`j'!=.&freq_`j'>3, generate(`i'`j')  bands(8) 
	capture quietly:  replace rmse_CS_`j'=e(rmse)  if country_file=="`i'"&totalimproved`j'!=.&freq_`j'>3
	capture drop `i'`j'	
	}
	}
	 set graphics on
	 
************************ Componenet EXTRA : RMSE result graph & table ****************************************
	
	set graphics off
	foreach m in LM LW CS {
		capture quietly: egen p50`m'=rowmedian(rmse_`m'_wat_used_u  rmse_`m'_wat_used_r  rmse_`m'_san_used_u   rmse_`m'_san_used_r)
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		capture quietly: egen p50`m'_`j'=median(rmse_`m'_`j')
		capture hist  rmse_`m'_`j', freq title ("`j'") bin(10) saving(`m'`j'hist,replace) graphregion(color(white)) kden xlabel(0(5)15) ylabel(0(150)600)
		capture graph twoway (scatter rmse_`m'_`j' freq_`j')(lfit  rmse_`m'_`j' freq_`j', saving(`m'`j'lf,replace) title(`m'`j') legend(off) xlabel(0(10)40) ylabel(0(5)20) graphregion(color(white)) )  
			} 
		}
		set graphics on // use this part only for egen function
		
		//final result graph 1 
		graph combine LMwat_used_uhist.gph LMwat_used_rhist.gph LMsan_used_uhist.gph LMsan_used_rhist.gph/*
		*/ LWwat_used_uhist.gph LWwat_used_rhist.gph LWsan_used_uhist.gph LWsan_used_rhist.gph/*
		*/ CSwat_used_uhist.gph CSwat_used_rhist.gph CSsan_used_uhist.gph CSsan_used_rhist.gph,/*
		*/title("RMSE distribution")  graphregion(color(white)) 
		capture graph export RMSE_distribution.png, replace
		
		//final result graph 2
		graph combine LMwat_used_ulf.gph LMwat_used_rlf.gph LMsan_used_ulf.gph  LMsan_used_rlf.gph/*
		 */ LWwat_used_ulf.gph LWwat_used_rlf.gph LWsan_used_ulf.gph  LWsan_used_rlf.gph/*
		 */ CSwat_used_ulf.gph CSwat_used_rlf.gph CSsan_used_ulf.gph  CSsan_used_rlf.gph/*
		 */, row(3) col(4) 
		 capture graph export RMSE_pattern.png, replace
		
		//final result graph 3
		foreach m in LM LW CS {	
		graph twoway (scatter rmse_`m'_wat_used_u freq_wat_used_u, mc(red)) (scatter rmse_`m'_wat_used_r freq_wat_used_r, mc(blue)) /*
		*/ (scatter rmse_`m'_san_used_u freq_san_used_u, mc(orange)) /*
		*/(scatter rmse_`m'_san_used_r freq_san_used_r, /*
		*/mc(green)  legend(off) title("`m'")saving(`m',replace) ylabel(0(5)15) ytitle("RMSE") xtitle("Frequency") graphregion(color(white)))
		}
		graph combine LM.gph LW.gph CS.gph, row(1) col(3) title("RMSE value scatter plot")  graphregion(color(white)) 
		capture graph export RMSE_scatter_pattern.png, replace
	 
	 foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	 graph box  rmse_LM_`j' rmse_LW_`j' rmse_CS_`j',saving(`j',replace) legend(off) title("`j'") graphregion(color(white))
	 }
	 graph combine wat_used_u.gph wat_used_r.gph san_used_u.gph  san_used_r.gph, col(4) row(1) graphregion(color(white)) caption("Blue:LM Red:LW Green:CS") title("RMSE median and upper adjacent value ")
	 graph export RMSE_hbox.png, replace
	 
	 
	 
	 
		//tabstat  rmse_LM_wat_used_u rmse_LM_wat_used_r rmse_LM_san_used_u rmse_LM_san_used_r rmse_LW_wat_used_u rmse_LW_wat_used_r rmse_LW_san_used_u rmse_LW_san_used_r rmse_CS_wat_used_u rmse_CS_wat_used_r rmse_CS_san_used_u rmse_CS_san_used_r, s(p25 p50 p75) c(s)
		foreach m in LM LW CS {
			capture quietly: gen rmse0`m'=""
			foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
				capture quietly: replace rmse0`m'="A. 0%- 25% of RMSE dstrbt" if   rmse_`m'_`j'<=0.9 &  rmse_`m'_`j'!=.
				capture quietly: replace rmse0`m'="B.25%-50% of RMSE dstrbt" if   rmse_`m'_`j'!=. &  rmse_`m'_`j'>0.9 &  rmse_`m'_`j'<=2.4
				capture quietly: replace rmse0`m'="C.50%-75% of RMSE dstrbt" if   rmse_`m'_`j'!=. &  rmse_`m'_`j'>2.4  &  rmse_`m'_`j'<=3.8
				capture quietly: replace rmse0`m'="D.>75% of RMSE dstrbt" if   rmse_`m'_`j'!=. &  rmse_`m'_`j'>3.8 
				capture quietly: replace rmse0`m'="E.Missing" if   rmse_`m'_`j'==.
				}
			}
			
		sum p50*
		foreach m in LM LW CS {
			tabstat  rmse_`m'_wat_used_u rmse_`m'_wat_used_r rmse_`m'_san_used_u rmse_`m'_san_used_r,  s(N, median, mean, min, max, SD) c(s)
			}	
		foreach m in LM LW CS {	
			tab rmse0`m'
			}
		
		
		
		/*  Use below part to generate proportion of low/med/high RMSE distribution of `j' regardless fitting method 
			foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
			gen rmse0`j'="A.Low 30% of RMSE dstrbt" if  rmse_LM_`j'<=2&rmse_LM_`j'!=.|rmse_LW_`j'<=2&rmse_LW_`j'!=. |rmse_CS_`j'<=2&rmse_CS_`j'!=. 
			replace rmse0`j'="B.Mid 30% of RMSE dstrbt" if  rmse_LM_`j'!=.& rmse_LM_`j'>2&rmse_LM_`j'<=6 |rmse_LW_`j'!=.& rmse_LW_`j'>2&rmse_LW_`j'<=6|rmse_CS_`j'!=.& rmse_CS_`j'>2&rmse_CS_`j'<=6
			replace rmse0`j'="C.High 30% of RMSE dstrbt" if  rmse_LM_`j'!=.& rmse_LM_`j'>6 |rmse_LW_`j'!=.& rmse_LW_`j'>6|rmse_CS_`j'!=.& rmse_CS_`j'>6
			tab rmse0`j'
			}
	    */
 
	 
//save Graph_data_spline_RMSE.dta,replace 
//save Graph_data_mspline_RMSE`k'.dta,replace 

**************************************************************************************************


save Graph_data_RMSE.dta,replace 


****************** RMSE base x-percent comparison 


clear
use Graph_data_extrapolation.dta


foreach i in Bolivia {
foreach j in wat_used_u { //wat_used_r san_used_u  san_used_r {
foreach k of numlist 100 90 80 70 {
	clear
	use Graph_data_extrapolation.dta			
	sample `k',by(country_file)
	capture ipolate  totalimproved`j'  year if country_file=="`i'",  gen(iplt`i'`j') epolate
	egen iextplt_`j'=rowmean(iplt*)
	
			
			//spline///////////////////////////////////////////////////////////////////////////////////////////////////////////////
			
			capture graph twoway /*
					*/scatter totalimproved`j'  year if  country_file=="`i'",  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
					*/mspline iextplt_`j'  year if country_file=="`i'" , bands(8) lc(pink) lpattern("-") || /*
					*/mspline totalimproved`j'  year if country_file=="`i'" &code!="year_Predict", bands(8) lc(red) lpattern(solid) /*
					*/title("`k'% ")saving(`i'_`j'RMSEspline`k', replace) legend(off) graphregion(color(white))  xlabel(1980(10)2020)
					
			
			//lowess///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			quietly sum totalimproved`j' if  country_file=="`i'"
			capture graph twoway /*
					*/scatter totalimproved`j'  year if  country_file=="`i'",  msymbol(O) mlcolor(gs0) mfc(gs0) || /*
					*/lowess iextplt_`j'  year if  country_file=="`i'",bwidth(.8) mean  lc(blue) lpattern("-") ||/*
					*/lowess totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict",bwidth(.8) mean  lc(blue) lpattern(solid) /*
					*/title("`k'%")saving(`i'_`j'RMSElowess`k', replace) legend(off) graphregion(color(white)) xlabel(1980(10)2020) caption("[N=`r(N)']") 
			
			drop   iplt*
			
					}
				
	capture graph combine `i'_`j'RMSEspline100.gph  `i'_`j'RMSEspline90.gph  `i'_`j'RMSEspline80.gph `i'_`j'RMSEspline70.gph ,/*
			*/ title("Spline") graphregion(color(white)) row(1) col(4) saving(`i'_`j'RMSEspline, replace) 
			capture graph export `i'_`j'_rmsespline.png, replace
					
	capture graph combine `i'_`j'RMSElowess100.gph   `i'_`j'RMSElowess90.gph `i'_`j'RMSElowess80.gph `i'_`j'RMSElowess70.gph ,/*
			*/title("LOWESS") graphregion(color(white)) row(1) col(4) saving(`i'_`j'RMSElowess, replace) caption("Dash line: 2yr extrapolation"  "Solid line: Original data")
			capture graph export `i'_`j'_rmselowess.png, replace
		
		}
		}


	
	//// Graph combine 
		foreach i in Bolivia  {
		foreach j in wat_used_u { 
		capture graph combine `i'_`j'RMSEspline.gph   `i'_`j'RMSElowess.gph ,title("`i'") graphregion(color(white)) row(2) col(1) xsize(10)
		capture graph export `i'_`j'_rmse.png, replace
	}
	}
	
	
	
	
	
	
	
	
/////////////////////////////////////////// RMSE value 

	
	gen hat_wat_used_u=.
	gen hat_wat_used_r=.
	gen hat_san_used_u=.
	gen hat_san_used_r=.

	gen rmse_wat_used_u=.
	gen rmse_wat_used_r=.
	gen rmse_san_used_u=.
	gen rmse_san_used_r=.		
					
	foreach i in Bolivia  {
	foreach j in wat_used_u { 
	quietly gen rmse_strg_`j'=""	
	capture quietly   mlowess   totalimproved`j'  year if  country_file=="`i'", bwidth(.8) gen(hat_strg_`j')   nograph 
	capture  replace   hat_`j'=hat_strg_`j' if  country_file=="`i'"
	quietly rmse      totalimproved`j'  hat_`j' if  country_file=="`i'"
	quietly replace rmse_strg_`j'=r(hat_`j') if country_file=="`i'"
	quietly destring rmse_strg_`j',replace 
	quietly sum		 rmse_strg_`j'
	quietly replace rmse_`j'=r(mean) if  country_file=="`i'"
	drop hat_strg_`j' rmse_strg_`j'
	}
}	



drop hat* rmse*

	
	

	
	************************************************** RMSE comparison (nonlinear fit) 
	



/// Ver 0813 
// Log file record purpose 

log using "/./Dropbox/2016_WASH/3files/nonlinearRMSEcomparison.log", replace
log off
forvalues k = 50(25)100 {


///////////////////////////////////////////// RMSE calculation //////////////////////////////////
//// RMSE comparison of different fitline
//// 25% exclusion (=75%) for RMSE comparison 
//// Extrapolation for spline method 

clear
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 
sample `k',by(country_file)
set more off
		
		/////// OLS ////////////////////////
					gen wat_u_N=.
					gen wat_r_N=.
					gen san_u_N=.
					gen san_r_N=.
					gen wat_u_rmse=.
					gen wat_r_rmse=.
					gen san_u_rmse=.
					gen san_r_rmse=.
					
		levelsof country_file, local(levels) 
					foreach i of local levels   {
								display "`i'"
							///water
								///OLS
								capture  regress totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_u!=.&freqsan>3
								capture  predict yhat_wat_u if country_file=="`i'"
								replace wat_u_rmse=e(rmse) if country_file=="`i'"
								replace wat_u_N=e(N) if country_file=="`i'"
		
								///OLS
								capture  regress totalimprovedwat_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedwat_used_r!=.&freqsan>3
								capture  predict yhat_wat_r if country_file=="`i'"
								replace wat_r_rmse=e(rmse) if country_file=="`i'"
								replace wat_r_N=e(N) if country_file=="`i'"
			
							///sanitation
								///OLS
								capture  regress totalimprovedsan_used_u  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_u!=.&freqsan>3
								capture  predict yhat_san_u if country_file=="`i'"
								replace san_u_rmse=e(rmse) if country_file=="`i'"
								replace san_u_N=e(N) if country_file=="`i'"
		
								///OLS
								capture  regress totalimprovedsan_used_r  year if  country_file=="`i'"&code!="year_Predict"&totalimprovedsan_used_r!=.&freqsan>3
								capture  predict yhat_san_r if country_file=="`i'"
								replace san_r_rmse=e(rmse) if country_file=="`i'"
								replace san_r_N=e(N) if country_file=="`i'"
		
								capture drop *hat*
								}
								
log on
display "`k' % sample of original dataset"
display "-----------------OLS-----------------------------------"
tabstat wat_u_N wat_r_N san_u_N san_r_N ,by(country_file) format(%9.2fc)   
tabstat wat_u_rmse wat_r_rmse san_u_rmse san_r_rmse ,by(country_file) format(%9.2fc) 	
log off
	
								drop  *rmse* *N
	   ////////////////// End of OLS RMSE comparison //////////////////////							
		

		
		
		////// LOWESS /////////////////////////

clear
use "/./Dropbox/2016_WASH/3files/Graph_data_5year_forRMSEcpmtn.dta"
sample `k',by(country_file)

drop freq*
egen freqwat=count(totalimprovedwat_used_t) , by(country_file)
egen freqsan=count(totalimprovedsan_used_t) , by(country_file)
egen freqwatU=count(totalimprovedwat_used_u) , by(country_file)
egen freqsanU=count(totalimprovedsan_used_u) , by(country_file)
egen freqwatR=count(totalimprovedwat_used_r) , by(country_file)
egen freqsanR=count(totalimprovedsan_used_r) , by(country_file)
rename  freqwatU freq_wat_used_u
rename  freqwatR freq_wat_used_r
rename  freqsanU freq_san_used_u
rename  freqsanR freq_san_used_r

drop if  freq_wat_used_u<4
drop if  freq_wat_used_r<4
drop if  freq_san_used_u<4
drop if  freq_san_used_r<4

drop if freqsan==.
drop if freqwat==.

	gen hat_wat_used_u=.
	gen hat_wat_used_r=.
	gen hat_san_used_u=.
	gen hat_san_used_r=.

	gen rmse_wat_used_u=.
	gen rmse_wat_used_r=.
	gen rmse_san_used_u=.
	gen rmse_san_used_r=.		

	levelsof country_file, local(levels) 
					foreach i of local levels   {
	foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	quietly gen rmse_strg_`j'=""	
	display "`i'"
	capture quietly   mlowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3, bwidth(.8) gen(hat_strg_`j')   nograph 
	//capture  generate   hat_strg_`j'=. if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'<=3
	capture  replace   hat_`j'=hat_strg_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly rmse      totalimproved`j'  hat_`j' if  country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly replace rmse_strg_`j'=r(hat_`j') if country_file=="`i'"&code!="year_Predict"&totalimproved`j'!=.&freq_`j'>3
	quietly destring rmse_strg_`j',replace 
	quietly sum		 rmse_strg_`j'
	quietly replace rmse_`j'=r(mean) if  country_file=="`i'"
	drop hat_strg_`j' rmse_strg_`j'
	}
}	
tabstat  rmse_wat_used_u rmse_wat_used_r rmse_san_used_u rmse_san_used_r, by(country_file)
				
		/////////////////////////////////////////////////////// 
		
	
////////////////////////////////////////////////////////////////////////////////////////////////

log on
display "`k' % sample of original dataset"

display "-----------------LOWESS-----------------------------------"
tabstat  rmse_wat_used_u rmse_wat_used_r rmse_san_used_u rmse_san_used_r, by(country_file)

log off
}

log close


******************************************** Basic cross validation 



clear
use Graph_data_extrapolation.dta


		foreach m in LWS SM {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {		
		gen `m'model_`j'=.
		gen `m'delta_`j'=.
		gen `m'dltPct_`j'=.
		gen `m'sd_`j'=.
		gen `m'se_`j'=.
		}
		}	

/// 	Run below two line as test and check the error message (if any).
quietly: crossfold reg totalimprovedwat_used_u year if country_file=="Afghanistan", k(5)
quietly: crossfold lowess  totalimprovedwat_used_u year if country_file=="Afghanistan", bw(0.8) mean nograph k(5)	

		
	// CV (m.spline Model)	
	
	set graphics off
	foreach k of numlist 5  {	
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		capture quietly: crossfold twoway mspline  totalimproved`j'  year if country_file=="`i'" &code!="year_Predict", bands(8) k(`k') title("`i'")
		capture quietly:  matrix def a=r(est)
		capture quietly: svmat double a, names(RMSE)
		capture quietly:  sum RMSE, detail
		capture quietly:  return list
		capture quietly:  replace SMmodel_`j'=r(p50) if country_file=="`i'" // LMSmodel stores MEDIAN value of RMSE from k-fold CV (default K is 5) 
		capture quietly: replace SMdelta_`j'=r(min)/r(max) if country_file=="`i'" 
		capture quietly: replace SMdltPct_`j'=1-SMdelta_`j' if country_file=="`i'" // (1-dealta) indicates % of change over K group 
		capture quietly:  replace SMsd_`j'=r(sd) if country_file=="`i'" 
		capture quietly:   replace SMse_`j'=r(sd)/sqrt(r(N)) if country_file=="`i'" 
		drop RMSE* _est*
		}
		}
		}
		set graphics on 		
		
		// Make table
		sum LMmodel* LWSmodel* SMmodel* , separator(4) format(%9.2f)//=Model RMSE 
		sum LMdltPct* LWSdltPct* SMdltPct*, separator(4)
		sum LMsd* LWSsd* SMsd*, separator(4)
		sum LMse* LWSse* SMse*, separator(4) //get the mean of SE 
		
		
		
		mean  LMmodel* LWSmodel* SMmodel*	
		mean  LMdltPct* LWSdltPct* SMdltPct*
		mean  LMsd* LWSsd*	SMsd*
		mean  LMse* LWSse*	SMse*
		
		tabstat LWSmodel* SMmodel* , s( mean median min max sd) format(%4.2fc) c(s) 
		tabstat LWSsd* SMsd* , s( mean median min max sd) format(%4.2fc) c(s) 
		tabstat LWSse* SMse* , s( mean median min max sd) format(%4.2fc) c(s) 
		
	
		// Drop old data points	
		drop *delta* *sd*  // keep RMSE,SE, delta%
		

		
	//////// Check validity. 
	/////// drop all countries with N<5 (freqwat & freqsan) & completely missing in *_U & *_R indicators 
drop if  freqwatU==0 & freqwat<5
drop if  freqwatR==0 & freqwat<5
drop if  freqsanU==0 & freqsan<5
drop if  freqsanR==0 & freqsan<5
drop if  freqwatU<5
drop if  freqwatR<5
drop if  freqsanU<5
drop if  freqsanR<5
drop if code=="year_Predict"
	

	
	
	
// CV (LOWESS model)		
	foreach k of numlist 5  {
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		foreach j in wat_used_u  {
		capture quietly: crossfold lowess  totalimproved`j'  year if country_file=="`i'" &code!="year_Predict", bw(0.8) mean  k(`k') title("`i'")
		capture quietly:  matrix def a=r(est)
		capture quietly: svmat double a, names(RMSE)
		capture quietly:  sum RMSE, detail
		capture quietly:  return list
		capture quietly:  replace LWSmodel_`j'=r(p50) if country_file=="`i'" // LWSmodel stores median value of RMSE from k-fold CV (default K is 5) 
		capture quietly: replace LWSdelta_`j'=r(min)/r(max) if country_file=="`i'"  
		capture quietly: replace LWSdltPct_`j'=1-LWSdelta_`j' if country_file=="`i'" // (1-dealta) indicates % of change over K group 
		capture quietly:  replace LWSsd_`j'=r(sd) if country_file=="`i'" 
		capture quietly:   replace LWSse_`j'=r(sd)/sqrt(r(N)) if country_file=="`i'" 
		capture: drop RMSE* _est*
		}
		}
		}
	
	
	*********************************** Cross validation for full model (100%) RMSE calculation & [N-2] dataset RMSE calculation
	// Goodness- of - fit check 
// Delete last 2 data points and compare RMSE 
// ver 1013 K-fold cross validation (LM, LOWESS, M.Spline + Extrapolation) and compare RMSE 
// k=5 (default value) 

//////////////////////////////
clear
use Graph_data_extrapolation.dta

	rename  freqwatU freq_wat_used_u
	rename  freqwatR freq_wat_used_r
	rename  freqsanU freq_san_used_u
	rename  freqsanR freq_san_used_r

	foreach m in LM LWS {
	foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
	gen `m'_hat_`j'=.
	gen `m'_rmse_`j'=.
	gen `m'model_`j'=.
}
}


///// Get RMSE from full model (no exclusion except the forecasting year) 
					
levelsof country_file, local(levels) 
foreach i of local levels   {
foreach j in wat_used_u wat_used_r san_used_u  san_used_r {					
			
			
			///OLS
			capture  quietly regress totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict"
			capture quietly  predict LM_hat_`j' if country_file=="`i'"&code!="year_Predict"
			quietly replace LM_rmse_`j'=e(rmse) if country_file=="`i'"&code!="year_Predict"
			
			
			// LOWESS
			capture  quietly gen rmse_strg_`j'=""
			capture  quietly  gen hat_strg_`j'=. 
			capture  mlowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict", bwidth(.8) mean predict(hat_strg_`j')  replace nograph 
			capture  replace    LWS_hat_`j'=hat_strg_`j' if  country_file=="`i'"&code!="year_Predict"
			capture  quietly  rmse      totalimproved`j'   LWS_hat_`j' if  country_file=="`i'"&code!="year_Predict"
			capture  quietly  replace rmse_strg_`j'=r(LWS_hat_`j') if country_file=="`i'"&code!="year_Predict"
			capture  quietly  destring rmse_strg_`j',replace 
			capture  quietly  sum		 rmse_strg_`j',  detail
			capture  quietly  replace LWS_rmse_`j'=r(p50) if  country_file=="`i'"
			drop *_strg_*
			
}
}

	 
	
	
/////// Get RMSE from CV 

set seed 12345


// CV (Linear regression Model)	
foreach k of numlist 5  {	
levelsof country_file, local(levels) 
foreach i of local levels   {
foreach j in wat_used_u  wat_used_r san_used_u  san_used_r {

		capture quietly: crossfold reg totalimproved`j'  year if country_file=="`i'" &code!="year_Predict",k(`k') 
		capture quietly:  matrix def a=r(est)
		capture quietly: svmat double a, names(RMSE)
		capture quietly:  sum RMSE, detail
		capture quietly:  return list
		capture quietly:  replace LMmodel_`j'=r(p50) if country_file=="`i'" // LMSmodel stores median value of RMSE from k-fold CV (default K is 5) 
		capture quietly: drop RMSE* _est*
		
}
}
}


quietly: crossfold reg totalimprovedwat_used_u year if country_file=="Peru", k(5)
quietly: crossfold lowess  totalimprovedwat_used_u year if country_file=="Peru", bw(0.8) mean nograph k(5)
quietly: crossfold reg totalimprovedwat_used_u year , k(5)
quietly: crossfold lowess  totalimprovedwat_used_u year , bw(0.8) mean nograph k(5)
// Above two lines generates _est* variables. Following code overwrites est* per iteration. 



foreach k of numlist 1 2 3 4 5 {
gen _est_est`k'=.
}


// CV (LOWESS model)		
foreach k of numlist 5  {
levelsof country_file, local(levels) 
foreach i of local levels   {
foreach j in wat_used_u  wat_used_r san_used_u  san_used_r {

		capture quietly:  gen hat_strg_`j'=.
		capture quietly: crossfold lowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict", bwidth(.8) mean gen(hat_strg_`j')  replace nograph  k(`k') 
		capture quietly:  matrix def a=r(est)
		capture quietly: svmat double a, names(RMSE)
		capture quietly:  sum RMSE, detail
		capture quietly:  return list
		capture quietly:  replace LWSmodel_`j'=r(p50) if country_file=="`i'" // LWSmodel stores median value of RMSE from k-fold CV (default K is 5) 
		capture: drop RMSE* _est*
		}
		}
		}
		
		
		
		
		tabstat *model* *rmse*, s(n mean sd min max) c(s)
		
		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
//////// Compute N-2 subset RMSE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// option1. Last 2 data

drop if code=="year_Predict"
by country_file, sort: gen N2year=_n 
egen N2mark=max(N2year) , by(country_file)
drop if N2mark==N2year
egen N1mark=max(N2year) , by(country_file)
drop if N1mark==N2year

drop N* 

save Graph_data_extrapolation_lastminusN2.dta,replace

/// option1a. Last N data

drop if code=="year_Predict"
by country_file, sort: gen N2year=_n 
egen N2mark=max(N2year) , by(country_file)
drop if N2mark==N2year
egen N1mark=max(N2year) , by(country_file)
drop if N1mark==N2year
egen N0mark=max(N2year) , by(country_file)
drop if N0mark==N2year
egen N4mark=max(N2year) , by(country_file)
drop if N4mark==N2year
egen N5mark=max(N2year) , by(country_file)
drop if N5mark==N2year
egen N6mark=max(N2year) , by(country_file)
drop if N6mark==N2year
egen N7mark=max(N2year) , by(country_file)
drop if N7mark==N2year


drop N* 

save Graph_data_extrapolation_lastminusN2.dta,replace


/// option2. First 2 data
clear
use Graph_data_extrapolation.dta

drop if code=="year_Predict"
by country_file, sort: gen N2year=_n 
egen N2mark=min(N2year) , by(country_file)
drop if N2mark==N2year
egen N1mark=min(N2year) , by(country_file)
drop if N1mark==N2year

drop N* 

save Graph_data_extrapolation_firstminusN2.dta,replace



/// option3. Median 3 data 

clear
use Graph_data_extrapolation.dta

drop if code=="year_Predict"
by country_file, sort: gen N2year=_n 
egen N2mark=max(N2year) , by(country_file)
gen N2marknew=round(N2mark/2)
drop if N2marknew==N2year
gen N1marknew=N2marknew+1 
drop if N1marknew==N2year

drop N* 

save Graph_data_extrapolation_MiddleminusN2.dta,replace


///////////////// calculate RMSE 


******************************** MCMC simulation example for Afghanistan 
clear
use Graph_data_extrapolation.dta

capture program drop _all 
set seed 12345

program define mymodel,rclass

tempvar x x2 y
reg totalimprovedwat_used_u  year
gen `x'=e(rmse) 
gen `x2'=rnormal(0,1)
gen `y'=`x'+`x2'
sum `y'
return scalar mean = r(mean)
end

simulate mean=r(mean), reps(1000): mymodel, obs(1000) nodots




////// OLS RMSE by MC 

clear
use Graph_data_extrapolation.dta

capture program drop _all 
set seed 12345

program define OLSrmse,rclass

foreach i in Afghanistan {	
foreach j in wat_used_u {

tempvar x_wat_used_u x2 y_wat_used_u 
regress totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict"
gen `x_wat_used_u'=e(rmse) if country_file=="`i'"&code!="year_Predict"
gen `x2'=rnormal(0,1)
gen `y_wat_used_u'=`x_wat_used_u'+`x2' if country_file=="`i'"&code!="year_Predict"
sum `y_wat_used_u'
return scalar mean = r(mean)

}
}

end

simulate mean=r(mean), reps(1000): OLSrmse, obs(1000) 
sum*

///// above works but new trial for tempvariable name
clear
use Graph_data_extrapolation.dta

capture program drop _all 
set seed 12345
 
program define OLSrmsewu,rclass
tempvar wat_used_u 
foreach i in Afghanistan   {	
regress totalimprovedwat_used_u  year if  country_file=="`i'"&code!="year_Predict"
gen `wat_used_u'=e(rmse) + rnormal(0,1) if country_file=="`i'"&code!="year_Predict"
sum `wat_used_u'
return scalar mean = r(mean)
}
end
simulate mean=r(mean), reps(1000): OLSrmsewu, obs(1000) 
sum*
////// Above code works but loop is not working properly.
clear
use Graph_data_extrapolation.dta

capture program drop _all 
set seed 12345
 
program define OLSrmsewu,rclass
tempvar wat_used_u 
foreach i in Afghanistan   {	
mlowess   totalimproved`j'  year if  country_file=="`i'"&code!="year_Predict", bwidth(.8) predict(hat_strg_`j')  replace nograph 
gen `wat_used_u'=e(rmse) + rnormal(0,1) if country_file=="`i'"&code!="year_Predict"
sum `wat_used_u'
return scalar mean = r(mean)
}
end
simulate mean=r(mean), reps(1000): OLSrmsewu, obs(1000) 
sum*


*************************************** Extrapolation Value Check 


// ver 0819 
// component A. Generate extrpolated data for each extrapolation method 
// component B. Generate graphs for each explt method
// component C. Compare last known value vs last explt value for method-wise comparison
clear
cd "/./Dropbox/2016_WASH/3files"
use "/./Dropbox/2016_WASH/3files/Graph_data_LM_BSTciComparison.dta" 


append using year_predict2 // Use this for year forecating +3
		save Graph_data_Yearappend2.dta,replace
		bys country_file: egen yearmin = min(year)
		sort country_file year
		replace yearmin=. if code=="year_Predict"
		
egen yearmax=max(year) if code=="year_Predict",by(country_file) 
drop if year==yearmax
drop yearmax
save Graph_data_extrapolation.dta,replace

use Graph_data_extrapolation.dta 








// component A.
levelsof country_file, local(levels) 
		foreach i of local levels   {
		
		display "`i'"
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u  {

			capture mipolate  totalimproved`j'  year if country_file=="`i'", forward gen(miplt`i'`j')
			capture nnipolate  totalimproved`j'  year if country_file=="`i'",  gen(nniplt`i'`j')
			capture ipolate  totalimproved`j'  year if country_file=="`i'",  gen(iplt`i'`j') epolate
			capture pchipolate  totalimproved`j'  year if country_file=="`i'",  gen(piplt`i'`j')
			capture quietly: regress totalimproved`j'  year if country_file=="`i'"
			capture predict olsplt`i'`j' if country_file=="`i'"
		}
} 



// Component A support 
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u  {
			egen miextplt_`j'=rowmean(miplt*) // combine extplt value from all countries into one variable 
			egen nniextplt_`j'=rowmean(nniplt*)
			egen iextplt_`j'=rowmean(iplt*)
			egen pchiextplt_`j'=rowmean(piplt*)
			egen olsextplt_`j'=rowmean(olsplt*)
		}
		drop miplt* nniplt* piplt* olsplt* iplt*


// component B.
levelsof country_file, local(levels) 
	foreach i of local levels   {
		foreach j in wat_used_u  {
			
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'")|| /*
		*/(lfit miextplt_`j' year  if country_file=="`i'", lc(red))||/*
		*/(lfit nniextplt_`j' year if country_file=="`i'",lc(blue))||/*
		*/(lfit pchiextplt_`j' year if country_file=="`i'", lc(khaki))||/*
		*/(lfit iextplt_`j' year if country_file=="`i'", lc(magenta))||/*
		*/(lfit totalimproved`j'  year if country_file=="`i'",lpattern(dot) lc(gs10))|| /*
		*/(line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
	*/ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/    title("linear regression") saving(lfit`i'`j',replace) legend(off) graphregion(color(white)) )
		
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'") ||/*
		*/(mspline miextplt_`j' year  if country_file=="`i'",bands(8)  lc(red))||/*
		*/(mspline nniextplt_`j' year if country_file=="`i'",bands(8) lc(blue))||/*
		*/(mspline pchiextplt_`j' year if country_file=="`i'",bands(8)  lc(khaki))||/*
		*/(mspline iextplt_`j' year if country_file=="`i'" ,bands(8) lc(magenta))||/*
		*/ (line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
		*/ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/   title("mspline") saving(mspline`i'`j',replace) legend(off) graphregion(color(white)) )
		
		capture graph twoway (scatter totalimproved`j'  year if country_file=="`i'") ||/*
		*/(lowess miextplt_`j' year  if country_file=="`i'",bwidth(.8) mean lc(red))||/*
		*/(lowess nniextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(blue))||/*
		*/(lowess pchiextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(khaki) )||/*
		*/(lowess iextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(magenta) )||/*
		*/ (line olsextplt_`j' year if country_file=="`i'" ,lpattern(solid) lc(gs0)/*
		 */ylabel(0(10)100) xlabel(1985(5)2015)/*
		*/    title("lowess") saving(lowess`i'`j',replace) legend(off) graphregion(color(white)) )

		
		capture  graph combine lfit`i'`j'.gph    mspline`i'`j'.gph     lowess`i'`j'.gph , /*
		*/row(1)  iscale(0.7) ycommon ysize(10) xsize(15) title("`i' (Total improved `j')") graphregion(color(white))  /*
		*/caption("Red:mipolate forward"  "Blue:nearest neighborhood extrapolation"  "Khaki:piecewise extrapolation"  "Magenta:ipolate extp" "Black:Extrapolated OLS") 
		capture graph export `i'_extrapolationMethodCheck.png, replace
			}
		} 
		
		
		
		
		


		
		
// component C.
/////// Compare last known value & last extrapolated value  per each extrapolation method and the spline method 


egen yearmax=max(year) if code!="year_Predict",by(country_file)
egen frcstyearmax=max(year) if code=="year_Predict",by(country_file) 


foreach k in olsextplt miextplt nniextplt iextplt pchiextplt  {
		//foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		foreach j in wat_used_u {
		
		gen basecmrs`k'_`j'= `k'_`j' if year==yearmax 
		gen topcmrs`k'_`j'= `k'_`j' if year==frcstyearmax
		
		egen base`k'_`j'= max(basecmrs`k'_`j'),by(country_file)
		egen top`k'_`j'= max(topcmrs`k'_`j'),by(country_file)
		//egen diff_`k'_`j'=diff( base`k'_`j' top`k'_`j') 
		egen diff_`k'=diff( base`k'_`j' top`k'_`j') 
		}
	}
	
tabstat  diff_*,by(country_file) s(mean) labelwidth(20)
drop *base* *top*






*********************** Extrapolation value check for pcipolate and nipolate function

/// Code from "ExtrapolationValueCheck.do" 
/// Objective: Check extrapolation value and see impact of extrapolated value to inital part of regression or last part of regression 
/// ver 1020



clear
use Graph_data_extrapolation.dta 

gen keep="Pattern1" if country_file=="Cayman_Islands"|country_file=="Ecuador"|country_file=="Kyrgyzstan"
replace keep="Pattern2" if country_file=="Ireland"|country_file=="Kenya"
replace keep="Pattern3" if country_file=="Malawi"|country_file=="Swaziland"

drop if keep==""






// component A.
levelsof country_file, local(levels) 
		foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
			capture ipolate  totalimproved`j'  year if country_file=="`i'",  gen(iplt`i'`j') epolate
			replace iplt`i'`j'=. if totalimproved`j'==.&code!="year_Predict" //prevent retro-extrapolation 
			capture pchipolate  totalimproved`j'  year if country_file=="`i'",  gen(piplt`i'`j')
			replace piplt`i'`j'=. if totalimproved`j'==.&code!="year_Predict" //prevent retro-extrapolation 

		}
} 


// Component A support 
			foreach j in wat_used_u wat_used_r san_used_u  san_used_r {			
			egen iextplt_`j'=rowmean(iplt*`j') 
			egen pchiextplt_`j'=rowmean(piplt*`j') 
			
		}
		drop   iplt* piplt*


		
		// quick result check 
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		graph twoway (scatter  totalimprovedwat_used_u year if country_file=="`i'",msymbol(x) mc(blue) msize(huge)) /*
		*/(scatter iextplt_wat_used_u year if country_file=="`i'",msymbol(oh) mc(red)  msize(huge) title("`i'_wat_u")) /*
		*/(scatter pchiextplt_wat_used_u year if country_file=="`i'",msymbol(dh) mc(black)  msize(huge))/*
		*/(line  iextplt_wat_used_u year if country=="`i'") (line  pchiextplt_wat_used_u year if country=="`i'")/*
		*/(lfit  totalimprovedwat_used_u year if country=="`i'", saving(`i',replace) )
		}
		graph combine Cayman_Islands.gph Ecuador.gph Kyrgyzstan.gph Ireland.gph Kenya.gph Malawi.gph Swaziland.gph, col(3) row(3) altshrink
		graph export ExtrapolationTest.png, replace
		
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		graph twoway (scatter  totalimprovedwat_used_u year if country_file=="`i'",msymbol(x) mc(blue) msize(huge)) /*
		*/(scatter iextplt_wat_used_u year if country_file=="`i'",msymbol(oh) mc(red)  msize(huge) title("`i'_wat_u")) /*
		*/(scatter pchiextplt_wat_used_u year if country_file=="`i'",msymbol(dh) mc(black)  msize(huge))/*
		*/(lfit  iextplt_wat_used_u year if country=="`i'") (lfit  pchiextplt_wat_used_u year if country=="`i'")/*
		*/(lfit  totalimprovedwat_used_u year if country=="`i'", saving(`i',replace) )
		}
		
		graph combine Cayman_Islands.gph Ecuador.gph Kyrgyzstan.gph Ireland.gph Kenya.gph Malawi.gph Swaziland.gph, col(3) row(3) altshrink
		graph export ExtrapolationTest.png, replace
		



// component B.
levelsof country_file, local(levels) 
	foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r  {
			
		graph twoway (scatter totalimproved`j'  year if country_file=="`i'")|| /*
		*/(lfit pchiextplt_`j' year if country_file=="`i'", lc(khaki))||/*
		*/(lfit iextplt_`j' year if country_file=="`i'", lc(magenta))||/*
		*/(lfit totalimproved`j'  year if country_file=="`i'",lc(gs10)
				*/ylabel(0(10)100) xlabel(1985(5)2015) title("`i'")/*
		*/saving(`i'`j'LM,replace) legend(off) graphregion(color(white)) )
		
		
		(lowess pchiextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(khaki) )||/*
		*/(lowess iextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(magenta) )||/*
		*/(lowess totalimproved`j' year if country_file=="`i'",bwidth(.8) mean lc(gs10)  /*
		*/ylabel(0(10)100) xlabel(1985(5)2015) title("`i'")/*
		*/saving(`i'`j'LOWESS,replace) legend(off) graphregion(color(white)) )

		}
		}
		
		
	levelsof country_file, local(levels) 
	foreach i of local levels   {
		  graph combine `i'wat_used_u.gph  `i'wat_used_r.gph  `i'san_used_u.gph  `i'san_used_r.gph , /*
		*/row(2) col(2)  ycommon ysize(10) xsize(15) title("`i'") graphregion(color(white))  /*
		*/caption("Khaki:piecewise extrapolation"  "Magenta:ipolate extp" "Black:Extrapolated OLS") altshrink 
		 graph export `i'_extrapolation.png, replace

		} 
		
		
		
		
		


		

		************************ yearAppend_Forward 
		
		
		// objective : generate missing y value for 4 year forwarding extension from last forecasting value 
// attention: new year should be APPENDED to the current dataset and not interfe BEFORE forecasting. (Append after forecasting ) 
// concept : Similar to yearAppend.do file 

clear
use "/./Dropbox/2016_WASH/3files/yearAppend_Original.dta"

*generate base variables
rename var1 country_file
rename var2 yearmax
rename var3 yearmin


* generate space for wide form
quietly forvalues j = 1(1)40 {
			generate country`j'=country_file if country_file=="Afghanistan'"
			}			

* fill country name for each year slate  
levelsof country_file, local(levels) 
 foreach i of local levels {
 forvalues j = 1(1)40 {
	replace country`j'=country_file if country_file=="`i'" 
}
}

* reshape to long to create space for "predicted year" N: Whatever last year of data observation to 2020 
gen n=_n
reshape long country, i(n) j(year_n)
gen year_predict= year_n+ yearmax
//drop if year_predict>2020

/*
drop if year_n>5
drop n  year_n  country
gen code="year_Predict" if year_predict!=.
rename year_predict year
*/


//drop  if year_n>3
//drop n  year_n  country


gen code="year_Predict" if year_n==1 | year_n==2
drop if code=="year_Predict"
replace code="year_forward4" if year_n==3 | year_n==4 | year_n==5 | year_n==6
rename year_predict year
drop yearmax yearmin n year_n
drop country
drop if code==""

save "/./Dropbox/2016_WASH/3files/Graph_data_YearappendForward4.dta",replace


******************************* Region_Conversion

		



/// IMPORT JMP AND POPULATION ESTIMATES
use Population.dta, clear
merge 1:1 country_file year using Estimates_unrounded_Stata13, nogenerate
//drop if year<1990
rename urban_pop pop_u
rename rural_pop pop_r
rename total_pop pop_t

/// SELECT REGIONS (using UNICEF list to get MDG regions)
replace country_file = "Reunion_15" if country_file=="reunion_15"
merge n:n country_file using "Country_key_Stata11.dta"
drop _merge
rename region_who regions  // Select "regions"

// ADJUST DATASET
*Drop countries not included in JMP estimates (St Pierre & Michelon, Gibraltar and Holy See)
drop if country_file == "St_Pierre_and_Miquelon_15"
drop if country_file == "Holy_see_15"
drop if country_file == "Gibraltar_15" 

drop  country_file
drop  country_code
order  name_notofficial
drop wat* san*
drop  year pop_u pop_r pop_t name_official area region_acp region_ldc devdvpd name_who_mf name_jmp2014 region_unicef_r1 region_unicef_r2 region_unicef_r3 region_developing region_oic region_wbincome2013 region_countdown75 region_un_majorarea region_un_region region_ecaafrica region_africanunion region_lldcs_sids regions_updated regions_notes country_in_backtable slno name_wb region_wblendingcat region_wbother dfid
drop if  name_notofficial==""

replace name_notofficial="Argentina" if name_notofficial=="argentina"     	 
replace name_notofficial="Aruba" if name_notofficial=="aruba"     	 
replace name_notofficial="Barbados" if name_notofficial=="barbados"     	 
replace name_notofficial="Belize" if name_notofficial=="belize"     	 
replace name_notofficial="Bolivia" if name_notofficial=="bolivia"     	 
replace name_notofficial="Brazil" if name_notofficial=="brazil"     	 
replace name_notofficial="Chile" if name_notofficial=="chile"     	 
replace name_notofficial="Colombia" if name_notofficial=="colombia"     	 
replace name_notofficial="Costa_Rica" if name_notofficial=="costa_rica"     	 
replace name_notofficial="Cuba" if name_notofficial=="cuba"     	 
replace name_notofficial="Dominica" if name_notofficial=="dominica"     	 
replace name_notofficial="Dominican_Republic" if name_notofficial=="dominican_republic"     	 
replace name_notofficial="Ecuador" if name_notofficial=="ecuador"     	 
replace name_notofficial="El_Salvador" if name_notofficial=="el_salvador"     	 
replace name_notofficial="French_Guiana" if name_notofficial=="french_guiana"     	 
replace name_notofficial="Guadeloupe" if name_notofficial=="guadeloupe"     	 
replace name_notofficial="Guatemala" if name_notofficial=="guatemala"     	 
replace name_notofficial="Guyana" if name_notofficial=="guyana"     	 
replace name_notofficial="Haiti" if name_notofficial=="haiti"     	 
replace name_notofficial="Honduras" if name_notofficial=="honduras"     	 
replace name_notofficial="Jamaica" if name_notofficial=="jamaica"     	 
replace name_notofficial="Martinique" if name_notofficial=="martinique"     	 
replace name_notofficial="Mexico" if name_notofficial=="mexico"     	 
replace name_notofficial="Nicaragua" if name_notofficial=="nicaragua"     	 
replace name_notofficial="Panama" if name_notofficial=="panama"     	 
replace name_notofficial="Paraguay" if name_notofficial=="paraguay"     	 
replace name_notofficial="Peru" if name_notofficial=="peru"     	 
replace name_notofficial="Puerto_Rico" if name_notofficial=="puerto_rico"     	 
replace name_notofficial="Reunion" if name_notofficial=="reunion"     	 
replace name_notofficial="Saint_Kitts_And_Nevis" if name_notofficial=="saint_kitts_and_nevis"     	 
replace name_notofficial="Saint_Lucia" if name_notofficial=="saint_lucia"     	 
replace name_notofficial="South_Sudan" if name_notofficial=="south_sudan"     	 
replace name_notofficial="St_Vincent_And_Grenad" if name_notofficial=="st_vincent_and_grenad"     	 
replace name_notofficial="Suriname" if name_notofficial=="suriname"     	 
replace name_notofficial="United_States_Virgin_Islands" if name_notofficial=="united_states_virgin_islands"     	 
replace name_notofficial="Uruguay" if name_notofficial=="uruguay"	 
replace name_notofficial="Venezuela" if name_notofficial=="venezuela"	 


sort name_notofficial
contract  name_notofficial regions
drop _freq 
drop if regions==""
rename  name_notofficial country_file
save "/./Dropbox/2016_WASH/3files/Population_WHOregions.dta",replace

sort name_notofficial
contract name_notofficial region_wbincome2015
drop _freq 
drop if region_wbincome2015==""
rename  name_notofficial country_file
save "/./Dropbox/2016_WASH/3files/Population_WB2015regions.dta",replace



**************************** Extrapolation + 4year forward extension 


/// Code from "ExtrapolationValueCheck.do" 
/// Objective: Build forecasting points using "ipolate" command (LM & LOWESS) + 4 year extension 
/// ver 1024



clear
use Graph_data_extrapolation.dta 


// component A.
levelsof country_file, local(levels) 
		foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
			capture ipolate  totalimproved`j'  year if country_file=="`i'",  gen(iplt`i'`j') epolate
			capture replace iplt`i'`j'=. if totalimproved`j'==.&code!="year_Predict" //prevent retro-extrapolation 
			capture quietly: regress totalimproved`j'  year if country_file=="`i'"
			capture predict olsplt`i'`j' if country_file=="`i'"
		}
} 


// Component A support 
			foreach j in wat_used_u wat_used_r san_used_u  san_used_r {			
			egen iextplt_`j'=rowmean(iplt*`j') 	
			egen olsextplt_`j'=rowmean(olsplt*`j')
		}
		drop   iplt* olsplt*

	
		append using Graph_data_YearappendForward4
		bys country_file: egen yearmin = min(year)
		sort country_file year

		// Forward extended forecasting
	levelsof country_file, local(levels) 
		foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
			capture mipolate  iextplt_`j'  year if country_file=="`i'", forward gen(forward`i'`j') 
			capture replace forward`i'`j'=. if totalimproved`j'==.&code!="year_Predict" &code!="year_forward4"   //prevent retro-extrapolation 
		}
} 


			foreach j in wat_used_u wat_used_r san_used_u  san_used_r {			
			egen extns_`j'=rowmean(forward*`j') 	
		}
		drop   forward* 
		
		
		
	/////// Compare last known value & last extrapolated value  per each spline method 


egen yearmax=max(year) if code!="year_Predict"&code!="year_forward4" ,by(country_file)
egen frcstyearmax=max(year) if code=="year_Predict",by(country_file) 


		foreach k in olsextplt  iextplt   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {

		gen basecmrs`k'_`j'= `k'_`j' if year==yearmax 
		gen topcmrs`k'_`j'= `k'_`j' if year==frcstyearmax
		
		egen base`k'_`j'= max(basecmrs`k'_`j'),by(country_file)
		gen OLS`k'_`j'=round(base`k'_`j',0.2)
		egen top`k'_`j'= max(topcmrs`k'_`j'),by(country_file)
		gen extl`k'_`j'=round(top`k'_`j',0.2)
		egen diff_`k'_`j'=diff( base`k'_`j' top`k'_`j') 
		//egen diff_`k'=diff( base`k'_`j' top`k'_`j') 
		}
	}
	
//tabstat  OLS,by(country_file) s(mean) labelwidth(20)
tabstat  diff_*,by(country_file) s(mean) labelwidth(20)
drop *basecmrs* *topcmrs*
	
	////////////// Result plot + table	

		levelsof country_file, local(levels) 
		foreach i of local levels   {
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		
		quietly: sum totalimproved`j'  if country_file=="`i'"
		
		capture: graph twoway (scatter  totalimproved`j' year if country_file=="`i'",msymbol(x) mc(blue) msize(small)) /*
		*/(scatter iextplt_`j' year if country_file=="`i'" ,msymbol(oh) mc(red)  msize(small) subtitle("`j'") caption("N: `r(N)'") ylabel(0(10)100) xlabel(1985(5)2015) saving(`i'_`j',replace) legend(off) graphregion(color(white))) /*
		*/(lfit  totalimproved`j' year if country_file=="`i'", lc(black) lpattern(dash) )/*
		*/(lowess extns_`j' year if country_file=="`i'",bwidth(.8) mean lc(orange) lpattern(solid) )
		//(lowess iextplt_`j' year if country_file=="`i'",bwidth(.8) mean lc(black) lpattern(dash) )
		}
		}
		
		
		levelsof country_file, local(levels) 
		foreach i of local levels   {
		capture: graph combine `i'_wat_used_u.gph `i'_wat_used_r.gph `i'_san_used_u.gph  `i'_san_used_r.gph ,/*
		*/graphregion(color(white)) plotregion(color(white)) col(2) row(2) caption("Black solid dash line: Linear regression for observed value" "Orange solid line: LOWESS including 2 year extrapolation", size(*0.5) )  altshrink title("`i'")
		capture: graph export Full_`i'.png, replace
		}



		

 save "/./Dropbox/2016_WASH/3files/Graph_data_extrapolation_full.dta"


merge m:m country_file using Population_WHOregions.dta, nogenerate
merge m:m country_file using Population_WB2015regions.dta, nogenerate

tabstat  diff_olsextplt_*,by(regions) s(mean) labelwidth(20)
tabstat  diff_iex*_*,by(regions) s(mean) labelwidth(20)

tabstat  diff_olsextplt_*,by(region_wbincome2015) s(mean) labelwidth(20)
tabstat  diff_iex*_*,by(region_wbincome2015) s(mean) labelwidth(20)



*********************** Prepare dataset for visualization 
clear
use "/./Dropbox/2016_WASH/3files/Graph_data_extrapolation_full.dta"
drop diff*
drop yearmin
drop yearmax
drop *max
drop freq*
drop *_t
order *_u *_r
order country* code year
 sort country* year

		
		foreach j in wat_used_u wat_used_r san_used_u  san_used_r {
		egen glb_m_obsr_`j'=median( totalimproved`j') if code!="year_Predict"|code!="year_forward4"
		//egen glb_m_prdc_`j'=median( totalimproved`j') if code=="year_Predict"
		egen rgn_m_obsr_`j'=median( totalimproved`j') if code!="year_Predict"|code!="year_forward4", by(regions) // by WHO region
		//egen rgn_m_prdc_`j'=median( totalimproved`j') if code=="year_Predict", by(regions) // by WHO region
		}




// END 
