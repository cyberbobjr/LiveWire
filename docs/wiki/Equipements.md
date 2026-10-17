[English version: [Equipment](Equipment)]

# Équipements

Chaque recette donne un meuble posable `Base.Mov_LiveWire_*`. On le pose, le tourne et le ramasse avec le curseur de meuble vanilla (fantôme, 4 orientations, 2 pour les objets muraux). La tuile exige un tournevis et le niveau d'Électricité ci-dessous, y compris pour la ramasser. Un appareil ramassé garde son état.

## Tableau des équipements

| Équipement | Rôle | Pose | Niveau d'Électricité |
|---|---|---|---|
| Panneau photovoltaïque | Source, 100 W | Dehors, ciel dégagé ; toit plat possible | 3 |
| Éolienne | Source, 400 W ; les pales tournent avec le vent | Dehors ; +15 % de vent par étage jusqu'au 3e | 6 |
| Roue à aubes | Source, 120 W jour et nuit | Rez-de-chaussée, au bord d'une rivière | 7 |
| Onduleur | Cœur du réseau, 1 500 W | Toute case de sol, intérieur compris | 5 |
| Powerbank | Stockage, 4 batteries comptées ; s'ouvre comme une caisse (capacité 50) | Partout ; ramassée seulement vide | 2 |
| Disjoncteur | Sécurité, facultatif | Sur un mur (nord ou ouest) | 3 |
| Alarme de batterie faible | Alerte, facultatif | Sur un mur | 2 |

## Règles de pose

- Panneau et éolienne : à l'extérieur, sous ciel ouvert.
- Roue à aubes : berge d'une rivière, rez-de-chaussée, à côté de l'eau de la rivière (lacs et étangs refusés).
- Une case refusée affiche la raison en rouge dans le panneau du curseur.

## Voyants

- Onduleur : écran allumé en marche, voyant rouge en cas de défaut.
- Sources et powerbank : voyant vert « connecté ».
- Disjoncteur : lampe rouge quand il a sauté.
- Alarme : gyrophare allumé pendant la sonnerie.

## Batteries

Les batteries ne se posent jamais au sol : glissez-les dans la powerbank avec l'inventaire vanilla.

| Batterie | Capacité nominale | Durée de vie |
|---|---|---|
| Batterie de voiture `Base.CarBattery1` | 0,40 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery2` | 0,60 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery3` | 0,90 kWh | 150 cycles |
| Batterie stationnaire `LiveWire.DeepCycleBattery` | 1,50 kWh | 600 cycles |

Capacité effective = nominale × (0,4 + 0,6 × état/100) × BatteryCapacityMultiplier.

![La powerbank ouverte comme une caisse](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot3.png)

## Ramasser et tourner

- Ramasser l'onduleur déconnecte tout son réseau ; le tourner conserve les liens.
- Ramasser une source conserve son état ; reposée, elle est « Non raccordé ».
- La powerbank ne se ramasse que vide.

## Voir aussi

[Raccordement](Raccordement) · [Équipements optionnels](Equipements-optionnels) · [Recettes](Recettes) · [Entretien et compétence](Entretien-et-competence)
