## Gluc-Cog Comprehensive Table 

| Variable Name | Type | Description | Levels | 
| :-----------: | :--: | :---------: | :----- |
| Subject_Code  | ```chr``` | ID of each participant | |
| Condition     | ```chr``` | Drink Type | Sugar, Artificial Sweetener, Water | 
| Session_Time  | ```chr``` | Testing Time | Short Visit, Long Visit 0-min PC (glucOnly.csv), Long Visit 20-min PC, Long Visit 60-min PC |
| Order         | ```chr``` | Order of Visits | Short Visit First, Treatment Visit First | 
| Test_Type     | ```chr``` | Type of Test Completed | 5 Tests: AVL, LSWM, OSD, PCPS, PSM |
| Std_Score     | ```chr``` | Standardized Test Score | |
| Raw_Score     | ```dbl``` | Raw Test Score | |
| BGC           | ```dbl``` | Blood Glucose Concentration | |
| Height        | ```dbl``` | Subject Height (cm) | |
| Weight        | ```dbl``` | Subject Weight (kg) | |
| BMI           | ```dbl``` | Subject Body Mass Index | |
| VAT_Rank      | ```dbl``` | The in-sample VAT value ranking | |
| Cog_Series    | ```int``` | Order that tests were completed | 1-10 |
| Sex           | ```chr``` | | Male, Female | 
| Age           | ```int``` | Age in years | |
| Years_of_Education | ```int``` | Education in years | |
| Race          | ```chr``` | | |
| Medications   |  ```lgl``` | Participant takes prescriptions | 1, 0 |
| Married       |  ```lgl``` | Participant is married | 1, 0 |
| Employed      |  ```lgl``` | Participant is employed | 1, 0 |
| If_employed_number_hours | ```int``` | Employment hours per week | |
| Date_visit_short | ```date``` | Date for baseline visit | |
| Lean_Mass_g   | ```dbl``` | Lean muscle mass (g) | |
| fat_mass_g    | ```dbl``` | Body fat mass (g) | |
| BMD_g_cm      | ```dbl``` | Bone mineral density (g/cm^3) | |
| BMC_g         | ```dbl``` | Bone mineral count (g) | |
| percent_fat   | ```dbl``` | Body fat percentage | |
| android_percent | ```dbl``` | Android fat percentage | |
| gynoid_percent | ```dbl``` | Gynoid fat percent | |
| VAT_g         | ```dbl``` | Visceral Adipose Tissue (g) | | 
| VAT_volume    | ```dbl``` | Visceral Adipose Tissue (g/cm^3) | | 
| Date_visit_Long | ```date``` | Date for treatment visit | |
| VAS_like      | ```dbl``` | Likeness score | |
| VAS_sweet     | ```dbl``` | Sweetness score | |
| VAS_sour      | ```dbl``` | Sourness score | |
| VAS_color     | ```dbl``` | Color score | |
| Percent_solution_consumed | ```dbl``` | Amount of solution consumed (usually 100%) | |
| Comments      | ```str``` | Additional comments about participant | |
| Exp_Strips    | ```lgl``` | Were participant BGC measurements recorded with expired glucose strips? | TRUE, FALSE |
| No_Data       | ```lgl``` | Was there missing data? | TRUE, FALSE |
| Non_Matching  | ```lgl``` | Was any body composition metrics not evaluated correctly? | TRUE, FALSE |
| DateFinished  | ```date``` | Date of last visit | |  