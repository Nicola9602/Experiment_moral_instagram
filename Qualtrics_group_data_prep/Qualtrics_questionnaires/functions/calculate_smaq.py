def calculate_smaq(df):
    """
    Calculate the Social Media Activity Questionnaire (SMAQ) score.

    Parameters:
    df (DataFrame): The DataFrame containing the questionnaire data.

    Returns:
    DataFrame: The DataFrame with the SMAQ score added.
    """
    # Define the columns to sum for the SMAQ score
    smaq_passive_columns = [col for col in df if 'SMAQ_Passive' in col]
    smaq_active_columns = [col for col in df if 'SMAQ_Active' in col]

    SMAQ_Passive_Score = df[smaq_passive_columns].sum(axis=1)


    # Calculate the SMAQ score
    df['SMAQ_Passive_Average'] = df[smaq_passive_columns].sum(axis=1) / len(smaq_passive_columns)
    df['SMAQ_Active_Average'] = df[smaq_active_columns].sum(axis=1) / len(smaq_active_columns)

    return df
