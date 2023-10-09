
library(tidyverse)
library(nlme)
library(scales)
library(car)

# For nlme::lme and car::Anova later on
options(contrasts = c("contr.sum", "contr.poly"))

glucCog <- read_csv("GlucCog Final/Cleaned Data/glucCog.csv")[-1]
glucOnly <- read_csv("GlucCog Final/Cleaned Data/glucOnly.csv")[-1]

sub_order <- as.vector(glucCog$Subject_Code %>% unique())
glucCog <- glucCog %>% 
  mutate(Subject_Code = factor(Subject_Code, levels = sub_order),
         Condition = factor(Condition, levels = c("Water", "Artificial", "Sugar")),
         Session_Time = factor(Session_Time, 
                               levels = c("ShortVisit","LongVisit20","LongVisit60")),
         Order = as.factor(Order))

### Figure 1: Blood Glucose Levels by Group ---------

g1_df <- glucOnly %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "Base",
                                  Session_Time == "LongVisit0" ~ "0m PC",
                                  Session_Time == "LongVisit20" ~ "20m PC",
                                  Session_Time == "LongVisit60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, 
                               levels = c("Base","0m PC","20m PC","60m PC")))

### INTERACTION CHART ###
pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure1",
    height = 5, width = 7)

ggplot(data = g1_df, aes(x = Session_Time, y = BGC,
             color = Condition, group = Condition)) +
  stat_summary(fun = mean, geom = "point") +
  stat_summary(fun = mean, geom = "line",  show.legend = F) +
  xlab("Session Time") +
  ylab("Blood Sugar Concentration") +
  scale_color_manual(values=c("Sugar" = "gray50", 
                              "Artificial" = "gray75", 
                              "Water" = "gray25")) +
  theme_bw()+
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.title.x = element_blank(), 
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12)) +
  guides(color = guide_legend(override.aes = list(size = 2)))

dev.off()

### Figure 2: Cognitive Performances Between Groups ---------

glucCog_short <- glucCog %>% 
  mutate(Test_Type = case_when(Test_Type == "Auditory Verbal Learning Test" ~ "AVL",
                               Test_Type == "List Sorting Working Memory" ~ "LSWM",
                               Test_Type == "Oral Symbol Digit" ~ "OSD",
                               Test_Type == "Pattern Comparison Processing Speed" ~ "PCPS",
                               Test_Type == "Picture Sequence Memory" ~ "PSM")) %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "SV",
                                  Session_Time == "LongVisit20" ~ "LV20",
                                  Session_Time == "LongVisit60" ~ "LV60")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("SV", "LV20", "LV60")))
  
compCog <- glucCog_short %>% 
  group_by(Subject_Code, Condition, Session_Time, Order) %>% 
  summarize(Std_Score = mean(Std_Score), VAT_Rank = mean(VAT_Rank)) %>% 
  ungroup() %>% 
  mutate(Test_Type = "Composite") %>% 
  mutate(Type_Score = "Standardized") %>% 
  rename(Score = Std_Score)

gluc.gathered <- glucCog_short %>% gather(., key = "Type_Score", value = "Score", Raw_Score:Std_Score) %>% 
  mutate(Type_Score = case_when(Type_Score == "Raw_Score" ~ "Raw",
                                Type_Score == "Std_Score" ~ "Standardized")) %>% 
  select(Subject_Code, Condition, Session_Time, Order, Score, Test_Type, Type_Score, VAT_Rank) 

g2_df <- rbind(compCog, gluc.gathered) %>% 
  mutate(Test_Type = factor(Test_Type, levels = c("AVL","LSWM","OSD","PCPS","PSM","Composite"))) %>% 
  mutate(Type_Score = factor(Type_Score, levels = c("Standardized","Raw"))) 

tests <- c("AVL","LSWM","OSD","PCPS","PSM","Composite")
pvals <- rep(NA, 6)

for (i in 1:6) {
  mme <- lme(fixed = Score ~ Condition * Session_Time * Order,
             random = ~ 1 | Subject_Code,
             contrasts = 
               list(Condition = "contr.sum", 
                    Session_Time = "contr.sum", 
                    Order = "contr.sum"),
             data = g2_df %>% 
                filter(Test_Type == tests[i], Type_Score == "Standardized"))
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) # change to [5] for condition:session_time
}

### BOXPLOT OF SCORES BY CONDITION ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure2",
    height = 6, width = 9)

ggplot(data = g2_df, aes(x = Condition, y = Score, group = Condition, fill = Condition)) +
  geom_boxplot() +
  scale_fill_manual(
    values=c("Sugar" = "gray75", "Artificial" = "gray100", "Water" = "gray50")) +
  xlab("") +
  theme_bw() +
  facet_grid(Type_Score ~ Test_Type, scales = "free_y", switch = "y", labeller = 
               as_labeller(
                 c(Standardized = "Standardized Score", Raw = "Raw Score",
                   AVL = paste("AVL p=", pvals[1], sep = ""), 
                   LSWM = paste("LSWM p=", pvals[2], sep = ""), 
                   OSD = paste("OSD p=", pvals[3], sep = ""), 
                   PCPS = paste("PCPS p=", pvals[4], sep = ""), 
                   PSM = paste("PSM p=", pvals[5], sep = ""), 
                   Composite = paste("Composite p=", pvals[6], sep = ""))), 
             drop = T) +
  theme(legend.position = "none", 
        strip.text.x = element_text(size = 10),
        axis.title.y = element_blank(), 
        axis.title.x = element_blank(), 
        strip.placement.y = "outside", 
        strip.text.y = element_text(size = 12),
        strip.background.y = element_blank(),
        legend.title = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) 

dev.off()

###

### Figure 3: Cognitive Performance by glucose level --------

g3_df <- BGC.Cog <- glucOnly %>% 
  drop_na(Std_Score) %>% 
  select(Subject_Code, Session_Time, Condition, Test_Type, Std_Score, Raw_Score, BGC, Order) %>% 
  group_by(Subject_Code, Session_Time, Condition, Order) %>% 
  summarize(Std_Score = mean(Std_Score, na.rm = T), 
            Raw_Score = mean(Raw_Score, na.rm = T), 
            BGC = mean(BGC)) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("ShortVisit", "LongVisit20", "LongVisit60")))

##### SCATTERPLOTS #####

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure3",
    height = 6, width = 9)

ggplot(data = g3_df) +
  geom_jitter(aes(x = BGC, y = Std_Score, fill = Condition, shape = Condition), size = 3) +
  geom_smooth(aes(x = BGC, y = Std_Score, color = Condition), se = F, method = "lm", show.legend = F) +
  scale_color_manual(values=c("Sugar" = "gray60", "Artificial" = "gray80", "Water" = "gray10")) + 
  scale_fill_manual(values=c("Sugar" = "gray70", "Artificial" = "gray100", "Water" = "gray20")) + 
  scale_shape_manual(values=c("Sugar" = 23, "Artificial" = 24, "Water" = 21)) + 
  facet_wrap(~ Order + Session_Time, scales = "fixed", ncol = 3, 
             labeller = as_labeller(
               c(`Short Visit First` = "Order 1", `Treatment Visit First` = "Order 2",
                 ShortVisit = "Baseline Visit", LongVisit20 = "Treatment Visit 20min Post Consumption", LongVisit60 = "Treatment Visit 60min Post Consumption"))) +
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 10),
        strip.text.y = element_blank(), 
        strip.background.y = element_blank(), 
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  ylim(c(-3,3)) +
  xlab("Blood Glucose Concentration") + ylab("Composite Score")

dev.off()

#######

### Figure 4: Cognitive Scores by Time Point -----------

g4_df <- g2_df %>% 
  mutate(Session_Time = case_when(Session_Time == "SV" ~ "Base",
                                  Session_Time == "LV20" ~ "20m PC",
                                  Session_Time == "LV60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Base","20m PC","60m PC"))) %>% 
  filter(Type_Score == "Standardized") %>% 
  mutate(Type_Score = "Standardized Score") %>% 
  mutate(Test_Type = factor(Test_Type, levels = tests))

##### INTERACTION GRAPH #####

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure4",
    height = 7, width = 10)

ggplot(data = g4_df,
       aes(x = Session_Time, y = Score, group = Condition, color = Condition)) +
  stat_summary(fun = mean, geom = "point") +
  stat_summary(fun = mean, geom = "line", show.legend = F) +
  xlab("Session Time") +
  scale_color_manual(values=c("Sugar" = "gray50", "Artificial" = "gray75", "Water" = "gray25")) +
  facet_grid(Type_Score ~ Test_Type, switch = "y") +
  theme_bw() + 
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12),
        strip.text.x = element_text(size = 12),
        strip.placement.y = "outside", 
        strip.text.y = element_text(size = 12),
        strip.background.y = element_blank(), 
        axis.title.y = element_blank()) +  
  guides(colour = guide_legend(override.aes = list(size = 3))) + 
  coord_cartesian(ylim = c(-.6, .6)) 

dev.off()

###

### Figure 5: Cognitive Scores by Time Point and Order -----------

g5_df <- g4_df %>% 
  mutate(Session_Time = as.character(Session_Time)) %>% 
  mutate(Session_Time = ifelse(Session_Time == "Base" & Order == "Treatment Visit First", "Base ", Session_Time)) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Base", "20m PC", "60m PC", "Base ")))

### INTERACTION GRAPHS ### 

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure5",
    height = 7, width = 10)

ggplot(data = g5_df, 
       aes(x = Session_Time, y = Score, group = Condition, color = Condition)) +
  stat_summary(fun = mean, geom = "point") +
  stat_summary(fun = mean, geom = "line",show.legend = F) +
  ylab("Standardized Score") +
  scale_color_manual(values=c("Sugar" = "gray50", "Artificial" = "gray75", "Water" = "gray25")) + 
  facet_wrap(~ Order + Test_Type, nrow = 2, scales = "free_x") +
  theme_bw() +
  guides(colour = guide_legend(override.aes = list(size = 2))) +
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.title.x = element_blank(), 
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12)) +
  coord_cartesian(ylim=c(-1,1))

dev.off()

###

### Figure 6: VAT by BGC Association ----------

g6_df <- glucOnly %>% 
  drop_na(BGC, VAT_Rank) %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "Base",
                                  Session_Time == "LongVisit0" ~ "0m PC",
                                  Session_Time == "LongVisit20" ~ "20m PC",
                                  Session_Time == "LongVisit60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Base","0m PC", "20m PC","60m PC"))) %>% 
  group_by(Subject_Code, Session_Time, Condition) %>% 
  summarize(BGC = mean(BGC), VAT_Rank = mean(VAT_Rank))

### Scatterplot ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure6",
    height = 7, width = 10)

ggplot(data = g6_df) +
  geom_point(aes(x = VAT_Rank, y = BGC, shape = Condition, fill = Condition), size = 3) +
  geom_smooth(aes(x = VAT_Rank, y = BGC, color = Condition), 
              se = F, method = "lm", show.legend = F) +
  #  geom_smooth(aes(x = VAT_Rank, y = Blood_Glucose_Test), color = "black", lty = 2, se = F, method = "lm") +
  #  scale_color_manual(values=c("Sugar" = "#999999", "Artificial" = "#E69F00", "Water" = "#56B4E9")) + 
  facet_wrap(~ Session_Time, ncol = 4) +
  scale_color_manual(values=c("Sugar" = "gray60", "Artificial" = "gray80", "Water" = "gray10")) + 
  scale_fill_manual(values=c("Sugar" = "gray70", "Artificial" = "gray100", "Water" = "gray20")) + 
  scale_shape_manual(values=c("Sugar" = 23, "Artificial" = 24, "Water" = 21)) + 
  facet_wrap(~ Session_Time, ncol = 4) +
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 16),
        axis.title.x = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  ylab("Blood Glucose Concentration") + xlab("Visceral Adipose Tissue Ranking")

dev.off()

###

### Figure 7: VAT by Cognitive Scoring Association -------

vatRankCog <- g2_df %>% 
  filter(Type_Score == "Standardized") %>% 
  drop_na(VAT_Rank, Score) %>% 
  mutate(Session_Time = case_when(Session_Time == "SV" ~ "Base",
                                  Session_Time == "LV20" ~ "20m PC",
                                  Session_Time == "LV60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Base","0m PC", "20m PC","60m PC"))) %>% 
  group_by(Subject_Code, Session_Time, Condition, Order, Test_Type) %>% 
  summarize(Score = mean(Score), VAT_Rank = mean(VAT_Rank)) %>% 
  mutate(Test_Type = factor(Test_Type, levels = tests))

### pval calculation ###

pvals <- rep(NA, 6)

for (i in 1:6) {
  mme <- lme(fixed = Score ~ VAT_Rank * Session_Time * Order,
                   random = ~ 1 | Subject_Code,
                   data = vatRankCog %>% 
                     filter(Test_Type == tests[i]), 
             contrasts = list(Session_Time = contr.sum,
                              Order = contr.sum))
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) # change to [5] for condition:session_time
  
}

# Warning is not an issue: its detecting LV0 without any scoring/factors

g7_df <- vatRankCog %>% 
  group_by(Subject_Code, Condition, Test_Type) %>% 
  summarize(Score = mean(Score), VAT_Rank = mean(VAT_Rank))

### Scatterplot ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure7",
    height = 5, width = 10)

ggplot(data = g7_df, 
             aes(x = VAT_Rank, y = Score)) +
  geom_jitter(aes(shape = Condition, fill = Condition), size = 3) +
  geom_smooth(aes(color = Condition), se = F, method = "lm", show.legend = F) +
  geom_smooth(color = "black", lty = 2, se = F, method = "lm") +
  facet_wrap(~ Test_Type, ncol = 6, labeller = 
               as_labeller(
                 c(AVL = paste("AVL p=", pvals[1], sep = ""), 
                   LSWM = paste("LSWM p=", pvals[2], sep = ""), 
                   OSD = paste("OSD p=", pvals[3], sep = ""), 
                   PCPS = paste("PCPS p=", pvals[4], sep = ""), 
                   PSM = paste("PSM p=", pvals[5], sep = ""), 
                   Composite = paste("Composite p=", pvals[6], sep = "")))) + 
  scale_color_manual(values=c("Sugar" = "gray60", "Artificial" = "gray80", "Water" = "gray10")) + 
  scale_fill_manual(values=c("Sugar" = "gray70", "Artificial" = "gray100", "Water" = "gray20")) + 
  scale_shape_manual(values=c("Sugar" = 23, "Artificial" = 24, "Water" = 21)) + 
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 12),
        axis.title.x = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  ylab("Standard Score") + xlab("Visceral Adipose Tissue Ranking")

dev.off()

###


# # | # | # | # #
# # | # | # | # #
# | # | # | # | #
# | # | # | # | #
# | # | # | # | #
# # | # | # | # #
# # | # | # | # #


