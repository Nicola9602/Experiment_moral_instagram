# Social Media Decision Analysis

This is the original R analysis organized into smaller files, **without redesigning the statistical methods**. The original cleaning and research documentation is retained below. The participant-level data are private.

## Repository layout and execution

- `run_analysis.R` runs the five scripts in sequence, sharing the same R session. Run from the project root with `Rscript run_analysis.R` or `source("run_analysis.R")` in R.
- `scripts/01_load_and_validate.R`: original loading and dataset preparation.
- `scripts/02_exploratory_analysis.R`: original descriptive percentages and observed-data plots.
- `scripts/03_binary_models.R`: original Yes/No models for main and filler dilemmas.
- `scripts/04_ordinal_models.R`: original arousal, valence, acceptability and filler ordinal models; predicted values.
- `scripts/05_visualizations.R`: original model-based graphs and saved figures.
- `R/functions.R`: the three original helper functions, moved without redesign.
- `data/`: place authorized `I_dilemmas.xlsx` and `Q_dilemmas.xlsx` here. These files are not distributed.
- `outputs/figures/`: generated PNGs.
- `outputs/tables/` and `reports/`: folders reserved for sharing non-identifying results and reports.

The code, model specifications, existing comments, explicit corrections and data preparation decisions are retained from the original script. Only the input / output paths and `source()` calls were adjusted to make the split scripts run as one analysis. No new checks or changed modeling choices have been inserted.

**Packages:** The original script still contains its automatic installation/loading code in `01_load_and_validate.R`. `performance` is referenced by namespace in the analysis but is not in that original package list; install it separately if needed.

**Environment:** `renv.lock` is a structural placeholder because the original R package versions were not provided and R is unavailable here. It is **not** a reproducible package snapshot. To create a real lockfile on the machine where you ran the analysis, install `renv`, run `renv::init(bare = TRUE)` (if the project is not already initialized), then `renv::snapshot()`. Commit the resulting lockfile and `renv` infrastructure.

**Execution note:** The project has not been run on the private study datasets in this environment. The original statistical assumptions and data corrections have not been revalidated.

---

## Existing project documentation

# Moral dilemma study: data cleaning and statistical analysis

This repository documents the processing and statistical analysis of responses to moral dilemmas administered through **Instagram** and **Qualtrics**. Python scripts convert the original exports into consistent, long-format datasets and calculate questionnaire scores. R scripts subsequently compare responses across experimental groups and dilemma characteristics and estimate sample-size-dependent statistical power from pilot data.

The repository is intended to make the **analysis decisions and code** available. Original survey exports, participant-level responses, timing files, and cleaned participant-level workbooks are **not distributed** because they contain research-participant information. Consequently, the pipeline can only be rerun on the original data by someone with authorized access. Reproducibility on those data has not been independently verified here.

## Processing workflow

Run the relevant Python cleaning scripts before the R statistical analysis. The two data-collection sources are cleaned separately and later combined by the R analysis.

| Script | Role | Main input(s) | Main output(s) |
| --- | --- | --- | --- |
| `clean_instagram.py` | Clean Instagram dilemma responses, process participant timing exports, score questionnaires, and assemble the Instagram dilemma table. | Individual timing `.xlsx` files, `Risultati_instagram.xlsx`, `Instagram_Questionnaires.xlsx` | `I_timings.xlsx`, `I_dilemmas.xlsx`, `I_questionnaire_averages.xlsx` |
| `dilemma_cleaning_qualtrics.py` | Clean Qualtrics dilemma survey exports, reconstruct dilemma order, reshape responses, process and merge questionnaire information. | `Qualtrics_Dilemmas_Results.csv` | `Q_dilemmas.xlsx`, intermediate `df_questionnaires.xlsx` |
| `questionnaire_cleaning.py` | Separately clean and summarize the Qualtrics questionnaire workbook. | `df_questionnaires.xlsx` | `cleaned_questionnaires.xlsx`, sheets `cleaned_data` and `averages` |
| `Analysis_final_dilemmas_lmer.r` | Combine Instagram and Qualtrics dilemma datasets and fit the main behavioural models, diagnostics and figures. | `I_dilemmas.xlsx`, `Q_dilemmas.xlsx` | Model summaries, contrasts and plots; selected figure files |
| `power_analysis.r` | Run pilot-data-based simulation power calculations for dilemma-choice and rating outcomes. | `pilot_I.xlsx`, `pilot_Q.xlsx` | Power estimates and power plots generated during R execution |

The filenames in this table reflect the scripts supplied for documentation; adjust them if the repository uses different capitalization or filenames. The example command lines below are intended to be run from the directory containing the relevant script and its helper package.

## 1. Instagram dilemma cleaning

`clean_instagram.py` is the executable, repeatable version of the original `Dilemma_cleaning_Instagram.ipynb`. It follows the notebook's transformation sequence while removing exploratory displays, plots and diagnostic print statements from the main processing workflow.

### Processing steps

1. **Import response times.** Read each participant's timing `.xlsx` file from a configured directory and concatenate the files into one table.
2. **Standardize timing variables.** Convert time strings into seconds, omit `duration_initial_message` and `total_time_spent`, and standardize `Response_id` to `ResponseId`.
3. **Reshape timings.** Convert the wide timing columns to long format (`ResponseId`, `Question`, `Duration`), standardize question labels, and split the question identifier into dilemma name and question type.
4. **Classify dilemmas.** Assign dilemma types and risk categories using the existing study-specific mappings. Reading-time records receive the corresponding exception for risk classification.
5. **Clean dilemma responses.** Load `Risultati_instagram.xlsx`, remove non-analysis survey fields, reshape the selected dilemma questions into long format, and apply the original answer and question-label transformations.
6. **Process questionnaires.** Load `Instagram_Questionnaires.xlsx`, apply the notebook's completion filters and manual corrections, reverse-score the specified items, and calculate SMAQ, SMUS and SMMS scale/subscale scores.
7. **Assemble and export tables.** Produce the Instagram dilemma dataset and questionnaire summary. The separate timing table is exported but is **not joined into the dilemma-response table** by this script.

### Helper functions

Reusable functions are stored in separate Python modules. They may be placed together in a `helper_functions/` package; if so, imports in `clean_instagram.py` must use that package prefix (for example, `from helper_functions.convert_to_seconds import convert_to_seconds`). An empty `helper_functions/__init__.py` file is recommended.

| Helper module | Purpose |
| --- | --- |
| `convert_to_seconds.py` | Convert `H:MM:SS` timing values to seconds. |
| `convert_question_name.py` | Standardize original timing/question identifiers. |
| `map_dilemma_functions.py` | Map dilemma names to dilemma types and risk categories. |
| `dilemma_functions.py` | Insert dilemma-reading records and clean response labels. |
| `questionnaire_functions.py` | Reverse-score relevant questionnaire items. |
| `questionnaire_scoring.py` | Calculate SMAQ, SMUS and SMMS subscales and overall scores according to the original code. |

### Setup and execution

Install the necessary Python libraries, including `pandas`, `numpy` and `openpyxl`. Set `folder_path`, `questions_file`, `questionnaires_file` and `output_folder` near the beginning of `clean_instagram.py`, then run:

```bash
python clean_instagram.py
```

Outputs are `I_timings.xlsx`, `I_dilemmas.xlsx` and `I_questionnaire_averages.xlsx`. Existing files with the same names may be overwritten.

**Data-quality caveats.** The original workflow retains positional question selection, questionnaire corrections at row indices 23, 30 and 36, a `Finished == 'True'` completion filter, regenerated questionnaire `ResponseId` values, age mean imputation and the original scoring formulas. These operations depend on the structure and ordering of the original exports. In particular, corrections expressed as row numbers should be checked against stable participant identifiers before reusing the workflow with a fresh export. The transformed outputs should be compared with the original notebook results on authorized data.

## 2. Qualtrics dilemma cleaning

`dilemma_cleaning_qualtrics.py` is the runnable conversion of `Dilemma_Cleaning_Qualtrics.ipynb`. It follows the original notebook rather than replacing the study's cleaning rules with new assumptions.

### Processing steps

1. Load the original Qualtrics dilemma CSV export.
2. Remove survey metadata and incomplete responses as specified by the notebook.
3. Normalize text and apply the existing manual data corrections.
4. Reconstruct the order of the presented dilemmas and identify the associated response columns.
5. Reshape dilemma answers from wide to long format, retaining the original dilemma and question mappings.
6. Separate and process questionnaire fields, reverse-score the specified items, and calculate questionnaire scale averages.
7. Merge questionnaire information into the long-format dilemma responses.
8. Export `Q_dilemmas.xlsx` and the intermediate `df_questionnaires.xlsx` workbook.

### Helper modules

| Helper module | Purpose |
| --- | --- |
| `functions/replace_with_numbers.py` | Convert dilemma names to the original numeric labels. |
| `functions/reverse_score.py` | Apply the original five-point reverse-scoring rule. |
| `functions/calculate_smaq.py` | Calculate passive and active SMAQ scores. |
| `functions/calculate_smus.py` | Calculate image, comparison, belief and consumption SMUS scores. |
| `functions/calculate_smms.py` | Calculate valence and agency SMMS scores. |

These are the module locations documented in the supplied Qualtrics-cleaning README. If they are moved into `helper_functions/`, update the imports accordingly.

### Setup and execution

The script was documented for Python 3.10 or later. Install the dependencies from the matching cleaning folder's `requirements.txt` and run:

```bash
python -m pip install -r requirements.txt
python dilemma_cleaning_qualtrics.py --input data/Qualtrics_Dilemmas_Results.csv --output-dir outputs
```

Without arguments, the script expects `Qualtrics_Dilemmas_Results.csv` in the current working directory and writes its outputs there. Importing the module does not automatically run the cleaning procedure. Both output workbooks may overwrite files with the same name.

The conversion preserves the original manual and positional operations, including the index-15 exclusion, index-21 correction, fixed age imputation, positional questionnaire split and row-wise timing concatenation. The main changes are organizational: helper functions were extracted, notebook-only print/display operations removed, a runnable entry point added, and some pandas assignments adjusted to avoid view/chained-assignment problems. These changes **do not constitute validation of the underlying cleaning decisions**. The original export's column structure and ordering are required.

## 3. Additional Qualtrics questionnaire cleaning

`questionnaire_cleaning.py` converts the original `Questionnaire_Cleaning_Qualtrics.ipynb` into a script dedicated to questionnaire processing. It reads `df_questionnaires.xlsx`, performs the original cleaning and scoring calculations, and writes one workbook containing two sheets:

- `cleaned_data`: the cleaned questionnaire-level records.
- `averages`: calculated scale summaries.

Run it after the Qualtrics dilemma cleaning has produced `df_questionnaires.xlsx` (or supply the path to a compatible existing workbook):

```bash
python questionnaire_cleaning.py
```

To choose input and output explicitly:

```bash
python questionnaire_cleaning.py path/to/df_questionnaires.xlsx --output path/to/cleaned_questionnaires.xlsx
```

The script preserves the original function names, processing order, calculations and constants while removing notebook displays and print statements. The original duplicated group-column names, positional `df.iloc[:, 50:]` selection and hardcoded demographic values remain unchanged. Five-point reverse scoring assumes valid responses in the range 1–5. The output file is overwritten if it already exists and must not be the same as the input file.

This step is separate from the questionnaire scoring already performed within the Qualtrics dilemma cleaner. **Do not assume that `cleaned_questionnaires.xlsx` is required by the R models**: the supplied main R script directly reads `I_dilemmas.xlsx` and `Q_dilemmas.xlsx`. The separate questionnaire workflow is useful for its own cleaned records and summaries; the relationship between its summaries and questionnaire variables embedded in `Q_dilemmas.xlsx` should be checked before interpretation.

## 4. Notebooks versus runnable Python scripts

The original `.ipynb` files are retained as **exploratory records**. They contain data inspection, intermediate tables, plotting and the reasoning or troubleshooting behind manual corrections. The `.py` files are the intended **reproducible cleaning pipeline**: they execute their transformations in a defined order, import shared helper functions and export documented outputs without depending on the order in which notebook cells were previously run.

The scripts generally preserve the original mappings and scientific decisions; they are **not independent reanalyses**. Their outputs should be checked against the original notebook exports before being used as final study data. Notebooks can contain embedded participant-level tables in saved cell outputs even when the source data files are not included. Clear all outputs and review cell contents and Git history before publishing notebooks.

## 5. Dependencies, project paths and private data

The cleaning workflows use Python, principally `pandas`, `numpy` and Excel support through `openpyxl`; install any further dependencies listed by the relevant script's `requirements.txt`. The statistical analysis uses R packages including `readxl`, `dplyr`, `ggplot2`, `lme4`, `ordinal`, `emmeans`, `DHARMa`, `performance` and `patchwork`. The pilot power analysis additionally uses `mixedpower` and `interactions`. The R scripts currently load broad package lists; some packages are used via explicit namespace calls and some require separate installation.

Use project-relative paths or locally configured paths rather than personal absolute paths. Do not commit original or cleaned participant-level CSV/XLSX files, individual timing exports, or identifying notebook outputs. A typical project `.gitignore` should exclude the local private data directory, generated results and Python caches, while keeping scripts, documentation and non-sensitive synthetic test fixtures tracked. Apply `.gitignore` before adding files: it does not remove already tracked content.

The current scripts depend on the **specific exported file schemas**; the public repository documents those expectations but does not provide participant data. The absence of original data prevents independent execution of the complete study pipeline and verification of the numerical estimates reported by the R scripts.

---

# Statistical analysis (R)

The following sections document the two statistical scripts. They appear **after the cleaning workflows** because their inputs are the cleaned dilemma data (or corresponding pilot data). The R code has been documented, not modified or statistically revalidated as part of preparing this README.

## 6. Main dilemma analysis — `Analysis_final_dilemmas_lmer.r`

This long R script performs several distinct analyses of the moral-dilemma experiment. Its length comes from repeating a complete statistical workflow for **different outcome variables**, not from one unusually complex model: each outcome requires its own data subset, response coding, candidate random-effects models, final fitted model, diagnostics or checks, estimated marginal means and figures.

### 6.1 Load and combine the two study datasets

The script reads `I_dilemmas.xlsx` and `Q_dilemmas.xlsx`, converts the literal string `"nan"` to missing values in the Instagram data, normalizes column names to lowercase, retains columns shared by both files and stacks the datasets vertically. It converts `responseid` to numeric and adds 100 to Instagram participant IDs to avoid collisions with Qualtrics IDs under the expected ID ranges. It also normalizes the sex variable and creates a participant-level sex table.

The principal analyses exclude `Dilemma_Reading` records and select dilemma types `I` and `S`. Filler dilemmas are processed separately later. The code's effect-coded predictors are:

| Predictor | Value −0.5 | Value +0.5 |
| --- | --- | --- |
| `c.group` | Instagram | Qualtrics |
| `c.dilemma` | `I` (labelled *Incidental* in plot helper) | `S` (labelled *Instrumental* in plot helper) |
| `c.risk` | `NC` (labelled *Without Involvement*) | Other coded category, intended `CC` (*With Involvement*) |

Effect coding with −0.5 and +0.5 expresses contrasts around the midpoint of each two-category predictor. The published labels and the original dilemma/risk codebook should be checked for consistency: the code assigns +0.5 to every value other than the designated negative category, including an unexpected value if one is present.

### 6.2 Yes/No dilemma decisions

The script selects rows with `question_new == "Yes/No"`, calculates descriptive affirmative-response percentages by group and dilemma type and displays a bar plot. It prepares effect-coded predictors and compares participant-level random-effects structures using `glmer()` with a binomial family: a random-intercept model, a model with a risk slope, and a model with both risk and dilemma slopes.

It then fits a main binomial mixed model with additive fixed effects of experimental group, risk and dilemma type and participant-specific random effects. The script requests Wald confidence intervals and performs convergence, singular-fit, collinearity and dispersion checks, followed by simulation-based residual diagnostics using `DHARMa` (uniformity, dispersion and outliers). It also uses `drop1()` for term-removal comparisons and computes a model-fit index where supported.

Finally, `emmeans()` estimates predicted probabilities for combinations of group, dilemma type and risk, relabels effect-coded conditions for presentation and plots estimated affirmative-response probabilities. **The script's model is additive in fixed effects**; the plotted combinations do not by themselves imply the model includes interaction terms. The binomial response coding must be verified to ensure that the fitted event probability corresponds to the intended *Yes* response.

### 6.3 Arousal ratings

The script selects `question_new == "Arousal"`, converts ratings to numeric, checks non-finite values and excludes missing answers. It then treats the rating as an **ordered categorical response** and compares cumulative-link mixed models (`ordinal::clmm`) with increasingly complex participant random-effects structures.

The chosen model includes fixed effects for group, risk and dilemma type and participant-level random slopes. It reports coefficient estimates and approximate Wald intervals, calculates a model-fit measure where supported and runs a nominal-effects check on a related `clm()` model. Through `emmeans`, it computes both an estimated mean response category (`mode = "mean.class"`) and probabilities for individual ordinal categories (`mode = "prob"`). The script produces combined mean-rating and response-probability figures and saves `AD_CLMM_combined_plot.png`.

### 6.4 Valence ratings

The valence section selects `question_new == "Valence"`, converts answers to an ordered factor and repeats the ordinal-model workflow with its own participant random-effects comparison. The final `clmm` model includes group, risk and dilemma type, with a participant intercept and separate risk and dilemma slope terms. It reports coefficients and intervals, performs a nominal-effects check with `clm()`, generates estimated mean-category values and category probabilities, and saves `VD_CLMM_combined_plot.png`.

### 6.5 Moral acceptability ratings

For `question_new == "Moral_Acceptability"`, the script fits and compares cumulative-link mixed models for ordered ratings, then selects a model with group, risk and dilemma-type fixed effects plus participant random effects. It calculates coefficient intervals, evaluates a nominal-effects check through `clm()` and obtains model-based mean-category estimates and response-category probabilities. The combined figure is saved as `MAD_CLMM_combined_plot.png`.

These three rating outcomes are kept separate because they represent different constructs and may require different fitted random-effects structures; their distinct sections and figures account for much of the R file's length.

### 6.6 Filler dilemmas

The last section selects `dilemma_type == "Filler"` and handles these records separately from the main `I` and `S` dilemmas. It summarizes Yes/No responses by study group, fits a binomial `glm()` for the filler-choice outcome and applies residual diagnostics. For filler arousal, valence and moral acceptability, it prepares ordered responses and fits ordinal cumulative-link models (`clmm`, with an additional `clm` for moral acceptability), reports approximate confidence intervals and runs nominal-effects checks on associated `clm()` models.

One source-code decision needs explicit justification: an observed filler moral-acceptability value of 8 is changed to 7 with a comment suggesting a keyboard error. This is a research-data correction, not a neutral formatting change, and should be verified against the original response scale and documentation.

### 6.7 Outputs and interpretation

The analysis produces model summaries, random-effects comparison tables, diagnostic plots, coefficient intervals, `emmeans` estimates, category-probability plots and saved PNG figures for the three main ordinal outcomes. Most output is printed or displayed during interactive execution rather than exported as a complete machine-readable report. The figure-saving calls currently contain an absolute Windows directory and should be changed to a configurable, local output path before the script is considered portable.

The script also installs missing R packages automatically, which is inconvenient for a controlled, reproducible environment. Prefer documenting installation separately and recording versions with `renv` (or an equivalent lockfile) rather than automatically installing them whenever the analysis runs.

**Checks to complete before claiming an end-to-end reproducible analysis:** verify the factor/event coding for binomial models; verify the participant-ID transformation and source overlap; correct the parameter-count extraction `attr(logLik(x), "dfYN")` (the usual attribute is `"df"`); verify ordinal-model assumptions and the appropriateness of nominal checks; confirm the filler-value correction; and rerun all models on the authorized cleaned datasets. These are issues to review, **not changes silently made to the original analyses**.

## 7. Pilot simulation power analysis — `power_analysis.r`

This separate script assesses how estimated statistical power changes with sample size using the available **pilot Instagram and Qualtrics datasets** (`pilot_I.xlsx` and `pilot_Q.xlsx`). It does not compute power from a conventional independent-samples formula. Instead, it fits pilot-based mixed models and passes them to the R package `mixedpower`, which simulates data under assumptions derived from the fitted model and estimates how frequently a tested effect meets the specified detection criterion.

### 7.1 Prepare the pilot data

The script standardizes column names, retains shared columns, stacks the pilot datasets, offsets Instagram participant IDs by 100, and removes `Dilemma_Reading` observations. It retains the main `I` and `S` dilemma types, selects the relevant question types and uses the same group, dilemma and risk effect coding as the main statistical analysis.

For the Yes/No analyses, affirmative responses (`si` or `sì`) are coded as 1 and other responses as 0 in the explicitly created binary variable. A later section selects a **16-participant pilot subset**, consisting of IDs 1–8 and 101–108 under the script's renumbering scheme. The assumed generalizability of this pilot subset is therefore important when interpreting simulated power.

### 7.2 Choice-outcome power models

The script begins with a linear mixed model for the 0/1-coded Yes/No outcome, including an experimental-group fixed effect and random intercepts for participant and dilemma type. It then builds binomial mixed models (`glmer()`) for Yes/No decisions, including one model with a group effect alone and a second with a group × dilemma-type × risk interaction plus a participant random intercept. The latter overwrites the `mlm` variable and is used in later simulation calls.

The script probes two-way and three-way interactions using the `interactions` package and uses `mixedpower()` to evaluate specified fixed effects over different simulated participant sample sizes. Because the first power fit treats a binary outcome using `lmer()`, it should not be interpreted as identical to the later binomial model; its modelling assumptions need to be justified separately.

### 7.3 Rating-outcome power models

The script then processes three rating outcomes separately:

| Outcome | Pilot model used for simulation |
| --- | --- |
| Arousal | `lmer(answer ~ c.group * c.dilemma * c.risk + (1 | responseid))` |
| Valence | The corresponding `lmer` model with the same three-way fixed-effects structure and participant random intercept. |
| Moral acceptability | The corresponding `lmer` model with the same fixed-effects structure and participant random intercept. |

For each outcome, it fits the pilot model, simulates power using `mixedpower()`, converts the result to a table and displays a power plot. Note that these power-analysis models treat ratings as numeric and use linear mixed models, whereas the main confirmatory/primary R analysis treats the ratings as ordered categories and uses cumulative-link mixed models. **The power simulations therefore do not directly represent the final ordinal models.**

### 7.4 Simulation settings and interpretation

The repeated `mixedpower()` calls specify:

| Parameter | Value in script | Interpretation |
| --- | --- | --- |
| `simvar` | `"responseid"` | Participant is the sampling unit whose number varies. |
| `steps` | `seq(60, 120, by = 10)` | Simulated sample sizes of 60, 70, 80, 90, 100, 110 and 120 participants. |
| `n_sim` | `1000` | Number of simulations requested for each setting. |
| `critical_value` | `2` | Detection threshold passed to `mixedpower`; interpretation depends on the installed package/version and its test-statistic definition. |
| `fixed_effects` | Selected main-effect coefficients such as `c.group`, `c.dilemma` and `c.risk` | Effects for which simulation-based detection rates are estimated. |

The resulting estimated power is the **proportion of simulated studies meeting the selected criterion**, conditional on the fitted pilot-model coefficients, variability and design assumptions. A power curve can help evaluate candidate sample sizes, but is not evidence that a later study actually achieved a given level of power. No numeric power values are documented here because the pilot data and generated results have not been provided.

The script specifies fixed-effect *main-effect names* in its `mixedpower()` calls, even when the underlying pilot models include interactions. Power for the interaction terms should not be assumed to have been evaluated merely because the interactions appear in the fitted model formula. The code also calls `mixedpower()` more than once into an object named `powertest`, overwriting earlier results rather than retaining all runs separately.

## 8. Reproducing the study

With authorized access to the original data, the intended sequence is: (1) clean the Instagram response and questionnaire exports; (2) clean the Qualtrics dilemma export; (3) optionally generate the separate cleaned Qualtrics questionnaire workbook; (4) confirm that `I_dilemmas.xlsx` and `Q_dilemmas.xlsx` have matching expected columns and compatible participant identifiers; (5) run `Analysis_final_dilemmas_lmer.r`; and (6) run `power_analysis.r` on the **separate pilot files** when documenting the study's sample-size planning.

The provided code reflects the historical study's cleaning and modelling decisions and includes some positional data corrections and local environment assumptions. Publicly documenting those details helps auditability but does not replace study-specific validation. The underlying participant-level workbooks are private, and no results should be described as independently reproduced solely because the scripts and README are public.
