capture             log close
log                 using "$gamePost/code/logs/mm_gamePost", replace

* Project: 			MahindiMaster
* Created: 			2020/05/01 - ET
* Last modified: 	2020/05/07 - ET
* Stata 			v.16.1

* **********************************************************************
* 1 (a) - Initialize form-specific parameters
* **********************************************************************

	local 			csvfile "$gamePost/dataSets/raw/MahindiMaster POST.csv"
	local 			dtafile ///
					"$gamePost/dataSets/intermediate/MahindiMaster POST.dta"

	local 			repeat_groups_csv1 ""
	local 			repeat_groups_stata1 ""
	local 			repeat_groups_short_stata1 ""

	local 			note_fields1 "risknote exp_explain1 p_size_acrest exp_explain4 exp_explain6 exp_graph2 exp_explain7 exp_explain8 exp_graph3 aspirations deviceid  subscriberid simid devicephonenum username caseid village_name"
	local 			calcfields "exp_c c1 c2 c3 c4 exp_d d1 d2 d3 d4 p_sizeha p_sizema p_sizepa lime exp_probe"

	local 			text_fields1 "duration comments village hhid hhid_verif hhid_div hhid_odd plant_seq2 yield_compare2 yield_specify p_sizeha p_sizema p_sizepa"
	local 			text_fields2 "p_size_acres exp_c c1 c2 c3 c4 lime exp_d d1 d2 d3 d4"

	local 			date_fields1 ""
	local 			datetime_fields1 "submissiondate starttime endtime"

* **********************************************************************
* 1 (b) - Import data from primary .csv file
* **********************************************************************
	import delimited using "`csvfile'", clear

* Drop extra table-list columns
		cap drop reserved_name_for_field_*
		cap drop generated_table_list_lab*

* Drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}

* Format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				foreach dtvar of varlist `dtvarlist' {
					tempvar tempdtvar
					rename `dtvar' `tempdtvar'
					gen double `dtvar'=.
					cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
					* automatically try without seconds, just in case
					cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
					format %tc `dtvar'
					drop `tempdtvar'
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				foreach dtvar of varlist `dtvarlist' {
					tempvar tempdtvar
					rename `dtvar' `tempdtvar'
					gen double `dtvar'=.
					cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
					format %td `dtvar'
					drop `tempdtvar'
				}
			}
		}
	}

* Ensure that text fields are imported as strings (with "" for missing values)
* Note that we treat calculate fields as text

	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				foreach stringvar of varlist `svarlist' {
					quietly: replace `ismissingvar'=.
					quietly: cap replace `ismissingvar'=1 if `stringvar'==.
					cap tostring `stringvar', format(%100.0g) replace
					cap replace `stringvar'="" if `ismissingvar'==1
				}
			}
		}
	}
	quietly: drop `ismissingvar'

    * Drop uninformative variables (missing because tablets were not GSM)
* and there were no comments
    cap drop    hhid_verif 
    cap drop    hhid_div 
    cap drop    hhid_odd
    cap drop    `calcfields'

    * Check if there are any saved comments, otherwise drop 
    capture {
        count if          !mi(comment)
        if `r(N)'==0 {
            drop comment
        }     
    }

* **********************************************************************
* 1 (c) - Consolidate ID variable
* **********************************************************************

* Consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid

* **********************************************************************
* 2 - Label variables
* **********************************************************************
	label               variable key "Unique submission ID"
	cap label           variable submissiondate "Date/time submitted"
	cap label           variable formdef_version "Form version used on device"

	label               variable enum "Enumerator"
    
	label               variable county "County"
	label               define county 3 "Homabay" 9 "Migori"
	label               values county county

	label               variable village "Village"

	label               variable hhid "Household ID"

	label               variable plant_seq "Planting in game vs normal planting process"
	note                plant_seq: "How similar is the way the game shows planting compared to how you normally plant?"
	label               define plant_seq 1 "The game planting sequence is similar to how I plant" 2 "The game planting sequence is somewhat similar to how I plant" 3 "The game planting sequence is slightly different from how I plant" 4 "The game planting sequence is very different from how I plant"
	label               values plant_seq plant_seq

	label               variable plant_seq2 "Main differences?"
	note                plant_seq2: "What is different?"

	label               variable plant_fun "Enjoy playing the game"
	note                plant_fun: "Did you enjoy playing the game?"
	label               define plant_fun 1 "Yes" 0 "No"
	label               values plant_fun plant_fun

	label               variable plant_learn "Learn something new from the game?"
	note                plant_learn: "Did you learn something new from the game?"
	label               define plant_learn 1 "Yes" 0 "No"
	label               values plant_learn plant_learn

	label               variable yield_compare "Game yields vs potential on own field"
	note                yield_compare: "Do you think overall the yields in the game are … than what you would get with the same inputs on your field?"
	label               define yield_compare 1 "Much higher" 2 "Higher" 3 "The same" 4 "Lower" 5 "Much lower"
	label               values yield_compare yield_compare

	label               variable yield_compare2 "Why do you think they are different?"
	note                yield_compare2: "Why do you think they are different?"

	label               variable yield_specify "Other reasons for differences between game & real life?"
	note                yield_specify: "Please comment on what other reasons for differences between game and real life"

	label               variable risk1 "Risk aversion: general"
	note                risk1: "How do you see yourself: Are you generally a person who is fully prepared to take risks or do you try to avoid taking risks?"
	label               define risk1 1 "Not at all willing to take risks" 2 "Somewhat UNwilling to take risks" 3 "Neither willing not unwilling" 4 "Somewhat willing to take risks" 5 "Very willing to take risks"
	label               values risk1 risk1

	label               variable risk2 "Risk aversion: on farm"
	note                risk2: "How do you see yourself: Are you a person who is fully prepared to take risks ON YOUR FARM or do you try to avoid taking risks ON YOUR FARM?"
	label               define risk2 1 "Not at all willing to take risks" 2 "Somewhat UNwilling to take risks" 3 "Neither willing not unwilling" 4 "Somewhat willing to take risks" 5 "Very willing to take risks"
	label               values risk2 risk2
    label               variable risk3 "Certain 3000 Ksh. vs. (3000,5000) lottery"
	label               variable risk4 "Are you sure of your choice?"
	label               variable risk5 "Certain 3000 Ksh. vs. (2500,5000) lottery"
	label               variable risk6 "Certain 3000 Ksh. vs. (2000,5000) lottery"
	label               variable risk7 "Certain 3000 Ksh. vs. (1500,5000) lottery"
	label               variable risk8 "Certain 3000 Ksh. vs. (1000,5000) lottery"
	label               variable risk9 "Certain 3000 Ksh. vs. (500,5000) lottery"
    
	note                risk3: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 3000 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"
	label               define risk 1 "Certainty" 2 "Lottery"
	label               values risk3 risk4 risk5 risk6 risk7 risk8 risk9 risk
	note                risk4: "Are you sure of your choice?   Bag 1 has one ball worth 3000 Ksh. Bag 2 has two balls. One is worth 3000 Ksh, and the other is worth 5000 Ksh.   If you choose Bag 2, you will win at least 3000 Ksh and have an equal chance of winning 5000 Ksh.  Which bag would you choose?"
	note                risk5: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 2500 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"
	note                risk6: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 2000 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"
	note                risk7: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 1500 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"
	note                risk8: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 1000 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"
	note                risk9: "Bag 1: one ball worth 3000 Ksh.   Bag 2: two balls.  One ball is worth 500 Ksh The other ball is worth 5000 Ksh.   Which bag would you choose?"

	label               variable p_size_unit "Area unit for sampled field"
	
    label               define p_size_unit                          ///
                        1 "acres" 2 "hectares" 3 "meters²" 4 "paces"
	label               values p_size_unit p_size_unit

	label               variable p_sizea "Area of sampled field (acres)?"

	label               variable p_sizeh "Area of sampled field (hectares)?"

	label               variable p_sizem "Area of sampled field (m^2)?"

	label               variable p_sizep1 ///
                        "How many paces for the width of the sampled field?"
    label               variable p_sizep2 ///
                        "How many paces for the length of the sampled field?"

    label               variable p_size_acres "Area of sampled field in acres?"

	label               variable exp_5  ///
                        "Expectation: Worst possible maize yield, fertilizer"
	note                exp_5:  ///
    "Now please think of this maize field on which we took soil samples a few months ago.  Imagine all the reasons why you might have a very bad maize harvest -- the worst that you can imagine for the long rains. In this WORST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED NO FERTILIZER of any kind?"

	label               variable exp_6  ///
                        "Expectation: Best possible maize yield, fertilizer"
	note                exp_6: "Imagine all the reasons why you might have a very, very good maize harvest on this field -- the best that you can imagine for the long rains. In this BEST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED NO FERTILIZER of any kind?"

	label               variable exp_c1 ///
                        "Number of beans in first interval, no fertilizer"

	label               variable exp_c2 ///
                        "Number of beans in second interval, no fertilizer"

	label               variable exp_c3 ///
                        "Number of beans in third interval, no fertilizer"

	label               variable exp_c4 ///
                        "Number of beans in fourth interval, no fertilizer"

	label               variable exp_c5 ///
                        "Number of beans in fifth interval, no fertilizer"

	label               variable exp_7  ///
                        "Expectation: Worst possible maize yield, fertilizer+lime"

	label               variable exp_8  ///
                        "Expectation: Best possible maize yield, fertilizer+lime"
    
	label               variable exp_d1 ///
                        "Number of beans in first interval, no fertilizer"

	label               variable exp_d2 ///
                        "Number of beans in second interval, no fertilizer"

	label               variable exp_d3 ///
                        "Number of beans in third interval, no fertilizer"

	label               variable exp_d4 ///
                        "Number of beans in fourth interval, no fertilizer"

	label               variable exp_d5 ///
                        "Number of beans in fifth interval, no fertilizer"
                        
	label               variable aspirations1 "Accept reality of things > dream of better future"
	note                aspirations1: "It is better learn to accept the reality of things than to dream of a better future."
	label               define aspirations1 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations1 aspirations1

	label               variable aspirations2 "Have aspirations for family > accept each day as it comes"
	note                aspirations2: "It is better to have aspirations for your family than to accept each day as it comes."
	label               define aspirations2 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations2 aspirations2

	label               variable aspirations3 "Satisfied with current farm production?"
	note                aspirations3: "I am satisfied with the current levels of production from my farm."
	label               define aspirations3 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations3 aspirations3

	label               variable aspirations4 "It is best to establish clear production goals ahead of time"
	note                aspirations4: "It is wiser to establish clear production goals for my farm than to address situations as they arrive."
	label               define aspirations4 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations4 aspirations4

	label               variable aspirations5 "Existing goals & plans for increasing yields & profits"
	note                aspirations5: "I have specific goals and plans for increasing my yields and my farm profits in the future."
	label               define aspirations5 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations5 aspirations5

	label               variable aspirations6 "Future shaped by own actions > actions of others"
	note                aspirations6: "My future is shaped mainly by my own actions rather by than the actions of others."
	label               define aspirations6 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations6 aspirations6

	label               variable aspirations7 "Hard work matters less than luck in farming"
	note                aspirations7: "To really prosper, a farmer must be lucky because hard work doesn’t really matter."
	label               define aspirations7 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations7 aspirations7

	label               variable aspirations8 "I can find a way to solve most problems."
	note                aspirations8: "I can find a way to solve most problems."
	label               define aspirations8 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations8 aspirations8

	label               variable aspirations9 "I know what to do when rainfall will be low"
	note                aspirations9: "If I believe rainfall is going to be low during the growing season, I know how to modify my production practices to adapt."
	label               define aspirations9 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations9 aspirations9

	label               variable aspirations10 "I regularly check crops to maximize yields"
	note                aspirations10: "I regularly check my crops during the growing season so I know what I need to do to get the best yield possible."
	label               define aspirations10 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations10 aspirations10

	label               variable aspirations11 "Discouraged when maize < others in village"
	note                aspirations11: "I become discouraged easily when my maize is not growing as well as others in my village."
	label               define aspirations11 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations11 aspirations11

	label               variable aspirations12 "I could switch crops if maize prices fall"
	note                aspirations12: "If maize prices fall, I could easily learn how to grow other crops instead."
	label               define aspirations12 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations12 aspirations12

	label               variable aspirations13 "Fate (mine & family's) determined by powerful others"
	note                aspirations13: "What happens to me and my family depends on powerful people rather than ourselves."
	label               define aspirations13 0 "Completely disagree" 1 "Disagree strongly" 2 "Disagree somewhat strongly" 3 "Disagree somewhat" 4 "Disagree a little" 5 "Neither agree nor disagree" 6 "Agree a little" 7 "Agree somewhat" 8 "Agree somewhat strongly" 9 "Agree strongly" 10 "Completely agree"
	label               values aspirations13 aspirations13
    
	label               variable starttime "Start Time"
	label               variable endtime "End Time"
    label               variable comments "Comments"
    label               variable duration "Duration"

* **********************************************************************
* 3 - Add metadata and save
* **********************************************************************

* Save data set
    customsave,         idvar(key) filename(mm_gamePost)  ///
                        path($gamePost/dataSets/intermediate)       ///
                        dofile(mm_gamePost.do)                  ///
                        description("Post-game data, de-identified")  ///
                        user(Emilia Tjernström)

* Generate a .csv file as well
    export delimited    "$gamePost/dataSets/intermediate/mm_gamePost.csv", replace

log close

log using "$gamePost/documentation/mm_gamePostCodeBook", replace
                
* Compact codebook
    codebook, compact

* More details
    codebook,       mv

log close

