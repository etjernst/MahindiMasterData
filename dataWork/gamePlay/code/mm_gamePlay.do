capture             log close
log                 using "$gamePlay/code/logs/mm_gamePlay", replace

* Project: 			MahindiMaster
* Created: 			2017/05/09 - RF
* Last modified: 	2020/05/07 - ET
* Stata 			v.16.1

* **********************************************************************
* 1 (a) - Import all data files (each player is a separate .csv file)
* **********************************************************************
	local 				i = 1

    * Get a list of all .csv files with game play data
	foreach 			dirname in files files2 files3 files4 {
		local 				csvlist: dir  ///
                            "$gamePlay/dataSets/raw/`dirname'" files "*.csv"
		foreach csvfile of local csvlist {
			* Import the files one by one
			import 		delimited ///
			"$gamePlay/dataSets/raw/`dirname'/`csvfile'", clear

			* Declare temporary file for each new data file
			tempfile 	csvfile

            * Save the first data file:
			if `i' == 1	{
				save 	"$gamePlay/dataSets/raw/gamePlay.dta", replace
			}
            * Save each data set as tempfile, open data set and append
			if `i' > 1 {
                save 		`csvfile'
				use         "$gamePlay/dataSets/raw/gamePlay.dta", clear
				append      using `csvfile'
				save 	"$gamePlay/dataSets/raw/gamePlay.dta", replace
			}
			local 		++i
		}
	}

* **********************************************************************
* 2 - Name variables
* **********************************************************************

	rename 				v1 name
	rename 				v2 villageid
	rename 				v3 hhid
	rename 				v4 level_game
	rename 				v5 starttime_game
	rename 				v6 finishtime_game
	rename 				v7 dap_game
	rename 				v8 can_game
	rename 				v9 lime_game
	rename 				v10 rain_game
	rename 				v11 yield_game
	rename 				v12 acreage_game
	rename 				v13 scaled_game
	rename 				v14 finallevel_game

* **********************************************************************
* 3 - Remove PID
* **********************************************************************
* Drop PID -- in this case, just the name which is the name of the hh head
    drop 				name

* **********************************************************************
* 4 - Add variable labels
* **********************************************************************

	label var 			dap_game "DAP (kg)"
	label var 			can_game "CAN (kg)"
	label var 			lime_game "Lime (kg)"
	label var 			yield_game "Yield (kg)"
	label var 			rain_game "Rainfall Scenario: 1=poor, 2=ok, 3=good"
	label var 			finallevel_game "Final Selection Round"

    label               variable hhid "Household ID"
    label               variable villageid "Village ID"
    label               variable level_game "Game round"
    label               variable hhid ""
    label               variable hhid "Household ID"


* **********************************************************************
* 5 - Add meta data and save
* **********************************************************************

* Save data set
    customsave,         idvar(hhid) filename(mm_gamePlay)  			///
                        path($gamePlay/dataSets/intermediate)       ///
                        dofile(mm_gamePlay.do)                  	///
                        description("Game play data, de-identified")  ///
                        user(Emilia Tjernström)

* Generate a .csv file as well
    export delimited    "$gamePlay/dataSets/intermediate/mm_gamePlay.csv" ///
						, replace

log close

log using "$gamePlay/documentation/mm_gamePlayCodeBook", replace

* Compact codebook
    codebook, compact

* More details
    codebook,       mv

log close
