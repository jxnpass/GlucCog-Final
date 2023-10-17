
library(tidyverse)
library(nlme)
library(car)

# For nlme::lme and car::Anova later on
options(contrasts = c("contr.sum", "contr.poly"))

glucCog <- read_csv("GlucCog Final/Cleaned Data/glucCog.csv")[-1] 
sub_order <- glucCog$Subject_Code %>% unique()

glucCog <- glucCog %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("ShortVisit", "LongVisit20", "LongVisit60")),
         Condition = factor(Condition, levels = c("Water", "Artificial", "Sugar")),
         Order = factor(Order, levels = c("Short Visit First", "Treatment Visit First")),
         Subject_Code = factor(Subject_Code, levels = sub_order))
glucOnly <- read_csv("GlucCog Final/Cleaned Data/glucOnly.csv")[-1] %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("ShortVisit", "LongVisit0", "LongVisit20", "LongVisit60")),
         Condition = factor(Condition, levels = c("Water", "Artificial", "Sugar")),
         Order = factor(Order, levels = c("Short Visit First", "Treatment Visit First")))

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
    random = ~1|Subject_Code,
    contrasts = list(Condition = "contr.sum")) %>% 
  Anova(type = "III")

# add session time #
lme(fixed = Std_Score ~ Condition * Session_Time, 
    data = glucCog, 
    random = ~1|Subject_Code,
    contrasts = list(Condition = "contr.sum", Session_Time = "contr.sum")) %>% 
  Anova(type = "III")

# include order # 
lme(fixed = Std_Score ~ Condition * Session_Time * Order, 
    data = glucCog, 
    random = ~1|Subject_Code,    
    contrasts = 
      list(Condition = "contr.sum", 
           Session_Time = "contr.sum", 
           Order = "contr.sum")) %>% 
  Anova(type = "III")

# evaluate by BGC instead of condition type (more descriptive effects of BGC) #
lme(fixed = Std_Score ~ BGC * Session_Time * Order,
    data = glucOnly %>% drop_na(Std_Score) %>% 
      group_by(Subject_Code, Condition, Session_Time, Order) %>% 
      summarize(BGC = mean(BGC), Std_Score = mean(Std_Score)), 
    random = ~1|Subject_Code,
    contrasts = list(Session_Time = "contr.sum", 
                     Order = "contr.sum")
    ) %>% 
  Anova(type = "III")

# warning above indicates factor level is missing (LongVisit0). This is okay. 

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
glucCogComp$Std_Score[2] - glucCogComp$Std_Score[1]
# Baseline-1st-Order: LV20 to LV60 improvement
glucCogComp$Std_Score[3] - glucCogComp$Std_Score[2]
# Treatment-1st-Order: LV20 to LV60 improvement
glucCogComp$Std_Score[6] - glucCogComp$Std_Score[5]
# Treatment-1st-Order: LV60 to SV improvement
glucCogComp$Std_Score[4] - glucCogComp$Std_Score[6]

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
                   data = VAT.Cog,
                   contrasts = list(Session_Time = "contr.sum",
                                    Order = "contr.sum")) 

compRes <- VAT.Cog.lme$residuals[,1]

# LM Results 
lm(compRes ~ VAT.Cog$VAT_Rank) %>% summary()
sd(VAT.Cog$VAT_Rank) * -0.0018985

# ANOVA Results

lme(fixed = Std_Score ~ VAT_Rank * Session_Time * Order,
    random = ~1|Subject_Code,
    data = VAT.Cog,
    contrasts = list(Session_Time = "contr.sum",
                     Order = "contr.sum")) %>% 
  Anova(type = "III")

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
    data = VAT.PCPS,
    contrasts = list(Session_Time = "contr.sum",
                     Order = "contr.sum")) %>% 
  Anova(type = "III")

# BGC # 

VAT.BGC <- glucOnly %>% 
  drop_na(BGC, VAT_Rank) %>% 
  group_by(Subject_Code, Condition, Session_Time, VAT_Rank) %>% 
  summarize(BGC = mean(BGC)) %>% 
  ungroup()

VAT.BGC.lme <- lme(fixed = BGC ~ Session_Time * Condition,
                  random = ~1|Subject_Code,
                  data = VAT.BGC,
                  contrasts = list(Session_Time = contr.sum,
                                   Condition = contr.sum)) 

bgcRes <- VAT.BGC.lme$residuals[,1]

# LM results
lm(bgcRes ~ VAT.BGC$VAT_Rank) %>% summary()
sd(VAT.BGC$VAT_Rank) * 0.05862

# ANOVA results

lme(fixed = BGC ~ VAT_Rank * Session_Time * Condition,
    random = ~1|Subject_Code,
    data = VAT.BGC,
    contrasts = list(Session_Time = contr.sum,
                     Condition = contr.sum)) %>% 
  Anova(type = "III")

### Condition on Cognitive Score per each test -----------

gluc.simple.comp <- glucCog %>% 
  group_by(Subject_Code, Condition, Session_Time, Order) %>% 
  summarize(Std_Score = mean(Std_Score), BGC = mean(BGC, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(Test_Type = "Composite") 

gluc.all.comp <- glucCog %>% select(Subject_Code, Condition, Session_Time, Order, Std_Score, Test_Type, BGC) %>% 
  rbind(., gluc.simple.comp)

tests <- gluc.all.comp$Test_Type %>% unique()
pvals <- data.frame("test_type" = tests, "pval" = NA)

for (i in 1:length(tests)) {
  test.dat <- gluc.all.comp %>% 
    filter(Test_Type == tests[i])
  
  test.anv <- lme(fixed = Std_Score ~ Condition*Session_Time*Order, # can replace condition with BGC
                  data = test.dat # %>% drop_na(BGC)
                  ,
                  random = ~1|Subject_Code,
                  contrasts = list(Condition = contr.sum, # put '#' in front of Condition
                                   Session_Time = contr.sum, 
                                   Order = contr.sum)) %>% 
    Anova(type = "III")
  
  pvals$pval[i] <- test.anv$`Pr(>Chisq)`[5] 
  # print(test.anv)
  # print(tests[i])
  
  ### Summary ###
  # p-val of interest is condition:session_time, compared to just condition with figure 3
  # we could also have interest in condition:session_time:order, 
  # but three-term interactions are hard to wrap one's head around
  # they're important to note, however, because they do contribute to testing significance
}

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








