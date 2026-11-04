def convert_to_seconds(time_str):
    """Convert a time string in the format H:MM:SS to seconds in floats.
    Args:
        time_str (str): Time string in the format H:MM:SS."""
    
    h, m ,s = map(float, time_str.split(':'))
    return h*3600 + m*60 + s
