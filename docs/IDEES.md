# Live Wire (`batman_LiveWire`) — idées

État : idées seulement, aucun code. Rien n'est prototypé ni testé en jeu.

## Constat

En Build 42.21 vanilla, la compétence Électricité ne sert qu'à :

- démarrer un véhicule sans clé (`ISHotwireVehicle.lua`) ;
- réparer un générateur (`ISFixGenerator.lua`) ;
- convertir une lampe sur pile (`ISLightActions.lua`) ;
- démonter de l'électronique, quasi seule source d'expérience ;
- une vingtaine de recettes (radios artisanales, minuteurs, capteurs de bombe, lampes de fortune).

Une fois le générateur branché, la compétence ne sert presque plus.

## Principe

L'électricien transforme le courant en avantage de survie : une base plus silencieuse, plus sûre et plus autonome. Chaque palier débloque quelque chose d'utile, et chaque fonctionnalité donne de l'expérience pour que la compétence ne se monte plus uniquement en démontant des radios.

## Les 10 fonctionnalités

| # | Niv. | Fonctionnalité | Intérêt en jeu |
|---|---|---|---|
| 1 | 1 | **Testeur / diagnostic** : multimètre fabriqué ; indique si une case est alimentée, la consommation des appareils branchés et l'autonomie restante du générateur. | Rend lisible un système aujourd'hui opaque ; porte d'entrée du mod. |
| 2 | 2 | **Chargeur de piles** : recharger les piles (lampes, radios) sur une prise alimentée, avec usure à chaque cycle. | Ressource renouvelable dès le début de partie. |
| 3 | 3 | **Désarmer les alarmes** : couper l'alarme d'une maison (au boîtier, avant d'entrer) ou d'un véhicule avant de le démarrer ; un échec la déclenche. | Les alarmes ruinent souvent une expédition : la fonctionnalité la plus demandée. |
| 4 | 3 | **Capteurs et alarme de base** : reprendre les capteurs de mouvement vanilla et les relier à une sonnette, une lumière ou une sirène dans la base. | Alerte la nuit et pendant le sommeil ; recycle des objets réservés aux bombes. |
| 5 | 4 | **Réparation d'appareils** : frigos, congélateurs, cuisinières et radios trouvés peuvent être en panne ; l'électricien les répare. | Donne une valeur au butin électroménager et un rôle d'électricien dans un groupe. |
| 6 | 5 | **Banc de batteries et onduleur** : stocker l'énergie dans des batteries de voiture, chargées par le générateur le jour, puis alimenter la base la nuit sans bruit. | Le générateur attire les zombies : nuit silencieuse. |
| 7 | 6 | **Pompe électrique** : alimenter une pompe qui remplit les collecteurs et la plomberie de la base depuis un puits ou une citerne. | Lien avec la plomberie B42, compense la coupure d'eau. |
| 8 | 7 | **Clôture électrifiée** : un grillage alimenté étourdit et repousse les zombies ; forte consommation, risque de griller en surcharge. | Défense de fin de partie, arbitrage avec le reste de la base. |
| 9 | 8 | **Sources alternatives** : dynamo à vélo (fatigue contre courant), petite éolienne, panneaux solaires récupérés sur les toits. | Autonomie sans carburant, objectif de long terme. |
| 10 | 9-10 | **Raccorder un bâtiment** : brancher générateur ou banc de batteries sur le tableau électrique pour alimenter tout le bâtiment, au-delà du rayon du générateur. | Récompense du métier : une vraie maison alimentée. |

## Faisabilité (estimation, à vérifier)

- **Simples** (Lua, scripts, actions chronométrées classiques) : 1, 2, 4, 5.
- **Moyennes** :
  - 3 : dépend de l'accès Lua à l'état d'alarme du bâtiment (à vérifier dans le Java 42.21) ;
  - 6 et 7 : simulation de stock et de consommation dans une ModData persistante, autorité serveur en multijoueur ;
  - 8 : sondage des zombies proches des clôtures, coût en performances à surveiller.
- **Risquées** :
  - 9 : modèles 3D et tuiles ; coexistence avec un éventuel mod solaire installé ;
  - **10** : le moteur juge l'alimentation d'une case d'après les générateurs à portée (`haveElectricity`) et on ne peut pas rétablir le réseau d'un seul quartier (voir `.claude/pz-knowledge/power-and-lights.md`). Il faudrait sans doute des générateurs relais invisibles : prototyper avant de s'engager, ou abandonner.
- **Transversal** : en multijoueur, état décidé par le serveur (stocks, alarmes, clôtures) et expérience donnée sur l'autorité (`addXp` est inopérant sur un client MP).

## Décisions ouvertes

- Orientation de la première version : utilitaire de survie (1 à 5), base autonome (6, 7, 9, 10) ou défense (3, 4, 8).
- Coexistence avec les mods d'énergie existants (solaire notamment) : à inventorier avant la fonctionnalité 9.
