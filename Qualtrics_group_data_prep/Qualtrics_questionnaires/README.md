# Questionnaire cleaning (Qualtrics)

A minimal Python conversion of `Questionnaire_Cleaning_Qualtrics(1).ipynb`.
The four original functions live in separate modules and are imported by
`questionnaire_cleaning.py`. Importing the main file does not run the workflow.

## Run

Requires Python 3 and the original questionnaire Excel workbook.

```bash
python -m pip install -r requirements.txt
python questionnaire_cleaning.py
```

By default, reads `df_questionnaires.xlsx` from the current working directory
and writes `cleaned_questionnaires.xlsx`. The output has `cleaned_data` and
`averages` sheets. Successful runs produce no console printouts.

To choose paths:

```bash
python questionnaire_cleaning.py path/to/input.xlsx --output path/to/results.xlsx
```

The output file is overwritten if it already exists; the input path must differ.

## Preserved behavior

The original calculations, function names, constants, processing order, and
comments are retained. Notebook displays and print statements are removed.
The unused `re` import is removed. An executable entry point and Excel export
are added. `.gitignore` keeps caches, the virtual environment, and Excel data
out of Git.

The original duplicate group column names and `df.iloc[:, 50:]` selection
remain unchanged. The original hard-coded demographic values also remain.
This conversion does not correct or reinterpret the notebook's scoring logic.
Reverse scoring still requires valid scores from 1 to 5.

The source workbook was not supplied with the notebook. Validation uses
synthetic data to compare the converted calculations with the original code;
real-data validation still requires that workbook.
