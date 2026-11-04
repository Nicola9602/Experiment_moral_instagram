packages <- c(
  "boot", "MASS", "robustlmm", "afex", "dplyr", "readr", "compute.es",
  "car", "ggplot2", "multcomp", "pastecs", "WRS2", "tidyr", "readxl",
  "DescTools", "knitr", "writexl", "rcompanion", "lsr", "ARTool", "lme4",
  "sjPlot", "DHARMa", "emmeans", "scales", "brms", "BH", "ordinal", "modelsummary",
  "jtools", "ggdist", "patchwork"
)

# Check which packages are missing
missing <- packages[!packages %in% rownames(installed.packages())]
if(length(missing) > 0) {
  cat('Installing missing packages...\n')
  install.packages(missing, repos='http://cran.r-project.org', quiet=TRUE)
  cat('Installation complete!\n')
  cat('Installed:', paste(missing, collapse=', '), '\n')
} else {
  cat('All packages already installed!\n')
}

lapply(packages, library, character.only = TRUE)

##############################################################################
# Dataset loading and preparation
##############################################################################

I_dilemmas <- read_excel('I_dilemmas.xlsx')
Q_dilemmas <- read_excel('Q_dilemmas.xlsx')
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


YN$dilemma_type <- as.factor(YN$dilemma_type)
YN$group <- as.factor(YN$group)
YN$risk <- as.factor(YN$risk)
YN$answer <- as.factor(YN$answer)
YN$question <- as.factor(YN$question)
# YN$affirmative_response_total <- as.factor(YN$affirmative_response_total)


# 3. Linear mixed model 
#---------------------------------------------------------

#Try different model complexities to choose the most adapt which is going to be the most complex
# the data can afford 

dfYN <- within(YN, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +

})

# 1 model comparison 
ctrl <- glmerControl(
  optimizer = "bobyqa",
  optCtrl = list(maxfun = 2e5)
)

m_ri <- glmer(
  answer ~ 1 +
    (1 | responseid),
  family = binomial,
  data = dfYN,
  control = ctrl
)

m_rs_risk <- glmer(
  answer ~ 1 +
    (1 + c.risk || responseid),
  family = binomial,
  data = dfYN,
  control = ctrl
)

m_rs_risk_dilemma <- glmer(
  answer ~ 1 +
    (1 + c.risk + c.dilemma || responseid),
  family = binomial,
  data = dfYN,
  control = ctrl
)

mods <- list(
  "Random intercept" = m_ri,
  "RI + risk slope" = m_rs_risk,
  "RI + risk + dilemma slopes" = m_rs_risk_dilemma
)

tab_re <- data.frame(
  Model = names(mods),
  npar = sapply(mods, function(x) attr(logLik(x), "dfYN")),
  logLik = sapply(mods, logLik),
  AIC = sapply(mods, AIC),
  BIC = sapply(mods, BIC)
)

kable(tab_re, digits = 2, caption = "Comparison of random-effects structures")

anova(m_ri, m_rs_risk, m_rs_risk_dilemma)

# 2 Final model 

m_main <- glmer(
  answer ~ c.group + c.risk + c.dilemma +
    (1 + c.risk + c.dilemma || responseid),
  family = binomial,
  data = dfYN,
  control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
)
summary(m_main)
confint(m_main, parm="beta_", method = "Wald")

## 1) basic estimation checks
performance::check_convergence(m_main)
lme4::isSingular(m_main, tol = 1e-4)

## 2) collinearity
performance::check_collinearity(m_main)

## 3) dispersion + simulation-based residual diagnostics
performance::check_overdispersion(m_main)

sim <- DHARMa::simulateResiduals(m_main, n = 1000)
plot(sim)
DHARMa::testUniformity(sim)
DHARMa::testDispersion(sim)
DHARMa::testOutliers(sim)

## optional, if observations have a meaningful order in time/trials
# DHARMa::testTemporalAutocorrelation(sim, time = df$trial_order)

## 4) This in case checks if there is a simpler model available and tells you whether you could use that or not. 
drop1(m_main, test = "Chisq")


## 6) optional but recommended descriptive fit index
performance::r2_nakagawa(m_main)

anova(m_main)


# 7) Estimated marginal means on the response scale = predicted probabilities

# Now since my values have been effect coded this has to be accounted for along two dimensions:
# 7.1) first I have to tell emmeans that those are categorical and not numerical variables
# specificially I will ask each risk * dilemma combination separately within each group

emm <- emmeans(m_main,
~ c.risk * c.dilemma | c.group, 
at = list(
  c.group = c(-0.5, 0.5),
  c.dilemma = c(-0.5, 0.5),
  c.risk = c(-0.5, 0.5)
  ),
  type = "response" # transforms values to probabilities 
)

# 7.2) however the output will not be readable yet because it is still effect coded 
# so we have to explain R what these effect code mean 

relabel_emm <- function(x){
emm_df <- as.data.frame(x)
emm_df$c.group <- factor(emm_df$c.group,
                        levels = c(-0.5, 0.5),
                        labels = c("Instagram", "Qualtrics"))
emm_df$c.dilemma <- factor(emm_df$c.dilemma,
                        levels = c(-0.5, 0.5),
                        labels = c("Incidental", "Instrumental"))
emm_df$c.risk <- factor(emm_df$c.risk,
                        levels = c(-0.5, 0.5),
                        labels = c("Without Involvement", "With Involvement"))         
emm_df
}              

emm_df <- relabel_emm(emm)


relabel_emm_prob <- function(x, response_var = "answer") {
  
  emm_df <- as.data.frame(confint(x))
  
  print(names(emm_df))  # useful diagnostic line
  
  if (!response_var %in% names(emm_df)) {
    stop(
      "The response-category column '", response_var, "' is missing. ",
      "Your emmeans object was probably created without `~ answer | ...`. ",
      "Use: emmeans(modAD_ord1, ~ answer | c.risk * c.dilemma * c.group, mode = 'prob')"
    )
  }
  
  emm_df$c.group <- factor(
    emm_df$c.group,
    levels = c(-0.5, 0.5),
    labels = c("Instagram", "Qualtrics")
  )
  
  emm_df$c.dilemma <- factor(
    emm_df$c.dilemma,
    levels = c(-0.5, 0.5),
    labels = c("Incidental", "Instrumental")
  )
  
  emm_df$c.risk <- factor(
    emm_df$c.risk,
    levels = c(-0.5, 0.5),
    labels = c("Without Involvement", "With Involvement")
  )
  
  emm_df[[response_var]] <- factor(
    emm_df[[response_var]],
    levels = sort(unique(emm_df[[response_var]]))
  )
  
  emm_df
}


summary(emm_df)
# pairs(emm_df)

# 8) Plot
ggplot(emm_df, aes(x=c.dilemma, y=prob, fill=c.group)) +
  geom_col(position = position_dodge(width=0.915)) +
facet_wrap(~c.risk) +
scale_y_continuous(
  limits = c(0,1),
  breaks = seq(0,0.8, by=0.2),
  labels = label_percent(accuracy=1),
  expand = c(0,0) # zero touches the x-axis
) +
labs(
    x = "Dilemma type",
    y = "Predicted probability of yes responses",
    fill = "Group",
    title = "Percentage of Utilitarian Choices"
  )


###################################################################################
# Analysis of Arousal / Valence / Moral Acceptability 
###################################################################################
# Data Filtering 
#--------------------------------------------------------
#Exclude Dilemma Reading 
AVMA <- df_I_S %>%
  filter(!question_new %in% c('Dilemma_Reading', 'Mood', 'Yes/No')) %>%
  filter(dilemma_type %in% c("I", "S" ))


AD <- AVMA %>%
  filter(question_new == 'Arousal')

VD <- AVMA %>%
  filter(question_new == 'Valence')

MAD <- AVMA %>%
  filter(question_new == 'Moral_Acceptability')


#=======================================================================================================
# lmer for Arousal (AD)
#=======================================================================================================

# 1. Data Preparation
#---------------------------------------------------------
AD$dilemma_type <- as.factor(AD$dilemma_type)
AD$group <- as.factor(AD$group)
AD$risk <- as.factor(AD$risk)
AD$sex <- as.factor(AD$sex)
AD$answer <- as.numeric(AD$answer)

# 2. Count non-finite values in AD$answer
#---------------------------------------------------------
non_finite_count <- sum(!is.finite(as.numeric(AD$answer)))
print(non_finite_count)
# Identify non-numeric or problematic values
non_numeric_values <- AD$answer[!is.finite(as.numeric(AD$answer))]
print(non_numeric_values)

# Remove rows with non-numeric values in AD$answer
AD <- AD %>%
  filter(!is.na(as.numeric(answer)))

# 3. Linear mixed model 
#---------------------------------------------------------

# 3.1) effect coding 
ADdf <- within(AD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +

})

ADdf$answer <- ordered(ADdf$answer)

# Model comparison 
modAD_ri <- clmm(
  answer ~ 1 + (1 | responseid),
  data = ADdf,
  link = "logit",
  threshold = "flexible"
)

modAD_rs_dilemma <- clmm(
  answer ~ 1 + (1 + c.dilemma | responseid),
  data = ADdf,
  link = "logit",
  threshold = "flexible"
)

modAD_rs_risk_dilemma <- clmm(
  answer ~ 1 + (1 + c.dilemma + c.risk | responseid),
  data = ADdf,
  link = "logit",
  threshold = "flexible"
)

modsAD <- list(
  "Random intercept" = modAD_ri,
  "RI + dilemma slope" = modAD_rs_dilemma,
  "RI + dilemma + risk slopes" = modAD_rs_risk_dilemma
)

tab_reAD <- data.frame(
  Model = names(modsAD),
  logLik = sapply(modsAD, logLik),
  AIC = sapply(modsAD, AIC),
  BIC = sapply(modsAD, BIC)
)

knitr::kable(tab_reAD, digits = 2, caption = "Comparison of random-effects structures")

anova(modAD_ri, modAD_rs_dilemma, modAD_rs_risk_dilemma)


# 1 Cumulative Link Mixed Model  
modAD_ord1 <- clmm(
  answer ~ c.group + c.risk + c.dilemma +
  (1 + c.risk + c.dilemma | responseid),
  data = ADdf,
  link = "logit",
  threshold = "flexible"
)
summary(modAD_ord1)

coefsAD <- coef(summary(modAD_ord1))

lowerAD <- coefsAD[, "Estimate"] - 1.96 * coefsAD[, "Std. Error"]
upperAD <- coefsAD[, "Estimate"] + 1.96 * coefsAD[, "Std. Error"]

cbind(coefsAD, CI_low = lowerAD, CI_high = upperAD)

performance::r2_nakagawa(modAD_ord1)

clm_checkAD <- clm(
  answer ~ c.group + c.risk + c.dilemma,
  data = ADdf,
  link = "logit",
  threshold = "flexible"
)

nominal_test(clm_checkAD)
 
# 3 Plotting 
emmAD_mean <- emmeans(modAD_ord1,
~ c.risk * c.dilemma | c.group, 
at = list(
  c.group = c(-0.5, 0.5),
  c.dilemma = c(-0.5, 0.5),
  c.risk = c(-0.5, 0.5)
  ),
  mode = "mean.class" 
)

emmAD_prob <- emmeans(
  modAD_ord1,
  ~ answer | c.risk * c.dilemma * c.group,
  at = list(
    c.group   = c(-0.5, 0.5),
    c.dilemma = c(-0.5, 0.5),
    c.risk    = c(-0.5, 0.5)
  ),
  mode = "prob"
)

# 4. relabeling 
emm_dfAD_mean <- relabel_emm(emmAD_mean)
emm_dfAD_prob <- relabel_emm_prob(emmAD_prob)


# 5. Plot 
# 5.1) Model plot mean + pred prob
p_meanAD <- ggplot(
  emm_dfAD_mean,
  aes(
    x = c.dilemma,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Arousal Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean arousal response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )
p_meanAD

p_probAD <- ggplot(
  emm_dfAD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.dilemma),
    colour = c.group,
    linetype = c.dilemma
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Arousal Response Probabilities",
    x = "Arousal response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Dilemma type"
  ) +
  guides(
    colour = "none",   # removes duplicate Group colour legend
    linetype = guide_legend(title = "Dilemma type")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probAD
p_combinedAD <- p_meanAD + p_probAD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )
p_probAD 
p_combinedAD

ggsave(
  filename = "AD_CLMM_combined_plot.png",
  path = r"(C:\Users\nicola.chinchella2\Desktop\PHD BOLOGNA\Study\Interaction with Social Media\Instagram experiment\Paper\2nd paper\Final Plots)",
  plot = p_combinedAD,
  width = 13,
  height = 6.5,
  dpi = 300
)

# # 5.2) Raw data plot 
# p_obsAD <- ggplot(AD, aes(x = dilemma_type, y = answer, fill = group)) +
#   geom_boxplot(
#     position = position_dodge(width = 0.8),
#     width = 0.6,
#     alpha = 0.7,
#     outlier.shape = NA
#   ) +
#   facet_wrap(~ risk) +
#   scale_y_continuous(
#     breaks = 1:9,
#     limits= c(1,9)
#   ) +
#   labs(
#     x = "Dilemma type",
#     y = "Answer",
#     fill = "Group"
#   )

#=======================================================================================================
# lmer for Valence (VD)
#=======================================================================================================

# 1. Data Preparation
#---------------------------------------------------------
VD$dilemma_type <- as.factor(VD$dilemma_type)
VD$group <- as.factor(VD$group)
VD$risk <- as.factor(VD$risk)
VD$sex <- as.factor(VD$sex)
VD$answer <- as.numeric(VD$answer)

VD <- VD %>% drop_na(answer)

# 3. Linear mixed model 
#---------------------------------------------------------

# 3.1) effect coding 
VDdf <- within(VD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +

})

VDdf$answer <- ordered(VDdf$answer)

# 1 Model comparison 
modVD_ri <- clmm(
  answer ~ 1 + (1 | responseid),
  data = VDdf,
  link = "logit",
  threshold = "flexible"
)

modVD_rs_dilemma <- clmm(
  answer ~ 1 + (1 | responseid) +
      (0 + c.risk | responseid),
  data = VDdf,
  link = "logit",
  threshold = "flexible"
)

modVD_rs_risk_dilemma <- clmm(
    answer ~ 1 + (1 | responseid) +
      (0 + c.risk | responseid) +
      (0 + c.dilemma | responseid),
  data = VDdf,
  link = "logit",
  threshold = "flexible"
)

modsVD <- list(
  "Random intercept" = modVD_ri,
  "RI + dilemma slope" = modVD_rs_dilemma,
  "RI + dilemma + risk slopes" = modVD_rs_risk_dilemma
)

tab_reVD <- data.frame(
  Model = names(modsVD),
  logLik = sapply(modsVD, logLik),
  AIC = sapply(modsVD, AIC),
  BIC = sapply(modsVD, BIC)
)

knitr::kable(tab_reVD, digits = 2, caption = "Comparison of random-effects structures")

anova(modVD_ri, modVD_rs_dilemma, modVD_rs_risk_dilemma)

# 2 Final model 

modVD_ord1 <- clmm(
  answer ~ c.group + c.risk + c.dilemma +
    (1 | responseid) +
    (0 + c.risk | responseid) +
    (0 + c.dilemma | responseid),
  data = VDdf,
  link = "logit",
  threshold = "flexible"
)
summary(modVD_ord1)

coefsVD <- coef(summary(modVD_ord1))

lowerVD <- coefsVD[, "Estimate"] - 1.96 * coefsVD[, "Std. Error"]
upperVD <- coefsVD[, "Estimate"] + 1.96 * coefsVD[, "Std. Error"]

cbind(coefsVD, CI_low_b = lowerVD, CI_high_b = upperVD)
performance::r2_nakagawa(modVD_ord1)


clm_checkVD <- clm(
  answer ~ c.group + c.risk + c.dilemma,
  data = VDdf,
  link = "logit",
  threshold = "flexible"
)

nominal_test(clm_checkVD)


# 3. Plotting -------------------------------------------------------------

emmVD_mean <- emmeans(
  modVD_ord1,
  ~ c.risk * c.dilemma | c.group,
  at = list(
    c.group   = c(-0.5, 0.5),
    c.dilemma = c(-0.5, 0.5),
    c.risk    = c(-0.5, 0.5)
  ),
  mode = "mean.class"
)

emmVD_prob <- emmeans(
  modVD_ord1,
  ~ answer | c.risk * c.dilemma * c.group,
  at = list(
    c.group   = c(-0.5, 0.5),
    c.dilemma = c(-0.5, 0.5),
    c.risk    = c(-0.5, 0.5)
  ),
  mode = "prob"
)


# 4. Relabeling -----------------------------------------------------------

emm_dfVD_mean <- relabel_emm(emmVD_mean)
emm_dfVD_prob <- relabel_emm_prob(emmVD_prob)


# 5. Plot ----------------------------------------------------------------

# 5.1 Estimated mean response plot
p_meanVD <- ggplot(
  emm_dfVD_mean,
  aes(
    x = c.dilemma,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Valence Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_meanVD


# 5.2 Predicted response probabilities
p_probVD <- ggplot(
  emm_dfVD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.dilemma),
    colour = c.group,
    linetype = c.dilemma
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.risk) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Valence Response Probabilities",
    x = "Response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Dilemma type"
  ) +
  guides(
    colour = "none",
    linetype = guide_legend(title = "Dilemma type")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probVD


# 5.3 Combined figure
p_combinedVD <- p_meanVD + p_probVD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )

p_combinedVD


# 5.4 Save figure
ggsave(
  filename = "VD_CLMM_combined_plot.png",
  path = r"(C:\Users\nicola.chinchella2\Desktop\PHD BOLOGNA\Study\Interaction with Social Media\Instagram experiment\Paper\2nd paper\Final Plots)",
  plot = p_combinedVD,
  width = 13,
  height = 6.5,
  dpi = 300
)



#=======================================================================================================
# lmer for Moral Acceptability (MAD)
#=======================================================================================================

#1. Data Preparation
#---------------------------------------------------------
MAD$dilemma_type <- as.factor(MAD$dilemma_type)
MAD$group <- as.factor(MAD$group)
MAD$risk <- as.factor(MAD$risk)
MAD$sex <- as.factor(MAD$sex)
MAD$answer <- as.numeric(MAD$answer)

MAD <- MAD %>% drop_na(answer)

# 2. Linear mixed model
#---------------------------------------------------------

# 3.1) effect coding 
MADdf <- within(MAD, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
  c.dilemma <- ifelse(dilemma_type == "I", -0.5, 0.5) # I == -, S == +
  c.risk <-  ifelse(risk == "NC", -0.5, 0.5) # NC == -, CC = +

})

MADdf$answer <- ordered(MADdf$answer)

# 1 Model comparison 
modMAD_ri <- clmm(
  answer ~ 1 + (1 | responseid),
  data = MADdf,
  link = "logit",
  threshold = "flexible"
)

modMAD_rs_dilemma <- clmm(
  answer ~ 1 + (1 + c.dilemma | responseid),
  data = MADdf,
  link = "logit",
  threshold = "flexible"
)

modMAD_rs_risk_dilemma <- clmm(
  answer ~ 1 + (1 + c.dilemma + c.risk | responseid),
  data = MADdf,
  link = "logit",
  threshold = "flexible"
)

modsMAD <- list(
  "Random intercept" = modMAD_ri,
  "RI + dilemma slope" = modMAD_rs_dilemma,
  "RI + dilemma + risk slopes" = modMAD_rs_risk_dilemma
)

tab_reMAD <- data.frame(
  Model = names(modsMAD),
  logLik = sapply(modsMAD, logLik),
  AIC = sapply(modsMAD, AIC),
  BIC = sapply(modsMAD, BIC)
)

knitr::kable(tab_reMAD, digits = 2, caption = "Comparison of random-effects structures")

anova(modMAD_ri, modMAD_rs_dilemma, modMAD_rs_risk_dilemma)

# 2 Comunulative final model 
modMAD_ord1 <- clmm(
  answer ~ c.group + c.risk + c.dilemma +
  (1 + c.risk + c.dilemma | responseid),
  data = MADdf,
  link = "logit",
  threshold = "flexible"
)
summary(modMAD_ord1)

coefsMAD <- coef(summary(modMAD_ord1))

lowerMAD <- coefsMAD[, "Estimate"] - 1.96 * coefsMAD[, "Std. Error"]
upperMAD <- coefsMAD[, "Estimate"] + 1.96 * coefsMAD[, "Std. Error"]

cbind(coefsMAD, CI_low = lowerMAD, CI_high = upperMAD)

performance::r2_nakagawa(modMAD_ord1)

#Test for nominal assomuption 
clm_checkMAD <- clm(
  answer ~ c.group + c.risk + c.dilemma,
  data = MADdf,
  link = "logit",
  threshold = "flexible"
)

nominal_test(clm_checkMAD)

# 3. Estimated marginal means -------------------------------------------

emmMAD_mean <- emmeans(
  modMAD_ord1,
  ~ c.risk * c.dilemma | c.group,
  at = list(
    c.group   = c(-0.5, 0.5),
    c.dilemma = c(-0.5, 0.5),
    c.risk    = c(-0.5, 0.5)
  ),
  mode = "mean.class"
)

emmMAD_prob <- emmeans(
  modMAD_ord1,
  ~ answer | c.risk * c.dilemma * c.group,
  at = list(
    c.group   = c(-0.5, 0.5),
    c.dilemma = c(-0.5, 0.5),
    c.risk    = c(-0.5, 0.5)
  ),
  mode = "prob"
)


# 4. Relabeling ----------------------------------------------------------

emm_dfMAD_mean <- relabel_emm(emmMAD_mean)
emm_dfMAD_prob <- relabel_emm_prob(emmMAD_prob)


# 5. Plot ---------------------------------------------------------------

# 5.1 Estimated mean response plot
p_meanMAD <- ggplot(
  emm_dfMAD_mean,
  aes(
    x = c.risk,
    y = mean.class,
    colour = c.group
  )
) +
  geom_point(
    position = position_dodge(width = 0.45),
    size = 3
  ) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    position = position_dodge(width = 0.45),
    width = 0.15,
    linewidth = 0.6
  ) +
  facet_wrap(~ c.dilemma) +
  scale_y_continuous(
    limits = c(1, 9),
    breaks = 1:9
  ) +
  labs(
    title = "A. Estimated Moral Acceptability Mean Responses",
    x = "Dilemma type",
    y = "Estimated mean response",
    colour = "Group"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_meanMAD


# 5.2 Predicted response probabilities
p_probMAD <- ggplot(
  emm_dfMAD_prob,
  aes(
    x = answer,
    y = prob,
    group = interaction(c.group, c.risk),
    colour = c.group,
    linetype = c.risk
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(
    aes(
      ymin = asymp.LCL,
      ymax = asymp.UCL
    ),
    width = 0.08,
    linewidth = 0.4
  ) +
  facet_wrap(~ c.dilemma) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, NA)
  ) +
  labs(
    title = "B. Predicted Moral Acceptability response probabilities",
    x = "Response category",
    y = "Predicted probability",
    colour = "Group",
    linetype = "Risk"
  ) +
  guides(
    colour = "none",
    linetype = guide_legend(title = "Risk")
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

p_probMAD


# 5.3 Combined figure
p_combinedMAD <- p_meanMAD + p_probMAD +
  plot_layout(
    ncol = 2,
    widths = c(1, 1.35),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )

p_combinedMAD


# 5.4 Save figure
ggsave(
  filename = "MAD_CLMM_combined_plot.png",
  path = r"(C:\Users\nicola.chinchella2\Desktop\PHD BOLOGNA\Study\Interaction with Social Media\Instagram experiment\Paper\2nd paper\Final Plots)",
  plot = p_combinedMAD,
  width = 13,
  height = 6.5,
  dpi = 300
)
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

YN_F$group <- as.factor(YN_F$group)
YN_F$answer <- as.factor(YN_F$answer)
# YN_F$affirmative_response_total <- as.factor(YN_F$affirmative_response_total)

YN_F <- YN_F %>% drop_na(answer)

# 2. Linear mixed model
#---------------------------------------------------------

# 3.1) effect coding 
YNFdf <- within(YN_F, {
  dependent_var <- "answer"

  # Effect coding for categorical predictors
  c.group <- ifelse(group == "Instagram", -0.5, 0.5) # Instagram == - , Qualtrics == +
})

YNFdf$answer <- ordered(YNFdf$answer)

# 2 Final model 

m_mainYNFdf <- glm(
  answer ~ c.group,
  family = binomial,
  data = YNFdf
)

summary(m_mainYNFdf)
confint.default(m_mainYNFdf)


summary(m_mainYNFdf)
performance::r2(m_mainYNFdf)
simYNF <- DHARMa::simulateResiduals(m_mainYNFdf, n = 1000)
plot(simYNF)

plotResiduals(simYNF, form = YNFdf$group)
DHARMa::testCategorical(simYNF, catPred = YNFdf$group)

# Arousal / Valence / Moral Acceptability — Fillers
################################################################################

# Filter Filler trials excluding "Dilemma_Reading"
AVMA_F <- df_F %>%
  filter(question_new != "Dilemma_Reading")

AD_F  <- AVMA_F %>% filter(question_new == "Arousal")
VD_F  <- AVMA_F %>% filter(question_new == "Valence")
MAD_F <- AVMA_F %>% filter(question_new == "Moral_Acceptability")

#===============================================================================
# Helper function to prepare data for cumulative mixed model
#===============================================================================
prepare_for_clmm <- function(dat) {
  
  dat <- dat %>%
    mutate(
      group        = as.factor(group),
      responseid   = as.factor(responseid)
    ) %>%
    drop_na(answer)
  
  # If answer is stored as numeric or numeric-like character, order it properly
  ans_levels <- sort(unique(as.numeric(as.character(dat$answer))))
  
  dat <- dat %>%
    mutate(
      answer = factor(answer, levels = ans_levels, ordered = TRUE),
      c.group    = ifelse(group == "Instagram", -0.5, 0.5),   # Instagram = -, Qualtrics = +
    )
  
  return(dat)
}

# MAD_F has one answer == 8 this is weird. Probably a keyboard error let's make it 7
MAD_F$answer[MAD_F$answer==8] <- 7

#===============================================================================
# Prepare datasets for cumulative mixed models
#===============================================================================
ADFdf  <- prepare_for_clmm(AD_F)
VDFdf  <- prepare_for_clmm(VD_F)
MADFdf <- prepare_for_clmm(MAD_F)

# 95% Wald CI helper
get_wald_ci <- function(model, term = "c.group") {
  tab <- coef(summary(model))
  est <- unname(tab[term, "Estimate"])
  se  <- unname(tab[term, "Std. Error"])
  
  c(
    Estimate = est,
    SE = se,
    CI_lower = est - 1.96 * se,
    CI_upper = est + 1.96 * se
  )
}

#===============================================================================
# Arousal
#===============================================================================
modADF_ord1 <- clmm(
  answer ~ c.group+
    (1 | responseid),
  data = ADFdf,
  link = "logit",
  threshold = "flexible"
)
summary(modADF_ord1)
get_wald_ci(modADF_ord1, "c.group")
performance::r2_nakagawa(modADF_ord1 )

clm_checkADF <- clm(
  answer ~ c.group,
  data = ADFdf,
  link = "logit",
  threshold = "flexible"
)

nominal_test(clm_checkADF)

#===============================================================================
# Valence
#===============================================================================
modVDF_ord1 <- clmm(
  answer ~ c.group +
    (1 | responseid),
  data = VDFdf,
  link = "logit",
  threshold = "flexible"
)
summary(modVDF_ord1)
get_wald_ci(modVDF_ord1, "c.group")
performance::r2_nakagawa(modVDF_ord1)

clm_checkVDF <- clm(
  answer ~ c.group,
  data = VDFdf,
  link = "logit",
  threshold = "flexible"
)

nominal_test(clm_checkVDF)
#===============================================================================
# Moral Acceptability
#===============================================================================
modMADF_clm <- clm(
  answer ~ c.group,
  data = MADFdf,
  link = "logit",
  threshold = "flexible"
)
summary(modMADF_clm)
get_wald_ci(modMADF_clm, "c.group")
performance::r2(modMADF_clm)
nominal_test(modMADF_clm)

modMADF_ord1 <- clmm(
  answer ~ c.group +
    (1 | responseid),
  data = MADFdf,
  link = "logit",
  threshold = "flexible"
)
summary(modMADF_ord1)
