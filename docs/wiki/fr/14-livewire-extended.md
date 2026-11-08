> English version: [LiveWire Extended](../en/14-livewire-extended.md)

# LiveWire Extended (module facultatif)

**LiveWire Extended** (`batman_LiveWireExtended`) est un mod facultatif livré avec Live Wire. Il a besoin de Live Wire et ajoute deux façons de porter le courant au-delà du cercle de l'onduleur. Sans lui, Live Wire fonctionne exactement comme avant.

## Raccorder un bâtiment entier

Clic droit sur un onduleur > **LiveWire Extended** > **Raccorder le bâtiment** (Électricité 3, ni outil ni fil). Le bâtiment où se trouve l'onduleur est raccordé ; un onduleur posé dehors raccorde le bâtiment le plus proche que son cercle atteint. Tous les étages reçoivent le courant, le sous-sol aussi, plus une bande d'une case autour du rez-de-chaussée (option sandbox, de 0 à 8).

- Le jeu alimente des blocs entiers de 8 x 8 cases : les cases voisines de ces blocs reçoivent aussi le courant (une allée, un bout de la cour d'à côté).
- Un bâtiment n'est raccordé qu'à un seul onduleur. **Débrancher le bâtiment** dans le même menu.
- Les appareils raccordés sont facturés par l'onduleur comme les autres : consommation, disjoncteur et batterie fonctionnent comme d'habitude. Quand deux onduleurs atteignent le même appareil, c'est le plus proche allumé qui le paie.

## Borne électrique extérieure

La **borne électrique** (recette au niveau 3 d'Électricité, trouvable aussi avec le matériel d'électricien) amène le courant dehors : un potager, un atelier, une maison construite par les joueurs.

1. Posez-la n'importe où avec le curseur de meubles (aucun niveau) ; ramassez-la au tournevis.
2. Clic droit dessus > **LiveWire Extended** > **Raccorder à un onduleur** : mêmes règles de câble que les autres équipements (à portée de câble, un fil électrique par tranche de 4 cases, Électricité 3). Son propre bloc de 8 x 8 cases est alimenté aussitôt.
3. **Régler la zone** : cliquez et faites glisser au sol. La zone est arrondie aux blocs entiers (le contour montre ce qui sera vraiment alimenté : vert si c'est permis, rouge sinon), 2 x 2 blocs au plus (16 x 16 cases), près de la borne, à son étage et aux étages voisins.
4. Une borne raccordée posée dans un bâtiment, ou tout contre lui, peut aussi **Raccorder le bâtiment** : un garage éloigné est alimenté par elle.

Débrancher ou ramasser la borne retire sa zone et le bâtiment qu'elle raccordait. Dehors, l'option du jeu « générateur en extérieur » décide toujours si les cases extérieures peuvent être alimentées.

## Sur l'onduleur

**Afficher la portée** dessine le cercle et le contour de chaque bloc ajouté par les bâtiments et les bornes, à votre étage. La page 4 de l'écran de l'onduleur liste les bâtiments et bornes raccordés.

## Retirer le module

Décochez-le dans la liste des mods quand vous voulez : Live Wire revient à son cercle au prochain chargement de la zone, sans courant résiduel. Rien n'est perdu dans les données de Live Wire.

Incompatible avec LG Extended Electricity, qui modifie la portée des générateurs dont Live Wire se sert.
