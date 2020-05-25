capture             log close
log                 using "$distribution/code/logs/mm_distribution", replace

* Project: 			MahindiMaster
* Created: 			2020/05/01 - ET
* Last modified: 	2020/05/25 - ET
* Stata 			v.16.1

* **********************************************************************
* 1 (a) - Initialize form-specific parameters
* **********************************************************************

	local 			csvfile ///
			"$distribution/dataSets/raw/MahindiMaster Distribution.csv"
	local 			dtafile ///
			"$distribution/dataSets/intermediate/MahindiMaster Distribution.dta"

	local 			repeat_groups_csv1 ""
	local 			repeat_groups_stata1 ""
	local 			repeat_groups_short_stata1 ""

	local 			note_fields1 "scaled dap_scale can_scale lime_scale formdef"
	local 			note_fields2 "village_name"
	local 			text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid comments village hhid"
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
    drop    deviceid subscriberid simid devicephonenum username caseid

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
* 2 - Label & sort variables
* **********************************************************************
	label           variable consent "Consent"

	label           variable key "Unique submission ID"
	cap label       variable submissiondate "Date/time submitted"

	label           variable enum "Enumerator"

	label           variable county "County"
	
    label           define county 3 "Homabay" 9 "Migori"
	label           values county county

	label           variable village "Village"

	label           variable hhid "Household ID"
    destring        hhid, replace

    label           variable dap "How much DAP did the participant order?"

	label           variable can "How much CAN did the participant order?"

	label           variable lime "How much lime did the participant order?"

	label           variable duration "Duration"

	cap label       variable comments "Comments"
    
	label           variable starttime "Start Time"
	
    label           variable endtime "End Time"
    
    order           key hhid village county consent enum, first

* **********************************************************************
* 3 - Add metadata and save
* **********************************************************************

* Save data set
    customsave,         idvar(key) filename(mm_distribution)            ///
                        path($distribution/dataSets/intermediate)       ///
                        dofile(mm_distribution.do)                      ///
                        description("Distribution data, de-identified") ///
                        user(Emilia Tjernström)

* Generate a .csv file as well
    export      delimited                                                   ///
                "$distribution/dataSets/intermediate/mm_distribution.csv"   ///
                , replace

log close

log using "$distribution/documentation/mm_distributionCodeBook", replace
                
* Compact codebook
    codebook, compact

* More details
    codebook,       mv

log close
