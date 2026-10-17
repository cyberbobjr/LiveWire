[English version: [Wiring](Wiring)]

# Raccordement

Les appareils d'un réseau Live Wire se relient à l'onduleur par des fils électriques. La maison, elle, n'a besoin d'aucun câblage : tout appareil dans la zone alimentée par l'onduleur fonctionne.

## Pas à pas

1. Fabriquez les appareils ([Recettes](Recettes)) et posez-les avec le curseur de meuble.
2. Clic droit sur un appareil, puis « Live Wire », puis le nom de l'appareil : le menu indique « Raccordé à l'onduleur à N cases » ou « Non raccordé », puis « Raccorder à un onduleur », avec une ligne par onduleur à portée : « Onduleur à N cases (k fil(s)) ». Autre voie : clic droit sur l'onduleur, « Raccorder un équipement » (liste des équipements libres à portée avec distance et fils) ou « Débrancher un équipement ».
3. Le générateur vanilla (secours) et l'ordinateur de bureau vanilla (gestion) se relient de la même façon, depuis leur propre menu : « Live Wire », puis Backup generator ou Management computer, puis « Raccorder à un onduleur ».

![Le menu Live Wire sur l'onduleur](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot1.png)

## Coût en fils

Un fil électrique `Base.ElectricWire` par tranche de 4 cases de distance, arrondi à l'entier supérieur, au moins 1 (option WirePerTiles ; 0 = câblage gratuit).

| Distance | Fils |
|---|---|
| 4 cases | 1 |
| 9 cases | 3 |
| 12 cases | 3 |

## Portée et limites

| Règle | Valeur |
|---|---|
| Portée de câble | 12 cases (option LinkRange, 4 à 30), 1 étage d'écart au plus |
| Sources par onduleur | Illimitées |
| Powerbanks par onduleur | Plusieurs |
| Disjoncteur, alarme, ordinateur de gestion, générateur de secours | Un de chaque par réseau au plus |
| Onduleur | Un par réseau |

## Générateur et ordinateur vanilla

Le générateur de secours et l'ordinateur de bureau sont des objets vanilla trouvés dans le monde, pas des recettes. Voir [Équipements optionnels](Equipements-optionnels).

## Menu de l'onduleur

Clic droit sur l'onduleur :

| Entrée | Effet |
|---|---|
| Open the inverter screen | Ouvre l'écran LCD |
| Turn on / Turn off | Marche / arrêt |
| Reset | Réarme après une disjonction |
| Show the powered area | Cercle cyan au sol |
| Connect equipment / Disconnect equipment | Gérer les liens |
| Soundproof the inverter | Pose du kit d'insonorisation |
| Inspect | Inspection (expérience) |
| Repair / Overhaul | Réparation / remise à neuf |

## Voir aussi

[Équipements](Equipements) · [Écran et logiciel](Ecran-et-logiciel) · [Options sandbox](Options-sandbox)
