
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

# Primary Research Graphics -----------
### Figure 1: Blood Glucose Levels by Group ---------

g1_df <- glucOnly %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "Short",
                                  Session_Time == "LongVisit0" ~ "PreC",
                                  Session_Time == "LongVisit20" ~ "20m PC",
                                  Session_Time == "LongVisit60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, 
                               levels = c("Short","PreC","20m PC","60m PC")))

### INTERACTION CHART ###
pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure1",
    height = 5, width = 7)

ggplot(data = g1_df, aes(x = Session_Time, y = BGC, group = Condition,
             lty = Condition, shape = Condition, fill= Condition)) +
  stat_summary(fun = mean, geom = "line",  show.legend = F, aes(color = Condition)) +
  stat_summary(fun = mean, geom = "point", size = 2.5) +
  xlab("Session Time") +
  ylab("Blood Sugar Concentration") +
  scale_color_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray85", 
                              "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray85", 
                              "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
  theme_bw()+
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.title.x = element_blank(), 
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12)) +
  guides(fill = guide_legend(override.aes = list(size = 3)))

dev.off()

### Figure 2: Cognitive Performances Between Groups ---------

tests <- c("AVLT","DCCS", "FICA","LSWM","OSD","PCPS","PSM","Fluid Composite")

g2_df <- glucCog %>% 
  mutate(Test_Type = case_when(Test_Type == "Auditory Verbal Learning Test" ~ "AVLT",
                               Test_Type == "List Sorting Working Memory" ~ "LSWM",
                               Test_Type == "Oral Symbol Digit" ~ "OSD",
                               Test_Type == "Pattern Comparison Processing Speed" ~ "PCPS",
                               Test_Type == "Picture Sequence Memory" ~ "PSM",
                               Test_Type == "Flanker Inhibitory Control and Attention" ~ "FICA",
                               Test_Type == "Dimensional Change Card Sort" ~ "DCCS",
                               Test_Type == "Cognition Fluid Composite v1.1" ~ "Fluid Composite")) %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "SV",
                                  Session_Time == "LongVisit20" ~ "LV20",
                                  Session_Time == "LongVisit60" ~ "LV60")) %>%
  mutate(Test_Type = factor(Test_Type, levels = tests)) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("SV", "LV20", "LV60"))) %>% 
  mutate(Condition = factor(Condition, levels = c("Artificial", "Sugar", "Water")))

pvals <- rep(NA, 8)

for (i in 1:length(tests)) {
  mme <- lme(fixed = FullC_T_Score ~ Condition * Session_Time * Order,
             random = ~ 1 | Subject_Code,
             contrasts = 
               list(Condition = "contr.sum", 
                    Session_Time = "contr.sum", 
                    Order = "contr.sum"),
             data = g2_df %>% 
                filter(Test_Type == tests[i]) %>% 
               drop_na(FullC_T_Score))
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) # change to [5] for condition:session_time
}

# calculate outliers (for aesthetic on next graph)

quartiles <- g2_df %>%
  group_by(Test_Type, Condition) %>%
  summarize(
    Q1 = quantile(FullC_T_Score, 0.25),
    Q3 = quantile(FullC_T_Score, 0.75),
    IQR = IQR(FullC_T_Score)
  )

# Identify outliers
g2_outliers <- g2_df %>%
  left_join(quartiles, by = c("Test_Type", "Condition")) %>%
  filter(FullC_T_Score < Q1 - 1.5 * IQR | FullC_T_Score > Q3 + 1.5 * IQR) %>% 
  mutate(Condition = factor(Condition, levels = c("Artificial", "Sugar", "Water")))

### BOXPLOT OF SCORES BY CONDITION ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure2",
    height = 6, width = 11)

ggplot(data = g2_df, aes(x = Condition, y = FullC_T_Score, group = Condition, 
                         fill = Condition)) +
  geom_hline(yintercept = 50, lty = 5, color = "gray65") +
  geom_hline(yintercept = 70, lty = 5, color = "gray95") +
  geom_hline(yintercept = 30, lty = 5, color = "gray95") +
  geom_boxplot(outlier.shape = NA, show.legend = F) +
  geom_point(g2_outliers, 
             mapping = aes(x = Condition, y = FullC_T_Score, group = Condition, 
                           fill = Condition, shape = Condition), 
             size = 3, show.legend = T) +
  scale_fill_manual(
    values=c("Sugar" = "gray70", 
             "Artificial" = "gray100", 
             "Water" = "gray35")) +
  scale_shape_manual(
    values = c("Sugar" = 23, 
               "Artificial" = 24, 
               "Water" = 21)) +
  xlab("") + 
  ylab("Fully-Corrected T-Score") +
  theme_bw() +
  facet_wrap(~ Test_Type, labeller = 
               as_labeller(
                 c(AVLT = paste("AVLT p=", pvals[1], sep = ""),
                   DCCS = paste("DCCS p=", pvals[2], sep = ""),
                   FICA = paste("FICA p=", pvals[3], sep = ""),
                   LSWM = paste("LSWM p=", pvals[4], sep = ""), 
                   OSD = paste("OSD p=", pvals[5], sep = ""), 
                   PCPS = paste("PCPS p=", pvals[6], sep = ""), 
                   PSM = paste("PSM p=", pvals[7], sep = ""), 
                   `Fluid Composite` = paste("Fluid Composite p=", pvals[8], sep = ""))), 
             nrow = 2) +
  theme(strip.text.x = element_text(size = 12),
        axis.title.y = element_text(size = 12), 
        axis.title.x = element_blank(), 
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.key.size = unit(8, units = "mm"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) 

dev.off()

###

### Figure 3: Cognitive Performance by glucose level --------

g3_df <- BGC.Cog <- glucOnly %>% 
  filter(Test_Type == "Cognition Fluid Composite v1.1") %>% 
  drop_na(FullC_T_Score) %>% 
  select(Subject_Code, Session_Time, Condition, Test_Type, FullC_T_Score, BGC, Order) %>% 
  group_by(Subject_Code, Session_Time, Condition, Order) %>% 
  summarize(FullC_T_Score = mean(FullC_T_Score, na.rm = T), 
            BGC = mean(BGC)) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("ShortVisit", "LongVisit20", "LongVisit60")))

g3_df %>% ungroup() %>% count(Session_Time, Order, Condition)

# SCATTERPLOTS 

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure3",
    height = 6, width = 9)

ggplot(data = g3_df) +
  geom_smooth(aes(x = BGC, y = FullC_T_Score, color = Condition), se = F, method = "lm", show.legend = F) +
  geom_jitter(aes(x = BGC, y = FullC_T_Score, fill = Condition, shape = Condition), size = 3) +
  scale_color_manual(values=c("Sugar" = "gray60", "Artificial" = "gray80", "Water" = "gray10")) + 
  scale_fill_manual(values=c("Sugar" = "gray70", "Artificial" = "gray100", "Water" = "gray20")) + 
  scale_shape_manual(values=c("Sugar" = 23, "Artificial" = 24, "Water" = 21)) + 
  facet_wrap(~ Order + Session_Time, scales = "fixed", ncol = 3, 
             labeller = as_labeller(
               c(`Short Visit First` = "Order 1", `Treatment Visit First` = "Order 2",
                 ShortVisit = "Short Visit", LongVisit20 = "Treatment Visit 20min Post Consumption", LongVisit60 = "Treatment Visit 60min Post Consumption"))) +
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 10),
        strip.text.y = element_blank(), 
        strip.background.y = element_blank(), 
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  xlab("Blood Glucose Concentration") + ylab("Fluid Composite T-Score")

dev.off()

### Figure 4: Cognitive Scores by Time Point and Order -----------

g4_df <- g2_df %>% 
  mutate(Session_Time = case_when(Session_Time == "SV" ~ "Short",
                                  Session_Time == "LV20" ~ "20m PC",
                                  Session_Time == "LV60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Short","20m PC","60m PC"))) %>% 
  mutate(Session_Time = as.character(Session_Time)) %>% 
  mutate(Session_Time = ifelse(Session_Time == "Short" & Order == "Short Visit First", "Short-1", Session_Time)) %>% 
  mutate(Session_Time = ifelse(Session_Time == "Short" & Order == "Treatment Visit First", "Short-2", Session_Time)) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Short-1", "20m PC", "60m PC", "Short-2")))

## INTERACTION GRAPH

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure4",
    height = 7, width = 12)

ggplot(data = g4_df,
       aes(x = Session_Time, y = FullC_T_Score, group = Condition, 
           linetype = Condition, shape = Condition)) +
  stat_summary(fun = mean, geom = "line", show.legend = F, 
               mapping = aes(color = Condition)) +
  stat_summary(fun = mean, geom = "point", size = 3, 
               mapping = aes(fill = Condition)) +
  xlab("Session Time") +
  ylab("Fully-Corrected T-Score") +
  scale_color_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray85", 
                              "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                             "Artificial" = "gray95", 
                             "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
  ylab("Fully-Corrected T-Score") +
  facet_wrap(~ Order + Test_Type, 
              labeller = as_labeller(c(`Short Visit First` = "Order 1", `Treatment Visit First` = "Order 2",
              AVLT = "AVLT", DCCS = "DCCS", FICA = "FICA", LSWM = "LSWM", OSD = "OSD", PCPS = "PCPS",
              PSM = "PSM", `Fluid Composite` = "Fluid Composite")),
             nrow = 2, scales = "free_x") +
  theme_bw() +
  guides(colour = guide_legend(override.aes = list(size = 3))) +
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.title.x = element_blank(), 
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 7.5))

dev.off()

# EXPLORATORY GRAPHICS ------------

### Figure 5: VAT by BGC Association ----------

g5_df <- glucOnly %>% 
  drop_na(BGC, VAT_Rank) %>% 
  mutate(Session_Time = case_when(Session_Time == "ShortVisit" ~ "Short",
                                  Session_Time == "LongVisit0" ~ "PreC",
                                  Session_Time == "LongVisit20" ~ "20m PC",
                                  Session_Time == "LongVisit60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Short","PreC", "20m PC","60m PC"))) %>% 
  group_by(Subject_Code, Session_Time, Condition) %>% 
  summarize(BGC = mean(BGC), VAT_Rank = mean(VAT_Rank))

### Scatterplot ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure5",
    height = 7, width = 10)

ggplot(data = g5_df) +
  geom_point(aes(x = VAT_Rank, y = BGC, shape = Condition, fill = Condition), size = 3) +
  geom_smooth(aes(x = VAT_Rank, y = BGC, color = Condition, lty = Condition), 
              se = F, method = "lm", show.legend = F) + 
  facet_wrap(~ Session_Time, ncol = 4) +
  scale_color_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray75", 
                              "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                             "Artificial" = "gray95", 
                             "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
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

### Figure 6: VAT by Cognitive Scoring Association -------

vatRankCog <- g2_df %>% 
  mutate(Session_Time = case_when(Session_Time == "SV" ~ "Short",
                                  Session_Time == "LV20" ~ "20m PC",
                                  Session_Time == "LV60" ~ "60m PC")) %>% 
  mutate(Session_Time = factor(Session_Time, levels = c("Short","20m PC","60m PC"))) # %>% 
  # group_by(Subject_Code, Session_Time, Condition, Order, Test_Type) %>% 
  # summarize(FullC_T_Score = mean(FullC_T_Score), VAT_Rank = mean(VAT_Rank)) 

### pval calculation ###

pvals <- rep(NA, 8)

for (i in 1:8) {
  mme <- lme(fixed = FullC_T_Score ~ VAT_Rank * Session_Time * Order,
                   random = ~ 1 | Subject_Code,
                   data = vatRankCog %>% 
                     filter(Test_Type == tests[i]), 
             contrasts = list(Session_Time = contr.sum,
                              Order = contr.sum))
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) 
  # change to [2], [5], [6], or [8] for VAT_Rank, VAT_Rank:Session_Time, VAT_Rank:Order, and VAT_Rank:Session_Time:Order
  
}

g6_df <- vatRankCog %>% 
  group_by(Subject_Code, Condition, Test_Type) %>% 
  summarize(FullC_T_Score = mean(FullC_T_Score), VAT_Rank = mean(VAT_Rank))

### Scatterplot ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/figure6",
    height = 6, width = 11)

ggplot(data = g6_df, 
             aes(x = VAT_Rank, y = FullC_T_Score)) +
  geom_point(aes(shape = Condition, fill = Condition), size = 3) +
  geom_smooth(aes(color = Condition, lty = Condition), se = F, method = "lm", show.legend = F) +
  facet_wrap(~ Test_Type, 
             labeller = as_labeller(
                 c(AVLT = paste("AVLT p=", pvals[1], sep = ""),
                   DCCS = paste("DCCS p=", pvals[2], sep = ""),
                   FICA = paste("FICA p=", pvals[3], sep = ""),
                   LSWM = paste("LSWM p=", pvals[4], sep = ""),
                   OSD = paste("OSD p=", pvals[5], sep = ""),
                   PCPS = paste("PCPS p=", pvals[6], sep = ""),
                   PSM = paste("PSM p=", pvals[7], sep = ""),
                   `Fluid Composite` = paste("Fluid Composite p=", pvals[8], sep = ""))),
             nrow = 2) +
  scale_color_manual(values=c("Sugar" = "gray45", 
                            "Artificial" = "gray85", 
                            "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                             "Artificial" = "gray95", 
                             "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 12),
        axis.title.x = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  ylab("Fully-Corrected T-Score") + xlab("Visceral Adipose Tissue Ranking")

dev.off()

###

# # | # | # | # #
# # | # | # | # #
# | # | # | # | #
# | # | # | # | #
# | # | # | # | #
# # | # | # | # #
# # | # | # | # #

# Supplemental Figures ------------------------

# Using the 'uncorrected standard scores' as another view of the 'fully-corrected t-scores'
# All graphs will be found in the supplemental section.

### Sup. Figure 1 -------- 
# A copy of figure 2
unc_tests <- c("DCCS", "FICA","LSWM","PCPS","PSM","Fluid Composite")

g1_sup <- g2_df %>% 
  filter(Test_Type %in% unc_tests) %>% 
  mutate(Test_Type = factor(Test_Type, levels = unc_tests))

pvals <- rep(NA, 6)

for (i in 1:length(unc_tests)) {
  mme <- lme(fixed = UnC_Std_Score ~ Condition * Session_Time * Order,
             random = ~ 1 | Subject_Code,
             contrasts = 
               list(Condition = "contr.sum", 
                    Session_Time = "contr.sum", 
                    Order = "contr.sum"),
             data = g1_sup %>% 
               filter(Test_Type == unc_tests[i])
             )
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) # change to [5] for condition:session_time
}

# calculate outliers (for aesthetic on next graph)

quartiles <- g1_sup %>%
  group_by(Test_Type, Condition) %>%
  summarize(
    Q1 = quantile(UnC_Std_Score, 0.25),
    Q3 = quantile(UnC_Std_Score, 0.75),
    IQR = IQR(UnC_Std_Score)
  )

# Identify outliers
g1_outliers <- g1_sup %>%
  left_join(quartiles, by = c("Test_Type", "Condition")) %>%
  filter(UnC_Std_Score < Q1 - 1.5 * IQR | UnC_Std_Score > Q3 + 1.5 * IQR) %>% 
  mutate(Condition = factor(Condition, levels = c("Artificial", "Sugar", "Water")))

# Create graphic 
pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/supplemental1",
    height = 6, width = 11)

ggplot(data = g1_sup, aes(x = Condition, y = UnC_Std_Score, group = Condition, 
                         fill = Condition)) +
  geom_hline(yintercept = 100, lty = 5, color = "gray65") +
  geom_hline(yintercept = 130, lty = 5, color = "gray95") +
  geom_hline(yintercept = 70, lty = 5, color = "gray95") +
  geom_boxplot(outlier.shape = NA, show.legend = F) +
  geom_point(g1_outliers, 
             mapping = aes(x = Condition, y = UnC_Std_Score, group = Condition, 
                           fill = Condition, shape = Condition), 
             size = 3, show.legend = T) +
  scale_fill_manual(
    values=c("Sugar" = "gray70", 
             "Artificial" = "gray100", 
             "Water" = "gray35")) +
  scale_shape_manual(
    values = c("Sugar" = 23, 
               "Artificial" = 24, 
               "Water" = 21)) +
  xlab("") + 
  ylab("Uncorrectd Standard Score") +
  theme_bw() +
  facet_wrap(~ Test_Type, labeller = 
               as_labeller(
                 c(DCCS = paste("DCCS p=", pvals[1], sep = ""),
                   FICA = paste("FICA p=", pvals[2], sep = ""),
                   LSWM = paste("LSWM p=", pvals[3], sep = ""), 
                   PCPS = paste("PCPS p=", pvals[4], sep = ""), 
                   PSM = paste("PSM p=", pvals[5], sep = ""), 
                   `Fluid Composite` = paste("Fluid Composite p=", pvals[6], sep = ""))), 
             nrow = 2) +
  theme(strip.text.x = element_text(size = 12),
        axis.title.y = element_text(size = 12), 
        axis.title.x = element_blank(), 
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.key.size = unit(8, units = "mm"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) 

dev.off()

### Sup. Figure 2 ---------
# copy of figure 4

g2_sup <- g4_df %>% 
  filter(Test_Type %in% unc_tests) %>% 
  mutate(Test_Type = factor(Test_Type, levels = unc_tests))

## INTERACTION GRAPH

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/supplemental2",
    height = 7, width = 12)

ggplot(data = g2_sup,
       aes(x = Session_Time, y = UnC_Std_Score, group = Condition, 
           linetype = Condition, shape = Condition)) +
  stat_summary(fun = mean, geom = "line", show.legend = F, 
               mapping = aes(color = Condition)) +
  stat_summary(fun = mean, geom = "point", size = 3, 
               mapping = aes(fill = Condition)) +
  xlab("Session Time") +
  ylab("Fully-Corrected T-Score") +
  scale_color_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray85", 
                              "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                             "Artificial" = "gray95", 
                             "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
  ylab("Uncorrected Standard Score") +
  facet_wrap(~ Order + Test_Type, 
             labeller = as_labeller(c(`Short Visit First` = "Order 1", `Treatment Visit First` = "Order 2",
                                      AVLT = "AVLT", DCCS = "DCCS", FICA = "FICA", LSWM = "LSWM", OSD = "OSD", PCPS = "PCPS",
                                      PSM = "PSM", `Fluid Composite` = "Fluid Composite")),
             nrow = 2, scales = "free_x") +
  theme_bw() +
  guides(colour = guide_legend(override.aes = list(size = 3))) +
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.title.x = element_blank(), 
        legend.key.height= unit(1, 'cm'),
        legend.key.width= unit(.3, 'cm'),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 7.5))

dev.off()

### Sup. Figure 3 -------------
# copy of figure 6

### pval calculation ###

pvals <- rep(NA, 6)

for (i in 1:6) {
  mme <- lme(fixed = UnC_Std_Score ~ VAT_Rank * Session_Time * Order,
             random = ~ 1 | Subject_Code,
             data = vatRankCog %>% 
               filter(Test_Type == unc_tests[i]), 
             contrasts = list(Session_Time = contr.sum,
                              Order = contr.sum))
  
  anv <- Anova(mme, type = "III")
  pvals[i] <- sprintf("%.3f", anv$`Pr(>Chisq)`[2]) 
  # change to [2], [5], [6], or [8] for VAT_Rank, VAT_Rank:Session_Time, VAT_Rank:Order, and VAT_Rank:Session_Time:Order
  
}

g3_sup <- vatRankCog %>% 
  group_by(Subject_Code, Condition, Test_Type) %>% 
  summarize(UnC_Std_Score = mean(UnC_Std_Score), VAT_Rank = mean(VAT_Rank)) %>% 
  filter(Test_Type %in% unc_tests) %>% 
  mutate(Test_Type = factor(Test_Type, levels = unc_tests))

### Scatterplot ###

pdf("~/GlucoseCognition_Project/GlucCog Final/Outputs/figures/supplemental3",
    height = 6, width = 11)

ggplot(data = g3_sup, 
       aes(x = VAT_Rank, y = UnC_Std_Score)) +
  geom_point(aes(shape = Condition, fill = Condition), size = 3) +
  geom_smooth(aes(color = Condition, lty = Condition), se = F, method = "lm", show.legend = F) +
  facet_wrap(~ Test_Type, 
             labeller = as_labeller(
               c(DCCS = paste("DCCS p=", pvals[1], sep = ""),
                 FICA = paste("FICA p=", pvals[2], sep = ""),
                 LSWM = paste("LSWM p=", pvals[3], sep = ""),
                 PCPS = paste("PCPS p=", pvals[4], sep = ""),
                 PSM = paste("PSM p=", pvals[5], sep = ""),
                 `Fluid Composite` = paste("Fluid Composite p=", pvals[6], sep = ""))),
             nrow = 2) +
  scale_color_manual(values=c("Sugar" = "gray45", 
                              "Artificial" = "gray85", 
                              "Water" = "gray0")) +
  scale_fill_manual(values=c("Sugar" = "gray45", 
                             "Artificial" = "gray95", 
                             "Water" = "gray0")) +
  scale_linetype_manual(values = c("Sugar" = 1, 
                                   "Artificial" = 2, 
                                   "Water" = 2)) +
  scale_shape_manual(values = c("Sugar" = 23, 
                                "Artificial" = 24, 
                                "Water" = 21)) +
  theme_bw() +
  theme(legend.position = "bottom", 
        strip.text.x = element_text(size = 12),
        axis.title.x = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_blank()) +
  guides(colour = guide_legend(override.aes = list(size=5))) + 
  ylab("Uncorrected Std Score") + xlab("Visceral Adipose Tissue Ranking")

dev.off()




