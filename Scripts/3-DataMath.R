# source("~/GlucoseCognition_Project/GlucCog Final/Scripts/DataPrep.R")

library(tidyverse)

glucCog  <- read_csv("GlucCog Final/Cleaned Data/DataPrepOutput.csv")[,-1]
sub_order <- as.vector(glucCog$Subject_Code %>% unique())
glucCog$Subject_Code <- factor(glucCog$Subject_Code, levels = sub_order)

### Step 1: Calculate BMI --------

glucCog <- glucCog %>% 
  mutate(BMI = Weight / ((Height/100)^2) )

### Step 2: clean data (remove bad rows/missing data/low to high BMI) ---------

glucCog <- glucCog %>% filter(!No_Data) # N = 162 -> 143

glucCog <- glucCog %>% 
  filter(BMI > 17 & BMI < 40) # N = 143 -> 140

# counting current sample size
# glucCog %>%
#   group_by(Subject_Code) %>%
#   count() %>% nrow()

### Step 2: Separate Data sets (one for glucose analysis, one for score analysis) ---------

glucOnly <- glucCog %>% filter(!Exp_Strips) %>% # N = 140 -> 95 subjects
  filter(Subject_Code != "CS_111_1") # wacky BGC measurement for subject 111, now 94 subjects
  
# glucCog <- glucCog %>% 
#   drop_na(FullC_T_Score) # rows are worthless without scores, LongVisit0 ommitted by this
  ## subjects without cognitive scores: 112, 113, 114, 116, 117, 118, 130, 131, 132, 134

### Step 4: Configure VAT Ranks -------------

# I want the VAT Ranks to be different across the two samples 
dat.VAT.score <- glucCog %>% 
  group_by(Subject_Code) %>% 
  summarize(VAT_g = mean(VAT_g)) %>% 
  mutate(VAT_Rank = rank(VAT_g)) %>% 
  select(Subject_Code, VAT_Rank)
  
glucCog <- left_join(glucCog, dat.VAT.score, by = "Subject_Code")

dat.VAT.gluc <- glucOnly %>% 
  group_by(Subject_Code) %>% 
  summarize(VAT_g = mean(VAT_g)) %>% 
  mutate(VAT_Rank = rank(VAT_g)) %>% 
  select(Subject_Code, VAT_Rank)

glucOnly <- left_join(glucOnly, dat.VAT.gluc, by = "Subject_Code")

### Step 5: Rearrange columns --------

glucCog <- glucCog %>% 
  select(Subject_Code, Condition, Session_Time, Order, Test_Type, Raw_Score, FullC_T_Score, BGC, Height, Weight, BMI, VAT_Rank, everything())

glucOnly <- glucOnly %>% 
  select(Subject_Code, Condition, Session_Time, Order, Test_Type, Raw_Score, FullC_T_Score, BGC, Height, Weight, BMI, VAT_Rank, everything()) %>% 
  subset(!is.na(FullC_T_Score) | Session_Time == "LongVisit0") %>% 
  drop_na(BGC)
### Done with glucOnly!

### Step 6: Drop NA values on cog dataset
glucCog <- glucCog %>% 
  drop_na(FullC_T_Score, Test_Type)
# N = 140 -> 130

write.csv(x = glucCog, file = "GlucCog Final/Cleaned Data/glucCog.csv") # 130 subjects
write.csv(x = glucOnly, file = "GlucCog Final/Cleaned Data/glucOnly.csv") # 94 subjects

### About the final two datasets -----------
# DF glucCog has N = 130 subjects with reliable scoring data and meets composition requirements (BMI)
# DF glucOnly has N = 94 subjects with reliable BGC data, shrinks to 84 when we need both scoring and BGC
