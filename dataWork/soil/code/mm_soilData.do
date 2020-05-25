capture             log close
log                 using "$soil/code/logs/mm_soilData", replace

* Project: 			MahindiMaster
* Created: 			2020/05/01 - ET
* Last modified: 	2020/05/25 - ET
* Stata 			v.16.1


* **********************************************************************
* 1 (a) - Open raw soil data, remove PID
* **********************************************************************
* Open soil data
    import excel        "$soil/dataSets/raw/pid/soil_Oct2016.xls"       ///
                        , sheet("University of California") firstrow    ///
                        cellrange(F1:X201) case(lower) clear

* Create numeric ID variable
    encode              fieldname, gen(idmerge)

* Remove value labels (since they are names)
    label drop          idmerge

* Drop some irrelevant variables (either repeated info or missing)
    list                crop depth condition in 1/10
    count               if !mi(condition)
    drop                crop depth condition

* Drop village identifier (comments) and fieldname (farmername)
    drop                comments fieldname
    lab var             idmerge "ID variable for merging soil tests"

* **********************************************************************
* 1 (b) - Basic formatting
* **********************************************************************
* Phosphorus & suplhur have non-numeric variables
    replace             phosphorus = "0.20" if phosphorus == "< 0.20"
    replace             sulphur = "0.50" if sulphur == "< 0.50"

* Destring since should be numeric
    destring            phosphorus, gen(p)
    label               variable          p "Phosphorous, numeric"
    order               p, after(phosphorus)

    destring            sulphur, gen(s)
    label               variable      s "Sulphur, numeric"
    order               s, after(sulphur)

* Save data set
    customsave,         idvar(idmerge) filename(mm_soilData)  ///
                        path($soil/dataSets/intermediate)       ///
                        dofile(mm_soilData.do)                  ///
                        description("Soil data with basic formatting")  ///
                        user(Emilia Tjernström)


* **********************************************************************
* 2 (a) - Open spreadsheet that tracked HHID merges, remove PID
* **********************************************************************

* Import spreadsheet that links soil data to household ID
	import excel 	    name = B hhid = D       ///
                        using "$soil/dataSets/raw/pid/HHIDmatching.xlsx"  ///
                        , sheet("Sheet1") clear cellrange(B2:D201)

* Create numeric ID variable
    encode              name, gen(idmerge)

* Remove value labels (since they are names)
    label drop          idmerge

* Keep only the id variable and the household ID to match
    keep                hhid idmerge
    lab var             hhid "Household ID"
    lab var             idmerge "ID variable for merging soil tests"

* **********************************************************************
* 2 (b) - Add HHID to soil data
* **********************************************************************

* Merge 1:1 with the soil data
    merge 1:1 idmerge using "$soil/dataSets/intermediate/mm_soildata"
    * All merge fine

    drop _merge idmerge

* Save data set
    customsave,         idvar(hhid) filename(mm_soilData)               ///
                        path($soil/dataSets/intermediate)               ///
                        dofile(mm_soilData.do)                          ///
                        description("Soil data with HHID for merging")  ///
                        user(Emilia Tjernström)

* Generate a .csv file as well
    export delimited    "$soil/dataSets/intermediate/mm_soilData.csv", replace

log close

log using "$soil/documentation/mm_soilCodeBook", replace
                
* Compact codebook
    codebook, compact

* More details
    codebook,       mv

log close
