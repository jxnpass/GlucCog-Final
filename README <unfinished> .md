# Gluc-Cog Project Overview

## Introduction

The Department of Nutrition, Dietetics, and Food Science at Brigham Young University aimed to determine in this study the effects of the AS aspartame, the caloric sugar sucrose, and water on short-term cognitive performance. In addition, glucose samples were collected as both a process measure and to correlate changes in blood glucose with any changes in cognitive performance. They hypothesized that an 11% sucrose-sweetened beverage would improve cognitive performance after a fasted state (as glucose levels rise) compared to the 0.05% aspartame-sweetened beverage or water ~20, and ~60 minutes post-consumption. They also inferred the aspartame and water groups would perform similarly in cognitive tasks as well as in blood glucose response. 

I served as the main research assistant over statistical analysis, and my main role was to organize their laboratory data and test their hypotheses. Over the course of a year and a half, I have cleaned messy data, manipulated variables, performed and fitted varying models, and visualized the results. My progress was regularly checked by my statistics professor/advisor, and I regularly communicated work to those in the NDFS Department.

Over this period of time, our research team expanded their research hypotheses and questions. The statistical methods I used are aimed towards answering the following:
1. Is there an effect of drink content that has an effect on cognitive outcomes?
2. Do the drinks affect the cognitive domains differently, such as executive function, memory, attention, or processing speed?
3. How do drinks affect the blood glucose concentration (BGC) in participants after fasting for an extended period of time?
4. How is BGC related to cognitive scoring?
5. How are certain body characteristics related to BGC or cognitive scoring?

Our research paper highlighted and answered these questions. The R programming project goes through each of these questions and reveals the processes by which we came to each conclusion.

This folder contains the contents of the entire Gluc-Cog project. The project consists of four folders:
1. Raw Data
2. Scripts
3. Cleaned Data
4. Outputs

### Raw Data

Raw data was collected from the department-funded research team. Lab data was collected to gather subject lifestyle and body composition information. Cognitive data from participants were collected using the NIH Toolbox Cognitive Battery Tests. In summary, the data collected from the experiment was as follows:

1. Subject demographics, such as race, gender, age, and employment, marital, medical status.
2. Subject body characteristics, which includes measurements of weight, height, fat mass, body fat percentage, or visceral adipose tissue.
3. Visual Analog Scale, a subjective measure looking at treatments taste and appearance.
4. Blood glucose concentrations, measured four times per participant, evaluating measure of glucose circulating in the bloodstream.
5. Cognitive performance, measured three times, evaluating mental acuity in different cognitive domains (working memory, executive function, etc). Value of score and type of test were collected.

The raw data was collected over two spreadsheets, but the script 'DataPrep.R' combines these data sets and cleans incorrect observations. I manually added information for some subjects, such as whether a group was using faulty glucose strips, the condition was mislabeled, the time of testing was incorrectly recorded, and many other necessary edits. 'DataPrep.R' handled the majority of these necessary calculations. 

### Scripts

There are five scripts that perform differing needed processes. 

1) [DataPrep.R](Scripts/DataPrep.R)
    * Takes in the raw laboratory data (from Excel, two sheets), imports said data into R, and processes it for analysis
    * Formats observations -- race, sex, subject codes, test names, weight/height, etc.
    * Deletes rows without any substantive value (e.g. missing cognitive scores)
    * Writes out finished data to prepare for 'DataMath.R' as 'DataPrepOutput.csv'
  
2) DataMath.R
    * Creates additional variables based on information previously provided, such as BMI, Visceral Adipose Tissue Rank, Standardized (scaled) Score.
    * Exports data into two files, 'glucCog.csv' and 'glucOnly.csv.' Data was separated because our research questions required that we tested Condition (categorical) and BGC (numerical) against Cogntiive Scores separately. The BGC measurements were recorded using faulty instruments for ~50 subjects, forcing our sample size to change across research questions. 
  
3) tables.R
    * Takes in data from 'glucCog.csv' and 
4) figures.R
5) analysis.R



### Cleaned Data

### Outputs
