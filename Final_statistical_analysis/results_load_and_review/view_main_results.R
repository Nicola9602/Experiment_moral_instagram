# Create a standalone HTML review of already-saved main-analysis results.
# No model fitting, simulation, or access to participant-level source datasets.
# Run from Final_statistical_analysis/: source("view_main_results.R")
source("results_load_and_review/load_main_results.R", local = FALSE)

dir.create("reports", showWarnings = FALSE, recursive = TRUE)
report_path <- file.path("reports", "main_analysis_review.html")

html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

render_table <- function(dat, max_rows = 500L) {
  if (is.null(dat) || !nrow(dat)) return("<p>No rows available.</p>")
  display <- head(dat, max_rows)
  header <- paste0("<tr>", paste0("<th>", html_escape(names(display)), "</th>", collapse = ""), "</tr>")
  cells <- vapply(seq_len(nrow(display)), function(i) {
    vals <- vapply(display[i, , drop = FALSE], function(v) {
      if (is.na(v[1])) "NA" else as.character(v[1])
    }, character(1))
    paste0("<tr>", paste0("<td>", html_escape(vals), "</td>", collapse = ""), "</tr>")
  }, character(1))
  note <- if (nrow(dat) > max_rows) sprintf("<p>Showing the first %d of %d rows; see the CSV for all rows.</p>", max_rows, nrow(dat)) else ""
  paste0("<div class='scroll'><table>", header, paste(cells, collapse = "\n"), "</table></div>", note)
}

pretty_label <- function(x) {
  x <- gsub("_", " ", x, fixed = TRUE)
  tools::toTitleCase(x)
}

sections <- character()

# Figures reference image files in the original output directory.
sections <- c(sections, "<h2>Figures</h2>")
if (!length(main_figures)) sections <- c(sections, "<p>No saved PNG figures found.</p>")
for (name in names(main_figures)) {
  src <- gsub("\\\\", "/", file.path("..", main_figures[[name]]))
  sections <- c(sections, paste0(
    "<section><h3>", html_escape(pretty_label(name)), "</h3>",
    "<img src='", html_escape(src), "' alt='", html_escape(name), "'></section>"
  ))
}

sections <- c(sections, "<h2>Saved tables</h2>")
if (!length(main_tables)) sections <- c(sections, "<p>No CSV tables found.</p>")
for (name in names(main_tables)) {
  sections <- c(sections, paste0(
    "<section><h3>", html_escape(pretty_label(name)), "</h3>",
    render_table(main_tables[[name]]), "</section>"
  ))
}

sections <- c(sections, "<h2>Saved model summaries</h2>")
if (!length(main_models)) sections <- c(sections, "<p>No saved RDS models found.</p>")
for (name in names(main_models)) {
  summary_text <- tryCatch(
    paste(capture.output(summary(main_models[[name]])), collapse = "\n"),
    error = function(e) paste("Model summary unavailable:", conditionMessage(e))
  )
  sections <- c(sections, paste0(
    "<section><details><summary>", html_escape(pretty_label(name)),
    "</summary><pre>", html_escape(summary_text), "</pre></details></section>"
  ))
}

page <- paste0(
'<!doctype html><html lang="en"><head><meta charset="utf-8">',
'<meta name="viewport" content="width=device-width,initial-scale=1">',
'<title>Main statistical analysis | Saved results</title>',
'<style>body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:1100px;margin:35px auto;padding:0 22px;color:#223047;line-height:1.5;background:#f8fafc}',
'h1{font-size:2rem}h2{margin-top:45px;border-bottom:1px solid #cbd5e1;padding-bottom:8px}',
'section{background:white;border:1px solid #e2e8f0;border-radius:10px;padding:18px;margin:18px 0}',
'img{width:100%;height:auto;max-width:100%}table{border-collapse:collapse;font-size:0.85rem;width:100%}',
'th,td{border-bottom:1px solid #e2e8f0;text-align:left;padding:7px 9px;white-space:nowrap}',
'th{background:#edf2f7}.scroll{overflow-x:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f5f9;padding:15px;font-size:0.8rem}',
'summary{cursor:pointer;font-weight:600}p.muted{color:#5f6f85}</style></head><body>',
'<h1>Main statistical analysis — saved results</h1>',
'<p class="muted">Generated from previously saved figures, CSV tables, and RDS models. No models are refitted.</p>',
'<p class="muted">This is a local research review report. Inspect model summaries and tables for sensitive information before sharing.</p>',
paste(sections, collapse="\n"), '</body></html>'
)
writeLines(page, report_path, useBytes = TRUE)
message("Review written to: ", normalizePath(report_path, winslash = "/"))
if (interactive()) utils::browseURL(normalizePath(report_path, winslash = "/"))
