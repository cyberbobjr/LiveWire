> English version: [LiveWire Extended](../en/14-livewire-extended.md)

# LiveWire Extended (module facultatif)

**LiveWire Extended** (`batman_LiveWireExtended`) est un mod facultatif livré avec LiveWire. Il a besoin de LiveWire. **Avec lui, un onduleur n'a plus de rayon** : il n'alimente que ce que vous lui raccordez, un bâtiment (par **Raccorder le bâtiment**, ou le bâtiment d'un tableau électrique que vous reliez) et les zones des bornes extérieures. Sans lui, LiveWire fonctionne exactement comme avant.

## Raccorder un bâtiment entier

Clic droit sur un onduleur > **LiveWire Extended** > **Raccorder le bâtiment** (Électricité 3, ni outil ni fil). Le bâtiment où se trouve l'onduleur est raccordé ; un onduleur posé dehors raccorde le bâtiment le plus proche dans sa portée de générateur (20 cases par défaut). Tous les étages reçoivent le courant, le sous-sol aussi, plus le reste des blocs de 8 x 8 cases qu'il couvre : le jeu alimente des blocs entiers. Une option sandbox ajoute une bande extérieure autour du rez-de-chaussée (0 à 8 cases, 0 par défaut).

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

## Tableaux électriques

Un **tableau électrique** (8, 16 ou 24 modules) se fixe au mur. Fabriquez-en un (Électricité 3), posez-le avec le curseur de meubles et raccordez-le à un onduleur avec du fil électrique, comme une borne. Ensuite :

- **Installez des disjoncteurs** au tournevis : 15 A, 20 A ou 30 A, un module chacun. Chacun est un objet à trouver (électriciens, quincailleries, garages) ou à fabriquer (Électricité 3, plus de pièces pour un calibre plus élevé).
- **Raccordez un appareil** à un disjoncteur, depuis l'appareil (clic droit > LiveWire Extended > Raccorder au tableau) ou depuis le tableau (Raccorder un appareil). Il faut du fil selon la distance, un tournevis, un testeur de tension (conservé) et Électricité 3 ; cela rapporte 5 XP. L'option se trouve dans le menu propre à l'objet quand le jeu lui en donne un (Interrupteur >, Applique >, four), sinon sous LiveWire Extended. Un appareil de plusieurs cases compte une fois ; une pièce et ses interrupteurs muraux forment un seul point d'éclairage ; une borne raccordée à un disjoncteur entraîne toute sa zone.
- **Dès qu'un tableau dessert un bâtiment, tout appareil de ce bâtiment raccordé à aucun disjoncteur n'a plus de courant.** Sans tableau, rien ne change.
- Chaque disjoncteur **saute seul** quand son circuit consomme plus que son calibre (W = A x V) ; réarmez-le sur le tableau. Avec le profil de consommation par défaut (valeurs du jeu), un disjoncteur ne saute presque jamais ; il protège avec les profils réalistes.
- **Ouvrez le tableau** pour voir chaque disjoncteur : levier, étiquette, charge en W et en A, énergie du jour, de la veille et sur 7 jours, et **Localiser** pour allumer ses appareils. L'étiquette s'écrit au stylo ou au crayon. Le logiciel de l'onduleur liste l'énergie de chaque disjoncteur dans son onglet Maison.
- Un **interrupteur crépusculaire** posé sur un disjoncteur ne laisse passer le courant qu'entre le crépuscule et l'aube : éclairage du jardin, lampes de porche.
- **Maisons de la carte** : une maison qui a son propre coffret électrique (souvent sur sa façade) l'a toujours pour tableau ; les autres bâtiments reçoivent un tableau sur un pan de mur nu (garage d'abord, puis buanderie ou réserve, puis entrée) dans 30 % des cas par défaut (option sandbox). Il ne fait rien tant que vous ne le raccordez pas à un onduleur ; il est alors précâblé, un disjoncteur par pièce et un 30 A à part pour la cuisinière et le sèche-linge, sans étiquette : à vous de découvrir quel disjoncteur alimente quoi.
- La machine à coudre électrique de My Tailor Is Rich et les machines de Functional Appliances 2 suivent aussi leur disjoncteur, de même que la pompe à eau et l'ordinateur de gestion de LiveWire.

## Sur l'onduleur

**Afficher la zone alimentée** dessine le contour de chaque bloc que l'onduleur alimente (ses bâtiments et les zones de ses bornes), à votre étage. La page 4 de l'écran de l'onduleur liste les bâtiments et bornes raccordés.

## Retirer le module

Si des tableaux sont en service, un admin ouvre d'abord le menu d'un tableau et choisit **Admin : tout remettre en service (avant de retirer le mod)** : plus aucun disjoncteur ne coupe et chaque appareil retrouve son état normal (les frigos refroidissent, les machines de Functional Appliances 2 retrouvent leur réglage). Décochez ensuite le module dans la liste des mods : LiveWire revient à son cercle au prochain chargement de la zone, sans courant résiduel. Rien n'est perdu dans les données de LiveWire. Le même menu remet les tableaux en fonction si vous changez d'avis.

Incompatible avec LG Extended Electricity, qui modifie la portée des générateurs dont LiveWire se sert, et avec Knox Power, qui pose son propre système de disjoncteurs dans les maisons.
