# MahindiMaster

## Index
- [Overview](#overview)
  - [Data cleaning](#data-cleaning)
  - [Data types](#data-types)
  - [Codebooks](#codebooks)
- [Acknowledgements](#acknowledgements)
- [Research team](#research-team)
- [Folder structure](#folder-structure)
- [Data cleaning details](#data-cleaning)
- [Analysis details](#analysis-steps)

## Overview

This README file explains the directory structure and data files for
"Bringing Farmville to the Tropics: App-based Simulations to Guide
Fertilizer Recommendations," funded by the Michigan State University
Global Center for Food Systems Innovations (GCFSI).

### Data cleaning

The data cleaning process is detailed in [`masterDoFile.do`](dataWork/masterDoFile.do),
and the scripts that it calls in order of running.

### Data types

This repo contains de-identified and labeled data in both
Stata and .csv format (since the raw data contains PID).
These log files contain the results from running the cleaning code:
* [`mm_distribution.log`](dataWork/distribution/code/logs/mm_distribution.log)
* [`mm_soilData.log`](dataWork/soil/code/logs/mm_soilData.log)
* [`mm_gamePree.log`](dataWork/preGame/code/logs/mm_gamePre.log)
* [`mm_gamePlay.log`](dataWork/gamePlay/code/logs/mm_gamePlay.log)
* [`mm_gamePost.log`](dataWork/gamePost/code/logs/mm_gamePost.log)

### Codebooks

The codebooks for each data set are located in DataSet/documentation.

## Acknowledgements
This work benefitted from the support and feedback of many.
We would be amiss if we did not recognize Matt Kimball and Tyler Lybbert
for their help animating and programming _MahindiMaster_.
David Cammarano and Christopher Kucharik at the University of
Wisconsin-Madison provided invaluable assistance with crop modeling choices.
We also wish to thank our Kenyan respondents and enumerators for their
enthusiasm, generosity and patience during the course of this research.

In addition to the funding from the Michigan State University Global Center
for Food Systems Innovations, we received support from the Daniel Louis and
Genevieve Rustvold Goldy Fellowship.

[Back to index](#index)

## Research team

The principal investigators on this project are
  - [Emilia Tjernström](https://emiliatjernstrom.com)
  - [Travis Lybbert](https://are.ucdavis.edu/people/faculty/travis-lybbert/)

[Back to index](#index)

## Folder structure

The general repo structure looks as follows:<br>

```stata
MahindiMaster
├────README.md
│    
├────dataWork
│    ├──masterDoFile.do
│    │
│    └──DataType`i'           /* one dir for each data type */
│       ├──dataSets
│       │  ├──raw
│       │  ├──intermediate    /* de-identified & labeled data */
│       │  └──analysis
│       ├──code
│       │  └──logs            /* logs from cleaning code */
│       ├──output
│       │  ├──tables
│       │  └──figures
│       ├──documentation      /* location of codebook for data set */
│       └──questionnaire      /* questionnaire in readable form */
│   
└──config
```

<details>
<summary>Full directory structure under fold</summary>

```stata
MahindiMaster
├────README.md
│    
├────dataWork
│    ├──masterDoFile.do
│    │
│    ├──soil
│    │  ├──dataSets
│    │  │  ├──raw
│    │  │  ├──intermediate
│    │  │  └──analysis
│    │  ├──code
│    │  │  └──logs
│    │  ├──output
│    │  │  ├──tables
│    │  │  └──figures
│    │  ├──documentation
│    │  └──questionnaire
│    │
│    │
│    ├──gamePre
│    │  ├──dataSets
│    │  │  ├──raw
│    │  │  ├──intermediate
│    │  │  └──analysis
│    │  ├──code
│    │  │  └──logs
│    │  ├──output
│    │  │  ├──tables
│    │  │  └──figures
│    │  ├──documentation
│    │  └──questionnaire
│    │
│    │
│    └──mahindiMaster
│    │  ├──dataSets
│    │  │  ├──raw
│    │  │  ├──intermediate
│    │  │  └──analysis
│    │  ├──code
│    │  │  └──logs
│    │  ├──output
│    │  │  ├──tables
│    │  │  └──figures
│    │  ├──documentation
│    │  └──questionnaire
│    │
│    │
│    └──gamePost
│    │  ├──dataSets
│    │  │  ├──raw
│    │  │  ├──intermediate
│    │  │  └──analysis
│    │  ├──code
│    │  │  └──logs
│    │  ├──output
│    │  │  ├──tables
│    │  │  └──figures
│    │  ├──documentation
│    │  └──questionnaire
│    │
│    │
│    └──distribution
│       ├──dataSets
│       │  ├──raw
│       │  ├──intermediate
│       │  └──analysis
│       ├──code
│       │  └──logs
│       ├──output
│       │  ├──tables
│       │  └──figures
│       ├──documentation
│       └──questionnaire
│
└──config
```

</details>

[Back to index](#index)

# Data
## Setup

The script `masterDoFile.do`
1. sets up global macros for all key filepaths
2. establishes the above directory structure in directory (set in Section 0)
  > set `$dirCreate = 0` if you do not want the folder structure to be created
3.  checks for required user-developed packages
  > if they are missing for current user, asks if they want to install <br>
  > also updates all ado files; set `$adoUpdate` to 0
  if you do not want to update
4. installs small package `customSave` (in Section 0 (c)), which
 adds meta data, notes, and labels to a data set for consistent
 documentation
5 runs all other scripts in order

[Back to index](#index)

## Soil data

* Can be merged on to the other data using the variable ``hhid``
* We collected soil samples from each farm household's largest maize field,
following protocols issued by ISO-certified soil laboratory CropNuts in Nairobi.
On each field, we took a minimum of five soil samples from the correct depth
and sent a mix of these five samples to the lab for testing.
* These data were inputs into the design and calibration of the app.
* The script [`mm_soilData.do`](dataWork/soil/code/mm_soilData.do) removes PID from the raw soil data, does basic processing, and merges on a household ID code.
  > Output from this data cleaning process as well as a codebook can be found in [`mm_soilData.log`](mm_soilData.log)

[Back to index](#index)

## Pre-survey

* This data set can be merged with the others using the variable ``hhid``
* This pre-app survey elicits farmer subjective expectations about yields
  under different inputs, aspirations, risk measures, and more.
* The script [`mm_gamePre.do`](dataWork/gamePre/code/mm_gamePre.do) removes PID from the pre-survey, does basic processing, and labels the data.
  > Output from this data cleaning process as well as a codebook can be found in [`mm_gamePre.log`](dataWork/gamePre/code/logs/mm_game.log)
  > * The codebook for this dataset is located in
    [`mm_gamePreCodeBook.log`](dataWork/gamePre/documentation/mm_gamereCodeBook.log)
[Back to index](#index)

## Game play

* This data set can be merged with the others using the variable ``hhid``
* The [_MahindiMaster_ Manual](dataWork/gamePlay/documentation/MM_Manual.pdf)
  describes how to use the _MahindiMaster_ app and the data that is stored by
  the app.
* The script
  [`mm_gamePlay.do`](dataWork/gamePlay/code/mm_gamePlay.do)
  does basic processing and labels variables.
  > * Output from the data cleaning process can be found in
  [`mm_gamePlay.log`](dataWork/gamePlay/code/logs/gamePlay.log)
  > * The codebook for this dataset is located in
    [`mm_gamePlayCodeBook.log`](dataWork/gamePlay/documentation/mm_gamePlayCodeBook.log)

[Back to index](#index)

## Post-survey

* This data set can be merged with the others using the variable ``hhid``
* After each farmer finished the structured play with the app,
  we conducted a post-survey, which included a re-administered
  subjective expectations module.
* The script
  [`mm_gamePost.do`](dataWork/gamePost/code/mm_gamePost.do)
  does basic processing and labels variables.
  > * Output from the data cleaning process can be found in
  [`mm_gamePost.log`](dataWork/gamePost/code/logs/mm_gamePost.log)
  > * The codebook for this dataset is located in
    [`mm_gamePostCodeBook.log`](dataWork/gamePost/documentation/mm_gamePostCodeBook.log)

[Back to index](#index)

## Distribution

* This data set can be merged with the others using the variable `hhid`
* Based on the final orders that farmers placed in the app,
  we distributed inputs to them accordingly. The delivered inputs
  were recorded using a SurveyCTO form.
* The script
  [`mm_distribution.do`](dataWork/distribution/documentation/mm_distribution.do)
  does basic processing and labels variables.
  > * Output from the data cleaning process can be found in
  [`mm_distribution.log`](dataWork/distribution/code/logs/mm_distribution.log)
  > * The codebook for this dataset is located in
    [`mm_distributionCodeBook.log`](dataWork/distribution/documentation/mm_distributionCodeBook.log)

[Back to index](#index)
