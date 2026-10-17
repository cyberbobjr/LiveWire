[English version: [Inverter-Screen-and-Software](Inverter-Screen-and-Software)]

# Écran de l'onduleur et logiciel

L'onduleur a un écran LCD, et un logiciel de gestion se lit sur un ordinateur relié.

## Écran LCD

Clic droit sur l'onduleur, « Ouvrir l'écran de l'onduleur ». Écran rétroéclairé, 5 pages que l'on parcourt avec < et > :

| Page | Contenu |
|---|---|
| 1 | Production / charge |
| 2 | Batteries |
| 3 | Sources |
| 4 | Maison |
| 5 | État |

Un bouton I/O avec voyant (vert allumé, rouge éteint, orange clignotant en cas de défaut), un bouton RESET après une disjonction, des barres de production et de charge à la même échelle ; les longues lignes défilent.

![Écran de l'onduleur dans la maison](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot2.png)

![Page 1 : production / charge](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/onduleur.png)

## Logiciel « Live Wire Monitor »

| Onglet | Contenu |
|---|---|
| Overview | Production et consommation en grands chiffres, barres à la même échelle, jauge de stockage et autonomie, fiche de l'onduleur (voyant, état, On/Off, Reset), alertes |
| Batteries | État des batteries |
| Sources | Les sources |
| House | La maison |
| History | Graphiques sur 48 h (production, consommation, stock des batteries) et prévision « les batteries tiendront jusqu'au lever du jour » ; exige un ordinateur de gestion relié |
| Equipment | Disjoncteur, alarme, générateur de secours, ordinateur |

### Sans Computer Mod

Un ordinateur de bureau vanilla relié à l'onduleur ouvre le logiciel sur l'écran propre au mod (moniteur, écran de démarrage « Live Wire OS », barre d'état avec l'heure du jeu).

![Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/livewire_monitor_without_compute.png)

*Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod.*

### Avec Computer Mod ou Laptop Mod

Avec le Computer Mod facultatif (Workshop 3725497089) ou le Laptop Mod (3798992436), le logiciel arrive sur un disque : « Disque : logiciel de gestion Live Wire » (`LiveWire.MonitorDisk`), trouvé dans le butin d'ordinateurs ([Tables de butin](Tables-de-butin)). Clic droit sur l'ordinateur avec le disque : « Installer le logiciel Live Wire ». Il apparaît alors comme application « Live Wire » sur leur bureau et s'exécute dans leur fenêtre (barre de titre, réduire, fermer, barre des tâches). Il montre l'onduleur relié à cet ordinateur, ou à défaut l'onduleur le plus proche à portée de câble.

![Bureau du Computer Mod avec l'icône Live Wire](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/computermod.png)

![Live Wire Monitor, onglet Overview](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/livewire_computermod.png)

![Onglet History : graphiques 48 h et prévision](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/conso_livewire_computermod.png)

![Onglet Equipment](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/equipement_livewire_computermod.png)

## Bourdonnement de l'onduleur

Un son propre au mod, audible seulement à une case autour d'un onduleur allumé (même étage). Chaque joueur règle son volume dans Options, Mods, Live Wire (0 = coupé, de 0 à 100). Les zombies entendent l'onduleur à 2 cases (option InverterNoiseRadius ; 0 = silencieux).

## Kit d'insonorisation

`LiveWire.SoundproofKit`, posé sur l'onduleur au tournevis (« Insonoriser l'onduleur »), retiré par « Retirer l'insonorisation » (le kit est rendu).

| Effet |
|---|
| Plus de bourdonnement, les zombies n'entendent plus l'onduleur |
| L'onduleur chauffe davantage et s'use 25 % plus vite |
| Le kit suit l'onduleur quand on le ramasse |

## Voir aussi

[Équipements optionnels](Equipements-optionnels) · [Raccordement](Raccordement) · [Options sandbox](Options-sandbox) · [Tables de butin](Tables-de-butin)
