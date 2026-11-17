# Run the analysis in sequence.
# Start R with the project root as the working directory.


packages <- c(
  "boot", "MASS", "robustlmm", "afex", "dplyr", "readr", "compute.es",
  "car", "ggplot2", "multcomp", "pastecs", "WRS2", "tidyr", "readxl",
  "DescTools", "knitr", "writexl", "rcompanion", "lsr", "ARTool", "lme4",
  "sjPlot", "DHARMa", "emmeans", "scales", "brms", "BH", "ordinal", "modelsummary",
  "jtools", "ggdist", "patchwork", "ps", "robustlmm"
)

invisible(lapply(packages, library, character.only = TRUE))


data_dir <- "data"
output_dir <- file.path("outputs", "figures")
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/diagnostics", recursive = TRUE, showWarnings = FALSE)

source(file.path("functions", "functions.R"), local = FALSE)
for (script in c(
  "01_load_and_validate.R",
  "02_exploratory_analysis.R",
  "03_binary_models.R",
  "04_ordinal_models.R",
  "05_visualizations.R"
)) {
  source(file.path("scripts", script), local = FALSE, echo = FALSE)
}
