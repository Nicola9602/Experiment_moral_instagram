def calculate_SMMS(dfIQ):
    """
    Calculate the Social Media Mindset Scale (SMMS) score.
    
    Parameters:
    dfIQ (DataFrame): The DataFrame containing the questionnaire data.
    
    Returns:
    DataFrame: The DataFrame with the SMMS score added.
    """
    # Define the columns to sum for the SMMS score
    valence_cols = [col for col in dfIQ if 'SMMS_Valence' in col]
    agency_cols = [col for col in dfIQ if 'SMMS_Agency' in col]
    
    # Calculate the SMMS score
    dfIQ['SMMS_Valence_Average'] = dfIQ[valence_cols].sum(axis=1) / len(valence_cols)
    dfIQ['SMMS_Agency_Average'] = dfIQ[agency_cols].sum(axis=1) / len(agency_cols)
    
    return dfIQ
