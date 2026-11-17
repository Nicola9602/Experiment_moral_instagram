# Original main and filler ordinal models, estimated marginal means and diagnostics.

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


# Arousal / Valence / Moral Acceptability — Fillers
################################################################################

# Filter Filler trials excluding "Dilemma_Reading"
AVMA_F <- df_F %>%
  filter(question_new != "Dilemma_Reading")

AD_F  <- AVMA_F %>% filter(question_new == "Arousal")
VD_F  <- AVMA_F %>% filter(question_new == "Valence")
MAD_F <- AVMA_F %>% filter(question_new == "Moral_Acceptability")



# MAD_F has one answer == 8 this is weird. Probably a keyboard error let's make it 7
MAD_F$answer[MAD_F$answer==8] <- 7

#===============================================================================
# Prepare datasets for cumulative mixed models
#===============================================================================
ADFdf  <- prepare_for_clmm(AD_F)
VDFdf  <- prepare_for_clmm(VD_F)
MADFdf <- prepare_for_clmm(MAD_F)


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


# ============================================================
# Save ordinal model results
# ============================================================

# Save fitted models
saveRDS(
  modAD_ord1,
  "outputs/models/arousal_model.rds"
)

saveRDS(
  modVD_ord1,
  "outputs/models/valence_model.rds"
)

saveRDS(
  modMAD_ord1,
  "outputs/models/moral_acceptability_model.rds"
)

# Save model comparison tables
write.csv(
  tab_reAD,
  "outputs/tables/arousal_model_comparison.csv",
  row.names = FALSE
)

write.csv(
  tab_reVD,
  "outputs/tables/valence_model_comparison.csv",
  row.names = FALSE
)

write.csv(
  tab_reMAD,
  "outputs/tables/moral_acceptability_model_comparison.csv",
  row.names = FALSE
)

# ============================================================
# Additional saved outputs for later review (no model changes)
# ============================================================

# Keep filler models available without refitting.
saveRDS(modADF_ord1, "outputs/models/filler_arousal_model.rds")
saveRDS(modVDF_ord1, "outputs/models/filler_valence_model.rds")
saveRDS(modMADF_ord1, "outputs/models/filler_moral_acceptability_model.rds")

# Save marginal mean-category estimates and category probabilities.
write.csv(emm_dfAD_mean, "outputs/tables/arousal_estimated_mean_categories.csv", row.names = FALSE)
write.csv(emm_dfAD_prob, "outputs/tables/arousal_predicted_probabilities.csv", row.names = FALSE)
write.csv(emm_dfVD_mean, "outputs/tables/valence_estimated_mean_categories.csv", row.names = FALSE)
write.csv(emm_dfVD_prob, "outputs/tables/valence_predicted_probabilities.csv", row.names = FALSE)
write.csv(emm_dfMAD_mean, "outputs/tables/moral_acceptability_estimated_mean_categories.csv", row.names = FALSE)
write.csv(emm_dfMAD_prob, "outputs/tables/moral_acceptability_predicted_probabilities.csv", row.names = FALSE)
