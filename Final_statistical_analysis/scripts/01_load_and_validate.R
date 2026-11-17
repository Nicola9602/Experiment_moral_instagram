# Original dataset loading / preparation.

##############################################################################
# Dataset loading and preparation
##############################################################################

I_dilemmas <- read_excel(file.path(data_dir, 'I_dilemmas.xlsx'))
Q_dilemmas <- read_excel(file.path(data_dir, 'Q_dilemmas.xlsx'))
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
