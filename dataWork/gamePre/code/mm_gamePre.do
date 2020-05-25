capture             log close
log                 using "$gamePre/code/logs/mm_gamePre", replace

* Project: 			MahindiMaster
* Created: 			2020/05/01 - ET
* Last modified: 	2020/05/01 - ET
* Stata 			v.16.1


* **********************************************************************
* 1 (a) - Initialize form-specific parameters
* **********************************************************************

	local 			csvfile "$gamePre/dataSets/raw/MahindiMaster.csv"
	local 			dtafile "$gamePre/dataSets/intermediate/MahindiMaster.dta"

	local 			repeat_groups_csv1 ""
	local 			repeat_groups_stata1 ""
	local 			repeat_groups_short_stata1 ""

	local 			note_fields1 "exp_1 exp_2 p_size_acrest exp_explain exp_explain2 exp_graph exp_explain4 exp_explain5 exp_explain6 exp_graph2 exp_explain7 exp_explain8 exp_graph3 confidence purchase aspirations ordernote"
	local 			note_fields2 "order_exceed order_exceed2 order_total endnote formdef village_name deviceid subscriberid simid devicephonenum username caseid "

	local 			calcfields "exp_b b1 b2 b3 b4 fertypel1lab fertypel2lab fertypel3lab exp_c c1 c2 c3 c4 lime exp_d d1 d2 d3 d4 order_max order1_convert order2_convert order3_convert p_sizeha p_sizema p_sizepa"
    
	local	 		text_fields1 "duration comments village hhid hhid_verif hhid_div hhid_odd p_sizeha p_sizema p_sizepa p_size_acres exp_b b1 b2 b3 b4 fertypeol1"
	local 			text_fields2 "fertypel1lab fertypeol2 fertypel2lab fertypeol3 fertypel3lab exp_c c1 c2 c3 c4 lime exp_d d1 d2 d3 d4 conf10 conf11 purchase1_name purchase1_location purchase1_landmark purchase1_distance"
	local 			text_fields3 "purchase1_other purchase2_name purchase2_location purchase2_landmark purchase2_distance purchase2_other purchase3_name purchase3_location purchase3_landmark purchase3_distance purchase3_other"
	local 			text_fields4 "purchase4_name purchase4_location purchase4_landmark purchase4_distance purchase4_other purchase5_name purchase5_location purchase5_landmark purchase5_distance purchase5_other purchase6_name"
	local 			text_fields5 "purchase6_location purchase6_landmark purchase6_distance purchase6_other order_max order1_convert order2_convert order3_convert"

	local 			date_fields1 ""
	local 			datetime_fields1 "submissiondate starttime endtime"

* **********************************************************************
* 1 (b) - Import data from primary .csv file
* **********************************************************************
	insheet using "`csvfile'", names clear

* Drop extra table-list columns
		cap drop reserved_name_for_field_*
		cap drop generated_table_list_lab*

* Drop note & calculate fields (since they don't contain any real data)
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
	replace             key = instanceid if key==""
	drop                instanceid

* **********************************************************************
* 1 (d) - Import data from primary .csv file
* **********************************************************************    

* Remove PID
    local               pid enum county
    
* The purchase location descriptions are borderline, but removing to be sure
    local               pid = "`pid' purchase?_landmark purchase?_other"
    local               pid = "`pid' purchase?_location purchase?_name"
    
* Encode all the PID
    foreach             pidvar of varlist `pid' {
    	di              `pidvar'
        egen            `pidvar'_code = group(`pidvar')
    }

* Drop PID
    drop                `pid' 
    
	* label variables
	label               variable key "Unique submission ID"
	cap label           variable submissiondate "Date/time submitted"

	label               variable consent "Consent?"
	note                consent: "Do you give your consent to participate?"
	
    cap label           define consent 1 "Yes" 0 "No"
	label               values consent consent

	label               variable enum "Enumerator"

	label               variable county ///
                        "County"
	cap label           define county 3 "Homabay" 9 "Migori"
	label               values county county

	label               variable village "Village"

	label               variable hhid "Household ID"
    destring            hhid, replace
    
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

	label               variable exp_3  ///
                        "Expectation: Worst possible maize yield, no fertilizer"
	note                exp_3:  ///
    "Now please think of this maize field on which we took soil samples a few months ago.  Imagine all the reasons why you might have a very bad maize harvest -- the worst that you can imagine for the long rains. In this WORST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED NO FERTILIZER of any kind?"

	label               variable exp_4  ///
                        "Expectation: Best possible maize yield, no fertilizer"
	note                exp_4: "Imagine all the reasons why you might have a very, very good maize harvest on this field -- the best that you can imagine for the long rains. In this BEST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED NO FERTILIZER of any kind?"

	label               variable exp_b1 ///
                        "Number of beans in first interval, no fertilizer"

	label               variable exp_b2 ///
                        "Number of beans in second interval, no fertilizer"

	label               variable exp_b3 ///
                        "Number of beans in third interval, no fertilizer"

	label               variable exp_b4 ///
                        "Number of beans in fourth interval, no fertilizer"

	label               variable exp_b5 ///
                        "Number of beans in fifth interval, no fertilizer"

	label               variable ffertl ///
                        "Have you applied fertilizer on this field since 2013?"
	
    label               define ffertl 1 "Yes" 0 "No"
	label               values ffertl ffertl

	label               variable fertypel1  ///
                        "First type of fertilizer applied to this field?"

	label               variable fertypeol1 "Other, specify"

	label               variable fertypel2   ///
                        "Second type of fertilizer applied to this field?"
                        
	label               variable fertypeol2 "Other, specify"

	label               variable fertypel3   ///
                        "Third type of fertilizer applied to this field?"
                        
	label               variable fertypeol3 "Other, specify"

    label               define fertype 0 "None" 1 "ASN (26:0:0)" 2 "CAN (26:0:0)" 3 "compost" 4 "DAP" 5 "DAP + CAN" 6 "DSP" 7 "foliar feeds" 8 "kero green" 9 "magmax lime" 10 "manure" 11 "MAP" 12 "mavuno-basal" 13 "Mavuno-top dress." 14 "mijingu 1100" 15 "NPK (17:17:0)" 16 "NPK (20:10:10)" 17 "NPK (20:20:0)" 18 "NPK (23:23:23)" 19 "NPK (25:5:+5S)" 20 "NPK 14:14:20" 21 "NPK(15:15:15)" 22 "NPK(17:17:17)" 23 "NPK(18:14:12)" 24 "NPK(23:23:0)" 25 "rock-phosphate" 26 "SA (21:0:0)" 27 "SSP" 28 "TSP" 29 "UREA (46:0:0)" 30 "UREA+CAN" 31 "Other, specify"
	
    label               values fertypel1 fertype
	label               values fertypel2 fertype
	label               values fertypel3 fertype

	label               variable fertamtl1 "Amount of 1st type of fertilizer?"
	label               variable fertunitl1b "Unit of measurement (1st fert)"

	label               variable fertamtl2  "Amount of 2nd type of fertilizer?"
	label               variable fertunitl2b "Unit of measurement (2nd fert)"

	label               variable fertamtl3  "Amount of 3nd type of fertilizer?"
	label               variable fertunitl3 "Unit of measurement (3nd fert)"

	label               define fertunit 1 "kg" 2 "litre" 3 "tonnes" 4 "1 kg bags" 5 "2 kg bags" 6 "5 kg bags" 7 "10 kg bags" 8 "25 kg bags" 9 "50 kg bags" 10 "90 kg bags" 11 "canter" 12 "cart (hand/donkey)" 13 "debe" 14 "pickup" 15 "wheelbarrow" 16 "gorogoro"
	
    label               values fertunitl1b fertunit
	label               values fertunitl2b fertunit
	label               values fertunitl3 fertunit

	label variable fertunitl3 "Unit of measurement (3rd fert)"

    
	label               variable exp_5  ///
                        "Expectation: Worst possible maize yield, with fertilizer"
    note exp_5: "Now please think of this maize field on which we took soil samples a few months ago.  Imagine all the reasons why you might have a very bad maize harvest -- the worst that you can imagine for the long rains. In this WORST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED THE FERTILIZER amounts you just told us about?"

	label               variable exp_6  ///
                        "Expectation: Best possible maize yield, with fertilizer"	
    note exp_6: "Imagine all the reasons why you might have a very, very good maize harvest on this field -- the best that you can imagine for the long rains. In this BEST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED THE FERTILIZER amounts you just told us about?"

	label               variable exp_c1 ///
                        "Number of beans in first interval, with fertilizer"

	label               variable exp_c2 ///
                        "Number of beans in second interval, with fertilizer"

	label               variable exp_c3 ///
                        "Number of beans in third interval, with fertilizer"

	label               variable exp_c4 ///
                        "Number of beans in fourth interval, with fertilizer"

	label               variable exp_c5 ///
                        "Number of beans in fifth interval, with fertilizer"

	label               variable exp_probe ///
                        "Is fertilizer expectations posing a challenge?"
	note                exp_probe: ///
                        "Enumerator: please probe as much as you can, but if the farmer insists they have NO IDEA, you can select 'no idea'"
	label               define exp_probe 0 "Farmer has no idea" 1 "Proceed"
	label               values exp_probe exp_probe

	label               variable exp_7  ///
                        "Expectation: Worst possible maize yield, fertilizer+lime"                        
    note exp_7: "Now please think of this maize field on which we took soil samples a few months ago.  Imagine all the reasons why you might have a very bad maize harvest -- the worst that you can imagine for the long rains. In this WORST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED THE FERTILIZER amounts you just told us about and ALSO APPLY \${lime} kg of LIME to this field?"

    label               variable exp_8  ///
                        "Expectation: Best possible maize yield, fertilizer+lime"
	note                exp_8: "Imagine all the reasons why you might have a very, very good maize harvest on this field -- the best that you can imagine for the long rains. In this BEST YEAR that you can imagine, how many bags do you think that you would harvest IF YOU APPLIED THE FERTILIZER amounts you just told us about and ALSO APPLY \${lime} kg of LIME to this field?"

	label               variable exp_d1 ///
                        "Number of beans in first interval, fertilizer+lime"

	label               variable exp_d2 ///
                        "Number of beans in second interval, fertilizer+lime"

	label               variable exp_d3 ///
                        "Number of beans in third interval, fertilizer+lime"

	label               variable exp_d4 ///
                        "Number of beans in fourth interval, fertilizer+lime"

	label               variable exp_d5 ///
                        "Number of beans in fifth interval, fertilizer+lime"

	label               variable conf1 ///
                        "Answer more questions than other village farmers?"
	note                conf1: "Do you think you will answer more questions correctly than other farmers in your village?"
	
    label               define conf1 ///
    1 "A lot more than others" 2 "A little more than others"    ///
    3 "The same as others" 4 "A little less than others"        ///
    5 "A lot less than others"
	label               values conf1 conf1

	label               variable conf2  ///
                        "Hybrid success depends on the environment or place"
	note                conf2: "Most hybrid seeds work better in some environments or places than in others."
	label               define conf2 0 "False" 1 "True" 31 "Don't know"
	label               values conf2 conf2

	label               variable conf3 ///
                        "How do yields of recycled hybrids compare to purchased hybrids?"
	note                conf3: "Do recycled hybrid seeds have lower / the same / higher yields than purchased hybrid seeds?"
	label               define conf3 0 "Lower" 1 "The same" 2 "Higher"
	label               values conf3 conf3

	label               variable conf4 ///
                        "Maize grows best in what kind of soil?"
	note                conf4: "Maize grows best in (extremely acidic, slightly acidic, not acidic) soil."
	label               define conf4 1 "Extremely acidic" 2 "Somewhat acidic" 3 "Not-acidic" 31 "Don't know"
	label               values conf4 conf4

	label               variable conf5 ///
                        "How much DAP does gvt recomment for 1 acre maize plot?"
	note                conf5: "How many kg of DAP does the Kenyan government recommend using on 1 acre maize plot?"

	label               variable conf6 ///
                        "How much CAN does gvt recomment for 1 acre maize plot?"
	note                conf6: "How many kg of CAN does the Kenyan government recommend using on 1 acre maize plot?"

	label               variable conf7 ///
                        "When should CAN be applied on maize as top dressing?"
	note                conf7: "Assuming only one fertilizer application, when should CAN be applied on maize as top dressing?"
	label               define conf7 1 "1-2 months before planting" 2 "At planting" 3 "At emergence" 4 "When plant is knee high" 5 "When plant is shoulder high" 31 "Don't know"
	label               values conf7 conf7

	label               variable conf8 ///
                         "When should lime be applied to your maize field?"
	note                conf8: "When should lime be applied to your maize field?"
	label               define conf8 1 "1-2 months before planting" 2 "At planting" 3 "At emergence" 4 "When plant is knee high" 5 "When plant is shoulder high" 31 "Don't know"
	label               values conf8 conf8

	label               variable conf9 "What benefit does lime provide?"
	note                conf9: "What benefit does lime provide?"
	label               define conf9 1 "Changes the soil texture" 2 "Makes soil drain better" 3 "Reduces acidity of soil" 4 "Kills pests" 31 "Don't know"
	label               values conf9 conf9

	label               variable conf10 ///
                         "What can be done to control Striga weed?"
	note                conf10: "What can be done to control Striga weed?"

	label               variable conf11 ///
                         "What are the symptoms of Maize Lethal Necrosis?"
	note                conf11: "What are the symptoms of Maize Lethal Necrosis?"

	label               variable placement1  ///
                        "How many questions do you think you got right?"
	note                placement1: "Now that you know the questions, how many questions do you believe that you answered correctly?"

	label               variable placement2  ///
                        "How many correct answers would average farmer in village get?"
	note                placement2: "How many questions do you think that the average farmer in this village would answer correctly?"

	label               variable placement3  ///
                        "Maize yields since 2013 compared to others in village"
	note                placement3: "Since 2013, compared to other farmers in the village, were your maize yields..."
	label               define placement3 1 "Much higher than others" 2 "A little higher than others" 3 "About same as others" 4 "A little less than others" 5 "A lot less than others"
	label               values placement3 placement3

	label               variable placement4  ///
                        "Frequency of doubts about farming decisions?"
	note                placement4: "How often do you have doubts about the farming decisions that you make?"
	label               define placement4 1 "Almost all the time" 2 "Very often" 3 "Sometimes" 4 "Rarely" 5 "Never"
	label               values placement4 placement4

	label               variable placement5  ///
                        "Doubts about farming decisions, compared to others?"
	note                placement5: "Compared to others, how often do you have doubts about the farming decisions that you make?"
	label               define placement5 1 "A lot more than others" 2 "A little more than others" 3 "The same as others" 4 "A little less than others" 5 "A lot less than others"
	label               values placement5 placement5

	label               variable purchase_nr   ///
                        "Hybrid purchases from how many stores?"
	label               variable purchase_nr2   ///
                        "Fertilizer purchases from how many stores?"  
    forval i = 1/3 {
        label               variable purchase`i'_name "Name of  AgroVet # (`i')"
        label               variable purchase`i'_location "Location of AgroVet # (`i')"
        label               variable purchase`i'_landmark "Landmarks near AgroVet # (`i')"
        label               variable purchase`i'_distance "Distance to AgroVet # (`i')"
        label               variable purchase`i'_other "Other direction to AgroVet # (`i')"
        
        local j = `i'+3
        label               variable purchase`j'_name "Name of  AgroVet # (`j')"
        label               variable purchase`j'_location "Location of AgroVet # (`j')"
        label               variable purchase`j'_landmark "Landmarks near AgroVet # (`j')"
        label               variable purchase`j'_distance "Distance to AgroVet # (`j')"
        label               variable purchase`j'_other "Other direction to AgroVet # (`j')"        
        
    }

    label               variable trust1 "Has AgroVet #1 sold you poor quality hybrids?"
    note                trust1: "For this seller, have you ever purchased hybrids from this seller that were of poor quality?  * seeds were not viable / did not germinate?"
    label               define trust1 1 "Yes" 0 "No"
    label               values trust1 trust1    
	label               variable trust2 "Overall, do you trust hybrid quality from Agrovet #1?"
	note                trust2: "Overall, how much do you trust the quality of the hybrids you can purchase from this seller?"
	label               define trust2 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust2 trust2

    label               variable trust3 "Has AgroVet #3 sold you poor quality hybrids?"
	note                trust3: "For this seller, have you ever purchased hybrids from this seller that were of poor quality?  * seeds were not viable / did not germinate?"
	label               define trust3 1 "Yes" 0 "No"
	label               values trust3 trust3
	label               variable trust4 "Overall, do you trust hybrid quality from Agrovet #2?"
	note                trust4: "Overall, how much do you trust the quality of the hybrids you can purchase from this seller?"
	label               define trust4 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust4 trust4

    label               variable trust5 "Has AgroVet #3 sold you poor quality hybrids?"
	note                trust3: "For this seller, have you ever purchased hybrids from this seller that were of poor quality?  * seeds were not viable / did not germinate?"
	label               define trust5 1 "Yes" 0 "No"
	label               values trust5 trust5
	label               variable trust6 "Overall, do you trust hybrid quality from Agrovet #3?"
	note                trust4: "Overall, how much do you trust the quality of the hybrids you can purchase from this seller?"
	label               define trust6 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust6 trust6

    label               variable trust7 "Has AgroVet #4 sold you poor quality fertilizer?"
	note                trust7: "For this seller, have you ever purchased fertilizer from this seller that was of poor quality?  * low-quality, for example"
    label               define trust7 1 "Yes" 0 "No"
    label               values trust7 trust7    
	label               variable trust8 "Overall, do you trust hybrid quality from Agrovet #4?"
	note                trust8: "Overall, how much do you trust the quality of the fertilizer you can purchase from this seller?"
	label               define trust8 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust8 trust8

    label               variable trust9 "Has AgroVet #5 sold you poor quality fertilizer?"
	note                trust9: "For this seller, have you ever purchased fertilizer from this seller that was of poor quality?  * low-quality, for example"
    label               define trust9 1 "Yes" 0 "No"
    label               values trust9 trust9    
	label               variable trust10 "Overall, do you trust hybrid quality from Agrovet #5?"
	note                trust10: "Overall, how much do you trust the quality of the fertilizer you can purchase from this seller?"
	label               define trust10 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust10 trust10
    
    label               variable trust11 "Has AgroVet #6 sold you poor quality fertilizer?"
	note                trust11: "For this seller, have you ever purchased fertilizer from this seller that was of poor quality?  * low-quality, for example"
    label               define trust11 1 "Yes" 0 "No"
    label               values trust11 trust11    
	label               variable trust12 "Overall, do you trust hybrid quality from Agrovet #6?"
	note                trust12: "Overall, how much do you trust the quality of the fertilizer you can purchase from this seller?"
	label               define trust12 1 "Completely trust their product" 2 "Trust the product a lot" 3 "Trust somewhat" 4 "Have some doubts about product" 5 "Do not trust product at all"
	label               values trust12 trust12
 

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

	label               variable dap_price "Current price, DAP (kg)"
	note                dap_price: "Enumerator: what is the cost/kg of DAP"

	label               variable can_price "Current price, CAN (kg)"
	note                can_price: "Enumerator: what is the cost/kg of CAN"

	label               variable lime_price "Current price, lime (kg)"
	note                lime_price: "Enumerator: what is the cost/kg of lime"

	label               variable order1 "DAP allocation"
	note                order1: "How much of your 5000 Ksh would allocate to DAP?"

	label               variable order2 "CAN allocation"
	note                order2: "How much of your 5000 Ksh would allocate to CAN?"

	label               variable order3 "Lime allocation"
	note                order3: "How much of your 5000 Ksh would allocate to Lime?"

    label               variable duration "Interview duration"          

    label               variable comments "Comments"          

    order               key hhid village county consent enum, first

    
* Save data set
    customsave,         idvar(key) filename(mm_gamePre)  ///
                        path($gamePre/dataSets/intermediate)       ///
                        dofile(mm_gamePre.do)                  ///
                        description("Pre-game data, de-identified")  ///
                        user(Emilia Tjernström)

* Generate a .csv file as well
    export delimited    "$gamePre/dataSets/intermediate/mm_gamePre.csv", replace

log close

log using "$gamePre/documentation/mm_gamePreCodeBook", replace
                
* Compact codebook
    codebook, compact

* More details
    codebook,       mv

log close


	


