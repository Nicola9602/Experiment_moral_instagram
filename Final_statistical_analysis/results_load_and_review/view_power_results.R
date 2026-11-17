# ============================================================
# View saved power-analysis results in a single HTML report.
# Run from Final_statistical_analysis/: source("view_power_results.R")
# Does NOT refit models or rerun simulations.
# Requires load_power_results.R in the project root.
# ============================================================

source("results_load_and_review/load_power_results.R", local = FALSE)

dir.create("reports", showWarnings = FALSE, recursive = TRUE)
report_file <- file.path("reports", "power_analysis_review.html")

escape_html <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

html_table <- function(dat) {
  if (is.null(dat) || !nrow(dat)) return("<p>No rows available.</p>")
  # Format for display without changing the original saved CSV.
  vals <- lapply(dat, function(x) {
    if (is.numeric(x)) format(round(x, 4), trim = TRUE, scientific = FALSE)
    else as.character(x)
  })
  header <- paste0("<th>", escape_html(names(dat)), "</th>", collapse = "")
  rows <- vapply(seq_len(nrow(dat)), function(i) {
    cells <- vapply(vals, function(column) {
      value <- column[i]
      paste0("<td>", if (is.na(value)) "" else escape_html(value), "</td>")
    }, character(1))
    paste0("<tr>", paste(cells, collapse = ""), "</tr>")
  }, character(1))
  paste0("<div class='table-scroll'><table><thead><tr>", header,
         "</tr></thead><tbody>", paste(rows, collapse = ""),
         "</tbody></table></div>")
}

labels <- c(
  binary_all_group = "Binary choice - full pilot, group effect",
  binary_group_only = "Binary choice - 16-person pilot, group effect",
  binary_interaction_predictors = "Binary choice - 16-person pilot, interaction model",
  arousal = "Arousal",
  valence = "Valence",
  moral_acceptability = "Moral acceptability"
)

sections <- character()
for (key in names(labels)) {
  title <- labels[[key]]
  parts <- paste0("<section><h2>", escape_html(title), "</h2>")

  if (key %in% names(power_figures)) {
    # reports/ and outputs/ are siblings; relative image references keep the report portable.
    image_path <- paste0("../outputs/power_analysis/figures/", basename(power_figures[[key]]))
    parts <- paste0(parts, "<img src='", escape_html(image_path),
                    "' alt='Power simulation plot for ", escape_html(title), "'>")
  } else {
    parts <- paste0(parts, "<p class='muted'>Saved figure not found.</p>")
  }

  if (key %in% names(power_tables)) {
    parts <- paste0(parts, "<h3>Simulation estimates</h3>", html_table(power_tables[[key]]))
  } else {
    parts <- paste0(parts, "<p class='muted'>Saved CSV table not found.</p>")
  }
  sections <- c(sections, paste0(parts, "</section>"))
}

model_labels <- c(
  binary_all = "Full-pilot binary LMM",
  binary_group = "16-person binary group-only GLMM",
  binary_interaction = "16-person binary interaction GLMM",
  arousal = "Arousal LMM",
  valence = "Valence LMM",
  moral_acceptability = "Moral acceptability LMM"
)
model_sections <- character()
for (key in names(model_labels)) {
  if (!key %in% names(power_models)) next
  details <- paste(escape_html(capture.output(summary(power_models[[key]]))), collapse = "\n")
  model_sections <- c(model_sections, paste0(
    "<details><summary>", escape_html(model_labels[[key]]),
    "</summary><pre>", details, "</pre></details>"))
}

html <- paste0(
  "<!doctype html><html lang='en'><head><meta charset='UTF-8'>",
  "<meta name='viewport' content='width=device-width,initial-scale=1'>",
  "<title>Pilot power analysis - saved results</title>",
  "<style>",
  "body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:1100px;margin:40px auto;padding:0 20px;color:#202832;background:#fff;line-height:1.5}",
  "h1{margin-bottom:6px}h2{margin-top:0}section{border-top:1px solid #dce0e5;padding:25px 0}",
  "img{display:block;width:100%;max-width:900px;height:auto;border:1px solid #eee;margin:18px 0}",
  ".muted{color:#666}.table-scroll{overflow-x:auto}table{border-collapse:collapse;font-size:13px;min-width:650px}",
  "td,th{border-bottom:1px solid #e8eaed;padding:7px 10px;text-align:left}th{background:#f5f6f7}",
  "details{border:1px solid #e0e3e6;border-radius:6px;margin:10px 0;padding:12px}",
  "summary{cursor:pointer;font-weight:600}pre{overflow:auto;white-space:pre;font-size:12px;background:#f8f9fa;padding:12px}",
  "</style></head><body>",
  "<h1>Pilot power analysis</h1>",
  "<p class='muted'>Review of previously saved simulation results; no models or simulations were rerun.</p>",
  "<p>Original settings: sample sizes 60-120 in steps of 10, 1,000 simulations per setting. The results below reflect your saved files.</p>",
  paste(sections, collapse = "\n"),
  "<h2>Fitted pilot model summaries</h2>",
  if (length(model_sections)) paste(model_sections, collapse = "\n") else "<p>No saved models found.</p>",
  "<p class='muted'>This is a local review report. Saved model objects may contain participant data; do not publish them without checking privacy.</p>",
  "</body></html>"
)

writeLines(html, report_file, useBytes = TRUE)
cat("\nReview report created: ", normalizePath(report_file, winslash = "/"), "\n", sep = "")

# Set FALSE if you only want to generate the report without opening your browser.
open_in_browser <- TRUE
if (open_in_browser && interactive()) {
  utils::browseURL(normalizePath(report_file, winslash = "/"))
}
