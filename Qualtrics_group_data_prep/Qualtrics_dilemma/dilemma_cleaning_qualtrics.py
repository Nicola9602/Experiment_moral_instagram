#!/usr/bin/env python3
"""Clean the Qualtrics dilemmas export and calculate questionnaire scores.

Converted from Dilemma_Cleaning_Qualtrics.ipynb. Cleaning order, mappings,
manual corrections, questionnaire formulas, and demographic calculations
are retained. Only notebook displays and console diagnostics are removed.
"""

import argparse
from pathlib import Path
import re

import numpy as np
import pandas as pd

from functions.replace_with_numbers import replace_with_numbers
from functions.reverse_score import reverse_score
from functions.calculate_smaq import calculate_smaq
from functions.calculate_smus import calculate_SMUS
from functions.calculate_smms import calculate_SMMS


def main(input_file="Qualtrics_Dilemmas_Results.csv", output_dir="."):
    """Run the original cleaning workflow and write its two Excel outputs."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(input_file, sep=',')

    #=======================================================================
    #Drop useless columns
    #=======================================================================

    #Raname Duration (in secons) to toal duration
    df = df.rename(columns={'Duration (in seconds)': 'Total_Duration_Seconds'})

    df.drop(['StartDate', 'EndDate', 'Status', 'IPAddress', 'Progress', 'RecordedDate', 'RecipientLastName', 'RecipientFirstName',
     'RecipientEmail', 'ExternalReference', 'LocationLatitude', 'LocationLongitude', 'DistributionChannel', 'UserLanguage',],axis=1, inplace=True)

    df.drop(columns=[col for col in df if 'click count' in col.lower()], inplace=True)
    df.drop(columns=[col for col in df if 'first click' in col.lower() or 'last click' in col.lower()], inplace=True)

    #drop the participants that didnt' finish.
    df = df[df['Finished'] == 'True']

    # drop participant 15 becuase it has too many Nans = 21
    df = df.drop(index=15)

    #=======================================================================
    # Reindex the RespondeId column with numbers from the 2nd on
    #=======================================================================
    df['ResponseId'] = range(1, len(df) +1 )

    #Change Q3 entry 21 from nan to youtube
    # drop column Q3_5_TEXT which is all Nan
    df.loc[21,'Q3'] = 'Youtube'
    df = df.drop(columns='Q3_5_TEXT')

    #=======================================================================
    # Change all the Time-Entries into numeric stuff they are string rn
    #=======================================================================

    # First get the columns you are working with
    items = df.filter(regex='Page Submit|6|10|12|Q1').columns
    #items = df.filter(like='Page Submit').columns
    df[items] = df[items].apply(pd.to_numeric, errors='coerce')

    # Numeric conversion complete.

    #=======================================================================
    # Find all text entries different from the ones allowed
    #=======================================================================
    # Make all lower case and strip
    df = df.map(lambda x: x.lower().strip() if isinstance(x, str) else x)
    # replace all sì with si
    df = df.map(lambda x: x.replace('sì', 'si') if isinstance(x,str) else x)

    allowed_str = ['si', 'no', 'triste', 'arrabbiato', 'impaurito', 'felice', 'sorpreso']

    invalid_positions = [(row, col) for row in df.index[2:] for col in df.columns [3:135]
                         if isinstance(df.at[row,col], str) and df.at[row, col] not in allowed_str]


    #=======================================================================
    # remap the invalid with valid stuff
    replacement_dict = {
        'di brutto': 'si',
        'no, la aiuterei': 'no',
        'trsite': 'triste',  # Fix typo in 'trsite' to 'triste'
        'arrabbiata': 'arrabbiato',  # Assuming 'arrabbiata' should be replaced with 'no'
        'impairito': 'impaurito',   # Assuming 'impaurito' should be replaced with 'no'
        'non lo so': 'si',   # Assuming 'non lo so' should be replaced with 'si'
        'triste e impaurito': 'triste',  # Assuming you want to standardize
        'triste e felice': 'triste'      # Assuming this is the intended replacement
    }

    df = df.map(lambda x: replacement_dict.get(x, x) if isinstance(x,str) else x)

    invalid_positions2 = [(row, col) for row in df.index[2:] for col in df.columns [3:135]
                         if isinstance(df.at[row,col], str) and df.at[row, col] not in allowed_str]

    #=======================================================================
    # Dealing with Nans
    #=======================================================================
    # Find the Nans and the relative columns etc

    nan_columns = df[2:].isna().sum()[lambda x: x>0].index
    nan_rows = {}
    for col in nan_columns:
        nan_rows[col] = df.loc[2:, col][df[col].isna()].index.tolist()

    # Sadly for the 36 I have to keep it like this.

    # Find the nan in Q1 'Age'
    nan_index_Q1 = df[df['Q1'].isna()].index

    #Find the mode of 'Age'
    most_common_age = round(df.loc[2:, 'Q1'].mean())


    # Change that NaN it with the mode of 'Age'
    df.loc[nan_index_Q1, 'Q1'] = 21

    #=======================================================================
    # REORDERING DILEMMAS
    #=======================================================================

    # Labels corresponding to the dilemmas (fixed mapping)
    labels = {
        1: "Incidente-senzaCoinvolgimentoInfermiere",
        2: "Incidentale-senzaCoinvolgimentoGru",
        3: "IncidentaleCoinvolgimentoAutostrada",
        4: "Incidentalecoinvolgimentocavernasotterranea",
        5: "StrumentalisenzacoinvolgimentoAscensore",
        6: "Strumsenzacoinvolsparatoria",
        7: "StrumconcoinvElicottero",
        8: "StrumconcoinvRapimento",
        9: "FillerCountryroad",
        10: "FillerParcheggio",
        11: "Fillerportafogli",
        12: "Fillersupermarket"
    }


    # Take only the columns with the names of the dilemmas

    selected_columns = [col for col in df.columns if "FL_3_DO" in col][:12]

    # Create a new columns with inside the dictionaries
    df['X'] = df[selected_columns].apply(lambda row: dict(zip(selected_columns, row)), axis=1)

    # Strip each dictionary item from FL_3_DO_. TO do that
    # lmbda loops trhough each row (d) then we use dictionary comprehension
    # this creates a new dictionary looping over the existing one
    # d.items returns all the key, value couples in the dictionary
    # k.replace replaces all of them.

    # This would be the same of having this function
    #def rename_keys(d):
    #    return {k.replace("FL_3_DO_", ""): v for k, v in d.items()}
    #df['X'] = df.['X'].apply(rename_keys)

    df['X'] = df['X'].apply(lambda d: {k.replace("FL_3_DO_", ""): v for k, v in d.items()})


    # Sort the order so that it comes from first to end the right order of dilemmas

    df['dilemmas_order'] = df['X'][2:].apply(lambda d: sorted(d.keys(), key=lambda k: int(d[k])))

    # Now assign back numbers to the dilemmas given the labels list
    # that is, replace the order with numbers given labels dictionary


    # this part "for name in dilemmas_list" takes the key for each name in the list
    # for key, value in labels.items() loops over the dictionary and checks if value == name
    # the first key defines what we want to put in the new list, that is
    # the number corresponding to the dilemma name from the labels dictionry if the condition is met


    df.loc[df.index[2:], 'dilemmas_order'] = df['dilemmas_order'].iloc[2:].apply(
        lambda names: replace_with_numbers(names, labels)
    )

    response_id_index = df.columns.get_loc('ResponseId')

    df.insert(response_id_index+1, 'dilemmas_order', df.pop('dilemmas_order'))

    df.drop(columns=['X'])

    # Divide dataset between dilemmas and questionnaires

    # dataframe for dilemmas
    dfd = df.iloc[:,:136].copy()

    #dataframe for questionnaires
    dfq = df.iloc[:,136:].copy()
    id_column = df['ResponseId']
    df.rename(columns={df.columns[137]:'sex'}, inplace=True)
    genere_column = df['sex']
    dfq.insert(0, 'ResponseId', id_column)
    dfd.insert(3, 'sex', df['sex'])


    #df_dilemmas.to_csv('df_dilemmas.csv')
    dfq.to_excel(output_dir / 'df_questionnaires.xlsx', index=False)

    ####################################################################################
    # TRANSFORM THE DATASET FROM WIDE TO LONG FORMAT
    ####################################################################################

    melted_questions = pd.melt(
        dfd,
        id_vars=['ResponseId', 'sex', 'dilemmas_order', 'Total_Duration_Seconds', 'Finished'], # the columns that remain columns
        var_name ='Question',
        value_vars = dfd.filter(regex='4|6|8|10|12').columns,
        value_name='Answer'
    )


    melted_timings = pd.melt(
        dfd,
        id_vars=['ResponseId', 'Total_Duration_Seconds'], # the columns that remain columns
        var_name ='Question',
        value_vars = dfd.filter(regex='_Page Submit').columns,
        value_name='Duration'
    )

    # NOW DIVIDE THE DATASETS IN TWO, ONE IS GOING TO BE THE QUESTION ANSWERS AND THE OTHER THE TIMING
    ####################################################################################

    special_questions = ['CountryRoad', 'Parking', 'Wallet', 'Market']

    # Initialize the new columns with empty values
    melted_questions['Dilemma'] = ''
    melted_questions['Dilemma_type'] = ''
    melted_questions['Risk'] = ''
    melted_questions['Question_New'] = ''

    # Iterate through the rows
    for index, row in melted_questions.iterrows():
        question = row['Question']

        if any(special in question for special in special_questions):
            # Apply the special logic (only Dilemma and Question_Num)
            melted_questions.at[index, 'Dilemma'] = re.split(r'[_\.]', question)[0]
            melted_questions.at[index, 'Question_New'] = re.split(r'[.]', question)[1]
            melted_questions.at[index, 'Dilemma_type'] = 'Filler'
            melted_questions.at[index, 'Risk'] = 'Nan'
        else:
            # Apply the general logic (Dilemma, Dilemma_type, Risk, Question_Num)
            split_parts = re.split(r'[_\.]', question)
            melted_questions.at[index, 'Dilemma'] = split_parts[0]
            melted_questions.at[index, 'Dilemma_type'] = split_parts[1]
            melted_questions.at[index, 'Risk'] = split_parts[2]
            melted_questions.at[index, 'Question_New'] = split_parts[3]


    #TIMING DATASET
    ####################################################################################

    # Initialize the new columns with empty values
    melted_timings['Dilemma'] = ''
    melted_timings['Dilemma_type'] = ''
    melted_timings['Risk'] = ''
    melted_timings['Question_New'] = ''

    # Iterate through the rows
    for index, row in melted_timings.iterrows():
        question = row['Question']

        if any(special in question for special in special_questions):
            # Apply the special logic (only Dilemma and Question_Num)
            split_parts = re.split(r'[_\.]', question)
            melted_timings.at[index, 'Dilemma'] = split_parts[0]
            melted_timings.at[index, 'Question_New'] = split_parts[2]
            melted_timings.at[index, 'Dilemma_type'] = 'Filler'
            melted_timings.at[index, 'Risk'] = 'Nan'
        else:
            # Apply the general logic (Dilemma, Dilemma_type, Risk, Question_Num)
            split_parts = re.split(r'[_\.]', question)
            melted_timings.at[index, 'Dilemma'] = split_parts[0]
            melted_timings.at[index, 'Dilemma_type'] = split_parts[1]
            melted_timings.at[index, 'Risk'] = split_parts[2]
            melted_timings.at[index, 'Question_New'] = split_parts[3]


    # ADD ALL THE READING THAT IS 2 TO THE DATASET melted_question SO THAT BOTH HAVE THE SAME LENGTH
    ####################################################################################

    # Step 1: Identify rows where Question_New == 4
    q4_rows = melted_questions[melted_questions['Question_New'] == '4']

    q2_rows = q4_rows.copy()

    q2_rows['Question_New'] = '2'
    q2_rows['Answer'] = np.nan

    # Step 2: Loop through each unique 'Dilemma' in q2_rows and insert at the right position
    for dilemma in q2_rows['Dilemma'].unique():
        # Find the first occurrence of this Dilemma in melted_questions
        dilemma_first_index = melted_questions[melted_questions['Dilemma'] == dilemma].index.min()

        # Filter the rows in q2_rows that belong to this dilemma
        dilemma_q2_rows = q2_rows[q2_rows['Dilemma'] == dilemma]

        # Insert these rows above the first occurrence in melted_questions
        melted_questions = pd.concat([
            melted_questions.iloc[:dilemma_first_index],  # Rows before this dilemma
            dilemma_q2_rows,  # The rows to insert
            melted_questions.iloc[dilemma_first_index:]  # Rows after the first occurrence
        ], ignore_index=True)

    columns_to_add = [col for col in melted_timings if col not in melted_questions]

    melted_questions = pd.concat([melted_questions, melted_timings[columns_to_add]], axis=1)


    # RENAME ALL THE THINGS WITH THEIR RIGHT NAME
    ####################################################################################
    for index, value in melted_questions['Question_New'].items():
        if value == '2':
            melted_questions.at[index, 'Question_New'] = 'Dilemma_Reading'
        elif value == '4':
            melted_questions.at[index, 'Question_New'] = 'Yes/No'
        elif value == '6':
            melted_questions.at[index, 'Question_New'] = 'Moral_Acceptability'
        elif value == '8':
            melted_questions.at[index, 'Question_New'] = 'Mood'
        elif value == '10':
            melted_questions.at[index, 'Question_New'] = 'Valence'
        elif value == '12':
            melted_questions.at[index, 'Question_New'] = 'Arousal'

    #Change Risk for the dilemma reading to nan
    melted_questions.loc[melted_questions['Question_New'] == 'Dilemma_Reading', 'Risk'] = np.nan

    # Drop the total_duration_second column because I want to calculate it afterwards
    melted_questions.drop(columns='Total_Duration_Seconds', inplace=True)

    # Given that somehow the dilemma_reading under Question has number .4 or others chang it back to 2

    melted_questions.loc[melted_questions['Question_New'] == 'Dilemma_Reading', 'Question'] \
        = melted_questions.loc[melted_questions['Question_New'] == 'Dilemma_Reading', 'Question'].str.replace(
            r'(\.\d+)', '.2', regex=True)

    melted_questions['Group'] = 'Qualtrics'

    # Download the dataset
    ####################################################################################

    #melted_questions.to_excel('Q_dilemmas.xlsx', index=False)

    # QUESTIONNAIRE CLEANING AND ADDING TO THE MELTED_QUESTIONS

    # FIrst rename melted_questions to Q_dilemmas

    Q_dilemmas = melted_questions

    # Import the questionnaires dataset
    df = pd.read_excel(output_dir / 'df_questionnaires.xlsx')

    df.rename(columns= {'Q1': 'Age', 'Q2':'Sex', 'Q3': 'Social'}, inplace=True)

    # # Define column groups
    # smaq_passive_cols = ['Q1_1', 'Q1_2', 'Q1_3', 'Q1_4', 'Q1_5', 'Q1_6', 'Q1_7', 'Q1_8', 'Q1_9', 'Q1_10']
    # smaq_active_cols = ['Q1_11', 'Q1_12', 'Q1_13', 'Q1_14', 'Q1_15', 'Q1_16', 'Q1_17']
    # smms_valence = ['Q1_1.1', 'Q1_2.1', 'Q1_3.1', 'Q1_4.1', 'Q1_5.1', 'Q1_6.1', 'Q1_7.1']
    # smms_agency = ['Q1_8.1', 'Q1_9.1', 'Q1_10.1', 'Q1_11.1', 'Q1_12.1']
    # smus_image = ['Q1_1.2', 'Q1_2.2', 'Q1_3.2', 'Q1_4.2', 'Q1_5.2']
    # smus_comparison = ['Q1_6.2', 'Q1_7.2', 'Q1_8.2']
    # smus_belief = ['Q1_9.2', 'Q1_10.2', 'Q1_11.2', 'Q1_12.2']
    # smus_consumption = ['Q1_13.1', 'Q1_14.1', 'Q1_15.1', 'Q1_16.1', 'Q1_17.1']

    # # Create renaming dictionary (all columns in group get the same name)
    # renaming_dict = {}
    # renaming_dict.update({col: 'SMAQ_Passive' for col in smaq_passive_cols})
    # renaming_dict.update({col: 'SMAQ_Active' for col in smaq_active_cols})
    # renaming_dict.update({col: 'SMMS_Valence' for col in smms_valence})
    # renaming_dict.update({col: 'SMMS_Agency' for col in smms_agency})
    # renaming_dict.update({col: 'SMUS_Image' for col in smus_image})
    # renaming_dict.update({col: 'SMUS_Comparison' for col in smus_comparison})
    # renaming_dict.update({col: 'SMUS_Belief' for col in smus_belief})
    # renaming_dict.update({col: 'SMUS_Consumption' for col in smus_consumption})

    # # Apply the renaming
    # df.rename(columns=renaming_dict, inplace=True)

    # Calculate mean and sd age and number of famle vs male
    df['Age'] = pd.to_numeric(df['Age'], errors='coerce')
    mean_age_q = df['Age'].mean()
    sd_age_q = df['Age'].std()

    # number of famle vs male

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

    # Social Media Activity Questionnaire calculation (SMAQ)


    # Social Media Use Scale calculation (SMUS)


    # Social Media Mindset Scale calculation (SMMS)


    # Now you can call these functions on dfIQ
    calculate_smaq(df)
    calculate_SMUS(df)
    calculate_SMMS(df)

    # Add the sex column to I_dilemmas for later use

    # This adds sex at the end matching for ResponseId so it repeates the values along all participants
    Q_dilemmas = Q_dilemmas.merge(df[['ResponseId', 'SMAQ_Passive_Average', 'SMAQ_Active_Average',
                                        'SMUS_Image_Average','SMUS_Comparison_Average', 'SMUS_Belief_Average',
                                        'SMUS_Consumption_Average', 'SMMS_Valence_Average',
                                        'SMMS_Agency_Average' ]], on='ResponseId', how='left')

    Q_dilemmas.to_excel(output_dir / 'Q_dilemmas.xlsx', index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="Qualtrics_Dilemmas_Results.csv",
                        help="Path to the original Qualtrics CSV export.")
    parser.add_argument("--output-dir", default=".",
                        help="Directory for df_questionnaires.xlsx and Q_dilemmas.xlsx.")
    args = parser.parse_args()
    main(args.input, args.output_dir)
