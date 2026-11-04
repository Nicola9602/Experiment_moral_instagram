# Instagram dilemma cleaning

This folder contains a runnable version of the original `Dilemma_cleaning_Instagram.ipynb` cleaning steps. The notebook remains the exploratory record and contains data inspection and plotting; `clean_instagram.py` is the repeatable cleaning sequence, without prints or exploration plots.

## Setup

Install `pandas`, `numpy`, `openpyxl` (`pip install pandas numpy openpyxl`). Keep all `.py` files in this folder. Update `folder_path`, `questions_file`, `questionnaires_file`, and `output_folder` in `clean_instagram.py`, then run `python clean_instagram.py` from this folder.

The original input files are private and are **not included**. The script expects individual timing `.xlsx` files, `Risultati_instagram.xlsx`, and `Instagram_Questionnaires.xlsx`.

## Helper files

- `convert_to_seconds.py`: time conversion.
- `convert_question_name.py`: timing question names.
- `map_dilemma_functions.py`: dilemma type and risk maps.
- `dilemma_functions.py`: adds dilemma-reading rows and cleans answers.
- `questionnaire_functions.py`: five-point reverse scoring.
- `questionnaire_scoring.py`: SMAQ, SMUS, SMMS scoring.

Outputs: `I_timings.xlsx`, `I_dilemmas.xlsx`, and `I_questionnaire_averages.xlsx`. The latter two are written explicitly here; the notebook's `I_dilemmas` export was commented out.

## Verify before research use

The code retains the notebook's positional question selection, raw questionnaire corrections at row indices 23, 30 and 36, `Finished == 'True'` filter, regenerated questionnaire ResponseIds, age mean imputation and original scoring formulas. These are **not portable decisions** unless the input layout is unchanged. Compare produced outputs with the original notebook on your authorized datasets. The timing table is saved separately, as in the notebook; this code does not join it into dilemma responses. Check cleaned notebooks for saved private outputs before publishing.
