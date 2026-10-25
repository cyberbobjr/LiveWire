> English version: [Water pump](../en/07-water-pump.md)

# Pompe à eau

*Nouveauté de la 1.2.0. Pas encore testée en jeu : merci de signaler tout problème.*

Des barils d'eau posés au sol peuvent alimenter les points d'eau de toute une maison. Une pompe électrique, raccordée à l'onduleur et posée à côté des barils, alimente les éviers, douches, baignoires et toilettes tant que le réseau a du courant.

## Ce qu'il faut

| Objet | Détail |
|---|---|
| Pompe à eau | Recette au niveau 6 d'Électricité (voir [Recettes](08-recettes.md)). Se pose comme tout équipement Live Wire, dedans ou dehors. |
| Fil électrique | Pour raccorder la pompe à un onduleur, comme tout équipement (1 fil pour 4 cases). |
| Barils d'eau | Récupérateurs d'eau de pluie vanilla, ou barils du mod facultatif **Useful Barrels**. Jusqu'à 8 par pompe. |
| Tuyaux en métal | 1 par baril, rendu quand on débranche le baril. |
| Clé anglaise | Pour raccorder éviers, douches et toilettes (action vanilla). |

## Installation

1. Posez la pompe **à côté des barils** : un baril doit être sur l'une des 8 cases autour de la pompe, au même étage (diagonales comprises). Une pompe entourée de barils en accepte jusqu'à 8.
2. Raccordez la pompe à un onduleur : clic droit sur la pompe > **Live Wire** > **Pompe à eau** > **Raccorder à un onduleur**.
3. Raccordez chaque baril : clic droit sur la pompe > **Raccorder un baril**, ou clic droit sur le baril > **Baril d'eau** > **Pompe à côté de ce baril (1 tuyau)**.
4. Raccordez les points d'eau avec une clé anglaise, comme en vanilla (clic droit sur l'évier > **Raccorder la plomberie de…**). L'option apparaît dès que la pompe dessert le point d'eau.

## Fonctionnement

- **Eau uniquement.** Un baril qui contient autre chose (essence, alcool…), même mélangé à de l'eau, est refusé. Un baril vide peut être raccordé ; il sert dès qu'il se remplit.
- **L'eau de pluie sort propre.** L'eau de pluie d'un baril est croupie, mais un point d'eau raccordé donne de l'eau propre, comme en vanilla.
- **Portée.** La pompe alimente les points d'eau raccordés situés dans une pièce, à **15 cases** au plus (option sandbox `PumpRange`, 5 à 30) et jusqu'à 3 étages au-dessus ou en dessous.
- **Réservoirs relais invisibles.** Le jeu ne cherche la source d'un point d'eau qu'à l'étage juste au-dessus. La pompe pose donc un petit réservoir invisible de 25 litres au-dessus de chaque point d'eau desservi, et le garde rempli depuis les barils. Rien à poser à la main.
- **Débit et courant.** 5 litres par minute de jeu et par pompe, 250 W pendant le pompage. La pompe **s'arrête seule** quand tous les réservoirs sont pleins : aucun courant consommé, aucun bruit.
- **Les points d'eau déjà alimentés** (baril vanilla à l'étage, réseau d'eau encore en service, autre mod) le restent : la pompe ne leur fait pas concurrence.
- **Plusieurs pompes** peuvent partager un même réseau.
- **En votre absence**, la pluie continue de remplir les barils (c'est le jeu qui s'en charge). La pompe ne travaille que dans une zone chargée, là où l'on se sert de toute façon des points d'eau.

## Voir ce qui est alimenté

- Clic droit sur la pompe > **Afficher les points d'eau alimentés** : un cercle bleu montre la portée, et les points d'eau desservis, les barils raccordés et la pompe sont surlignés en bleu. **Masquer les points d'eau alimentés** l'éteint.
- Un **voyant bleu** s'allume sur la pompe lorsqu'elle est alimentée, même au repos ou sans point d'eau raccordé. Il s'éteint sans courant ou lorsque le circuit équipements/principal est coupé.
- Le menu de la pompe indique son état : en marche, à l'arrêt (tous les points d'eau pleins), pas de courant, pas d'eau dans les barils, hors service.
- Le logiciel de gestion (onglet Équipements) affiche le nombre de pompes en service et leur débit en litres par heure. Rien d'autre sur la pompe n'y figure.

## Bruit

Un léger ronronnement de moteur s'entend autour d'une pompe en marche (même réglage de volume que le bourdonnement de l'onduleur, Options > Mods > Live Wire). Les zombies l'entendent à 2 cases.

## Usure

La pompe ne s'use que pendant qu'elle tourne (1 point d'état par 10 jours de pompage) et se répare comme les autres équipements. Hors service, elle ne remplit plus les réservoirs.

## Avant de retirer le mod

Lancez d'abord l'action de debug ou d'administration **Retirer tous les relais d'eau** (clic droit > Live Wire, mode debug en solo, admin en multijoueur), puis sauvegardez. L'action arrête aussi toutes les pompes, pour qu'aucun réservoir ne revienne. Les réservoirs des zones non chargées sont retirés au prochain chargement de leur zone, tant que le mod est encore installé. Pour réutiliser les pompes sans retirer le mod, lancez l'action de debug **Réactiver les pompes à eau**.

## Voir aussi

[Équipements](02-equipements.md) - [Raccordement](03-raccordement.md) - [Recettes](08-recettes.md) - [Options sandbox](11-options-sandbox.md) - [Multijoueur](12-multijoueur.md)


Cliquez sur la pompe pour son **LCD individuel** : état de la pompe, débit d'eau
mesuré en L/h et consommation en W. Lire le LCD ne déplace aucune eau. Le bouton
**Raccordements** choisit l'onduleur de cette pompe ; les barils restent gérés par
les actions habituelles. Voir [les écrans et raccordements](06-equipements-optionnels.md#lcd-de-chaque-appareil-et-choix-de-londuleur).


Le LCD de la pompe a un fond **bleu**. Le voyant posé simule sa lueur ; il indique
l'alimentation, pas un débit garanti. Les règles de débit/barils restent inchangées.
Pour intervenir sans risque, éteignez l'onduleur, même si le voyant est éteint.
