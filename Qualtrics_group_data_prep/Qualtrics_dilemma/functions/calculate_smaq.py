def calculate_smaq(dfIQ):
    """
    Calculate the Social Media Activity Questionnaire (SMAQ) score.
    
    Parameters:
    dfIQ (DataFrame): The DataFrame containing the questionnaire data.
    
    Returns:
    DataFrame: The DataFrame with the SMAQ score added.
    """
    # Define the columns to sum for the SMAQ score
    smaq_passive_columns = [col for col in dfIQ if 'SMAQ_Passive' in col]
    smaq_active_columns = [col for col in dfIQ if 'SMAQ_Active' in col]

    SMAQ_Passive_Score = dfIQ[smaq_passive_columns].sum(axis=1)

    # Calculate the SMAQ score
    dfIQ['SMAQ_Passive_Average'] = dfIQ[smaq_passive_columns].sum(axis=1) / len(smaq_passive_columns)
    dfIQ['SMAQ_Active_Average'] = dfIQ[smaq_active_columns].sum(axis=1) / len(smaq_active_columns)
    
    return dfIQ
