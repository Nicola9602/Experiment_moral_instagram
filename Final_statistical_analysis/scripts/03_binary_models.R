# Original main and filler Yes/No models.

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
  npar = sapply(mods, function(x) attr(logLik(x), "df")),
  logLik = sapply(mods, logLik),
  AIC = sapply(mods, AIC),
  BIC = sapply(mods, BIC)
)

kable(tab_re, digits = 2, caption = "Comparison of random-effects structures")

comparison_yn <- anova(
  m_ri,
  m_rs_risk,
  m_rs_risk_dilemma
)


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

emm_df <- relabel_emm(emm)

# 7.2) however the output will not be readable yet because it is still effect coded 
# so we have to explain R what these effect code mean



summary(emm_df)
# pairs(emm_df)


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

# ============================================================
# Save binary model results
# ============================================================

# Save fitted models
saveRDS(
  m_main,
  "outputs/models/binary_model.rds"
)

saveRDS(
  m_mainYNFdf,
  "outputs/models/filler_binary_model.rds"
)

# Save model comparison table
write.csv(
  tab_re,
  "outputs/tables/binary_model_comparison.csv",
  row.names = FALSE
)

# Save likelihood-ratio tests
write.csv(
  as.data.frame(comparison_yn),
  "outputs/tables/binary_likelihood_ratio_tests.csv"
)

#Save estimated probabilities
write.csv(
  emm_df,
  "outputs/tables/binary_predicted_probabilities.csv",
  row.names = FALSE
)