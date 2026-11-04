def calculate_SMMS(df):
    """
    Calculate the Social Media Mindset Scale (SMMS) score.

    Parameters:
    df (DataFrame): The DataFrame containing the questionnaire data.

    Returns:
    DataFrame: The DataFrame with the SMMS score added.
    """
    # Define the columns to sum for the SMMS score
    valence_cols = [col for col in df if 'SMMS_Valence' in col]
    agency_cols = [col for col in df if 'SMMS_Agency' in col]

    # Calculate the SMMS score
    df['SMMS_Valence_Average'] = df[valence_cols].sum(axis=1) / len(valence_cols)
    df['SMMS_Agency_Average'] = df[agency_cols].sum(axis=1) / len(agency_cols)

    return df
