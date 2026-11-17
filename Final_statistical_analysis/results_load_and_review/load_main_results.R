# Load saved main-analysis results without refitting models.
# Run from Final_statistical_analysis/: source("load_main_results.R")

main_output <- "outputs"

main_model_files <- c(
  binary = "binary_model.rds",
  filler_binary = "filler_binary_model.rds",
  arousal = "arousal_model.rds",
  valence = "valence_model.rds",
  moral_acceptability = "moral_acceptability_model.rds",
  filler_arousal = "filler_arousal_model.rds",
  filler_valence = "filler_valence_model.rds",
  filler_moral_acceptability = "filler_moral_acceptability_model.rds"
)

main_table_files <- c(
  binary_model_comparison = "binary_model_comparison.csv",
  binary_likelihood_ratio_tests = "binary_likelihood_ratio_tests.csv",
  binary_predicted_probabilities = "binary_predicted_probabilities.csv",
  arousal_model_comparison = "arousal_model_comparison.csv",
  valence_model_comparison = "valence_model_comparison.csv",
  moral_acceptability_model_comparison = "moral_acceptability_model_comparison.csv",
  arousal_estimated_mean_categories = "arousal_estimated_mean_categories.csv",
  arousal_predicted_probabilities = "arousal_predicted_probabilities.csv",
  valence_estimated_mean_categories = "valence_estimated_mean_categories.csv",
  valence_predicted_probabilities = "valence_predicted_probabilities.csv",
  moral_acceptability_estimated_mean_categories = "moral_acceptability_estimated_mean_categories.csv",
  moral_acceptability_predicted_probabilities = "moral_acceptability_predicted_probabilities.csv"
)

main_figure_files <- c(
  binary_predicted_probabilities = "binary_predicted_probabilities.png",
  filler_binary_observed = "filler_binary_observed.png",
  arousal = "AD_CLMM_combined_plot.png",
  valence = "VD_CLMM_combined_plot.png",
  moral_acceptability = "MAD_CLMM_combined_plot.png"
)

read_optional <- function(files, folder, reader) {
  result <- list()
  for (label in names(files)) {
    path <- file.path(main_output, folder, files[[label]])
    if (file.exists(path)) {
      result[[label]] <- tryCatch(reader(path), error = function(e) {
        warning(sprintf("Could not read %s: %s", path, conditionMessage(e)))
        NULL
      })
    } else {
      message("Not yet saved: ", path)
    }
  }
  result
}

main_models <- read_optional(main_model_files, "models", readRDS)
main_tables <- read_optional(main_table_files, "tables", function(path) {
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
})
main_figures <- setNames(
  file.path(main_output, "figures", unname(main_figure_files)),
  names(main_figure_files)
)
main_figures <- main_figures[file.exists(main_figures)]

cat("Loaded:", length(main_models), "models,", length(main_tables),
    "tables, and", length(main_figures), "figure paths.\n")
cat("Use main_models$arousal, main_tables$arousal_model_comparison, or main_figures['arousal'].\n")
