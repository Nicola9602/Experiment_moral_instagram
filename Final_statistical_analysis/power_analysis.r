packages <- c(
  "boot", "MASS", "robustlmm", "afex", "dplyr", "readr", "compute.es",
  "car", "ggplot2", "multcomp", "pastecs", "WRS2", "tidyr", "readxl",
  "DescTools", "knitr", "writexl", "rcompanion", "lsr", "ARTool", "lme4", 
  "sjPlot", "interactions", "mixedpower", "vscDebugger", "Matrix", "jsonlite"
)


lapply(packages, library, character.only = TRUE)

##############################################################################
# Dataset loading and preparation
##############################################################################

I_dilemmas <- read_excel("pilot_I.xlsx")
Q_dilemmas <- read_excel("pilot_Q.xlsx")
cat("I_dilemmas:", dim(I_dilemmas), "\n")
cat("Q_dilemmas:", dim(Q_dilemmas), "\n")
cat("I_dilemmas col names:", colnames(I_dilemmas), "\n")
cat("Q_dilemmas col names:", colnames(Q_dilemmas), "\n")

I_dilemmas[I_dilemmas == "nan"] <- NA
# Lower case all column names in both 
colnames(I_dilemmas) <- tolower(colnames(I_dilemmas))
colnames(Q_dilemmas) <- tolower(colnames(Q_dilemmas))

# Find common columns in both dataframes
common_cols <- intersect(colnames(I_dilemmas), colnames(Q_dilemmas))

# Subset both dataframes to only include common columns

I_dilemmas_common <- I_dilemmas[, common_cols] # nolint
Q_dilemmas_common <- Q_dilemmas[, common_cols]

# Stack the datasets

df <- rbind(I_dilemmas_common, Q_dilemmas_common)
print(colnames(df))
df$responseid <- as.numeric(df$responseid)


# add 100 to all participants with instagram group so that they are not confused with the other group
df <- df %>%
  mutate(responseid = if_else(group == "Instagram", responseid + 100, responseid))
df$sex <- tolower(df$sex)

sex_df <- df %>%
  distinct(responseid, sex)

# Filter to keep only the I and S 
df_I_S <- df %>%
  filter(question_new != "Dilemma_Reading") %>%
  filter(dilemma_type %in% c("I", "S" ))


# ==================================================================
# Power on asnwer ~ DV_type (question_new)
# ==================================================================

df <- df_I_S  %>%
  filter(question_new == "Yes/No") %>%
  mutate(answer = as.integer(tolower(answer) %in% c("si", "sì"))) 
          
df$answer <- as.integer(df$answer)

df <- within(df, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +

})


mlmAll <- lmer(
  answer ~ c.group + (1 | responseid) + (1 | dilemma_type),
  data = df,
  control = lmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)

powertestAll <- mixedpower(
  model = mlmAll,
  data = df,
  fixed_effects = c("c.group"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

as.data.frame(powertestAll)
multiplotPower(powertestAll)


# ==================================================================
# Yes No
# ==================================================================


YN <- df_I_S %>%
    filter(question_new == "Yes/No") %>%
    dplyr::select(responseid, risk, answer, dilemma_type, group, sex)

YN$affirmative_response_total <- ifelse(tolower(YN$answer) %in% c("si", "sì"), 1, 0)

affirmative_percentage <- YN %>%
  group_by(dilemma_type, group) %>%
  summarise(
    total_responses = n(),
    affirmative_responses = sum(affirmative_response_total, na.rm = TRUE),
    percentage_affirmative = (affirmative_responses / total_responses) * 100
  )

#Filter YN to only keep 16 participants 

YN <- YN %>%
    filter((responseid >= 1 & responseid <= 8) |
          (responseid >= 101 & responseid <= 108))


### Scale variables ###
df <- within(YN, {
  dependent_var <- "affirmative_response_total"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +

  # Standardize continuous predictors which I don't have here
#   c.asso <- scale(asso_rating)
#   c.skill <- scale(test_score)
#   c.bias <- scale(bias)
})

# Mixed logistic model
mlm <- glmer(
  affirmative_response_total ~ c.group +
    (1 | responseid),
  family = binomial,
  data = df,
  control = glmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)

# Mixed logistic model
mlm <- glmer(
  affirmative_response_total ~ c.group * c.dilemma * c.risk +
    (1 | responseid),
  family = binomial,
  data = df,
  control = glmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)


summary(mlm)

# Don't do outlier removal because I don't have continous data 

# # Outlier detection based on residuals
# df$residuals <- residuals(
#   mlm,
#   type = if (isGLMM(mlm)) "deviance" else "response",
#   scaled = TRUE
# )

# # Remove outliers
# df1 <- df[df$residuals > -2.5 & df$residuals < 2.5, ]

# # Re-scale continuous variables after outlier removal
# df1 <- within(df1, {
#   dependent_var <- "area350450"
#   c.asso <- scale(asso_rating)
#   c.skill <- scale(test_score)
#   c.bias <- scale(bias)
# })

# # Refit model on cleaned dataset
# mlm1 <- lmer(
#   area350450 ~ c.context * c.relevance * c.laterality * c.skill +
#     c.repetition +
#     (1 | subject_stfile) +
#     (1 | probe_str_) +
#     (1 | Electrode),
#   REML = TRUE,
#   data = df1,
#   control = lmerControl(
#     optCtrl = list(maxfun = 20000),
#     optimizer = "bobyqa"
#   )
# )

# summary(mlm1)

# Probe 2-way interactions
probe_interaction(mlm, pred = c.group, modx = c.dilemma, digits = 3)
probe_interaction(mlm, pred = c.group, modx = c.risk, digits = 3)
probe_interaction(mlm, pred = c.dilemma, modx = c.risk, digits = 3)

# Probe 3-way interactions
probe_interaction(mlm, pred = c.group, modx = c.dilemma, mod2 = c.risk, digits = 3)

### Power analysis ###
#devtools::install_github("DejanDraschkow/mixedpower")
library(mixedpower)

powertest <- mixedpower(
  model = mlm,
  data = df,
  fixed_effects = c("c.group"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

powertest <- mixedpower(
  model = mlm,
  data = df,
  fixed_effects = c("c.group", "c.dilemma", "c.risk"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

as.data.frame(powertest)
multiplotPower(powertest)

#========================================================================

#Exclude Dilemma Reading 
AVMA <- df_I_S %>%
  filter(!question_new %in% c('Dilemma_Reading', 'Mood', 'Yes/No')) %>%
  filter(dilemma_type %in% c("I", "S" ))


#========================================================================
# Arousal 
#========================================================================
AD <- AVMA %>%
  filter(question_new == 'Arousal')

AD <- AD %>%
    filter((responseid >= 1 & responseid <= 8) |
          (responseid >= 101 & responseid <= 108))
AD$answer <- as.integer(AD$answer)

df <- within(AD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +
})


mlmAD <- lmer(
  answer ~ c.group * c.dilemma * c.risk +
    (1 | responseid),
  data = df,
  control = lmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)

powertestAD <- mixedpower(
  model = mlmAD,
  data = df,
  fixed_effects = c("c.group", "c.dilemma", "c.risk"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

as.data.frame(powertestAD)
multiplotPower(powertestAD)

#========================================================================
# Valence
#========================================================================
VD <- AVMA %>%
  filter(question_new == 'Valence')

VD <- VD %>%
    filter((responseid >= 1 & responseid <= 8) |
          (responseid >= 101 & responseid <= 108))
VD$answer <- as.integer(VD$answer)
df <- within(VD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +
})


mlmVD <- lmer(
  answer ~ c.group * c.dilemma * c.risk +
    (1 | responseid),
  data = df,
  control = lmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)

powertestVD <- mixedpower(
  model = mlmVD,
  data = df,
  fixed_effects = c("c.group", "c.dilemma", "c.risk"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

as.data.frame(powertestVD)
multiplotPower(powertestVD)

#========================================================================
# Moral Acceptability 
#========================================================================


MAD <- AVMA %>%
  filter(question_new == 'Moral_Acceptability')

MAD <- MAD %>%
    filter((responseid >= 1 & responseid <= 8) |
          (responseid >= 101 & responseid <= 108))
MAD$answer <- as.integer(MAD$answer)
df <- within(MAD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +
})


mlmMAD <- lmer(
  answer ~ c.group * c.dilemma * c.risk +
    (1 | responseid),
  data = df,
  control = lmerControl(
    optCtrl = list(maxfun = 20000),
    optimizer = "bobyqa"
  )
)

powertestMAD <- mixedpower(
  model = mlmMAD,
  data = df,
  fixed_effects = c("c.group", "c.dilemma", "c.risk"),
  simvar = "responseid",
  steps = seq(60, 120, by=10), # this is the number of participants 
  critical_value = 2,
  n_sim = 1000
)

as.data.frame(powertestMAD)
multiplotPower(powertestMAD)