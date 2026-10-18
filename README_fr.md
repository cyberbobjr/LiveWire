<p align="center"><img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/preview.png" width="256"></p>

# Live Wire

**La compétence Électricité devient un métier : panneaux, éoliennes et roues à aubes alimentent toute la maison, sans carburant ni fumées.**

Project Zomboid Build 42.21 · id `batman_LiveWire` · EN/FR · licence MIT

[English version: README.md](README.md)

![Installation extérieure : panneaux photovoltaïques et éolienne](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot4.png)

## Sommaire

- [Principe](#principe)
- [Équipements et batteries](#équipements-et-batteries)
- [Raccorder les éléments](#raccorder-les-éléments)
- [Écran de l'onduleur et logiciel de gestion](#écran-de-londuleur-et-logiciel-de-gestion)
- [Équipements optionnels](#équipements-optionnels)
- [Pompe à eau](#pompe-à-eau)
- [Tables de calcul](#tables-de-calcul)
- [Recettes](#recettes)
- [Tables de butin](#tables-de-butin)
- [Usure et entretien](#usure-et-entretien)
- [Compétence Électricité](#compétence-électricité)
- [Options sandbox](#options-sandbox)
- [Multijoueur, état, installation](#multijoueur-état-installation)
- [Project Viewpoint](#project-viewpoint)
- [Licence et crédits](#licence-et-crédits)
- [Pour les développeurs](#pour-les-développeurs)

## Principe

Live Wire repose sur **trois rôles et un seul réseau** :

- **Les sources produisent** : panneau photovoltaïque (100 W), éolienne (400 W), roue à aubes (120 W), en puissance nominale. Le nombre de sources par onduleur n'est pas limité ; chacune doit se trouver à portée de fil (12 cases, 1 étage d'écart au plus).
- **Les batteries stockent** (facultatif) : batteries de voiture ou batteries stationnaires, rangées dans une powerbank (4 batteries comptées par powerbank, rendement de charge 0,90). Plusieurs powerbanks par onduleur.
- **L'onduleur convertit et distribue** : 1 500 W maximum (demande de la maison), 20 W de consommation à vide, rendement de 0,85 à 1,0 (selon le niveau de l'installateur), un seul par réseau. Il se pose à l'intérieur et n'est pas toxique (ce n'est pas un générateur du jeu).
- **La maison** : tout appareil situé dans un rayon de 20 cases et à ±3 étages de l'onduleur (options vanilla `GeneratorTileRange` et `GeneratorVerticalPowerRange`) est alimenté. Aucun câblage appareil par appareil.

![Schéma : sources, onduleur, powerbank et maison](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/diagram_fr.png)

**Installation minimale** : une source et un onduleur. Sans batterie, la maison ne tourne que sur la production du moment (par exemple, trois panneaux par grand soleil font fonctionner un congélateur-réfrigérateur à midi, pas la nuit).

C'est le jeu lui-même qui décide ce qui est alimenté (une case est alimentée comme si elle se trouvait près d'un générateur) : frigos, lumières, cuisinières, téléviseurs et radios fonctionnent exactement comme en vanilla.

**Les frigos restent froids pendant votre absence.** Tant qu'il y a du courant, réfrigérateurs et congélateurs conservent la nourriture même quand la zone est déchargée. Vérifié en jeu : un steak frais dans un frigo alimenté, joueur à 300 cases, 10 heures de jeu : âge 0,083 jour (froid) au lieu de 0,417 jour (chaud). Limite du moteur : l'état d'alimentation trouvé au rechargement de la zone compte pour toute la durée de l'absence.

## Équipements et batteries

Chaque recette donne un meuble posable `Base.Mov_LiveWire_*`. On le pose, le tourne et le ramasse avec le curseur de meubles vanilla (fantôme, 4 orientations, 2 pour les objets muraux). La pose, comme le ramassage, exige un tournevis et le niveau d'Électricité indiqué. Un appareil ramassé garde son état. Règles de pose ajoutées par le mod : en extérieur (ciel dégagé) pour le panneau et l'éolienne ; au rez-de-chaussée, sur la berge, contre l'eau d'une rivière pour la roue à aubes (lacs et étangs refusés). Une case refusée affiche la raison en rouge dans le panneau du curseur.

![Tous les équipements Live Wire et leurs chiffres](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/equipment_fr.png)

| Équipement | Rôle | Pose | Niveau |
|---|---|---|---|
| Panneau photovoltaïque | Source, 100 W | Extérieur, ciel dégagé ; toit plat possible | 3 |
| Éolienne | Source, 400 W ; les pales tournent avec le vent | Extérieur ; +15 % de vent par étage jusqu'au 3e | 6 |
| Roue à aubes | Source, 120 W jour et nuit | Rez-de-chaussée, au bord d'une rivière | 7 |
| Onduleur | Cœur du réseau, 1 500 W | Toute case d'étage, intérieur compris | 5 |
| Powerbank | Stockage, 4 batteries comptées ; s'ouvre comme une caisse (capacité 50) | Partout ; ramassée seulement vide | 2 |
| Disjoncteur | Sécurité, facultatif | Sur un mur (nord ou ouest) | 3 |
| Alarme de batterie faible | Alerte, facultatif | Sur un mur | 2 |
| Pompe à eau | Consommateur, 250 W en pompant : amène l'eau des barils aux robinets | Toute case d'étage, intérieur ou extérieur | 6 |

**Batteries** (jamais au sol : glissez-les dans la powerbank avec l'inventaire vanilla) :

| Batterie | Capacité nominale | Durée de vie |
|---|---|---|
| Batterie de voiture `Base.CarBattery1` | 0,40 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery2` | 0,60 kWh | 150 cycles |
| Batterie de voiture `Base.CarBattery3` | 0,90 kWh | 150 cycles |
| Batterie stationnaire `LiveWire.DeepCycleBattery` | 1,50 kWh | 600 cycles |

Capacité effective = nominale × (0,4 + 0,6 × état/100) × `BatteryCapacityMultiplier`.

![La powerbank ouverte comme une caisse](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot3.png)

**Voyants sur les tuiles** : écran de l'onduleur allumé quand il fonctionne, voyant rouge en cas de défaut ; voyant vert « connecté » sur les sources et la powerbank ; lampe rouge du disjoncteur quand il a sauté ; gyrophare de l'alarme allumé tant qu'elle sonne ; voyant bleu sur la pompe à eau tant qu'elle dessert au moins un point d'eau.

![Intérieur : onduleur, powerbank, ordinateur, alarme et disjoncteur muraux](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot5.png)

## Raccorder les éléments

1. Fabriquez les appareils ([recettes](#recettes)) et posez-les avec le curseur de meubles.
2. Clic droit sur un appareil > « Live Wire » > nom de l'appareil : affiche « Raccordé à l'onduleur à N cases » ou « Non raccordé », puis « Raccorder à un onduleur » > une ligne par onduleur à portée : « Onduleur à N cases (k fil(s)) ». Ou clic droit sur l'onduleur > « Raccorder un équipement » (liste des équipements libres à portée, avec distance et nombre de fils) / « Débrancher un équipement ».
3. **Coût** : fil électrique `Base.ElectricWire`, **1 fil par tranche de 4 cases** de distance, arrondi au supérieur, au moins 1 (option `WirePerTiles` ; 0 = gratuit). Exemple : un panneau à 9 cases de l'onduleur coûte 9 / 4 = 2,25, soit **3 fils**.
4. **Portée** : 12 cases (option `LinkRange`, de 4 à 30), 1 étage d'écart au plus.
5. **Limites par réseau** : au plus un disjoncteur, une alarme, un ordinateur de gestion et un générateur de secours.
6. Le générateur vanilla (secours) et l'ordinateur de bureau vanilla (gestion) se raccordent de la même façon, depuis leur propre menu clic droit : « Live Wire » > Générateur de secours / Ordinateur de gestion > Raccorder à un onduleur.
7. Ramasser l'onduleur déconnecte tout son réseau ; le faire pivoter conserve les liens. Une source ramassée garde son état ; reposée, elle est « Non raccordé ».

**Menu clic droit de l'onduleur** : ouvrir l'écran de l'onduleur, allumer / éteindre, réarmer (après un déclenchement), afficher la zone alimentée (cercle cyan au sol), raccorder / débrancher un équipement, insonoriser l'onduleur, inspecter, réparer, remettre à neuf.

![Menu clic droit « Live Wire » de l'onduleur](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot1.png)

## Écran de l'onduleur et logiciel de gestion

**Écran LCD** (clic droit sur l'onduleur > Ouvrir l'écran de l'onduleur) : écran rétroéclairé de 5 pages (Production/Charge, Batteries, Sources, Maison, État) avec les boutons < et > ; bouton I/O à voyant (vert allumé, rouge éteint, orange clignotant en cas de défaut) ; bouton RESET quand l'onduleur a sauté ; barres de production et de charge à la même échelle ; les longues lignes défilent.

![Écran LCD de l'onduleur, page Production/Charge](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/onduleur.png)

![Écran de l'onduleur dans la maison](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot2.png)

**Logiciel de gestion « Live Wire Monitor »** : onglets Vue d'ensemble, Batteries, Sources, Maison, Historique, Équipements.
- Vue d'ensemble : production et consommation en grands chiffres avec barres à la même échelle, jauge de stockage et autonomie, fiche de l'onduleur (voyant d'état, état, Marche/Arrêt, Reset), alertes.
- Historique : graphiques sur 48 h (production, consommation, stock des batteries) et prévision « les batteries tiendront jusqu'à l'aube ». Nécessite un ordinateur de gestion relié.

| Configuration | Fonctionnement |
|---|---|
| **Sans le Computer Mod** | Un ordinateur de bureau vanilla relié à l'onduleur ouvre le logiciel sur l'écran d'ordinateur propre au mod (moniteur, écran de démarrage « Live Wire OS », barre d'état avec l'heure du jeu). |
| **Avec le Computer Mod (Workshop 3725497089) ou le Laptop Mod (3798992436)** | Le logiciel est livré sur un disque, « Disque : logiciel de gestion Live Wire » (`LiveWire.MonitorDisk`), trouvé dans le butin d'ordinateurs. Clic droit sur l'ordinateur avec le disque > « Installer le logiciel Live Wire ». Il apparaît ensuite comme application « Live Wire » sur leur bureau et s'exécute dans leur fenêtre (barre de titre, réduire, fermer, barre des tâches). Il montre l'onduleur relié à cet ordinateur, ou l'onduleur le plus proche à portée de fil. |

**Sans Computer Mod** (ordinateur de bureau vanilla, écran propre au mod) :

![Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/livewire_monitor_without_compute.png)

Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod.

**Avec Computer Mod ou Laptop Mod** (logiciel installé depuis le disque) :

![Bureau du Computer Mod avec l'icône Live Wire](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/computermod.png)

![Live Wire Monitor, vue d'ensemble, dans le Computer Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/livewire_computermod.png)

![Historique sur 48 h et prévision](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/conso_livewire_computermod.png)

![Onglet Equipment du logiciel dans le Computer Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/equipement_livewire_computermod.png)

**Bourdonnement de l'onduleur** : un son propre au mod, audible seulement à une case autour d'un onduleur allumé (même étage). Chaque joueur règle son volume dans Options > Mods > Live Wire (0 = coupé). Les zombies l'entendent à 2 cases (option `InverterNoiseRadius`).

**Kit d'insonorisation** (`LiveWire.SoundproofKit`) : se monte sur l'onduleur avec un tournevis (« Insonoriser l'onduleur ») et se retire par « Retirer l'insonorisation » (le kit est rendu). Effets : plus de bourdonnement, les zombies ne l'entendent plus ; en contrepartie l'onduleur chauffe davantage et s'use 25 % plus vite. Le kit suit l'onduleur quand on le ramasse.

Un onduleur insonorisé est recouvert de mousse acoustique grise sur le dessus, les côtés et l'arrière (l'écran reste visible), et « Insonorisé » s'affiche quand on l'inspecte et sur la page État de son écran.

## Équipements optionnels

| Équipement | Effet | Niveau |
|---|---|---|
| Disjoncteur (mur) | Saute à la place de l'onduleur quand la demande de la maison dépasse 1 500 W : l'onduleur ne perd plus 3 points d'état. Lampe rouge quand il a sauté ; réarmement sur le disjoncteur lui-même (« Réarmer le disjoncteur »), refusé tant que la surcharge persiste. | 3 |
| Alarme de batterie faible (mur) | Sous 20 % de stock : message aux joueurs à 30 cases, bip toutes les 10 minutes de jeu jusqu'à « Couper la sonnerie » ; le gyrophare reste allumé jusqu'à ce que le stock repasse au-dessus de 25 %. | 2 |
| Générateur de secours (générateur vanilla) | Démarré par le mod sous 20 % de batterie, arrêté à 90 % (options sandbox). Fournit 1 200 W et brûle 1 L de carburant pour 3 kWh (en plus de sa consommation vanilla). Toujours bruyant et toxique en intérieur ; à brancher et alimenter en carburant à la manière vanilla. Ne démarre jamais sans batteries. | 3 |
| Ordinateur de gestion (ordinateur de bureau vanilla) | Historique 48 h, prévision jusqu'à l'aube. Délestage au niveau 7 : éteint les lumières sous 15 % pour sauver le frigo, réarmé au-dessus de 30 %. | 6 |
| Onduleurs couplés (jusqu'à 3 onduleurs de plus) | La puissance du réseau est la somme des onduleurs en service : jusqu'à 4 × 1 500 W = 6 000 W. Voir ci-dessous. | 6 |

### Onduleurs en parallèle (couplage)

Dans une vraie installation autonome, on gagne de la puissance en ajoutant des onduleurs identiques en parallèle, pas en poussant un onduleur au-delà de sa capacité. Live Wire fait de même :

- Clic droit sur un onduleur > **Coupler à un onduleur** > un onduleur maître à portée de câble. L'onduleur cliqué devient **esclave**. Coût : le fil électrique de la distance et 1 **kit de couplage d'onduleurs** (recette au niveau 6 d'Électricité).
- L'esclave ne doit avoir aucun équipement raccordé ; un maître accepte au plus 3 esclaves (4 onduleurs).
- Un seul réseau, un seul parc de batteries, une seule zone alimentée (celle du maître). Capacité = 1 500 W × onduleurs en service ; chaque onduleur allumé consomme 20 W à vide et s'use comme d'habitude.
- Un esclave éteint ou cassé ne compte plus : si la demande dépasse alors ce qui reste, le disjoncteur (ou le maître) saute. Chaque esclave a son interrupteur ; on réarme sur le maître ou le disjoncteur.
- **Découpler** sur l'esclave le rend de nouveau indépendant (le kit est rendu). Un maître ramassé libère ses esclaves.
- La page État de l'écran LCD et le logiciel affichent « Couplés : n / total en service » et la capacité totale.
- Deux onduleurs indépendants dont les zones se recouvrent ne comptent plus deux fois les mêmes appareils : chaque appareil est compté par l'onduleur allumé le plus proche.

### Quand le disjoncteur saute-t-il ?

Quand la demande des appareils de la maison dépasse le maximum de l'onduleur, **1 500 W** (les 20 W à vide ne comptent pas). Le contrôle a lieu à chaque pas de simulation : toutes les 10 minutes de jeu et juste après une action. Exemple : un lave-linge et un sèche-linge superposés qui tournent ensemble (jusqu'à 1 800 W). Sans disjoncteur, c'est l'onduleur qui saute et perd 3 points d'état (réinitialisation sur l'onduleur).

## Pompe à eau

Un appareil posé comme les autres (niveau 6). Elle pompe l'eau des barils vers les robinets de la maison. Pas encore testée en jeu.

- Raccordez la pompe à l'onduleur avec du fil électrique, comme pour tout appareil.
- Raccordez chaque baril d'eau (récupérateur d'eau de pluie vanilla, ou baril du mod facultatif Useful Barrels) avec un **tuyau en métal** (`Base.MetalPipe`, rendu au débranchement). Le baril doit être à côté de la pompe : l'une de ses 8 cases voisines, au même étage. Jusqu'à 8 barils par pompe. Seul un baril qui contient de l'eau (ou vide) peut être raccordé.
- Au-dessus de chaque évier, baignoire, douche ou toilette raccordé, situé dans une pièce à **15 cases** au plus de la pompe (option `PumpRange`, de 5 à 30) et jusqu'à 3 étages au-dessus ou en dessous, la pompe garde un réservoir relais invisible de 25 L. La plomberie vanilla y prend l'eau : raccordez le point d'eau avec la clé anglaise comme d'habitude (« Raccorder la plomberie de… »).
- Aucun relais n'est posé au-dessus d'un robinet qui a déjà une autre source d'eau (baril vanilla à l'étage, eau courante, autre mod).
- Tant que le réseau a du courant, la pompe remplit les relais depuis ses barils, à 5 L par minute de jeu au plus. Elle consomme 250 W seulement en pompant, et s'arrête quand tous les robinets sont pleins. Un léger bourdonnement de moteur s'entend à 4,5 cases pendant la marche ; les zombies l'entendent à 2 cases.
- Seule l'eau est déplacée ; la pluie remplit toujours les barils comme avant. L'eau croupie sort propre au robinet, comme en vanilla.
- Clic droit sur la pompe > **Afficher les points d'eau alimentés** : un cercle bleu montre la portée, et les points d'eau desservis, les barils raccordés et la pompe sont surlignés en bleu. Un voyant bleu s'allume sur la pompe tant qu'elle dessert au moins un point d'eau.
- Plusieurs pompes par réseau. L'onglet Équipements du logiciel affiche le nombre de pompes en service et leur débit (L/h), rien d'autre.
- **Avant de retirer le mod**, lancez l'action de débogage « Retirer tous les relais d'eau » (menu Live Wire > Débogage, avec les droits d'administrateur en multijoueur), sinon les tuiles invisibles des relais restent dans la sauvegarde.

## Tables de calcul

Le serveur calcule toutes les 10 minutes de jeu, joueurs présents ou non (option `SimulateUnloaded`, activée par défaut).

![Trois graphiques : journée solaire, courbe de l'éolienne, énergie par jour face à une maison type](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/production_fr.png)

**Puissance d'une source** : P = nominale × facteur de la source × facteur d'état × rendement de pose × multiplicateur sandbox.

- Facteur d'état = 0,5 + 0,5 × état/100.
- Rendement de pose (niveau d'Électricité de l'installateur à la pose) : 0,85 (niveaux 3 à 6), 0,95 (7 et 8), 1,0 (9 et 10).
- Chaque source lisse sa sortie (réponse sur 30 minutes de jeu) : un nuage de passage ne fait pas vaciller la maison.

**Solaire (100 W)** : courbe sinusoïdale entre l'aube et le crépuscule de la saison ; un ciel couvert laisse 20 % (facteur × (1 − 0,8 × nuages)) ; la neige recouvre le panneau pendant les chutes et fond au-dessus de 0 °C (action « Déneiger »). Environ 0,94 kWh par jour d'été et 0,60 kWh en hiver (panneau neuf, ciel clair).

**Éolien (400 W)** : part de la puissance nominale selon la vitesse du vent v, avec +15 % de vent par étage jusqu'au 3e.

| Vent | Part de la puissance |
|---|---|
| Moins de 10 km/h | 0 |
| 10 à 45 km/h | ((v − 10) / 35)³ |
| 45 à 85 km/h | 100 % |
| Plus de 85 km/h | 0 (frein automatique) |

Exemples : 25 km/h ≈ 31 W, 40 km/h ≈ 252 W.

**Roue à aubes (120 W)** : jour et nuit, ≈ 2,9 kWh par jour ; saison : printemps × 1,2, été × 0,8, automne et hiver × 1,0. Rivières seulement (le moteur ne sait pas distinguer le courant d'un lac).

**Charge des batteries** : surplus × 0,90 (rendement de charge) ; autodécharge 0,2 % par jour ; quand elles sont pleines, l'excédent est perdu (affiché « production perdue »).

**Onduleur** : il couvre d'abord la demande avec la production courante (× rendement), puis avec les batteries ; il ne peut redémarrer que si la production couvre la demande ou si les batteries contiennent plus de 2 % de leur capacité. Échelle d'énergie : 1 unité de puissance du moteur par heure = 1 000 W (option `PowerScale`).

**Consommation des appareils** (valeurs du moteur vanilla, appareil allumé) :

| Appareil | Consommation |
|---|---|
| Lumière | 2 W |
| Radio sur secteur | 10 W |
| Télévision | 30 W |
| Réfrigérateur seul | 80 W |
| Cuisinière, micro-ondes, lave-linge, sèche-linge | 90 W |
| Congélateur-réfrigérateur | 130 W |
| Lave-linge + sèche-linge superposés | jusqu'à 1 800 W |

**Exemple de dimensionnement** : un congélateur-réfrigérateur et 10 lumières ≈ 170 W (avec les 20 W de l'onduleur à vide), soit 4,1 kWh par jour. Une nuit d'hiver de 14 h demande ≈ 2,4 kWh : environ 4 batteries de voiture ou 2 batteries stationnaires.

| Installation | Été (kWh/jour) | Hiver (kWh/jour) | Verdict pour 4,1 kWh/jour |
|---|---|---|---|
| 4 panneaux photovoltaïques | 3,8 | 2,4 | Déficit |
| 6 panneaux + 1 éolienne (vent moyen 25 km/h ≈ 0,7 kWh) | 6,3 | 4,3 | Juste suffisant |
| 1 roue à aubes + 2 panneaux | 4,8 | 4,1 | Stable |

Le nombre de panneaux n'est pas limité : les productions s'additionnent (100 W nominaux chacun). La limite de 1 500 W s'applique à la demande de la maison, pas à la production.

## Recettes

Les recettes sont dans le menu d'artisanat, catégorie Électricité, et s'apprennent automatiquement au niveau d'Électricité requis. Les outils sont conservés.

![Planche illustrée des recettes Live Wire](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/recipe_book_fr.png)

| Ingrédients | Outils (conservés) | Compétence | Résultat |
|---|---|---|---|
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/LightBulb.png" width="24" height="24"> Ampoule<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Battery.png" width="24" height="24"> Pile | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | Électricité 1 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/VoltageTester.png" width="32" height="32"> **Testeur de tension** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Calculator.png" width="24" height="24"> Calculatrice | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | aucune | 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="32" height="32"> **Pièces électroniques**<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SolarCell.png" width="32" height="32"> **Cellule photovoltaïque** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SheetMetal.png" width="24" height="24"> Plaque en métal<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> | Électricité 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/PowerBank.png" width="32" height="32"> **Powerbank** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Amplifier.png" width="24" height="24"> Amplificateur | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | Électricité 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/BatteryAlarm.png" width="32" height="32"> **Alarme de batterie faible** |
| 4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Plank.png" width="24" height="24"> Planche<br>10 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Nails.png" width="24" height="24"> Clous<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/RippedSheets.png" width="24" height="24"> Tissu déchiré | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Hammer.png" width="24" height="24"> | Électricité 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SoundproofKit.png" width="32" height="32"> **Kit d'insonorisation d'onduleur** |
| 10 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SolarCell.png" width="24" height="24"> Cellule photovoltaïque<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SheetMetal.png" width="24" height="24"> Plaque en métal<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Glue.png" width="24" height="24"> Super glue | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> | Électricité 3 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SolarPanel.png" width="32" height="32"> **Panneau photovoltaïque** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SmallSheetMetal.png" width="24" height="24"> Petite plaque en métal<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | Électricité 3 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Breaker.png" width="32" height="32"> **Disjoncteur** |
| 4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Amplifier.png" width="24" height="24"> Amplificateur<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SmallSheetMetal.png" width="24" height="24"> Petite plaque en métal<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> | Électricité 5 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Inverter.png" width="32" height="32"> **Onduleur** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Speaker.png" width="24" height="24"> Haut-parleur<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SheetMetal.png" width="24" height="24"> Plaque en métal<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/MetalBar.png" width="24" height="24"> Barre en métal<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pipe.png" width="24" height="24"> Tuyau en plastique<br>6 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Hammer.png" width="24" height="24"> | Électricité 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/WindTurbine.png" width="32" height="32"> **Éolienne** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/CarBattery1.png" width="24" height="24"> Batterie de voiture (toutes)<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ScrapMetal.png" width="24" height="24"> Ferraille | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> | Électricité 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/DeepCycleBattery.png" width="32" height="32"> **Batterie stationnaire** |
| 8 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Plank.png" width="24" height="24"> Planche<br>20 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Nails.png" width="24" height="24"> Clous<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Speaker.png" width="24" height="24"> Haut-parleur<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/MetalBar.png" width="24" height="24"> Barre en métal | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Hammer.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | Électricité 7 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/WaterWheel.png" width="32" height="32"> **Roue à aubes** |
| 3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/MetalPipe.png" width="24" height="24"> Tuyau en métal<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SmallSheetMetal.png" width="24" height="24"> Petite plaque en métal<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screws.png" width="24" height="24"> Vis | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/PipeWrench.png" width="24" height="24"> | Électricité 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/WaterPump.png" width="32" height="32"> **Pompe à eau** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectricWire.png" width="24" height="24"> Fil électrique<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Amplifier.png" width="24" height="24"> Amplificateur | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Screwdriver.png" width="24" height="24"> | Électricité 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/CouplingKit.png" width="32" height="32"> **Kit de couplage d'onduleurs** |
| 5 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/ElectronicsScrap.png" width="24" height="24"> Pièces électroniques<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Aluminum.png" width="24" height="24"> Aluminium | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Pliers.png" width="24" height="24"> | Électricité 8 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/SolarCell.png" width="32" height="32"> **Cellule photovoltaïque** |

L'ordinateur de gestion et le générateur de secours ne se fabriquent pas : ce sont des objets vanilla que l'on trouve dans le monde.
| 3 × Pièces électroniques<br>2 × Fil électrique<br>2 × Tuyau en métal<br>1 × Petite plaque en métal<br>4 × Vis | Tournevis, clé à molette (gardés) | Électricité 6 | **Pompe à eau** |

## Tables de butin

**Comment lire ces tables** : Project Zomboid teste chaque objet indépendamment à chaque tirage d'une liste de conteneur. Un **poids** de W donne environ W % par tirage à rareté normale (avant les réglages de butin du sandbox et la densité de zombies). La colonne « Tirages » est le nombre de tirages de cette liste vanilla. La chance approximative par conteneur vaut 1 − (1 − W/100)^Tirages. Pour les meubles posables comme le panneau, le jeu applique le modificateur « Autre » (0,6 à rareté normale).

**Cellule photovoltaïque** `LiveWire.SolarCell` (toujours) :

| Liste vanilla | Lieu | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| GarageTools | Rangement d'outils de garage | 2 | 4 | 7,8 % |
| CrateTools | Caisses d'outils | 1 | 4 | 3,9 % |
| GarageMetalwork | Rangement de métallerie de garage | 1 | 4 | 3,9 % |
| MechanicShelfElectric | Garage mécanique, étagère électrique | 2 | 4 | 7,8 % |
| ElectricianTools | Outils d'électricien | 3 | 3 | 8,7 % |
| MetalShopTools | Outils de métallerie | 1 | 4 | 3,9 % |
| WireFactoryElectric | Fabrique de fils, électrique | 2 | 4 | 7,8 % |
| ToolStoreMisc | Quincaillerie, divers | 2 | 4 | 7,8 % |

**Panneau solaire prêt à poser** `Base.Mov_LiveWire_SolarPanel` (toujours ; meuble, × 0,6 à rareté normale) :

| Liste vanilla | Lieu | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| GarageTools | Rangement d'outils de garage | 0,3 | 4 | 0,7 % |
| CrateTools | Caisses d'outils | 0,3 | 4 | 0,7 % |
| GarageMetalwork | Rangement de métallerie de garage | 0,2 | 4 | 0,5 % |
| ToolStoreMisc | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
| ToolStoreTools | Quincaillerie, outils | 0,3 | 4 | 0,7 % |

### Équipements Live Wire tout faits

Trouvés déjà fabriqués, en plus des recettes (les réglages de butin sandbox s'appliquent).

| Équipement | Liste vanilla | Où | Poids | Tirages | ≈ chance par conteneur |
|---|---|---|---|---|---|
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/VoltageTester.png" width="24" height="24"> **Testeur de tension** | `ElectricianTools` | Outils d'électricien | 3 | 3 | 8,7 % |
|  | `ToolStoreTools` | Quincaillerie, outils | 1 | 4 | 3,9 % |
|  | `GarageTools` | Rangement d'outils de garage | 1 | 4 | 3,9 % |
|  | `CrateTools` | Caisses d'outils | 1 | 4 | 3,9 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 3,9 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/DeepCycleBattery.png" width="24" height="24"> **Batterie stationnaire** | `CarSupplyBatteries` | Magasin de pièces auto, batteries | 2 | 4 | 7,8 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 1 | 4 | 3,9 % |
|  | `GarageMechanics` | Garage, rangement mécanique | 0,3 | 4 | 1,2 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Inverter.png" width="24" height="24"> **Onduleur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 0,5 | 3 | 0,9 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 0,5 | 4 | 1,2 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,2 | 4 | 0,5 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,1 | 4 | 0,2 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/Breaker.png" width="24" height="24"> **Disjoncteur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 1 | 3 | 1,8 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 2,4 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,3 | 4 | 0,7 % |
|  | `CrateTools` | Caisses d'outils | 0,3 | 4 | 0,7 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/PowerBank.png" width="24" height="24"> **Powerbank** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 0,5 | 3 | 0,9 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 0,5 | 4 | 1,2 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,3 | 4 | 0,7 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,2 | 4 | 0,5 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/BatteryAlarm.png" width="24" height="24"> **Alarme de batterie faible** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 1 | 3 | 1,8 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 2,4 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/WindTurbine.png" width="24" height="24"> **Éolienne** (meuble : × 0,6 inclus) | `ToolStoreMisc` | Quincaillerie, divers | 0,1 | 4 | 0,2 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 0,1 | 4 | 0,2 % |

**Disque du logiciel de gestion** `LiveWire.MonitorDisk` (seulement quand le Computer Mod est actif) :

| Liste vanilla | Lieu | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| ElectronicStoreComputers | Magasin d'électronique, ordinateurs | 2 | 1 | 2,0 % |
| CrateComputer | Caisses d'ordinateurs | 2 | 4 | 7,8 % |
| BookstoreComputer | Librairie, rayon informatique | 1 | 4 | 3,9 % |
| UniversityDesk_Computer | Bureau d'université, informatique | 1 | 4 | 3,9 % |
| UniversityDesk_Electrical | Bureau d'université, électricité | 2 | 4 | 7,8 % |
| OfficeDesk | Bureaux | 0,3 | 4 | 1,2 % |

Par ailleurs : 1 cellule photovoltaïque par calculatrice démontée (sans niveau) ; au niveau 8, une cellule se fabrique à partir de 5 déchets électroniques et 1 aluminium.

## Usure et entretien

| Appareil | Usure normale | Accélérateurs |
|---|---|---|
| Panneau photovoltaïque | −1 tous les 10 jours | Orage, seulement avec `StormDamage` (désactivé par défaut) |
| Éolienne | −1 tous les 4 jours | Vent > 85 km/h avec `StormDamage` |
| Roue à aubes | −1 tous les 6 jours | — |
| Onduleur | −1 tous les 5 jours en marche | Charge > 80 % : usure × 2 ; chaque déclenchement sans disjoncteur : −3 ; insonorisé : × 1,25 |
| Disjoncteur | −1 tous les 15 jours | — |
| Pompe à eau | −1 tous les 10 jours en pompant | — |
| Powerbank, alarme | −1 tous les 30 jours | — |
| Batterie | 100 / durée de vie par cycle complet | Décharge sous 20 % : usure doublée ; autodécharge 0,2 % par jour |

- **Réparation** : 1 déchets électroniques + 1 fil électrique, gain de 5 + niveau d'Électricité points (jusqu'à 90). Chance d'échec : max(5, 40 − 5 × niveau) %, divisée par deux dès le niveau 8 ; les pièces sont perdues en cas d'échec.
- **Remise à neuf** (niveau 8, 4 déchets électroniques + 2 fils) : retour à 100.
- **Reconditionnement d'une batterie** (niveau 4) : 1 déchets électroniques + 0,5 L d'eau, +15 d'état, plafonné à 80.
- **Testeur de tension** (`LiveWire.VoltageTester`) : clic droit sur une case > Live Wire > Mesurer. Alimentée oui/non (niveau 0), origine (1), consommation de l'appareil (2), bilan du réseau (4).

## Compétence Électricité

| Niveau | Débloque | Effet continu |
|---|---|---|
| 0 | Lire un testeur : alimenté ou non | — |
| 1 | Testeur de tension | Lecture détaillée de la case |
| 2 | Powerbank, alarme de batterie faible, kit d'insonorisation | Usure des batteries −5 % |
| 3 | Panneaux photovoltaïques, disjoncteur, générateur de secours | Rendement de pose 0,85 |
| 4 | Reconditionner une batterie | Lecture de l'autonomie |
| 5 | Onduleur | — |
| 6 | Éolienne, batterie stationnaire, ordinateur de gestion | Usure des batteries −10 % |
| 7 | Roue à aubes, délestage | Rendement de pose 0,95 |
| 8 | Cellules photovoltaïques à partir de déchets, remise à neuf | Échec de réparation divisé par deux |
| 9-10 | — | Rendement de pose 1,0 ; usure des appareils −25 % |

**Expérience** (toujours attribuée par le serveur) : recettes du mod (voir le tableau) ; poser une source 10 (panneau), 20 (éolienne, roue à aubes) ; poser un onduleur 25 ; connecter une source ou une batterie 3 ; inspecter un appareil 2 (une fois par appareil et par jour) ; mesurer avec le testeur 1 (une fois par case et par heure) ; réparer 5 + 1 par point, 15 au maximum ; reconditionner une batterie 8 ; réinitialiser après avoir corrigé une surcharge 5 (une fois par heure) ; insonoriser l'onduleur 3.

## Options sandbox

Page « LiveWire » des options sandbox.

| Option | Défaut | Plage | Effet |
|---|---|---|---|
| `PowerScale` | 1,0 | 0,1-10 | 1 unité de puissance du moteur par heure = 1 000 W × cette valeur |
| `SolarMultiplier` / `WindMultiplier` / `HydroMultiplier` | 1,0 | 0-10 | Production par famille de sources |
| `BatteryCapacityMultiplier` | 1,0 | 0,1-10 | Capacité des batteries |
| `BatteryWearMultiplier` / `DeviceWearMultiplier` | 1,0 | 0-10 | Usure ; 0 = aucune |
| `InverterNoiseRadius` | 2 | 0-10 | Rayon du bourdonnement entendu par les zombies ; 0 = silencieux |
| `LinkRange` | 12 | 4-30 | Distance de câble maximale |
| `PumpRange` | 15 | 5-30 | Rayon autour d'une pompe à eau dans lequel ses points d'eau sont alimentés |
| `WirePerTiles` | 4 | 0-20 | Cases par fil électrique ; 0 = câblage gratuit |
| `StormDamage` | désactivé | — | Dégâts d'orage et de vent fort |
| `XPMultiplier` | 1,0 | 0-10 | Expérience donnée par le mod |
| `SkillGates` | activé | — | Désactivé = aucun niveau requis |
| `SimulateUnloaded` | activé | — | Continue de simuler sans personne à proximité |
| `BackupStartPercent` / `BackupStopPercent` | 20 / 90 | 0-90 / 10-100 | Seuils du générateur de secours |

**Option joueur** (Options > Mods > Live Wire) : volume du bourdonnement de l'onduleur, de 0 à 100 (0 = coupé).

## Multijoueur, état, installation

**Multijoueur.** Production, stock, états, pannes et expérience sont calculés par le serveur ; le client affiche et envoie des demandes que le serveur revérifie. Installations partagées selon les règles vanilla des refuges. Le logiciel peut avoir jusqu'à 10 minutes de jeu de retard. Si le serveur se met en pause quand il est vide, l'installation se met en pause aussi. Les générateurs vanilla sont inchangés ; si un générateur et un onduleur couvrent les mêmes appareils, les deux sont consommés. Outils de debug : `-debug` en solo, administrateurs en multijoueur. **Le multijoueur n'a pas encore été testé en jeu.**

**État** : version 1.3.1. Testé en jeu en solo pendant le développement (pose, conteneur, raccordement, lumières, disjoncteur, alarme, écran LCD, logiciel, zone alimentée, rotation, ramassage, frigo pendant l'absence ; intégration du Computer Mod). Les valeurs d'équilibrage sont des valeurs de départ.

**Installation**
- Abonnez-vous au mod sur le Workshop Steam (une fois publié), ou
- copiez le dossier `Contents/mods/batman_LiveWire` dans `Zomboid/mods`.

Mods facultatifs : Computer Mod (3725497089) ou Laptop Mod (3798992436) pour le logiciel de gestion installable par disque.

## Project Viewpoint

L'objet Workshop contient aussi le mod facultatif **Live Wire - Viewpoint models** (`batman_LiveWireViewpoint`) : les modèles 3D de tous les équipements, de leurs voyants, des pales et de la mousse d'insonorisation pour [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528). À activer seulement si vous utilisez Project Viewpoint ; sans lui, ce mod ne fait rien. Les modèles sont produits à partir de la même géométrie Blender que les tuiles (`source/viewpoint/export_viewpoint.py`).

![Viewpoint](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/viewpoint.png)
![Viewpoint](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/viewpoint2.png)

*Les équipements Live Wire vus avec Project Viewpoint.*

## Licence et crédits

Licence MIT (voir [LICENSE](LICENSE)).

Création originale, sans code ni ressource repris d'autres mods.

## Pour les développeurs

- `docs/` : documentation et pages du wiki ;
- `tools/check_mod.py` : vérification du mod ;
- `tests/` : tests ;
- `source/` : sources.
