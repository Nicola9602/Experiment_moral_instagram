#!/usr/bin/env python3
"""Run the questionnaire cleaning workflow from the original Qualtrics notebook."""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from functions.reverse_score import reverse_score
from functions.calculate_smaq import calculate_smaq
from functions.calculate_SMUS import calculate_SMUS
from functions.calculate_SMMS import calculate_SMMS


def main(input_path="df_questionnaires.xlsx", output_path="cleaned_questionnaires.xlsx"):
    """Run the original calculations, save both tables, and return them."""
    df = pd.read_excel(input_path)

    # Define column groups
    smaq_passive_cols = ['Q1_1', 'Q1_2', 'Q1_3', 'Q1_4', 'Q1_5', 'Q1_6', 'Q1_7', 'Q1_8', 'Q1_9', 'Q1_10']
    smaq_active_cols = ['Q1_11', 'Q1_12', 'Q1_13', 'Q1_14', 'Q1_15', 'Q1_16', 'Q1_17']
    smms_valence = ['Q1_1.1', 'Q1_2.1', 'Q1_3.1', 'Q1_4.1', 'Q1_5.1', 'Q1_6.1', 'Q1_7.1']
    smms_agency = ['Q1_8.1', 'Q1_9.1', 'Q1_10.1', 'Q1_11.1', 'Q1_12.1']
    smus_image = ['Q1_1.2', 'Q1_2.2', 'Q1_3.2', 'Q1_4.2', 'Q1_5.2']
    smus_comparison = ['Q1_6.2', 'Q1_7.2', 'Q1_8.2']
    smus_belief = ['Q1_9.2', 'Q1_10.2', 'Q1_11.2', 'Q1_12.2']
    smus_consumption = ['Q1_13.1', 'Q1_14.1', 'Q1_15.1', 'Q1_16.1', 'Q1_17.1']

    # Create renaming dictionary (all columns in group get the same name)
    renaming_dict = {}
    renaming_dict.update({col: 'SMAQ_Passive' for col in smaq_passive_cols})
    renaming_dict.update({col: 'SMAQ_Active' for col in smaq_active_cols})
    renaming_dict.update({col: 'SMMS_Valence' for col in smms_valence})
    renaming_dict.update({col: 'SMMS_Agency' for col in smms_agency})
    renaming_dict.update({col: 'SMUS_Image' for col in smus_image})
    renaming_dict.update({col: 'SMUS_Comparison' for col in smus_comparison})
    renaming_dict.update({col: 'SMUS_Belief' for col in smus_belief})
    renaming_dict.update({col: 'SMUS_Consumption' for col in smus_consumption})

    # Apply the renaming
    df.rename(columns=renaming_dict, inplace=True)

    # There is aamimatch because the Qualtrics questionnaire is not the latest version lcks the last participant

    # Calculate mean and sd age and number of famle vs male
    df['Age'] = pd.to_numeric(df['Age'], errors='coerce')
    mean_age_q = df['Age'].mean()
    sd_age_q = df['Age'].std()

    # number of famle vs male
    sex_counts = df['Sex'].value_counts()

    n_males_q = 10
    n_female_q = 25

    mean_age_by_sex_q_f = 21.72
    mean_age_by_sex_q_m = 22.30

    sd_age_by_sex_q_f =  0.936305
    sd_age_by_sex_q_m = 2.110819

    # Mean age by sex
    mean_age_by_sex = df.groupby('Sex')['Age'].mean()

    # Standard deviation of age by sex
    sd_age_by_sex = df.groupby('Sex')['Age'].std()

    # values from the Instagram dataset
    mean_age_i = 23.0
    sd_age_i = 2.4842360136324753

    n_males_i = 21
    n_females_i = 15

    mean_age_by_sex_i_m = 23.619048
    mean_age_by_sex_i_f = 22.133333

    sd_age_by_sex_i_m = 2.940683
    sd_age_by_sex_i_f = 1.302013

    #so total stuff

    pooled_sd = np.sqrt(((35 - 1) * sd_age_q**2 + (35 - 1) * sd_age_i**2) / (35 + 35 - 2))

    # Calculate the combined mean

    combined_mean = (mean_age_q + mean_age_i) / 2

    # --- FEMALES ---
    # Combined mean age for females
    combined_mean_f = (n_female_q * mean_age_by_sex_q_f + n_females_i * mean_age_by_sex_i_f) / (n_female_q + n_females_i)

    # Pooled SD for females
    pooled_sd_f = np.sqrt(
        ((n_female_q - 1) * sd_age_by_sex_q_f**2 + (n_females_i - 1) * sd_age_by_sex_i_f**2) / (n_female_q + n_females_i - 2)
    )

    # --- MALES ---
    # Combined mean age for males
    combined_mean_m = (n_males_q * mean_age_by_sex_q_m + n_males_i * mean_age_by_sex_i_m) / (n_males_q + n_males_i)

    # Pooled SD for males
    pooled_sd_m = np.sqrt(
        ((n_males_q - 1) * sd_age_by_sex_q_m**2 + (n_males_i - 1) * sd_age_by_sex_i_m**2) / (n_males_q + n_males_i - 2)
    )

    # Change the reverse columns

    # Get the reverse columns
    reverse_columns = [col for col in df if 'Reverse' in col]

    rev_col_index = [df.columns.get_loc(col) for col in reverse_columns]

    for col in reverse_columns:
        df[col] = df[col].apply(reverse_score)

    #Social media activity questionnaire colaculation SMAQ

    # Social media use use Scale calculation

    # Calculate the Social media mindset scores SMMS

    calculate_smaq(df)
    calculate_SMMS(df)
    calculate_SMUS(df)

    Questionnaires_averages = df.iloc[:,50:]

    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="cleaned_data", index=False)
        Questionnaires_averages.to_excel(writer, sheet_name="averages", index=False)

    return df, Questionnaires_averages


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input", nargs="?", type=Path, default=Path("df_questionnaires.xlsx"),
        help="Input Excel workbook (default: df_questionnaires.xlsx).",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=Path("cleaned_questionnaires.xlsx"),
        help="Output Excel workbook (default: cleaned_questionnaires.xlsx).",
    )
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Input and output must be different files.")
    main(args.input, args.output)
