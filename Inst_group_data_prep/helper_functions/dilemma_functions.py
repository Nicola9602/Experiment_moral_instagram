import pandas as pd
import re
def insert_reading_time_blocks(df):
    # Desired dilemma order
    ordered_dilemmas = [
        'Infermiere', 'Gru', 'Autostrada', 'Caverna',
        'Ascensore', 'Sparatoria', 'Elicottero', 'Rapimento',
        'CountryRoad', 'Parking', 'Wallet', 'Market'
    ]
    
    suffix_order = ['.2', '.4', '.6', '.8', '.10', '.12']
    response_ids = df['ResponseId'].unique()
    
    new_data = []

    for dilemma in ordered_dilemmas:
        # Get all rows for the current dilemma
        dilemma_rows = df[df['Dilemma'] == dilemma]
        # Get the unique base questions from the 'Question' column, excluding the suffix
        base_questions = dilemma_rows['Question'].str.extract(r'^(.*?)(?:\.\d+)$')[0].unique()

        for base_q in base_questions:
            for suffix in suffix_order:
                qname = f"{base_q}{suffix}"

                if suffix == '.2':
                    for rid in response_ids:
                        example_row = dilemma_rows[(dilemma_rows['Question'].str.startswith(base_q)) & (dilemma_rows['ResponseId'] == rid)]
                        if example_row.empty:
                            continue
                        example_row = example_row.iloc[0]

                        new_data.append({
                            'ResponseId': rid,
                            'Dilemmas_order': example_row['Dilemmas_order'],
                            'Question': qname,
                            'Answer': '',
                            'Dilemma': example_row['Dilemma'],
                            'Dilemma_type': example_row['Dilemma_type'],
                            'Risk': example_row['Risk'],
                            'Question_New': '2'
                        })
                else:
                    real_rows = dilemma_rows[(dilemma_rows['Question'] == qname)]
                    if not real_rows.empty:
                        new_data.extend(real_rows.to_dict(orient='records'))

    return pd.DataFrame(new_data)


def clean_answer(x):
    if pd.isna(x) or (isinstance(x, str) and x.strip() == ''):
        return pd.NA
    
    if isinstance(x, str):
        x = x.strip().lower()  # Normalize to lowercase and strip whitespace
        if x in ['si', 'sì']:
            return 'si'
        elif x in ['no', 'nò']:
            return 'no'
        elif x.isdigit() and int(x) in range(1, 10):
            return int(x)
        elif x in ['arrabbiato', 'triste', 'impaurito', 'sorpreso', 'felice']:
            return x.capitalize()  # Capitalize for consistent formatting
        else:
            return x
    return x
