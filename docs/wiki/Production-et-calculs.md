[English version: [Production-and-Calculations](Production-and-Calculations)]

# Production et calculs

Le serveur calcule tout toutes les 10 minutes de jeu, joueurs présents ou non (option SimulateUnloaded, activée par défaut). Cette page détaille le modèle.

## Puissance d'une source

P = nominale × facteur de source × facteur d'état × rendement de pose × multiplicateur sandbox

Chaque source lisse sa sortie (réponse sur 30 minutes de jeu) : un nuage de passage ne fait pas clignoter la maison.

### Facteur d'état

Facteur d'état = 0,5 + 0,5 × état/100.

| État | Facteur |
|---|---|
| 100 | 1,000 |
| 75 | 0,875 |
| 50 | 0,750 |
| 25 | 0,625 |
| 0 | 0,500 |

### Rendement de pose

Il dépend du niveau d'Électricité de l'installateur au moment de la pose.

| Niveau | Rendement |
|---|---|
| 3 à 6 | 0,85 |
| 7 à 8 | 0,95 |
| 9 à 10 | 1,0 |

## Solaire (100 W)

Courbe en sinus entre l'aube et le crépuscule de la saison. Les nuages laissent 20 % en ciel couvert (facteur × (1 − 0,8 × nuages)). La neige se dépose sur le panneau pendant une chute de neige et fond au-dessus de 0 °C (action « Déneiger »). Environ 0,94 kWh par jour d'été et 0,60 kWh en hiver (panneau neuf, ciel dégagé).

## Éolien (400 W)

0 sous 10 km/h ; ((v − 10) / 35)³ entre 10 et 45 km/h ; 100 % de 45 à 85 km/h ; 0 au-dessus de 85 km/h (frein automatique). Le vent gagne 15 % par étage, jusqu'au 3e.

| Vent (km/h) | Part de la puissance nominale | Puissance |
|---|---|---|
| 0 | 0 % | 0 W |
| 10 | 0 % | 0 W |
| 20 | 2 % | environ 9 W |
| 25 | 8 % | environ 31 W |
| 30 | 19 % | environ 75 W |
| 40 | 63 % | environ 252 W |
| 45 | 100 % | 400 W |
| 60 | 100 % | 400 W |
| 85 | 100 % | 400 W |
| 90 | 0 % (frein) | 0 W |

## Roue à aubes (120 W)

Jour et nuit, environ 2,9 kWh par jour. Rivières seulement (le moteur ne sait pas distinguer le courant d'un lac).

| Saison | Coefficient | Puissance | kWh/jour |
|---|---|---|---|
| Printemps | × 1,2 | 144 W | environ 3,5 |
| Été | × 0,8 | 96 W | environ 2,3 |
| Automne | × 1,0 | 120 W | environ 2,9 |
| Hiver | × 1,0 | 120 W | environ 2,9 |

(Valeurs nominales, avant état et rendement de pose.)

## Charge des batteries

- Surplus × 0,90 (rendement de charge).
- Autodécharge : 0,2 % par jour.
- Batterie pleine : la production en trop est perdue (affichée « Production perdue »).
- Échelle d'énergie : 1 unité de puissance du moteur par heure = 1 000 W (option PowerScale).

## Ordre d'alimentation de l'onduleur

L'onduleur couvre d'abord la demande avec la production du moment (× rendement), puis avec les batteries. Il ne peut redémarrer que si la production couvre la demande ou si les batteries contiennent plus de 2 % de leur capacité. La limite de 1 500 W s'applique à la demande de la maison, pas à la production.

## Consommation des appareils

Valeurs du moteur vanilla, appareils allumés.

| Appareil | Consommation |
|---|---|
| Lumière | 2 W |
| Radio sur secteur | 10 W |
| Télévision | 30 W |
| Frigo seul | 80 W |
| Cuisinière, micro-ondes, lave-linge, sèche-linge | 90 W |
| Frigo-congélateur | 130 W |
| Lave-linge et sèche-linge superposés | jusqu'à 1 800 W |

## Exemple de dimensionnement

Un frigo-congélateur et 10 lumières font environ 170 W (avec les 20 W de l'onduleur à vide), soit 4,1 kWh par jour. Une nuit d'hiver de 14 h demande environ 2,4 kWh : compter environ 4 batteries de voiture ou 2 batteries stationnaires.

| Installation | Été (kWh/jour) | Hiver (kWh/jour) | Verdict pour 4,1 kWh/jour |
|---|---|---|---|
| 4 panneaux photovoltaïques | 3,8 | 2,4 | Déficit |
| 6 panneaux + 1 éolienne (vent moyen 25 km/h, environ 0,7 kWh) | 6,3 | 4,3 | Juste suffisant |
| 1 roue à aubes + 2 panneaux | 4,8 | 4,1 | Stable |

## Combien de panneaux ?

Il n'y a pas de limite : les productions s'additionnent (100 W nominaux chacun). Le plafond de 1 500 W concerne la demande de la maison, pas la production.

## Voir aussi

[Équipements](Equipements) · [Entretien et compétence](Entretien-et-competence) · [Options sandbox](Options-sandbox) · [Multijoueur et FAQ](Multijoueur-et-FAQ)
