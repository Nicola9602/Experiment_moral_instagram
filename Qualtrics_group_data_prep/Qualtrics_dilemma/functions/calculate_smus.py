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
