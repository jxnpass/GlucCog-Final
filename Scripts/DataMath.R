# source("~/GlucoseCognition_Project/GlucCog Final/Scripts/DataPrep.R")

library(tidyverse)

glucCog  <- read_csv("GlucCog Final/Cleaned Data/DataPrepOutput.csv")[,-1]
sub_order <- as.vector(glucCog$Subject_Code %>% unique())
glucCog$Subject_Code <- factor(glucCog$Subject_Code, levels = sub_order)

### Step 1: Calculate BMI --------

glucCog <- glucCog %>% 
  mutate(BMI = Weight / ((Height/100)^2) )

### Step 2: clean data (remove bad rows/missing data/low to high BMI) ---------

# Score Subject Count N = 140
glucCog <- glucCog %>% 
  filter(!No_Data,
         BMI > 17 & BMI < 40) 

# glucCog %>% 
#   group_by(Subject_Code) %>% 
#   count() %>% nrow()

### Step 2: Standardize Cognitive Scores ---------------
# omission of bad tests 

test_avgs <- glucCog %>% 
  filter(Session_Time != "LongVisit0") %>% 
  drop_na(Raw_Score) %>% 
  group_by(Test_Type) %>% 
  summarize(Mean = mean(Raw_Score))

test_sds <- glucCog %>% 
  filter(Session_Time != "LongVisit0") %>% 
  drop_na(Raw_Score) %>% 
  group_by(Test_Type) %>% 
  summarize(SD = sd(Raw_Score))

# Function for finding t score and graph

glucCog$Std_Score <- NA

TScore <- function(score, test_name) {
  t.score <- (score - test_avgs$Mean[test_avgs$Test_Type == test_name]) / 
    test_sds$SD[test_sds$Test_Type == test_name]
  return(t.score)
}

for (i in 1:nrow(glucCog)) {
  if (!is.na(glucCog$Raw_Score[i])) {
    glucCog$Std_Score[i] <- TScore(glucCog$Raw_Score[i], glucCog$Test_Type[i]) 
  }
}

# Ommitted two tests, FICA and DCCS (due to lack of variation)

glucCog <- glucCog %>% 
  filter(!(Test_Type %in% c("Dimensional Change Card Sort","Flanker Inhibitory Control and Attention")))

### Step 3: Separate Data sets (one for glucose analysis, one for score analysis) ---------

glucOnly <- glucCog %>% filter(!Exp_Strips) %>% # 95 subjects
  filter(Subject_Code != "CS_111_1") # wacky BGC measurement for subject 111, no 94
  
glucCog <- glucCog %>% 
  drop_na(Std_Score) # rows are worthless without scores, LongVisit0 ommitted by this
  ## subjects without cognitive scores: 112, 113, 114, 116, 117, 118, 130, 131, 132, 134

### Step 4: Configure VAT Ranks -------------

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
  select(Subject_Code, Condition, Session_Time, Order, Test_Type, Std_Score, Raw_Score, BGC, Height, Weight, BMI, VAT_Rank, everything())

glucOnly <- glucOnly %>% 
  select(Subject_Code, Condition, Session_Time, Order, Test_Type, BGC, Std_Score, Raw_Score, Height, Weight, BMI, VAT_Rank, everything()) %>% 
  subset(!is.na(Std_Score) | Session_Time == "LongVisit0") %>% 
  drop_na(BGC)
### Done!

write.csv(x = glucCog, file = "GlucCog Final/Cleaned Data/glucCog.csv")
write.csv(x = glucOnly, file = "GlucCog Final/Cleaned Data/glucOnly.csv") 

### About the final two datasets -----------
# DF glucCog has N = 130 subjects with reliable scoring data and meets composition requirements (BMI)
# DF glucOnly has N = 94 subjects with reliable BGC data, shrinks to 85 when we need both scoring and BGC





