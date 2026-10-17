[English version: [Maintenance-and-Skill](Maintenance-and-Skill)]

# Entretien et compétence

## Usure

| Appareil | Usure normale | Accélérateurs |
|---|---|---|
| Panneau photovoltaïque | −1 tous les 10 jours | Orage, seulement avec l'option StormDamage (désactivée par défaut) |
| Éolienne | −1 tous les 4 jours | Vent > 85 km/h avec StormDamage |
| Roue à aubes | −1 tous les 6 jours | aucun |
| Onduleur | −1 tous les 5 jours en marche | Charge > 80 % : usure × 2 ; chaque disjonction sans disjoncteur : −3 ; insonorisé : × 1,25 |
| Disjoncteur | −1 tous les 15 jours | aucun |
| Powerbank, alarme | −1 tous les 30 jours | aucun |
| Batterie | 100 / durée de vie en cycles par cycle complet | Décharge sous 20 % : usure doublée ; autodécharge 0,2 % par jour |

## Réparation, remise à neuf, reconditionnement

| Action | Niveau | Coût | Effet |
|---|---|---|---|
| Réparer (Repair) | selon l'appareil | 1 déchets électroniques + 1 fil électrique | Gain de 5 + niveau d'Électricité en points d'état (jusqu'à 90). Échec : max(5, 40 − 5 × niveau) %, divisé par deux dès le niveau 8 ; pièces perdues en cas d'échec |
| Remise à neuf (Overhaul) | 8 | 4 déchets électroniques + 2 fils électriques | Retour à 100 |
| Reconditionner une batterie | 4 | 1 déchets électroniques + 0,5 L d'eau | +15 d'état, plafonné à 80 |

## Testeur de tension

`LiveWire.VoltageTester` : clic droit sur une case, « Live Wire », « Mesurer ».

| Niveau | Lecture |
|---|---|
| 0 | Alimenté ou non |
| 1 | Origine du courant |
| 2 | Consommation de l'appareil |
| 4 | Bilan du réseau |

## Compétence Électricité

| Niveau | Débloque | Effet continu |
|---|---|---|
| 0 | Lire un testeur : alimenté ou non | aucun |
| 1 | Testeur de tension | Lecture détaillée de la case |
| 2 | Powerbank, alarme de batterie faible, kit d'insonorisation | Usure des batteries −5 % |
| 3 | Panneaux photovoltaïques, disjoncteur, générateur de secours | Rendement de pose 0,85 |
| 4 | Reconditionner une batterie | Lecture de l'autonomie |
| 5 | Onduleur | aucun |
| 6 | Éolienne, batterie stationnaire, ordinateur de gestion | Usure des batteries −10 % |
| 7 | Roue à aubes, délestage | Rendement de pose 0,95 |
| 8 | Cellules à partir de déchets, remise à neuf | Échec de réparation divisé par deux |
| 9-10 | aucun | Rendement de pose 1,0 ; usure des appareils −25 % |

## Expérience

Toujours attribuée par le serveur.

| Action | Expérience |
|---|---|
| Recettes du mod | voir [Recettes](Recettes) |
| Poser une source | 10 (panneau), 20 (éolienne, roue à aubes) |
| Poser un onduleur | 25 |
| Connecter une source ou une batterie | 3 |
| Inspecter un appareil | 2 (une fois par appareil et par jour) |
| Mesurer au testeur | 1 (une fois par case et par heure) |
| Réparer | 5 + 1 par point, maximum 15 |
| Reconditionner une batterie | 8 |
| Réarmer après avoir réglé une surcharge | 5 (une fois par heure) |
| Insonoriser l'onduleur | 3 |

L'option XPMultiplier ajuste l'expérience donnée, et SkillGates = false supprime les niveaux requis ([Options sandbox](Options-sandbox)).

## Voir aussi

[Équipements](Equipements) · [Recettes](Recettes) · [Production et calculs](Production-et-calculs)
