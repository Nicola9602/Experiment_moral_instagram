"""Instagram cleaning extracted from the original Jupyter notebook.
Edit paths below. Keep source data private.
"""
import numpy as np
import pandas as pd
import re
import os

from helper_functions.convert_to_seconds import convert_to_seconds
from helper_functions.convert_question_name import convert_question_name
from helper_functions.map_dilemma_functions import map_dilemma_risk, map_dilemma_type
from helper_functions.dilemma_functions import insert_reading_time_blocks, clean_answer
from helper_functions.questionnaire_functions import reverse_score
from helper_functions.questionnaire_scoring import calculate_smaq, calculate_SMUS, calculate_SMMS

# Settings: paths on your own computer
questions_file = 'Risultati_instagram.xlsx'
questionnaires_file = 'Instagram_Questionnaires.xlsx'
output_folder = '.'
os.makedirs(output_folder, exist_ok=True)

# region 1. Importing timings
# Import the Timings from the folder, given that each particinapt has its own 
# csv then loop through them and stack them up in a single xlsx

# Edit this folder path to your own local private data
folder_path = 'ADD_YOUR_PATH'

# This folder works on the work computer


# Create a list to store the DataFrames dfT for timings
dfT = []

file_list = sorted(f for f in os.listdir(folder_path) if f.endswith('.xlsx') and not f.startswith('~$'))

for file in file_list: 
    file_path = os.path.join(folder_path, file)
    df = pd.read_excel(file_path)
    
    dfT.append(df)
    

if not dfT:
    raise FileNotFoundError('No timing workbooks in folder_path')
dfT = pd.concat(dfT, ignore_index=True)


# NOw write a funciton to convert the timings from HH:MM:SS to seconds
#--------------------------------------------------------------------------

# Apply it to all dfT columns but skip the first beause it is ResponseId
for col in dfT.columns[1:]:
    dfT[col] = dfT[col].astype(str).apply(convert_to_seconds)  

# Drop the duration_initial_message and total_time_spent because I don't have them 
# in the other data
dfT.drop(columns=['duration_initial_message', 'total_time_spent'], inplace=True)

# Rename the Response Id so that it is the same as in the other data
dfT.rename(columns={'Response_id': 'ResponseId'}, inplace=True)
melted_T = pd.melt(
    dfT,
    id_vars = ['ResponseId'],
    var_name = 'Question',
    value_name = 'Duration'
)

melted_T['Question'] = melted_T['Question'].apply(convert_question_name)

# Split the 'Question' column once and assign the results to new columns
split_questions = melted_T['Question'].str.split('_', n=1, expand=True)
melted_T['Dilemma'] = split_questions[0]  # First part before '_'
melted_T['Question_New'] = split_questions[1] 

#Add the dilemma type and risk

# Define a function to map Dilemma to Dilemma_type
    

# Apply the function to create the Dilemma_type column
melted_T['Dilemma_type'] = melted_T['Dilemma'].apply(map_dilemma_type)
melted_T['Risk'] = melted_T['Dilemma'].apply(map_dilemma_risk)

melted_T['Risk'] = [pd.NA if question_new == 'Dilemma_Reading' else risk for question_new, risk in zip(melted_T['Question_New'], melted_T['Risk'])]
melted_T.to_excel(os.path.join(output_folder, 'I_timings.xlsx'), index=False)
# endregion

# region 2. Cleaning dilemmas
# Load the questions dataframe dfQ
dfQ = pd.read_excel(questions_file)
# Drop the columns that are not needed
dfQ.drop(columns=['Finished'], inplace=True)
dfQ.drop([0], axis=0, inplace=True)
dfQ.reset_index(inplace=True)

# This is the pivoted dataset for the Questions 
melted_Q = pd.melt(
    dfQ,
    id_vars=['ResponseId', 'Dilemmas_order'],
    var_name='Question',
    value_vars = dfQ.filter(regex='4|6|8|10|12').columns,
    value_name = 'Answer'
)

# Set some special questions which are the fillers
special_questions = ['CountryRoad', 'Parking', 'Wallet', 'Market']

# Initialize new empty columns where to store subsequents values 
melted_Q['Dilemma'] = ''
melted_Q['Dilemma_type'] = ''
melted_Q['Risk'] = ''
melted_Q['Question_New'] = ''

# Iterate through the rows 
for index, row in melted_Q.iterrows():
    question = row['Question']
    
    if any(special in question for special in special_questions):
        #Apply special logic to only get the dilemma and Question_num
        melted_Q.at[index, 'Dilemma'] = re.split(r'[_\.]', question)[0]
        melted_Q.at[index, 'Question_New'] = re.split(r'[_\.]', question)[2]
        melted_Q.at[index, 'Dilemma_type'] = 'Filler'
        melted_Q.at[index, 'Risk'] = re.split(r'[_\.]', question)[1]
    else:
        # Apply the general logic (Dilemma, Dilemma_type, Risk, Quesiton_Num)
        split_parts = re.split(r'[_\.]', question)
        melted_Q.at[index, 'Dilemma'] = split_parts[0]
        melted_Q.at[index, 'Dilemma_type'] = split_parts[1]
        melted_Q.at[index, 'Risk'] = split_parts[2]
        melted_Q.at[index, 'Question_New'] = split_parts[3]
        

# Write A function to recreate the Question names like in melted_T
#-------------------------------------------------------------------



# Apply the function
melted_Q = insert_reading_time_blocks(melted_Q)

# RENAME ALL THE THINGS WITH THEIR RIGHT NAME 
#-------------------------------------------------------------------

for index, value in melted_Q['Question_New'].items():
    if value == '2':
        melted_Q.at[index, 'Question_New'] = 'Dilemma_Reading'
    elif value == '4':
        melted_Q.at[index, 'Question_New'] = 'Yes/No'
    elif value == '6':
        melted_Q.at[index, 'Question_New'] = 'Moral_Acceptability'
    elif value == '8':
        melted_Q.at[index, 'Question_New'] = 'Mood'
    elif value == '10':
        melted_Q.at[index, 'Question_New'] = 'Valence'
    elif value == '12':
        melted_Q.at[index, 'Question_New'] = 'Arousal'
        

# # Clean the Answer column
# #--------------------------------------------------------------------
# def clean_answer(x):
#     if pd.isna(x) or (isinstance(x, str) and x.strip() == ''):
#         return pd.NA
    
#     if isinstance(x, str):
#         if x.lower() in ['si', 'sì']:
#             return 'si'
#         elif x.lower() in ['no', 'nò']:
#             return 'no'
#         elif x.isdigit() and int(x) in range(1,10):
#             return int(x)
#         elif x.lower() in ['arrabbiato', 'triste', 'impaurito', 'sorpreso', 'felice']:
#             return x
#         else:
#             return x
#     return x


melted_Q['Answer'] = melted_Q['Answer'].apply(clean_answer)


I_dilemmas = melted_Q

I_dilemmas['Group'] = 'Instagram'
# endregion

# region 3. Questionnaire cleaning

# Some data are wrong. Here I don't have too much data, so I will change them manually. 
# COnsider that with more data I should have probabily looped on them and flagged them for 
# further considerations. 
# Change the two nans that can be changed 
dfIQ.loc[23, 'Q3_1'] = 'Youtube'
dfIQ.loc[30, 'Q3_1'] = 'Youtube'
dfIQ.loc[36, 'Q1'] = 23

# drop useless columns 
dfIQ = dfIQ.drop(columns=['StartDate', 'EndDate', 'Status', 'IPAddress', 'Progress','RecordedDate', 'RecipientLastName', 'RecipientFirstName', 'RecipientEmail',
       'ExternalReference', 'LocationLatitude', 'LocationLongitude','DistributionChannel', 'UserLanguage', 'Q3_2',
       'Q3_3', 'Q3_4', 'Q3_5', 'Q3_5_TEXT'])

dfIQ.rename(columns={'Q3_1': 'Social', 'Q1': 'Age', 'Q2':'Sex'}, inplace=True)

dfIQ = dfIQ[dfIQ['Finished'] == 'True']

dfIQ = dfIQ.iloc[1:,:]
dfIQ.reset_index(drop=True, inplace=True)

dfIQ['ResponseId'] = range(1, len(dfIQ) + 1)
# Convert Age to numeric (will turn bad strings into NaN)
dfIQ['Age'] = pd.to_numeric(dfIQ['Age'], errors='coerce')

# Fill missing with the rounded mean of valid ages
dfIQ['Age'] = dfIQ['Age'].fillna(dfIQ['Age'].mean().round())

# Change the reverse columns 



# Get the reverse columns
reverse_columns = [col for col in dfIQ if 'Reverse' in col]

rev_col_index = [dfIQ.columns.get_loc(col) for col in reverse_columns]

for col in reverse_columns:
    dfIQ[col] = dfIQ[col].apply(reverse_score)



# Social Media Activity Questionnaire calculation (SMAQ)
# Social Media Use Scale calculation (SMUS)
# Social Media Mindset Scale calculation (SMMS)
calculate_smaq(dfIQ)
calculate_SMUS(dfIQ)
calculate_SMMS(dfIQ)

Questionnaires_averages = dfIQ.iloc[:, 52:]

# Add the sex column to I_dilemmas for later use

# This adds sex at the end matching for ResponseId so it repeates the values along all participants
I_dilemmas = I_dilemmas.merge(dfIQ[['ResponseId', 'Sex', 'SMAQ_Passive_Average', 'SMAQ_Active_Average',
                                    'SMUS_Image_Average','SMUS_Comparison_Average', 'SMUS_Belief_Average',
                                    'SMUS_Consumption_Average', 'SMMS_Valence_Average',
                                    'SMMS_Agency_Average' ]], on='ResponseId', how='left')

#Then I want the column in position two, just a whim
I_dilemmas.insert(loc=2, column='Sex', value=I_dilemmas.pop('Sex'))


# Save cleaned data. In the notebook this export was commented out.
I_dilemmas.to_excel(os.path.join(output_folder, 'I_dilemmas.xlsx'), index=False)
Questionnaires_averages.to_excel(os.path.join(output_folder, 'I_questionnaire_averages.xlsx'), index=False)
# endregion
