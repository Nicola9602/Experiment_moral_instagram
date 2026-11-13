# Original helper functions moved out of the long analysis script.

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
