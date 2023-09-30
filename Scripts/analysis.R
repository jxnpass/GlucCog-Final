
library(tidyverse)
library(nlme)
library(car)

glucCog <- read_csv("GlucCog Final/Cleaned Data/glucCog.csv")[-1] %>% 
  mutate(Session_Time = as.factor(Session_Time),
         Condition = as.factor(Condition),
         Order = as.factor(Order))
glucOnly <- read_csv("GlucCog Final/Cleaned Data/glucOnly.csv")[-1]

options(contrasts = c('contr.sum','contr.poly'))
options(contrasts = c("contr.treatment", "contr.poly"))

### Treatment Order Differences ----------------
 
sub_count <- glucCog %>% 
  count(Subject_Code) %>% 
  nrow()
 
glucCog %>% 
  group_by(Order) %>% 
  count(Subject_Code) %>% 
  count(Order) %>% 
  mutate(prop = n/sub_count)

### BGC comparison between Groups x Session_time --------

glucOnly %>% 
  group_by(Subject_Code, Session_Time, Condition) %>% 
  summarize(BGC = mean(BGC)) %>% 
  ungroup() %>% 
  group_by(Session_Time, Condition) %>% 
  summarize(BGC = mean(BGC))
  
### Cognitive score by condition ----------

# basic #
lme(fixed = Std_Score ~ Condition, 
    data = glucCog, 
    random = ~1|Subject_Code) %>% Anova(type = "III")

# add session time #
lme(fixed = Std_Score ~ Condition * Session_Time, 
    data = glucCog, 
    random = ~1|Subject_Code) %>% Anova(type = "III")

# include order # 
lme(fixed = Std_Score ~ Condition * Session_Time * Order, 
    data = glucCog, 
    random = ~1|Subject_Code) %>% Anova(type = "III")

### TESTING ### 

# evaluate by BGC instead of condition type (more descriptive effects of BGC) #
lme(fixed = Std_Score ~ BGC * Session_Time * Order, # switch order, much different results
    data = glucOnly %>% drop_na(Std_Score) %>% 
      group_by(Subject_Code, Condition, Session_Time, Order) %>% 
      summarize(BGC = mean(BGC), Std_Score = mean(Std_Score)), 
    random = ~1|Subject_Code) %>% Anova(type = "III")
# might have something. however, I don't think this tells us enough...
lme(fixed = Std_Score ~ BGC * Session_Time * Order, 
    data = glucOnly %>% drop_na(Std_Score) %>% 
      group_by(Subject_Code, Condition, Session_Time, Order) %>% 
      summarize(BGC = mean(BGC), Std_Score = mean(Std_Score)), 
    random = ~1|Subject_Code) %>% anova()

BGC.Cog.lme <- lme(fixed = Std_Score ~ Session_Time * Order,
                   random = ~1|Subject_Code,
                   data = glucOnly %>% 
                      drop_na(BGC, Std_Score)) 

res <- BGC.Cog.lme$residuals[,1]

# LM Results 
lm(res ~ glucOnly$BGC[!is.na(glucOnly$Std_Score)]) %>% summary()

### --- ###

### Cognitive score improvement tracking based on order of testing -------

glucCogComp <- glucCog %>%
  drop_na(Std_Score) %>% 
  group_by(Subject_Code, Session_Time, Order) %>% 
  summarize(Std_Score = mean(Std_Score)) %>% 
  ungroup() %>% 
  group_by(Order, Session_Time) %>% 
  summarize(Std_Score = mean(Std_Score)) 

# Baseline-1st-Order: SV to LV20 improvement
glucCogComp$Std_Score[1] - glucCogComp$Std_Score[3]
# Baseline-1st-Order: LV20 to LV60 improvement
glucCogComp$Std_Score[2] - glucCogComp$Std_Score[1]
# Treatment-1st-Order: LV20 to LV60 improvement
glucCogComp$Std_Score[5] - glucCogComp$Std_Score[4]
# Treatment-1st-Order: LV60 to SV improvement
glucCogComp$Std_Score[6] - glucCogComp$Std_Score[5]

### VAT Analysis (LM against LME residuals) ----------------

# cognition composite score #

VAT.Cog <- glucCog %>% 
  drop_na(Std_Score, VAT_Rank) %>% 
  group_by(Subject_Code, Condition, Session_Time, Order, VAT_Rank) %>% 
  summarize(Std_Score = mean(Std_Score)) %>% 
  ungroup() %>% 
  mutate(Test_Type = "Composite") 

VAT.Cog.lme <- lme(fixed = Std_Score ~ Session_Time * Order,
                    random = ~1|Subject_Code,
                    data = VAT.Cog) 

compRes <- VAT.Cog.lme$residuals[,1]

# LM Results 
lm(compRes ~ VAT.Cog$VAT_Rank) %>% summary()
sd(VAT.Cog$VAT_Rank) * -0.0018985

# ANOVA Results

lme(fixed = Std_Score ~ VAT_Rank * Session_Time * Order,
    random = ~1|Subject_Code,
    data = VAT.Cog) %>% Anova(type = "II")

# PCPS score # 

VAT.PCPS <- glucCog %>% 
  filter(Test_Type == "Pattern Comparison Processing Speed") %>% 
  drop_na(Std_Score, VAT_Rank) %>% 
  group_by(Subject_Code, Session_Time, Order, VAT_Rank) %>% 
  summarize(Std_Score = mean(Std_Score)) %>% 
  ungroup()

VAT.PCPS.lme <- lme(fixed = Std_Score ~  Session_Time * Order,
                  random = ~1|Subject_Code,
                  data = VAT.PCPS) 

pcpsRes <- VAT.PCPS.lme$residuals[,1]

# LM results
lm(pcpsRes ~ VAT.PCPS$VAT_Rank) %>% summary()
sd(VAT.PCPS$VAT_Rank) * -0.005966

# ANOVA Results

lme(fixed = Std_Score ~ VAT_Rank * Session_Time * Order,
    random = ~1|Subject_Code,
    data = VAT.PCPS) %>% Anova(type = "III")

# BGC # 

VAT.BGC <- glucOnly %>% 
  drop_na(BGC, VAT_Rank) %>% 
  group_by(Subject_Code, Condition, Session_Time, VAT_Rank) %>% 
  summarize(BGC = mean(BGC)) %>% 
  ungroup()

VAT.BGC.lme <- lme(fixed = BGC ~ Session_Time * Condition,
                  random = ~1|Subject_Code,
                  data = VAT.BGC) 

bgcRes <- VAT.BGC.lme$residuals[,1]

# LM results
lm(bgcRes ~ VAT.BGC$VAT_Rank) %>% summary()
sd(VAT.BGC$VAT_Rank) * 0.05862

# ANOVA results

lme(fixed = BGC ~ VAT_Rank * Session_Time * Condition,
    random = ~1|Subject_Code,
    data = VAT.BGC) %>% Anova(type = "III")

### Condition on Cognitive Score per each test -----------

gluc.simple.comp <- glucCog %>% 
  group_by(Subject_Code, Condition, Session_Time, Order) %>% 
  summarize(Std_Score = mean(Std_Score)) %>% 
  ungroup() %>% 
  mutate(Test_Type = "Composite") 

gluc.all.comp <- glucCog %>% select(Subject_Code, Condition, Session_Time, Order, Std_Score, Test_Type) %>% 
  rbind(., gluc.simple.comp)

tests <- gluc.all.comp$Test_Type %>% unique()
pvals <- data.frame("test_type" = tests, "pval" = NA)

for (i in 1:length(tests)) {
  test.dat <- gluc.all.comp %>% 
    filter(Test_Type == tests[i])
  
  test.anv <- lme(fixed = Std_Score ~ Condition*Session_Time*Order,
                  data = test.dat, 
                  random = ~1|Subject_Code) %>% anova()
  
  pvals$pval[i] <- test.anv$`p-value`[5] 
  # pval of interest is condition:session_time, compared to condition with figure 3
}

pvals

test.dat <- gluc.all.comp %>% 
  filter(Test_Type == "Oral Symbol Digit")
lme(fixed = Std_Score ~ Condition*Session_Time*Order,
    data = gluc.all.comp %>% 
      filter(Test_Type == "Oral Symbol Digit"), 
    random = ~1|Subject_Code) %>% Anova(type = "III")


### Deeper dive into OSD -------

# A mathematical reflection from figure 5
# gluc.all.comp %>% 
#   mutate(Session_Time = factor(Session_Time, c("ShortVisit","LongVisit20","LongVisit60"))) %>% 
#   filter(Test_Type == "Oral Symbol Digit") %>% 
#   group_by(Condition, Session_Time, Order) %>% 
#   summarize(sd(Std_Score), Std_Score = mean(Std_Score), n()) %>% 
#   mutate(diff = c(NA, diff(Std_Score)))

### Greatest cognitive improvement (from learning effect) --------

# mainly interested in knowing how big improvements were from session 1, 2, then 3,
# regardless of condition, or order of test taking
improv.df <- gluc.all.comp %>% 
  mutate(SessionNumber = 
         case_when(Order == "Short Visit First" & Session_Time == "ShortVisit" ~ 1,
                   Order == "Short Visit First" & Session_Time == "LongVisit20" ~ 2,
                   Order == "Short Visit First" & Session_Time == "LongVisit60" ~ 3,
                   Order == "Treatment Visit First" & Session_Time == "LongVisit20" ~ 1,
                   Order == "Treatment Visit First" & Session_Time == "LongVisit60" ~ 2,
                   Order == "Treatment Visit First" & Session_Time == "ShortVisit" ~ 3)) %>% 
  group_by(Test_Type, SessionNumber) %>% 
  summarize(Std_Score = mean(Std_Score)) %>% 
  mutate(diff = c(NA, diff(Std_Score))) %>% 
  ungroup()

tot_change.df <- improv.df %>% 
  group_by(Test_Type) %>% 
  summarize(tot_change = sum(diff, na.rm = T))

tot_change.df
# AVL had biggest 1 to 3 improvement 
# LSM had smallest 1 to 3 improvement

### Which VATs were 0? -------------

glucCog %>% 
  filter(VAT_g == 0) %>% 
  select(Subject_Code, BMI, VAT_g) %>% 
  unique()








