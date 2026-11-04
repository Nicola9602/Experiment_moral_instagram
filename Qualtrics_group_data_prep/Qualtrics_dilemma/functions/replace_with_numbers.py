def replace_with_numbers(dilemmas_list, labels):
    """Map ordered dilemma names to their IDs using the supplied labels."""
    return [key for name in dilemmas_list for key, value in labels.items() if value == name]
