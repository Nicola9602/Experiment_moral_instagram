# Original descriptive summaries and observed response plots.

################################################################################
# Analysis of Yes/No Responses
################################################################################

# Filter data for rows where Question_New == "Yes/No" and select relevant columns
#--------------------------------------------------------

YN <- df_I_S %>%
    filter(question_new == "Yes/No") %>%
    dplyr::select(responseid, risk, answer, dilemma_type, group, sex, question)

YN$affirmative_response_total <- ifelse(tolower(YN$answer) %in% c("si", "sì"), 1, 0)

affirmative_percentage <- YN %>%
  group_by(dilemma_type, group) %>%
  summarise(
    total_responses = n(),
    affirmative_responses = sum(affirmative_response_total, na.rm = TRUE),
    percentage_affirmative = (affirmative_responses / total_responses) * 100
  )

print(affirmative_percentage)

ggplot(data = YN) + 
  aes(x = interaction(dilemma_type, group), y = affirmative_response_total) +
  stat_summary(fun = mean, geom = "bar", fill = "skyblue") +
  labs(y = "Percentage Affiramtive", title = "Mean Affirmative Reponses by Dilemma") +
  theme_minimal()


#=======================================================================================================
# lmer for Fillers
#=======================================================================================================

# Filter to keep only the filler
df_F <- df %>%
  filter(question_new != "Dilemma_Reading") %>%
  filter(dilemma_type == "Filler")


# Analysis of Yes/No Responses — Fillers
#=======================================================================================================

# Filter Yes/No rows and select relevant columns
YN_F <- df_F %>%
  filter(question_new == "Yes/No") %>%
  dplyr::select(risk, answer, dilemma_type, group, responseid)

# Create binary variable for affirmative responses
YN_F$affirmative_response_total <- ifelse(tolower(YN_F$answer) %in% c("si", "sì"), 1, 0)

# Summarize affirmative percentages
affirmative_percentage_F <- YN_F %>%
  group_by(dilemma_type, group) %>%
  summarise(
    total_responses = n(),
    affirmative_responses = sum(affirmative_response_total, na.rm = TRUE),
    percentage_affirmative = (affirmative_responses / total_responses) * 100
  )

print(affirmative_percentage_F)

summary_YN_F <- YN_F %>%
  group_by(dilemma_type, group, risk) %>%
  summarise(
    prop_yes = mean(affirmative_response_total),
    n = n(),
    se = sqrt(prop_yes * (1 - prop_yes) / n),
    ci_lower = prop_yes - 1.96 * se,
    ci_upper = prop_yes + 1.96 * se, 
   )

# Plot
ggplot(data = YN_F) + 
  aes(x = interaction(dilemma_type, group), y = affirmative_response_total) +
  stat_summary(fun = mean, geom = "bar", fill = "skyblue") +
  labs(y = "Percentage Affirmative", title = "Mean Affirmative Responses (Filler)") +
  theme_minimal()
