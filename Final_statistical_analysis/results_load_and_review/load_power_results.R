# ============================================================
# Load previously saved pilot power-analysis results
# Run from the Final_statistical_analysis/ project root:
# source("load_power_results.R")
# This script DOES NOT fit models or rerun simulations.
# ============================================================

power_output_dir <- file.path("outputs", "power_analysis")
power_models_dir <- file.path(power_output_dir, "models")
power_tables_dir <- file.path(power_output_dir, "tables")
power_figures_dir <- file.path(power_output_dir, "figures")

if (!dir.exists(power_output_dir)) {
  stop("Cannot find outputs/power_analysis. Run this script from the project root, after the power analysis has been saved.")
}

# Names exactly match the files saved by scripts/06_power_analysis.R.
model_files <- c(
  binary_all = "binary_all_lmer.rds",
  binary_group = "binary_group_glmer.rds",
  binary_interaction = "binary_interaction_glmer.rds",
  arousal = "arousal_lmer.rds",
  valence = "valence_lmer.rds",
  moral_acceptability = "moral_acceptability_lmer.rds"
)

simulation_files <- c(
  binary_all_group = "binary_all_group_power_result.rds",
  binary_group_only = "binary_group_only_power_result.rds",
  binary_interaction_predictors = "binary_interaction_predictors_power_result.rds",
  arousal = "arousal_power_result.rds",
  valence = "valence_power_result.rds",
  moral_acceptability = "moral_acceptability_power_result.rds"
)

table_files <- c(
  binary_all_group = "binary_all_group_power.csv",
  binary_group_only = "binary_group_only_power.csv",
  binary_interaction_predictors = "binary_interaction_predictors_power.csv",
  arousal = "arousal_power.csv",
  valence = "valence_power.csv",
  moral_acceptability = "moral_acceptability_power.csv"
)

figure_files <- c(
  binary_all_group = "binary_all_group_power.png",
  binary_group_only = "binary_group_only_power.png",
  binary_interaction_predictors = "binary_interaction_predictors_power.png",
  arousal = "arousal_power.png",
  valence = "valence_power.png",
  moral_acceptability = "moral_acceptability_power.png"
)

# Load available saved objects; report missing files rather than refitting them.
load_saved <- function(directory, filenames, reader) {
  paths <- file.path(directory, unname(filenames))
  names(paths) <- names(filenames)
  missing <- !file.exists(paths)
  if (any(missing)) {
    message("Missing saved files in ", directory, ": ",
            paste(basename(paths[missing]), collapse = ", "))
  }
  lapply(paths[!missing], reader)
}

power_models <- load_saved(power_models_dir, model_files, readRDS)
power_simulations <- load_saved(power_models_dir, simulation_files, readRDS)
power_tables <- load_saved(power_tables_dir, table_files,
                           function(path) read.csv(path, check.names = FALSE))

power_figures <- file.path(power_figures_dir, unname(figure_files))
names(power_figures) <- names(figure_files)
power_figures <- power_figures[file.exists(power_figures)]

cat("\nSaved power analysis loaded (no models or simulations rerun).\n")
cat("Models: ", paste(names(power_models), collapse = ", "), "\n", sep = "")
cat("Simulations: ", paste(names(power_simulations), collapse = ", "), "\n", sep = "")
cat("Tables: ", paste(names(power_tables), collapse = ", "), "\n", sep = "")
cat("Figures: ", paste(names(power_figures), collapse = ", "), "\n", sep = "")


