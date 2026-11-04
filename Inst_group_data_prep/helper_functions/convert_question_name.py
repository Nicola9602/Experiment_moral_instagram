def convert_question_name(question):
    # Updated mapping for question types to codes
    question_code_map = {
        'Durata_lettura_dilemma': 'Dilemma_Reading',
        'durata_LoFaresti': 'Yes/No',
        'Moralmente_accettabile': 'Moral_Acceptability',
        'stato_emotivo': 'Mood',
        'piacere_dispiacere': 'Valence',
        'calma_agitazione': 'Arousal'
    }

    for key, value in question_code_map.items():
        if key in question:
            question = question.replace(key,value)
    
    return question
