# Gluc-Cog Project Overview

UNFINISHED AS OF 11.14.23 

This folder contains the contents of the entire Gluc-Cog project. The project consists of four folders:

1. [Raw Data](./Raw%20Data)
2. [Scripts](./Scripts)
3. [Cleaned Data](Cleaned%20Data)
4. [Outputs](./Outputs)

### [Raw Data](./Raw%20Data)

Raw data was collected from the department-funded research team. Lab data was collected to gather subject lifestyle and body composition information. Cognitive data from participants were collected using the NIH Toolbox Cognitive Battery Tests. In summary, the data collected from the experiment was as follows:

1. Subject demographics, such as race, gender, age, and employment, marital, medical status.
2. Subject body characteristics, which includes measurements of weight, height, fat mass, body fat percentage, or visceral adipose tissue.
3. Visual Analog Scale, a subjective measure looking at treatments taste and appearance.
4. Blood glucose concentrations, measured four times per participant, evaluating measure of glucose circulating in the bloodstream.
5. Cognitive performance, measured three times, evaluating mental acuity in different cognitive domains (working memory, executive function, etc). Value of score and type of test were collected.

The raw data was collected over two spreadsheets, but the script [DataPrep.R](Scripts/DataPrep.R) combines these data sets and cleans incorrect observations. I manually added information for some subjects that the professor and lab assistants specified to me, such as whether a group was using faulty glucose strips, the condition was mislabeled, the time of testing was incorrectly recorded, and many other necessary edits. [DataPrep.R](Scripts/DataPrep.R) handled the majority of these fixes.

### [Scripts](./Scripts)

There are five scripts that serve different functions. 

1) [DataPrep.R](Scripts/DataPrep.R)
    * Takes in the raw laboratory data (from Excel, two sheets), imports said data into R, and processes it for analysis
    * Formats observations -- race, sex, subject codes, test names, weight/height, etc.
    * Deletes rows without any substantive value (e.g. missing cognitive scores)
    * Writes out finished data to prepare for [DataMath.R](Scripts/DataMath.R) as [DataPrepOutput.csv](Cleaned%20Data/DataPrepOutput.csv)
  
2) [DataMath.R](Scripts/DataMath.R)
    * Creates additional variables based on information previously provided, such as BMI, Visceral Adipose Tissue Rank, Standardized (scaled) Score.
    * Exports data into two files, 'glucCog.csv' and 'glucOnly.csv.' Data was separated because our research questions required that we tested Condition (categorical) and BGC (numerical) against Cognitive Scores separately. The BGC measurements were recorded using faulty instruments for ~50 subjects, forcing our sample size to change across research questions. 
  
3) [tables.R](Scripts/tables.R)
    * Takes in data from 'glucCog.csv' and generates four tables for the research paper. 
    * First table describes demographic data describing age, gender, race, marriage, employment, and medication status, and BMI measurements. Known as **Table 2** in paper. 
    * Second table describes body compositions, such as fat, lean, bone mineral, and visceral adipose tissue measurements. We performed a one-way type 1 ANOVA to determine if these certain characteristics were failed to be distributed evenly across treatment groups (to avoid confounding). Known as **Tables 3A/3B** in paper.
    * Third table describes visual analog scale scoring, which evaluates how subjects perceived the differing conditions/drinks. One-way type 1 ANOVA was also utilized for determining treatment differences. Known as **Table 4**.
    * Fourth table represents the type 3 ANOVA results derived from fitting a linear mixed effects model (LME) with a 'sums' contrast on the categorical variables. The model fitted Condition, Session Time, Order, and all possible interaction combinations between them. These results determined our main conclusions. Known as **Table 5**.
    * All tables are saved manually in [tables.docx](Outputs/tables.docx). Manually copying tables preserved the format better than exporting it through R.
    
4) [figures.R](Scripts/figures.R)
    * Takes in data from 'glucCog.csv' and 'glucOnly.csv' and produces the seven visualizations and graphs. 
    * Fits the linear mixed effects models and tests it through ANOVA, outputting the assorted p-values. 
    * Utilizes ```theme_bw()``` (black-white) from ggplot as its main theme with customized texts and labels.
    * All seven visualizations and graphics are exported as PDF files and placed in [Outputs/figures](./Outputs/figures/).

5) [analysis.R](Scripts/analysis.R)
    * Calculated some of the more basic summary statistics, like sample size information, cognitive improvements over session times, test averages, and other informatinon discussed in paper's writing.
    * Run different ANOVA tests for the different mixed model scenarios, adjusting which variables are assumed as the fixed effects.
        * These fixed effects vary in combination between condition (drinks), session time, order (what order was treatment versus baseline day), and BGC. Special considerations were given for VAT rank, where we posed seperate questions about VAT's influence on cognitive perofrmance and resting glucose concentrations. 
    * Estimated coefficients for VAT Rank on composite cognition, PCPS (pattern comparison processing speed) cognition, and BGC
    * Extracted individual cognitive test p-values when fitted by the different mixed model combinations. 

### [Cleaned Data](./Cleaned%20Data)

As discussed previously in the [Raw Data](#raw-data) and [Scripts](#scripts) sections, the [DataPrep.R](Scripts/DataPrep.R) file takes in the two raw data files, cleans, and combines them into one comprehensive dataset. The wrangling that took place resulsted in [DataPrepOutput.csv](Cleaned%20Data/DataPrepOutput.csv) being written. However, this is not the final dataset.

[DataMath.R](Scripts/DataMath.R) took in [DataPrepOutput.csv](Cleaned%20Data/DataPrepOutput.csv) and resulted in writing both [glucCog.csv](Cleaned%20Data/glucCog.csv) and [glucOnly.csv](Cleaned%20Data/glucOnly.csv). This script was focused on taking a processed/cleaned data file and writing two new files required for the two sets of analysis. [glucOnly.csv](Cleaned%20Data/glucOnly.csv) is merely a subset of [glucCog.csv](Cleaned%20Data/glucCog.csv), where the sample size is restricted to those subjects with viable (non-expired) measurements in glucose. BMI was also calculated for each subject, which restricted the sample size to those with what was considered 'healthy' BMI values according to the NDFS department. This resulted in [glucOnly.csv](Cleaned%20Data/glucOnly.csv) with $N = 94$ subjects ($N = 84$ with cognitive measurements) and [glucCog.csv](Cleaned%20Data/glucCog.csv) with $N = 130$ subjects. 

The formats of the two datasets are the same, and summarized in the table as follows.

| Subject_Code      | Condition | Session_Time | Order | Test_Type | Std_Score | Raw_Score | BGC | Height | Weight | BMI | +31 columns | 
| :----------------: | :-------: | :----------: | :----: | :-------: | -----: | ------: | -------: | ------: | ------: | ------: | :-----: |
| CS_1_1     |  Sugar   | ShortVisit | ShortVisitFirst | AVL | .66 | 41 | 110 | 178.5 | 87.75 | 27.5 | $\cdots$ |
| CS_1_1     |  Sugar   | ShortVisit | ShortVisitFirst | LSWM | .66 | 23 | 110 | 178.5 | 87.75 | 27.5 | $\cdots$ |
| CS_1_1     |  Sugar   | ShortVisit | ShortVisitFirst | PCPS | -.02 | 61 | 110 | 178.5 | 87.75 | 27.5 | $\cdots$ |
| $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$ | $\ddots$ |
| CS_1_1     |  Sugar   | LongVisit20 | ShortVisitFirst | AVL | .37 | 39 | 144 | 178.5 | 87.75 | 27.5 | $\cdots$ |
| $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$ | $\ddots$ |
| CS_1_1     |  Sugar   | LongVisit60 | ShortVisitFirst | AVL | 1.25 | 45 | 119 | 178.5 | 87.75 | 27.5 | $\cdots$ |
| $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$ | $\ddots$ |
| CS_2_1     |  Water   | ShortVisit | TreatmentVisitFirst | AVL | -.52 | 33 | 90 | 163.5 | 57.90 | 21.6 | $\cdots$ |
| $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$   | $\vdots$ |   $\vdots$  | $\vdots$ | $\vdots$ | $\vdots$ | $\ddots$ |

I made a comprehensive [table](VAR_DESC.md) listing each variable name, type, and description, and levels. 

### [Outputs](./Outputs)

The two scripts [tables.R](Scripts/tables.R) and [figures.R](Scripts/figures.R) procure the two types of outputs: [tables.docx](Outputs/tables.docx) and the pdf files from the [figures folder](Outputs/figures). The [tables](Outputs/tables.docx) document consists of four tables describing subject characteristics, body characterisitcs, VAS scores (subjective rating of drink taste and color), and the ANOVA results from the mixed model evaluating cognitive score from condition and session times. 

#### Tables
1) Demographics: Provides a general summary of participant traits by condition/group. Aggregates statistics in sex, age, race, medications, married, employed, height (cm), weight (kg), and BMI. 
2) Body Characteristics: Provides a general summary of body compositions by condition/group. Aggregate statistics in lean mass (kg), fat mass (kg), bone mineral density (g/cm^3), bone mineral count (g), body fat percentage, and VAT (g and g/cm^3). One-way ANOVA tests calculated group differences and significances. 
3) Visual Analog Scale: General scoring of each condition's visual perception and taste. Subjects rated (1-10 scale) how much they liked the taste of the drink, liked the color, how sweet the drink tasted, and how sour the drink tasted. One-way ANOVA tests calculated drinks differences, finding significant results in taste and sweetness between groups. 
4) The ANOVA resulting from the fitted mixed model, analyzing cognitive score from condition, session times, and the interaction. The interaction term is arguably the most important, as we would suspect that the drink had the biggest influence on cognition at the time that the drink was consumed.

#### 