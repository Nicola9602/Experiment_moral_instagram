def calculate_SMUS(df):
    """
    Calculate the Social Media Use Scale (SMUS) score.

    Parameters:
    df (DataFrame): The DataFrame containing the questionnaire data.

    Returns:
    DataFrame: The DataFrame with the SMUS score added.
    """
    # Define the columns to sum for the SMUS score
    image_based_cols = [col for col in df if 'SMUS_Image' in col]
    comparison_based_cols = [col for col in df if 'SMUS_Comparison' in col]
    belief_based_cols = [col for col in df if 'SMUS_Belief' in col]
    consumption_based_cols = [col for col in df if 'SMUS_Consumption' in col]

    # Calculate the SMUS score
    df['SMUS_Image_Average'] = df[image_based_cols].sum(axis=1) / len(image_based_cols)
    df['SMUS_Comparison_Average'] = df[comparison_based_cols].sum(axis=1) / len(comparison_based_cols)
    df['SMUS_Belief_Average'] = df[belief_based_cols].sum(axis=1) / len(belief_based_cols)
    df['SMUS_Consumption_Average'] = df[consumption_based_cols].sum(axis=1) / len(consumption_based_cols)

    return df
