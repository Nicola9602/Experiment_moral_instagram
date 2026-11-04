def reverse_score(score):
    """
    Reverses a score from a 5-point scale.

    Parameters:
    score (int): The score to be reversed. It should be between 1 and 5.

    Returns:
    int: The reversed score.
    """
    if score < 1 or score > 5:
        raise ValueError("Score must be between 1 and 5")

    # Mapping of original scores to reversed scores
    score_map = {1: 5, 2: 4, 3: 3, 4: 2, 5: 1}

    return score_map[score]
