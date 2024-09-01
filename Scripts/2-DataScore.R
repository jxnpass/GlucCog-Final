library(tidyverse)

glucCog  <- read_csv("GlucCog Final/Cleaned Data/DataPrepOutput.csv")[,-1]

# Computing a T Score for Supplemental Tests (AVL and OSD) --------

AVL_sample <- data.frame(
  MIN_AGE = rep(c(18,30,40), each = 3),
  MAX_AGE = rep(c(29,39,49), each = 3),
  SEX = rep(c("Male", "Female", "General"), 3),
  MEAN = c(23.95, 25.57, 24.92, 23.71, 25.11, 24.71, 23.67, 25.10, 24.39),
  SD = c(11.59, 6.70, 8.45, 7.75, 7.02, 7.21, 9.68, 9.85, 9.78))

### ADD GENERAL GENDER to sample data

OSD_sample <- data.frame(
  MIN_AGE = rep(c(18,30,40), each = 3),
  MAX_AGE = rep(c(29,39,49), each = 3),
  SEX = rep(c("Male", "Female", "General"), 3),
  MEAN = c(89.37, 85.63, 87.14, 85.61, 79.97, 81.56, 80.26, 82.59, 81.38),
  SD = c(40.60, 21.69, 28.37, 23.41, 22.01, 22.51, 35.25, 24.49, 29.36))
  
norm_Scores <- function(row_data) {

  sex <- row_data$Sex
  if (is.na(sex)) {sex = "General"}
  age <- row_data$Age
  raw <- row_data$Raw_Score
  test <- row_data$Test_Type
  

  if (is.na(test)) {
    t_score <- row_data$FullC_T_Score
  }
  else if (is.na(age)) {
    t_score <- row_data$FullC_T_Score
  }
  else if (test == "Auditory Verbal Learning Test") {
    curr_group <- AVL_sample %>% 
      filter(SEX == sex, age >= MIN_AGE & age <= MAX_AGE)
    t_score <- 10* ((raw - curr_group$MEAN) / curr_group$SD) + 50
  }
  else if (test == "Oral Symbol Digit") {
    curr_group <- OSD_sample %>% 
      filter(SEX == sex, age >= MIN_AGE & age <= MAX_AGE)
    t_score <- 10 * ((raw - curr_group$MEAN) / curr_group$SD) + 50
  }
  else {
    t_score <- row_data$FullC_T_Score
  }
  return(t_score)
  
}

for (i in 1:nrow(glucCog)) {
  glucCog$FullC_T_Score[i] = norm_Scores(glucCog[i,])
}

### Remove score outliers -------

glucCog <- glucCog[-3045,] # subject 146 has a very odd PCPS score


### Export Data ----- 

write.csv(x = glucCog, file = "GlucCog Final/Cleaned Data/DataPrepOutput.csv")

