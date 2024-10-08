# source("~/GlucoseCognition_Project/GlucCog Final/Scripts/DataMath.R")

library(tidyverse)
library(gtsummary)
library(gtable)
library(cowplot)
library(nlme)
library(car)
library(DescTools)
library(pairwiseCI)
library(reshape2)

# For nlme::lme and car::Anova later on
options(contrasts = c("contr.sum", "contr.poly"))

glucCog <- read_csv("GlucCog Final/Cleaned Data/glucCog.csv")[-1]
sub_order <- as.vector(glucCog$Subject_Code %>% unique())
glucCog <- glucCog %>% mutate(Subject_Code = factor(Subject_Code, levels = sub_order))

### Set up data so that each subject has one row (no duplication of characteristics) ---------

char <- glucCog %>% 
  select(Subject_Code, Condition, everything()) %>% 
  select(-BGC,-contains('Date'),-contains('Score'),-Session_Time, -Order,-Test_Type,-National_Percentile,-Theta,-SE,-Cog_Series) %>% 
  unique() %>% 
  mutate(Married = ifelse(Married == 0,F,T),
         Medications = ifelse(Medications == 0,F,T),
         Employed = ifelse(Employed == 0,F,T)) %>% 
  mutate(If_employed_number_hours = ifelse(is.na(If_employed_number_hours), 0, If_employed_number_hours)) %>% 
  mutate(Condition = factor(Condition, levels = c("Artificial", "Water", "Sugar")))

### Table 1: demographics ----------

dems <- char %>% 
  select(Condition, Sex, Age, Race, Medications, Married, Employed, Height, Weight, BMI) %>%
  tbl_summary(
    by = Condition,
    statistic = list(all_continuous()  ~ c("{mean} ({sd})",
                                           "{median} [{min}, {max}]"),
                     all_categorical() ~ "{n}    ({p}%)"),
    digits = list(all_continuous()  ~ c(2, 3),
                  all_categorical() ~ c(0, 1)),
    type = list(
     #             Sex ~ "categorical",
      Age ~ "continuous2",
    #              Race ~ "categorical",
      Medications ~ "categorical",
      Married ~ "categorical",
      Employed ~ "categorical",
      Weight ~ "continuous2",
      Height ~ "continuous2",
      BMI ~ "continuous2"),
    label  = list(Age ~ "Age (Years)",
                  Weight ~ "Weight (kg)",
                  Height ~ "Height (cm)")
  ) %>%
  modify_header(label = "**Variable**",
                all_stat_cols() ~ "**{level}**<br>N = {n}") %>%
  #modify_caption("Participant Demographics") %>%
  bold_labels() %>% 
  add_overall(
    last = T,
    # The ** make it bold
    col_label = "**Total**<br>N = {N}"
  )

# Optional: I wanted to "Americanize" height and weight so I did a little
# data manipulation to make sure metric system measurements look okay

america <- char %>% 
  select(Subject_Code, Height, Weight, BMI) %>% 
  mutate(Weight_lbs = Weight * 2.205,
         Height_ft = Height * 0.0328) %>% 
  mutate(Height_ft_simple = floor(Height_ft)) %>% 
  mutate(Height_in = (Height_ft - floor(Height_ft)) * 12) %>% 
  select(-Height, -Weight) 

# View(america)

range(america$Weight_lbs)
range(america$Height_ft)

### One-way ANOVA for demographics
dg_cols <- colnames(char)[c(3:5,7:8,10:13)]
dg_pvals <- data.frame(cols = dg_cols, type = NA, test_stat = NA, p = NA)

for (i in 1:length(dg_cols)) {
  label <- dg_cols[i]
  if (i %in% c(4,6:9)) {
    chi_df = data.frame(Condition = char$Condition,
                        y = char[label])
    result <- chisq.test(x = chi_df$Condition,
                         y = chi_df[,2])
    dg_pvals$test_stat[i] <- result$statistic
    dg_pvals$p[i] <- result$p.value
    dg_pvals$type[i] = 'Chi-Sq'
  }
  else {
    formula_str <- paste(label, "~ Condition")
    my_lm <- lm(formula_str, data = char)
    result <- anova(my_lm)
    dg_pvals$test_stat[i] <- result$`F value`[1]
    dg_pvals$p[i] <- result$`Pr(>F)`[1]
    dg_pvals$type[i] <- 'F-stat'
  }
}

# View(dg_pvals)

### Table 2: Body Composition ----------

char2 <- char %>% 
  mutate(Lean_mass_kg = Lean_Mass_g / 1000, 
         fat_mass_kg = fat_mass_g / 1000, 
         BMC_kg = BMC_g / 1000
  ) %>% 
  select(Condition, Lean_mass_kg, fat_mass_kg, BMD_g_cm, BMC_kg, percent_fat, VAT_g, VAT_volume)

bc <- char2 %>% 
    tbl_summary(
    by = Condition,
    statistic = list(all_continuous()  ~ c("{mean} ({sd})",
                                           "{median}",
                                           "[{min}, {max}]"),
                     all_categorical() ~ "{n}    ({p}%)"),
    digits = list(all_continuous()  ~ c(2, 3),
                  all_categorical() ~ c(0, 1)),
    type = all_continuous() ~ "continuous2",
    label  = list(Lean_mass_kg ~ "Lean Mass (kg)",
                  fat_mass_kg ~ "Fat Mass (kg)",
                  BMD_g_cm ~ "Bone Mineral Density (g/cm^3)",
                  BMC_kg ~ "Bone Mineral Count (g)",
                  percent_fat ~ "Body Fat Percentage",
                  VAT_g ~ "VAT (g)",
                  VAT_volume ~ paste("VAT (g/cm^3)")
    )
  ) %>%
  modify_header(label = "**Variable**",
                all_stat_cols() ~ "**{level}**<br>N = {n}") %>%
  #modify_caption("Participant Demographics") %>%
  bold_labels() %>% 
  add_overall(
    last = T,
    # The ** make it bold
    col_label = "**Total**<br>N = {N}"
  )

### One-way ANOVA for body composition 
bc_cols <- colnames(char2)[-1]
bc_pvals <- data.frame(cols = bc_cols, Fstat = NA, p = NA)

for (i in 1:length(bc_cols)) {
  label <- bc_cols[i]
  formula_str <- paste(label, "~ Condition")
  my_lm <- lm(formula_str, data = char2)
  result <- anova(my_lm)
  bc_pvals$Fstat[i] <- result$`F value`[1]
  bc_pvals$p[i] <- result$`Pr(>F)`[1]
}

# VAT_g and VAT_vol are heavy right-skewed, so use kw test instead 
bc_pvals$Fstat[6] <- kruskal.test(VAT_g ~ Condition, data = char2)$statistic
bc_pvals$p[6] <- kruskal.test(VAT_g ~ Condition, data = char2)$p.value
bc_pvals$Fstat[7] <- kruskal.test(VAT_volume ~ Condition, data = char2)$statistic
bc_pvals$p[7] <- kruskal.test(VAT_volume ~ Condition, data = char2)$p.value


bc_pvals$Fstat <- round(bc_pvals$Fstat, digits = 3)
bc_pvals$p <- round(bc_pvals$p, digits = 3)

# View(bc_pvals)


### Table 3: Visual Analog Scale Ratings --------
# this data represented the ratings subjects gave to their drinks and experience

vas_df <- char %>% select(Condition, contains("VAS"))

vas <- vas_df %>%
  tbl_summary(
    by = Condition,
    statistic = list(all_continuous()  ~ c("{mean} ({sd})",
                                           "{median}",
                                           "[{min}, {max}]"),
                     all_categorical() ~ "{n}    ({p}%)"),
    digits = list(all_continuous()  ~ c(2, 3),
                  all_categorical() ~ c(0, 1)),
    type = all_continuous() ~ "continuous2",
    label  = list(VAS_like ~ "Like",
                  VAS_sweet ~ "Sweet",
                  VAS_sour ~ "Sour",
                  VAS_color ~ "Color")
  ) %>%
  modify_header(label = "**Variable**",
                all_stat_cols() ~ "**{level}**<br>N = {n}") %>%
  #modify_caption("Participant Demographics") %>%
  bold_labels() %>% 
  add_overall(
    last = T,
    # The ** make it bold
    col_label = "**Total**<br>N = {N}"
  )

vas_cols <- vas_df[-1] %>% colnames()

vas_pvals <- data.frame(cols = vas_cols, Fstat = NA, p = NA)

for (i in 1:length(vas_cols)) {
  label <- vas_cols[i]
  formula_str <- paste(label, "~ Condition")
  my_lm <- lm(formula_str, data = vas_df)
  result <- anova(my_lm)
  vas_pvals$Fstat[i] <- result$`F value`[1]
  vas_pvals$p[i] <- result$`Pr(>F)`[1]
}

vas_pvals$Fstat <- round(vas_pvals$Fstat, digits = 3)
vas_pvals$p <- round(vas_pvals$p, digits = 4)

# View(vas_pvals)

# Pairwise differences

Bonf <- function(data, VAS_type) {
  
  # prep data
  vas_data = data %>% 
    select(Condition, VAS_type) %>% 
    rename(Response = VAS_type) %>% 
    drop_na()
  
  # calculate p-values
  p_tb <- pairwise.t.test(x = vas_data$Response, 
                  g = vas_data$Condition,
                  p.adjust.method = 'bonferroni',
                  alternative = 'two.sided')
  p_tb <- p_tb$p.value
  p_tb <- p_tb %>% melt() %>% 
    mutate(Comparison = paste(Var1, Var2, sep = "-")) %>% 
    rename(P_val = value) %>% 
    select(Comparison, P_val) %>% 
    drop_na()

  # calculate pairwise CIs
  row_names <- p_tb$Comparison
  pw <- pairwiseCI(Response ~ Condition, data = vas_data, method = "Param.diff",
                   alternative = 'two.sided', conf.level=1-0.05/3, var.equal = F)
  pw_tb <- pw$byout
  pw_tb <- pw_tb[[1]]
  tb <- pw_tb %>% 
    as_tibble() %>% 
    select(estimate, lower, upper) %>% 
    cbind(p_tb) %>% 
    select(Comparison, everything())
  
  return(tb)  
  
}

pw_like <- Bonf(char,'VAS_like') %>% mutate(Type = "Like")
pw_sweet <- Bonf(char, 'VAS_sweet') %>% mutate(Type = "Sweet")
pw_sour <- Bonf(char, 'VAS_sour') %>% mutate(Type = "Sour")
pw_color <- Bonf(char, "VAS_color") %>% mutate(Type = "Color")

pw_df <- rbind(pw_like, pw_sweet, pw_sour, pw_color) %>% 
  mutate(estimate = round(estimate, digits = 4),
         lower = round(lower, digits = 4),
         upper = round(upper, digits = 4),
         P_val = round(P_val, digits = 4)) %>% 
  select(Type, everything() )

# View(pw_df)

### Table 4: ANOVA ------ 

glucCog.f <- glucCog %>% 
  mutate(Session_Time = factor(Session_Time, 
                               levels = c("ShortVisit","LongVisit20","LongVisit60")),
         Condition = factor(Condition, 
                            levels = c("Water", "Artificial", "Sugar"))) %>% 
  filter(Test_Type != "Cognition Fluid Composite v1.1")


# Since score is normed, I do not need to include Test Type as a variable
glucCog_lme <- lme(fixed = FullC_T_Score ~ Condition*Session_Time,
                   random = ~1|Subject_Code, 
                   data = glucCog.f,
                   contrasts = list(Condition = contr.sum, Session_Time = contr.sum))
glucCog_anova <- Anova(glucCog_lme, type = "III")

# View(glucCog_anova)

### Outputs of tables filed into tables.docx and tables.pdf

