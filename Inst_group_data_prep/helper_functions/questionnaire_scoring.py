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


def calculate_SMUS(dfIQ):
    """
    Calculate the Social Media Use Scale (SMUS) score.
    
    Parameters:
    dfIQ (DataFrame): The DataFrame containing the questionnaire data.
    
    Returns:
    DataFrame: The DataFrame with the SMUS score added.
    """
    # Define the columns to sum for the SMUS score
    image_based_cols = [col for col in dfIQ if 'SMUS_Image' in col]
    comparison_based_cols = [col for col in dfIQ if 'SMUS_Comparison' in col] 
    belief_based_cols = [col for col in dfIQ if 'SMUS_Belief' in col]
    consumption_based_cols = [col for col in dfIQ if 'SMUS_Consumption' in col]
    
    # Calculate the SMUS score
    dfIQ['SMUS_Image_Average'] = dfIQ[image_based_cols].sum(axis=1) / len(image_based_cols)
    dfIQ['SMUS_Comparison_Average'] = dfIQ[comparison_based_cols].sum(axis=1) / len(comparison_based_cols)
    dfIQ['SMUS_Belief_Average'] = dfIQ[belief_based_cols].sum(axis=1) / len(belief_based_cols)
    dfIQ['SMUS_Consumption_Average'] = dfIQ[consumption_based_cols].sum(axis=1) / len(consumption_based_cols)
    
    return dfIQ


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
