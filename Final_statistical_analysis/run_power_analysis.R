# Run pilot power analysis independently of the main analysis.
# Start R with Final_statistical_analysis/ as the working directory.

packages <- c(
  "boot", "MASS", "robustlmm", "afex", "dplyr", "readr", "compute.es",
  "car", "ggplot2", "multcomp", "pastecs", "WRS2", "tidyr", "readxl",
  "DescTools", "knitr", "writexl", "rcompanion", "lsr", "ARTool", "lme4", 
  "sjPlot", "interactions", "mixedpower", "Matrix", "jsonlite"
)

invisible(lapply(packages, library, character.only = TRUE))


power_output_dir <- file.path("outputs", "power_analysis")
power_tables_dir <- file.path(power_output_dir, "tables")
power_models_dir <- file.path(power_output_dir, "models")
power_figures_dir <- file.path(power_output_dir, "figures")

for (directory in c(power_tables_dir, power_models_dir, power_figures_dir)) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
}

source(file.path("scripts", "06_power_analysis.R"), local = FALSE, echo = TRUE)
