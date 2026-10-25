> English version: [Inverter screen and software](../en/05-inverter-screen-and-software.md)

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

![Écran de l'onduleur dans la maison](../../images/screenshots/shot2.png)

![Page 1 : production / charge](../../images/screenshots/onduleur.png)

## Logiciel « Live Wire Monitor »

| Onglet | Contenu |
|---|---|
| Overview | Production et consommation en grands chiffres, barres à la même échelle, jauge de stockage et autonomie, fiche de l'onduleur (voyant, état, On/Off, Reset), alertes |
| Batteries | État des batteries |
| Sources | Les sources |
| House | La maison |
| History | Graphiques sur 48 h (production, consommation, stock des batteries) et prévision « les batteries tiendront jusqu'au lever du jour » ; exige un ordinateur de gestion relié |
| Equipment | Disjoncteur, alarme, générateur de secours, ordinateur |
| Consommateurs | Consommation mesurée des appareils, 200 entrées au maximum |
| Prévisions | Production estimée sur trois jours d'après la météo ; ordinateur de gestion alimenté requis |
| Événements | Les 30 derniers événements horodatés du réseau |

### Sans Computer Mod

Un ordinateur de bureau vanilla relié à l'onduleur ouvre le logiciel sur l'écran propre au mod (moniteur, écran de démarrage « Live Wire OS », barre d'état avec l'heure du jeu).

![Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod](../../images/screenshots/livewire_monitor_without_compute.png)

*Logiciel de gestion sur un ordinateur vanilla, sans Computer Mod ni Laptop Mod.*

### Avec Computer Mod ou Laptop Mod

Avec le Computer Mod facultatif (Workshop 3725497089) ou le Laptop Mod (3798992436), le logiciel arrive sur un disque : « Disque : logiciel de gestion Live Wire » (`LiveWire.MonitorDisk`), trouvé dans le butin d'ordinateurs ([Tables de butin](09-tables-de-butin.md)). Clic droit sur l'ordinateur avec le disque : « Installer le logiciel Live Wire ». Il apparaît alors comme application « Live Wire » sur leur bureau et s'exécute dans leur fenêtre (barre de titre, réduire, fermer, barre des tâches). Il montre l'onduleur relié à cet ordinateur, ou à défaut l'onduleur le plus proche à portée de câble.

![Bureau du Computer Mod avec l'icône Live Wire](../../images/screenshots/computermod.png)

![Live Wire Monitor, onglet Overview](../../images/screenshots/livewire_computermod.png)

![Onglet History : graphiques 48 h et prévision](../../images/screenshots/conso_livewire_computermod.png)

![Onglet Equipment](../../images/screenshots/equipement_livewire_computermod.png)

## Bourdonnement de l'onduleur

Un son propre au mod, audible seulement à une case autour d'un onduleur allumé (même étage). Chaque joueur règle son volume dans Options, Mods, Live Wire (0 = coupé, de 0 à 100). Les zombies entendent l'onduleur à 2 cases (option InverterNoiseRadius ; 0 = silencieux).

## Kit d'insonorisation

`LiveWire.SoundproofKit`, posé sur l'onduleur au tournevis (« Insonoriser l'onduleur »), retiré par « Retirer l'insonorisation » (le kit est rendu).

| Effet |
|---|
| Plus de bourdonnement, les zombies n'entendent plus l'onduleur |
| L'onduleur chauffe davantage et s'use 25 % plus vite |
| Mousse acoustique grise sur le dessus, les côtés et l'arrière ; « Insonorisé » à l'inspection et sur la page État de l'écran |
| Le kit suit l'onduleur quand on le ramasse |

## Consommateurs, câblage, événements et prévisions

Le nom du réseau apparaît aussi sur le LCD, à l'inspection et dans les alarmes.
Les vues de réseau montrent les raccordements et les consommateurs avec leurs watts.
Les liaisons entre étages sont en pointillés ; les consommateurs sont teintés sur
leur sprite réel. Le logiciel liste au maximum 200 consommateurs
par instantané, avec leur service réel et leur demande théorique.

Le journal conserve 30 événements horodatés. La prévision utilise trois jours de
météo officielle et les facteurs réels de production : orientation, saleté, neige,
état et frein. Elle projette la demande moyenne récente et la réserve accessible.
Ce sont des estimations : météo moyenne, entretien et capacité supposés constants ;
les futures pannes et la production future d'un secours ne sont pas prévues.


## Clic direct et LCD de powerbank

Un clic gauche sur l'onduleur ouvre son LCD ; sur le disjoncteur, il ouvre le
tableau électrique. Approchez-vous, sans viser ni utiliser un curseur de construction.

Un clic sur une **powerbank** ouvre son propre LCD : charge utile, kWh disponibles,
capacité utile, réserve liée au froid, places et batteries en trop. Les boutons
précédent/suivant affichent la charge et l'état de chaque batterie. Ce LCD fonctionne
même sans raccordement. L'inventaire vanilla sert toujours à déplacer les batteries.
Le bouton **Raccordements** ouvre la fenêtre commune.

**Afficher les consommateurs** teinte directement les appareils, y compris les
lumières : vert sous 50 W, orange jusqu'à 300 W, rouge au-dessus ; bleu à l'arrêt
ou non alimenté, gris pour un autre réseau. Masquer retire ces teintes. Les watts
exacts restent consultables dans la liste du logiciel.


![Live Wire 1.6.0 — LCDs and electrical panel](../../images/screenshots/shot7.png)

## Voir aussi

[Équipements optionnels](06-equipements-optionnels.md) · [Raccordement](03-raccordement.md) · [Options sandbox](11-options-sandbox.md) · [Tables de butin](09-tables-de-butin.md)
