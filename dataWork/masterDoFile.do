* Project: 			MahindiMaster
* Created: 			2020/01/20 - ET
* Last modified: 	2020/05/25 - ET
* Stata 			v.16.1

* NOTE: Necessary steps for setup in Section 0

* This .do file runs cleaning .do files in the correct order

    /* This script also establishes an identical workspace between users
       by specifying settings, noting any required programs/user-written code,
       and setting global macros to help ensure consistency, accuracy
       and conciseness in the code.

       Further, this master .do file maps all files within the data folder
       and serves as the starting point to find any do-file, dataset or output.
    */

* dependencies
	* this local contains required packages
    local userpack customsave

* **********************************************************************
* 0 - General setup:
*       - users
*       - users' home directories
*       - create folder structures (can be switched off)
* **********************************************************************

* Set $dirCreate to 0 to skip directory creation
        global              dirCreate    1

* Set $adoUpdate to 0 to skip updating ado files
        global              adoUpdate     1

*   Users can add/change their initials and directories below
*   All subsequent files are referred to using dynamic, absolute filepaths

* User initials:
    * Emilia	            et

* Set this value to the user currently using this file
    global                  user "et"

* Specify Stata version in use
    global                  stataVersion 16.1    // set Stata version
    version                 $stataVersion
    set logtype             text

* **********************************************************************
* Define root folder globals
    if "$user" == "et" {
        global myDocs "C:/Users/`c(username)'/Desktop/git"
		if "`c(username)'"=="btje4229" {
			global dropbox ///
			"C:/Users/`c(username)'/Dropbox (Personal)"
		}
		else{
			global dropbox "C:/Users/Emilia/Dropbox"
		}
    }

* **********************************************************************
* Set sub-folder globals
    global projectFolder          "$myDocs/MahindiMaster"
    global dataWork               "$projectFolder/dataWork"
	global config                 "$dataWork/config"

* A dir for each data source or round
    global soil                   "$dataWork/soil"
    global gamePre                "$dataWork/gamePre"
    global gamePlay               "$dataWork/gamePlay"
    global gamePost               "$dataWork/gamePost"
    global distribution           "$dataWork/distribution"

* **********************************************************************
* Make a local macro containing all the sub-directory names
    * temporarily set delimiter to ; so can break the line
    #delimit ;
    local directories = "$soil $gamePre $gamePost
						  $gamePlay $distribution";
    #delimit cr

/* Within each data folder, standardize sub-folders
	dataSets
    	raw 	        // contains raw data, never to be altered
    	intermediate	// contains any intermediate data sets
		analysis	    // analysis-ready data sets
	code	     // scripts specific to folder data
                 // plus a folder-master .do file
        code/logs       // where log files live
	output
        tables
        figures
	documentation	    // documentation
	questionnaire	    // questionnaires */

* **********************************************************************
* 0 (a) - Create file structure
* **********************************************************************

if $dirCreate == 1 {
	foreach folder of local directories {
		* capture ignores the error code if directory exists
		qui: capture mkdir          "`folder'/"
		qui: capture mkdir          "`folder'/dataSets/"
		qui: capture mkdir          "`folder'/dataSets/raw/"
		qui: capture mkdir          "`folder'/dataSets/intermediate/"
		qui: capture mkdir          "`folder'/dataSets/analysis/"
		qui: capture mkdir          "`folder'/code/"
		qui: capture mkdir          "`folder'/code/logs"
		qui: capture mkdir          "`folder'/output/"
		qui: capture mkdir          "`folder'/output/tables/"
		qui: capture mkdir          "`folder'/output/figures/""
		qui: capture mkdir          "`folder'/documentation/"
		qui: capture mkdir          "`folder'/questionnaire/"
	}

    * Overall analysis
	qui: capture mkdir          "$dataWork/analysis"
	qui: capture mkdir          "$dataWork/analysis/code"
	qui: capture mkdir          "$dataWork/analysis/code/logs"
	qui: capture mkdir          "$dataWork/analysis/output"
	qui: capture mkdir          "$dataWork/analysis/output/tables"
	qui: capture mkdir          "$dataWork/analysis/output/figures"
	qui: capture mkdir          "$dataWork/analysis/output/tables/appendix"
	qui: capture mkdir          "$dataWork/analysis/output/figures/appendix"
}
* **********************************************************************
* 0 (b) - Check if any required packages are installed
* **********************************************************************

foreach package in `userpack' {
	capture : which `package', all
	if (_rc) {
        capture window stopbox rusure "You are missing some packages." "Do you want to install `package'?"
        if _rc == 0 {
            capture ssc install `package', replace
            if (_rc) {
                window stopbox rusure `"This package is not on SSC. Do you want to proceed without it?"'
            }
        }
        else {
            exit 199
        }
	}
}

* Update all ado files
    if $adoUpdate == 1 {
        ado update, update
    }

* **********************************************************************
* 0 (c) - Install metadata .do file
* **********************************************************************
    net         install StataConfig ///
                , from(https://raw.githubusercontent.com/etjernst/Materials/master/stata/) ///
                replace

* **********************************************************************
* 0 (d) Set graph and Stata preferences
* **********************************************************************
    set         scheme plotplain
    set         more off

* **********************************************************************
* 1 - Process raw data files
* **********************************************************************

* Import and de-identify soil data
	do         "$soil/code/mm_soilData.do"

* Import and de-identify pre-game survey
    do         "$gamePre/code/mm_gamePre.do"

* Import game data
    do         "$gamePlay/code/mm_gamePlay.do"

* Import post-game survey
    do         "$gamePost/code/mm_gamePost.do"

* Import distribution survey
    do         "$distribution/code/mm_distribution.do"
