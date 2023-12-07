ssc install kountry

*** Clean and prepare the CHAT dataset
use orig_chat.dta, clear
* Standardize country names
kountry country_name, from(iso3c)
drop country_name
rename NAMES_STD country_name

* Get rid of all irrelevant variables
drop if year < 1970 | year > 1999
keep country_name year cellphone computer elecprod internetuser irrigatedarea vehicle_car

* Generate growth rates for each technology sector
reshape wide cellphone computer elecprod internetuser irrigatedarea  vehicle_car, i(country_name) j(year)

forvalues i=1970/1998{
	local j=`i'+1
	gen cellphone_growth`i'=((cellphone`j'/cellphone`i')-1)*100
	gen computer_growth`i'=((computer`j'/computer`i')-1)*100
	gen elecprod_growth`i'=((elecprod`j'/elecprod`i')-1)*100
	gen internetuser_growth`i'=((internetuser`j'/internetuser`i')-1)*100
	gen irrigatedarea_growth`i'=((irrigatedarea`j'/irrigatedarea`i')-1)*100
	gen vehicle_car_growth`i'=((vehicle_car`j'/vehicle_car`i')-1)*100
}

reshape long cellphone computer elecprod internetuser irrigatedarea vehicle_car cellphone_growth computer_growth elecprod_growth internetuser_growth irrigatedarea_growth  vehicle_car_growth, i(country_name) j(year)

drop cellphone computer elecprod internetuser irrigatedarea vehicle_car
save chat.dta, replace



*** Now clean and prepare the PWT dataset
use orig_pwt.dta, clear

* Standardize country names
kountry country, from(iso3c)
drop country
rename NAMES_STD country_name

* Get rid of all irrelevant variables and rename remaining variables
keep year rgdpna country_name pop avh rconna xr pl_c
drop if year < 1970 | year > 1999
rename rgdpna GDP
rename avh workhours
rename rconna rconsump
rename xr exchrte
rename pl_c prclvl

* Calculate and save growth rate for GDP
reshape wide GDP pop workhours rconsump exchrte prclvl, i(country_name) j(year)
forvalues i=1970/1998{
	local j=`i'+1
	gen GDPgrowth`i'=((GDP`j'/GDP`i')-1)*100
}
reshape long GDP GDPgrowth pop workhours rconsump exchrte prclvl, i(country_name) j(year)

save pwt.dta, replace



*** Now merge the datasets and perform analysis
merge 1:1 country_name year using chat.dta
keep if _merge==3

* Generate per capita variables

**# Bookmark #1
gen GDP_growth_percap = GDPgrowth / pop
gen workhours_percap = workhours / pop
gen rconsump_percap = rconsump / pop
drop GDP GDPgrowth workhours rconsump

foreach var in cellphone_growth computer_growth elecprod_growth internetuser_growth irrigatedarea_growth vehicle_car_growth {
	replace `var' = `var' / pop
	rename `var' `var'_percap
}

* Take the log of all numerical variables used in the regression
foreach var in exchrte prclvl GDP_growth_percap workhours_percap rconsump_percap cellphone_growth_percap computer_growth_percap elecprod_growth_percap internetuser_growth_percap irrigatedarea_growth_percap vehicle_car_growth_percap {
	replace `var' = log(`var')
	rename `var' l`var'
}

* Run a regression with all technology growth variables
rreg lGDP_growth_percap lexchrte lprclvl lworkhours_percap lrconsump_percap lcellphone_growth_percap lcomputer_growth_percap lelecprod_growth_percap linternetuser_growth_percap lirrigatedarea_growth_percap lvehicle_car_growth_percap year

* Perform a joint hypothesis test on all technology growth variables except
* electric, which is already very significant
test (lcellphone_growth_percap=0) (lcomputer_growth_percap=0) (linternetuser_growth_percap=0) (lirrigatedarea_growth_percap=0) (lvehicle_car_growth_percap=0)

* Try expanding to more data by removing computer/cellphone/internet vars
rreg lGDP_growth_percap lexchrte lprclvl lworkhours_percap lrconsump_percap lelecprod_growth_percap lirrigatedarea_growth_percap lvehicle_car_growth_percap year

* Try expanding to more data by removing irrigated land and vehicle vars
rreg lGDP_growth_percap lexchrte lprclvl lworkhours_percap lrconsump_percap lcellphone_growth_percap lcomputer_growth_percap lelecprod_growth_percap linternetuser_growth_percap year

* Perform a joint hypothesis test on computer/cellphone/internet vars
test (lcellphone_growth_percap=0) (lcomputer_growth_percap=0) (linternetuser_growth_percap=0)


*** Compare GDP growth and technology growth rates for developing countries versus developed countries

gen developed = 0
replace developed = 1 if country_name == "france"
replace developed = 1 if country_name == "germany"
replace developed = 1 if country_name == "italy"
replace developed = 1 if country_name == "japan"
replace developed = 1 if country_name == "united kingdom"
replace developed = 1 if country_name == "united states"

collapse (mean) pop lexchrte lprclvl lcellphone_growth_percap lcomputer_growth_percap lelecprod_growth_percap linternetuser_growth_percap lirrigatedarea_growth_percap lvehicle_car_growth_percap lGDP_growth_percap lworkhours_percap lrconsump_percap, by(country_name developed)

sum lGDP_growth_percap lcellphone_growth_percap lcomputer_growth_percap lelecprod_growth_percap linternetuser_growth_percap lirrigatedarea_growth_percap lvehicle_car_growth_percap if developed == 1

sum lGDP_growth_percap lcellphone_growth_percap lcomputer_growth_percap lelecprod_growth_percap linternetuser_growth_percap lirrigatedarea_growth_percap lvehicle_car_growth_percap if developed == 0







