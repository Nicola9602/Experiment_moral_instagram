import pandas as pd
F = ['CountryRoad', 'Parking', 'Wallet', 'Market']
I = ['Infermiere', 'Gru', 'Autostrada', 'Caverna']
S = ['Ascensore', 'Sparatoria', 'Elicottero', 'Rapimento']
NC = ['Infermiere', 'Gru', 'Ascensore', 'Sparatoria']
CC = ['Autostrada', 'Caverna', 'Elicottero', 'Rapimento']
def map_dilemma_type(dilemma):
    if dilemma in F:
        return 'F'
    elif dilemma in I:
        return 'I'
    elif dilemma in S:
        return 'S'


def map_dilemma_risk(dilemma):
    if dilemma in NC:
        return 'NC'
    elif dilemma in CC:
        return 'CC'
    elif dilemma in F:
        return pd.NA
