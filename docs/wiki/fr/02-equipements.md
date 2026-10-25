> English version: [Equipment](../en/02-equipment.md)

# Équipements

![Tous les équipements Live Wire et leurs chiffres](../../images/diagrams/equipment_fr.png)

Chaque recette donne un meuble posable `Base.Mov_LiveWire_*`. On le pose, le tourne et le ramasse avec le curseur de meuble vanilla (fantôme, 4 orientations, 2 pour les objets muraux). La tuile exige un tournevis et le niveau d'Électricité ci-dessous, y compris pour la ramasser. Un appareil ramassé garde son état.

## Tableau des équipements

| Équipement | Rôle | Pose | Niveau d'Électricité |
|---|---|---|---|
| Panneau photovoltaïque | Source, 100 W | Dehors, ciel dégagé ; toit plat possible | 3 |
| Éolienne | Source, 400 W ; les pales tournent avec le vent | Dehors ; +15 % de vent par étage jusqu'au 3e | 2 |
| Roue à aubes | Source, 120 W jour et nuit | Rez-de-chaussée, au bord d'une rivière | 2 |
| Onduleur | Cœur du réseau, 1 500 W | Toute case de sol, intérieur compris | 5 |
| Powerbank | Stockage, 4 batteries comptées ; s'ouvre comme une caisse (capacité 50) | Partout ; ramassée seulement vide | 2 |
| Disjoncteur | Sécurité, facultatif | Sur un mur (nord ou ouest) | 3 |
| Alarme de batterie faible | Alerte, facultatif | Sur un mur | 2 |
| Pompe à eau | Alimente les points d'eau de la maison depuis des barils, 250 W pendant le pompage | N'importe où, à côté de ses barils | 6 |

## Règles de pose

- Panneau et éolienne : à l'extérieur, sous ciel ouvert.
- Roue à aubes : berge d'une rivière, rez-de-chaussée, à côté de l'eau de la rivière (lacs et étangs refusés).
- Pompe à eau : n'importe où ; ses barils doivent être sur les 8 cases autour d'elle (voir [Pompe à eau](07-pompe-a-eau.md)).
- Une case refusée affiche la raison en rouge dans le panneau du curseur.

## Voyants

- Onduleur : écran allumé en marche, voyant rouge en cas de défaut.
- Sources et powerbank : voyant vert « connecté ».
- Disjoncteur : lampe rouge quand il a sauté.
- Alarme : gyrophare allumé pendant la sonnerie.
- Pompe à eau : voyant bleu lorsqu'elle est alimentée, même au repos.

## Batteries

Les batteries ne se posent jamais au sol : glissez-les dans la powerbank avec l'inventaire vanilla.

| Batterie | Capacité nominale | Durée de vie |
|---|---|---|
| Batterie de voiture `Base.CarBattery1` | 0,40 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery2` | 0,60 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery3` | 0,90 kWh | 150 cycles |
| Batterie stationnaire `LiveWire.DeepCycleBattery` | 1,50 kWh | 600 cycles |

Capacité effective = nominale × (0,4 + 0,6 × état/100) × BatteryCapacityMultiplier.

![La powerbank ouverte comme une caisse](../../images/screenshots/shot3.png)

## Ramasser et tourner

- Ramasser l'onduleur déconnecte tout son réseau ; le tourner conserve les liens.
- Ramasser une source conserve son état ; reposée, elle est « Non raccordé ».
- La powerbank ne se ramasse que vide. Si elle en porte une autre, retirez celle
  du dessus avant de déplacer, tourner ou démonter celle du dessous.

## Superposer deux powerbanks

Utilisez le curseur de pose de meubles pour poser une seconde powerbank sur la
même case que la première : le fantôme doit apparaître au-dessus. Deux banques
au maximum par pile, soit huit emplacements de batteries (quatre par banque).

Chaque banque possède son propre conteneur et doit être raccordée à l'onduleur.
Le bouton **Banque 1/2** ou **Banque 2/2** du LCD passe de celle du bas à celle du
haut et sélectionne son conteneur dans la fenêtre de butin. Le panneau de
raccordement indique aussi le numéro de banque. Les batteries ne sont ni fusionnées
ni copiées ; une nouvelle banque ne contient pas de batteries gratuites.

## Voir aussi

[Raccordement](03-raccordement.md) · [Équipements optionnels](06-equipements-optionnels.md) · [Recettes](08-recettes.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md)
