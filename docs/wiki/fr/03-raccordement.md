> English version: [Wiring](../en/03-wiring.md)

# Raccordement

Les appareils d'un réseau Live Wire se relient à l'onduleur par des fils électriques. La maison, elle, n'a besoin d'aucun câblage : tout appareil dans la zone alimentée par l'onduleur fonctionne.

## Pas à pas

1. Fabriquez les appareils ([Recettes](08-recettes.md)) et posez-les avec le curseur de meuble.
2. Clic droit sur un appareil, puis « Live Wire », puis le nom de l'appareil : le menu indique « Raccordé à l'onduleur à N cases » ou « Non raccordé », puis « Raccorder à un onduleur », avec une ligne par onduleur à portée : « Onduleur à N cases (k fil(s)) ». Autre voie : clic droit sur l'onduleur, « Raccorder un équipement » (liste des équipements libres à portée avec distance et fils) ou « Débrancher un équipement ».
3. Le générateur vanilla (secours) et l'ordinateur de bureau vanilla (gestion) se relient de la même façon, depuis leur propre menu : « Live Wire », puis Backup generator ou Management computer, puis « Raccorder à un onduleur ».

![Le menu Live Wire sur l'onduleur](../../images/screenshots/shot1.png)

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
| Portée de câble | 12 cases horizontalement (option LinkRange, 4 à 30), 3 étages d'écart au plus par défaut (option LinkVerticalRange, 0 à 10 ; 0 = même étage). S'applique aussi au couplage d'onduleurs |
| Sources par onduleur | Illimitées |
| Powerbanks par onduleur | Plusieurs |
| Disjoncteur, alarme, ordinateur de gestion, générateur de secours | Un de chaque par réseau au plus |
| Onduleur | Un par réseau |

## Générateur et ordinateur vanilla

Le générateur de secours et l'ordinateur de bureau sont des objets vanilla trouvés dans le monde, pas des recettes. Voir [Équipements optionnels](06-equipements-optionnels.md).

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

## Tout raccorder depuis une seule fenêtre

Cliquez directement sur un équipement Live Wire proche. Sur un panneau solaire,
une éolienne, une roue ou une alarme, la fenêtre de raccordement s'ouvre. Sur le LCD
de l'onduleur, appuyez sur **Raccordements**. Le tableau électrique sert aux circuits
et au réarmement.

Choisissez l'onduleur en haut, sélectionnez un équipement, puis **Raccorder** ou
**Débrancher**. Le personnage se déplace jusqu'à lui ; les fils et les règles de
compétence restent nécessaires. La fenêtre reste ouverte pour les autres équipements.
**Actualiser** recherche les objets nouvellement posés. Les équipements raccordés à
un autre réseau sont signalés : débranchez-les d'abord de ce réseau.

Le clic droit reste disponible. Le couplage des onduleurs et les barils de pompe
conservent leurs options spécifiques.

## Voir aussi

[Équipements](02-equipements.md) · [Écran et logiciel](05-ecran-et-logiciel.md) · [Options sandbox](11-options-sandbox.md)
