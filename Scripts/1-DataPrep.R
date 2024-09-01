library(readxl)
library(tidyverse)

lab.dat <- read_excel("GlucCog Final/Raw Data/Artificial_Lab_Data_Final 7_22_22.xlsx",
                      range = "A1:AP164", na = ".", sheet = "Sheet1")[-111,] 
          # duplicate subject code 110, removed bc no cog testing was done
cog.dat <- read_excel("GlucCog Final/Raw Data/Cognitive Outcomes Final 7_22_22.xlsx") %>% 
  drop_na(Subject_Code)


### Step 1 Subject Code Fixing (factorizing, fixing typos, etc) ------------

# Lab data
sub_order <- as.vector(lab.dat$Subject_Code)
lab.dat$Subject_Code <- factor(lab.dat$Subject_Code, levels = sub_order)

# Cog data (fixing typos)

cog.dat$Subject_Code <- gsub("-", "_", cog.dat$Subject_Code)
cog.dat$Subject_Code <- gsub("c", "C", cog.dat$Subject_Code)
cog.dat$Subject_Code <- gsub("s", "S", cog.dat$Subject_Code)
cog.dat$Subject_Code <- gsub("SC", "CS", cog.dat$Subject_Code)

# Also need to change certain subject codes as they are different between datasets
cog.dat$Subject_Code[461:484] <- "CS_22_2"
cog.dat$Subject_Code[1189:1212] <- "CS_55_1"
cog.dat$Subject_Code[1900:1923] <- "CS_87_1"

cog.dat$Subject_Code <- factor(cog.dat$Subject_Code, levels = sub_order)

### Step 2: Start with labeling on lab data (ABNML Data, Expired Strips, etc.) ----------

# Subjects with Expired Strips (highlighted orange and within those bounds)

exp.strips <- sub_order[52:101]

lab.dat <- lab.dat %>% 
  mutate(Exp_Strips = ifelse(Subject_Code %in% exp.strips ,T, F)) 

# Subjects with No Data (highlighted green)

lab.dat <- lab.dat %>% 
  mutate(No_Data = ifelse(Subject_Code %in% sub_order[c(12,15,34,37,57,60,76,98,102,115,122,125,123,127,133,143,150,156,158)],T,F))

# Subjects with wonky glucose measurements (highlighted blue in certain columns)

lab.dat <- lab.dat %>% 
  mutate(Non_Matching = ifelse(Subject_Code %in% sub_order[c(14,24,44,62,69,82,113,120,134,135)],T,F)) 

### Step 3: Rewrite condition, make it a factor (specified at bottom of sheet 1) --------

lab.dat <- lab.dat %>% 
  mutate(Condition = case_when(Condition == 1 ~ "Water",
                               Condition == 2 ~ "Artificial",
                               Condition == 3 ~ "Sugar")) %>% 
  mutate(Condition = factor(Condition, levels = c("Water","Artificial","Sugar")))

# Assign specific subjects to condition (asked for by dr. L)

lab.dat$Condition[c(3,14,44,69,120,134)] <- "Sugar"

### Step 4: Fixing typos on Sex, Race ----------

lab.dat$Sex <- gsub("male", "Male", lab.dat$Sex)
lab.dat$Sex <- gsub("feMale", "Female", lab.dat$Sex, ignore.case = T)

# White
lab.dat$Race <- gsub("caucasian", "White", lab.dat$Race, ignore.case = T)
lab.dat$Race <- gsub("caucasion", "White", lab.dat$Race, ignore.case = T)
lab.dat$Race <- gsub("white", "White", lab.dat$Race, ignore.case = T)
lab.dat$Race <- gsub("White ", "White", lab.dat$Race, ignore.case = T)
lab.dat$Race[lab.dat$Subject_Code == "CS_40_2"] <- "White"

# Mixed
lab.dat$Race <- gsub("white/latina", "Mixed", lab.dat$Race, ignore.case = T)
lab.dat$Race <- gsub("white/hispanic", "Mixed", lab.dat$Race, ignore.case = T)

# Latino
lab.dat$Race <- gsub("hispanic", "Hispanic", lab.dat$Race, ignore.case = T)
lab.dat$Race <- gsub("latino", "Hispanic", lab.dat$Race, ignore.case = T)

# Asian
lab.dat$Race <- gsub("asain", "Asian", lab.dat$Race, ignore.case = T)

# Other
lab.dat$Race <- gsub("other", "Other", lab.dat$Race, ignore.case = T)

## Step 5: Change Session Time and Test name on Cog data, Factorize Session and Test Type ---------
# matter of preference for me: 'Why waste time say lot word when few word do trick?'

cog.dat <- cog.dat %>% 
  rename(Test_Type = Inst, 
         Session_Time = `Assessment Name`) %>% 
  filter(Session_Time != "Assessment 4") # subject 62 did AVL test four times, don't know why 

for (i in 1:nrow(cog.dat)) {
  
  ## Test_Type (Test)
  if (!is.na(cog.dat$Test_Type[i])) {
    if (str_detect(cog.dat$Test_Type[i], pattern = "Auditory Verbal")) {
      cog.dat$Test_Type[i] <- "Auditory Verbal Learning Test"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "Picture Sequence Memory")) {
      cog.dat$Test_Type[i] <- "Picture Sequence Memory"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "Pattern Comparison")) {
      cog.dat$Test_Type[i] <- "Pattern Comparison Processing Speed"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "List Sorting")) {
      cog.dat$Test_Type[i] <- "List Sorting Working Memory"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "Flanker")) {
      cog.dat$Test_Type[i] <- "Flanker Inhibitory Control and Attention"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "Dimensional")) {
      cog.dat$Test_Type[i] <- "Dimensional Change Card Sort"
    }
    else if (str_detect(cog.dat$Test_Type[i], pattern = "Oral Symbol")) {
      cog.dat$Test_Type[i] <- "Oral Symbol Digit"
    }
  }
  
  ## ASSESSMENT NAME
  
  if (!is.na(cog.dat$Session_Time[i])) {
    if (str_detect(cog.dat$Session_Time[i], pattern = "Short") || str_detect(cog.dat$Session_Time[i], pattern = "First")) {
      cog.dat$Session_Time[i] <- "ShortVisit" 
    }
    else if (str_detect(cog.dat$Session_Time[i], pattern = "1") || str_detect(cog.dat$Session_Time[i], pattern = "one")) {
      cog.dat$Session_Time[i] <- "LongVisit20"
      }
    else if (str_detect(cog.dat$Session_Time[i], pattern = "2")) {
      cog.dat$Session_Time[i] <- "LongVisit60"
      }
  }
  
}


# Some need individual changes
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_55_1" & cog.dat$Session_Time == "Assessment 3" & !is.na(cog.dat$Subject_Code)] <- "ShortVisit"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_121_2" & cog.dat$Session_Time == "Assessment 3" & !is.na(cog.dat$Subject_Code)] <- "ShortVisit"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_1_1"][1:7] <- "LongVisit20"; cog.dat$Session_Time[cog.dat$Subject_Code == "CS_1_1"][8:14] <- "LongVisit60"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_1_1"][1:7] <- "LongVisit20"; cog.dat$Session_Time[cog.dat$Subject_Code == "CS_1_1"][8:14] <- "LongVisit60"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_2_1"][8:14] <- "LongVisit20"; cog.dat$Session_Time[cog.dat$Subject_Code == "CS_2_1"][15:21] <- "LongVisit60"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_3_1"][1:7] <- "LongVisit20"; cog.dat$Session_Time[cog.dat$Subject_Code == "CS_3_1"][8:14] <- "LongVisit60"
cog.dat$Session_Time[cog.dat$Subject_Code == "CS_4_1"][1:7] <- "LongVisit20"; cog.dat$Session_Time[cog.dat$Subject_Code == "CS_4_1"][8:14] <- "LongVisit60"

# #final check on session time
# cog.dat %>% 
#   group_by(Session_Time) %>% 
#   count()
# 
# #final check on test type (should be only seven unique tests)
# cog.dat %>% 
#   group_by(Test_Type) %>% 
#   count()

# Certain scores are also bad, I just deleted these:
cog.dat <- cog.dat[-c(2050, 2464),]

### Step 6: Select variables to include in joined dataset from cog.dat -------

cog.dat.final <- cog.dat %>% 
  select(Subject_Code, Session_Time, Test_Type, RawScore, Theta, SE,
         `Computed Score`, `Uncorrected Standard Score`, `Age-Corrected Standard Score`,
         `Fully-Corrected T-score`, `National Percentile (age adjusted)`, DateFinished) %>% 
  rename(Raw_Score = RawScore,
         Computed_Score = `Computed Score`,
         UnC_Std_Score = `Uncorrected Standard Score`,
         AgeC_Std_Score = `Age-Corrected Standard Score`,
         FullC_T_Score = `Fully-Corrected T-score`,
         National_Percentile = `National Percentile (age adjusted)`)

### Step 7: Fix lab data weight and height ------------

# convert in. to cm. 
lab.dat$Body_height_cm_short[97] <- lab.dat$Body_height_cm_short[97] * 2.54
lab.dat$Body_height_cm_short[101] <- lab.dat$Body_height_cm_long[101]

# convert lbs to kg
lab.dat$Body_weight_kg_short[c(6,97,111,112)] <- lab.dat$body_weight_kg_long[c(6,97,111,112)]

lab.dat <- lab.dat %>% 
  select(-body_weight_kg_long, -Body_height_cm_long) %>% 
  rename(Weight = Body_weight_kg_short, Height = Body_height_cm_short)

# fix weird lean mass value
lab.dat$Lean_Mass_g[97] <- lab.dat$Lean_Mass_g[97] * 1000

### Step 8: Reorganize data set to include BGC (blood glucose concentration) and Cog Series

lab.dat$Blood_glucose_Long_2[151] <- 88 # mis-input on spreadsheet, changed manually

lab.dat.BGC <- lab.dat %>% 
  gather(key = "Session_Time", value = "BGC", matches("Blood_glucose")) %>% 
  mutate(Session_Time = case_when(Session_Time == "Blood_glucose_short" ~ "ShortVisit",
                                  Session_Time == "Blood_glucose_Long_2" ~ "LongVisit0",
                                  Session_Time == "Blood_glucose_Long_3" ~ "LongVisit20",
                                  Session_Time == "Blood_glucose_Long_4" ~ "LongVisit60")) %>% 
  arrange(Subject_Code)

lab.dat.series <- lab.dat %>% 
  gather(key = "Session_Time", value = "Cog_Series", matches("Cognition")) %>% 
  mutate(Session_Time = case_when(Session_Time == "Cognition_Series_1" ~ "ShortVisit",
                                  Session_Time == "Cognition_series_Long_2" ~ "LongVisit20",
                                  Session_Time == "Cognition_series_Long_3" ~ "LongVisit60")) %>% 
  arrange(Subject_Code) %>% select(Subject_Code, Session_Time, Cog_Series)

lab.dat.final <- full_join(lab.dat.BGC, lab.dat.series, by = c("Subject_Code", "Session_Time")) %>% 
  select(-Cognition_Series_1, -Cognition_series_Long_2, -Cognition_series_Long_3)

### Step 9: Join data sets by subject ID ------------

full.dat <- full_join(x = lab.dat.final, y = cog.dat.final, by = c("Subject_Code", "Session_Time")) %>% 
  select(Subject_Code, Condition, Session_Time, contains('Score'), Theta, National_Percentile, BGC, Cog_Series, everything()) %>% 
  select(-If_withdrew_reason, -Day_of_cycle_short, -Day_of_cycle_long) # useless column(s)

### Step 10: Fix vars Married, Employed, etc. -----

full.dat <- full.dat %>% 
  mutate(Married = ifelse(Married %in% c(2,0),0,1)) %>% 
  mutate(Employed = ifelse(Employed %in% c(2,0),0,1)) %>% 
  mutate(Medications = ifelse(Medications %in% c(2,0),0,1)) 

full.dat <- full.dat %>% 
  mutate(If_employed_number_hours = ifelse(str_detect(If_employed_number_hours, "[na]"),0,If_employed_number_hours)) %>% 
  mutate(If_employed_number_hours = as.double(If_employed_number_hours)) %>% 
  mutate(If_employed_number_hours = ifelse(If_employed_number_hours == 0, NA, If_employed_number_hours)) 

full.dat <- full.dat %>% 
  mutate(Order = case_when(Order == 1 ~ "Short Visit First",
                           Order == 2 ~ "Treatment Visit First"))

### DONE !

write.csv(x = full.dat, file = "GlucCog Final/Cleaned Data/DataPrepOutput.csv")

# if using source...

glucCog <- full.dat


