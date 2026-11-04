# Qualtrics Dilemmas Cleaning

Python conversion of the original cleaning notebook. The script follows the same processing order: remove survey metadata and incomplete responses, normalize text, apply the existing manual corrections, reconstruct dilemma order, reshape responses, reverse-score questionnaire items, calculate scale averages, and merge scores into the final dilemma table.

## Run

Requires Python 3.10 or later. From this folder:

```bash
python -m pip install -r requirements.txt
python dilemma_cleaning_qualtrics.py --input data/Qualtrics_Dilemmas_Results.csv --output-dir outputs
```

Without arguments, the script reads `Qualtrics_Dilemmas_Results.csv` from the current working directory and writes there. Imports do not run the cleaning pipeline. Ordinary execution produces no diagnostic printouts; errors retain their normal Python traceback.

## Files

| File | Purpose |
| --- | --- |
| `dilemma_cleaning_qualtrics.py` | Main executable workflow, retaining the notebook's sequence and variable names. |
| `functions/replace_with_numbers.py` | Maps dilemma names to the existing numerical labels. Labels are passed explicitly instead of accessed as a notebook global. |
| `functions/reverse_score.py` | Original five-point reverse-scoring function. |
| `functions/calculate_smaq.py` | Original passive and active SMAQ averages. |
| `functions/calculate_smus.py` | Original image, comparison, belief, and consumption SMUS averages. |
| `functions/calculate_smms.py` | Original valence and agency SMMS averages. |

## Outputs

- `df_questionnaires.xlsx`: intermediate questionnaire dataset, written and read again as in the notebook.
- `Q_dilemmas.xlsx`: final long-format dilemma data with questionnaire scores.

Existing output files with these names are overwritten.

## Conversion scope

Cleaning rules, manual corrections, mappings, demographic calculations, commented-out alternatives, and scoring formulas are preserved. Notebook displays, print statements, and loops used only for printing are removed. Function definitions are extracted into modules. A `main()` entry point and optional input/output arguments make the script executable.

Two small pandas changes avoid chained assignment and accidental view mutation: dilemma-order assignment uses `.loc`, and the dilemma/questionnaire slices use `.copy()`. Elementwise `applymap` calls use the equivalent `DataFrame.map` API to avoid deprecation printouts. Dependencies are constrained to compatible major versions.

The input must retain the notebook's expected Qualtrics column names, order, and row indices. In particular, the original index-15 exclusion, index-21 correction, fixed age imputation, positional questionnaire split, and row-wise timing concatenation remain in place. The commented questionnaire-renaming block remains inactive. Demographic constants and pooled calculations are retained without reinterpretation. This conversion does not reassess those research decisions.

Syntax, command-line execution, function equivalence, and exported workbooks were checked using a synthetic fixture. The original private CSV was not supplied, so results on the real export still need verification.
