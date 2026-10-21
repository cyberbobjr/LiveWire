# Live Wire (`batman_LiveWire`) — idées

État : idées retenues par l'utilisateur le 2026-10-18, après la version 1.1.0. **La pompe (idée 2) est implémentée en 1.2.0, non testée en jeu ; les autres idées n'ont aucun code.** Chaque idée doit encore être tranchée dans `decisions-ouvertes.md`, une question à la fois, avant tout développement.

La liste d'origine (dix fonctionnalités de la v0.1 : testeur, onduleur, batteries, sources, disjoncteur…) est réalisée ou abandonnée. Elle reste dans l'historique Git de ce fichier.

## Idées retenues

| # | Niv. | Fonctionnalité | Rôle sur le réseau | Faisabilité estimée |
|---|---|---|---|---|
| 1 | 2 | Chargeur de piles | Consommateur | Simple |
| 2 | 6 | Pompe électrique : eau courante depuis des barils | Consommateur | Moyenne à risquée |
| 3 | 7 | Clôture électrifiée | Consommateur, à la demande | Moyenne à risquée |
| 4 | — | Installations abandonnées à récupérer | Exploration, source d'équipements | Moyenne |
| 5 | 6 | Onduleurs en parallèle (et fin du double comptage) | Capacité du réseau | Moyenne |

Ordre de développement proposé : 1, puis 2, puis 3. Le chargeur réutilise presque tout l'existant. La clôture demande le plus de vérifications en multijoueur. L'idée 4 ne dépend pas des autres : elle peut venir à tout moment, idéalement après les modèles définitifs, pour que les installations trouvées aient bonne allure.

Les appareils 1 à 3 sont des **consommateurs raccordés** à l'onduleur. Ce sont de nouvelles tuiles du mod (`batman_livewire_01`), raccordées par menu avec du fil électrique, comme les autres équipements (D-3, D-19). Leur consommation s'ajoute à la demande de la maison, dans la limite de 1 500 W de l'onduleur et sous la surveillance du disjoncteur.

---

### 1. Chargeur de piles (Électricité 2)

**Principe.** Un petit appareil posé sur une table ou un mur, avec une case de rangement qu'on ouvre comme la powerbank. On y dépose des piles `Base.Battery` vides ou entamées. Tant que le réseau fournit du courant, elles se rechargent.

**Intérêt en jeu.**
- C'est la première raison d'installer du courant en début de partie, avant le frigo : lampes de poche, radios et talkies sans chercher de piles neuves.
- Il donne un usage au niveau 2 d'Électricité, aujourd'hui pauvre en recettes.

**Règles proposées (valeurs de départ, à équilibrer).**
- Environ 15 W par pile en charge, et 4 piles au plus comptées en même temps (même logique que la powerbank).
- Une pile vide se recharge en quelques heures de jeu.
- Usure : chaque cycle complet abaisse la charge maximale de la pile, qui finit par ne plus rien tenir. Il faut compter les cycles dans la ModData de la pile, car une pile vanilla n'a pas d'état.
- Aucune charge sans courant ; l'écran LCD et le logiciel affichent la ligne « Chargeur ».
- Fabrication : déchets électroniques, fil électrique, un peu de métal ou de plastique, tournevis gardé.

**Faisabilité (confirmé statiquement pour la pile).**
- `Base.Battery` est un objet `base:drainable` (`UseDelta = 0.007`, `media/scripts/generated/items/drainable.txt:673`). La charge se lit et s'écrit sur l'objet, sur le serveur, puis se synchronise (`sendItemStats` pour un objet dans un meuble, voir `multiplayer.md`).
- Le conteneur vient de la tuile, comme celui de la powerbank (D-4). La demande s'ajoute dans `LW_Demand.lua`.
- Hors zone chargée, les piles d'un conteneur ne sont pas accessibles. Il faut rattraper la charge au rechargement de la zone, sur le modèle de `LW_FridgeCatchup.lua`, d'après le journal d'alimentation de l'onduleur.

**À vérifier.**
- Les autres objets à pile vanilla, comme les lampes posées ou les talkies, se chargent-ils pile en place ? Proposition : non, seules les piles seules.
- Accepte-t-on les piles de mods tiers (par tag ou par type) ?

---

### 2. Pompe électrique : l'eau courante depuis des barils (Électricité 6)

**État : implémentée dans la version 1.2.0, non testée en jeu.** Les choix ci-dessous sont ceux retenus ; les écarts de réalisation sont notés dans ce texte (relais de 25 L, remplissage chaque minute, son, plusieurs pompes, logiciel, barils à côté de la pompe).

**Principe.** Une pompe électrique est raccordée d'un côté à l'onduleur, de l'autre à un ou plusieurs barils d'eau. Tant qu'elle a du courant, elle alimente en eau la maison : éviers, baignoires, douches et toilettes raccordés de la zone desservie tirent l'eau des barils, quel que soit l'étage. Les barils restent dehors, au sol, où la pluie les remplit.

**Exigences de l'utilisateur (2026-10-18, non négociables).**
- **Multijoueur** : la pompe fonctionne en multijoueur, y compris sur un serveur dédié.
- **Sans joueur** : les barils se remplissent par la pluie même quand aucun joueur n'est dans la zone.
- **Raccordement** : la pompe est reliée à un baril (vanilla ou Useful Barrels) **et** à l'onduleur. Sans baril ou sans onduleur, elle ne fait rien. La prise directe en rivière de la version précédente est donc **abandonnée**.

**Barils acceptés.**
- Les récupérateurs d'eau de pluie vanilla (entités `RainCollector`, 400 et 600 L).
- Les barils du mod **Useful Barrels** (Workshop 3436537035, `id=UsefulBarrelsMP`), **uniquement remplis d'eau**.
- Règle générale, sans dépendre du code de l'autre mod : un objet posé dans le monde qui porte un composant `FluidContainer` dont le contenu est uniquement `Water` ou `TaintedWater`, ou vide.
- Un baril vide reste raccordé, et la pompe l'ignore jusqu'à ce qu'il contienne de l'eau.
- **Seule l'eau est autorisée** (exigence de l'utilisateur, 2026-10-18) : eau propre ou croupie, rien d'autre. L'eau croupie n'est pas un problème : un point d'eau raccordé la rend propre (voir ci-dessous). Un baril qui contient un autre fluide (essence, alcool…), même mélangé à de l'eau, est refusé au raccordement, avec la raison affichée. S'il reçoit un autre fluide après coup, la pompe ne le touche plus tant qu'il n'a pas été vidé.

**Ce que fait le moteur (confirmé statiquement, Java 42.21.0 et Lua vanilla ; détails dans [`notes-moteur.md`](notes-moteur.md), n° 46 et 47).**
- **Plomberie** : un point d'eau raccordé à la clé anglaise tire son eau d'une source cherchée seulement à l'étage juste au-dessus (`z + 1`), dans le carré 3 × 3 au-dessus de lui. Cette source doit être un `IsoThumpable` à capacité de fluide (`IsoObject.java:2379-2441`). Un baril Useful Barrels, simple `IsoObject` auquel ce mod ajoute un `FluidContainer`, n'est donc jamais une source de plomberie vanilla.
- **Pluie hors zone chargée : déjà assurée par le jeu.** Quand une zone se décharge, tout objet dont le `FluidContainer` capte la pluie (`rainCatcher > 0`) est confié à une `MetaEntity`. Elle garde l'information « dehors », continue de recevoir la pluie et est sauvegardée. Ses composants reviennent sur l'objet au rechargement de la zone (`GameEntityManager.java:190-200`, `:270-295` ; `MetaEntity.java:42`, `:65-84` ; `FluidContainer.java:1227` ; `FluidContainerUpdateSystem.java:54`, `:71-85`).
  - Vanilla : `RainFactor = 0.4` pour le récupérateur (`media/scripts/generated/entities/outdoors/entity_raincollector.txt`).
  - Useful Barrels : 0,3, mais **seulement une fois le couvercle découpé** (`EnableRainFactor`). Un baril fermé ne capte pas la pluie, chargé ou non.
  - **Le mod n'a donc rien à simuler pour la pluie.** Il ne doit surtout pas vider ni remplacer le composant d'un baril, ce qui casserait ce mécanisme.

**Mécanisme retenu : un réservoir relais invisible au-dessus de chaque point d'eau desservi.** Validé par l'utilisateur le 2026-10-18 : le but est que des barils posés au sol alimentent la maison, et les barils invisibles créés pour cela par le mod ne le dérangent pas.
- La pompe pose sur la case `z + 1`, au-dessus de chaque point d'eau raccordé de sa zone, un **relais** : un `IsoThumpable` invisible, non bloquant, portant son propre `FluidContainer` de **25 L** sans captage de pluie. Le jeu y voit une source vanilla normale.
- Le point d'eau se raccorde ensuite par l'action vanilla (clé anglaise). Le menu « Raccorder » apparaît parce qu'une source existe au-dessus.
- Le serveur **déplace réellement** l'eau des barils vers les relais qui ne sont pas pleins. Pas de compte fictif : l'eau quitte vraiment les barils.
  - Quand : chaque minute de jeu, tant que la pompe a du courant et des barils. Aucun écouteur `OnWaterAmountChange` : le remplissage suit la minute de jeu, il ne réagit pas à chaque prise d'eau.
  - Ordre de prise : le baril le plus plein d'abord.
  - Qualité : sans importance. Le relais peut contenir de l'eau croupie : le point d'eau raccordé la donne **propre** au joueur, comme en vanilla avec un baril à l'étage (confirmé statiquement, [`notes-moteur.md`](notes-moteur.md) n° 48).
- Débit : **5 L par minute de jeu** au plus. Consommation : **250 W** pendant que la pompe pompe, rien quand tous les relais sont pleins.
- Sans courant, la pompe à l'arrêt ou hors service : plus de remplissage. On tire ce qui reste dans les relais (10 L chacun), puis l'eau s'arrête.
- La pompe ne travaille que si elle et le baril concerné sont sur des cases chargées. Hors zone chargée, personne ne tire d'eau et la pluie est gérée par le moteur : rien à rattraper.

**Création indépendante.** Le mod **LG Extended Plumbing** (Workshop 3779561845) a servi seulement à confirmer que le moteur accepte un objet invisible placé au-dessus des points d'eau. Aucun code n'en est repris. Son principe (un « miroir » qui copie la somme des barils, avec un registre comptable) n'est pas celui retenu ici (de l'eau réellement déplacée dans un tampon de 10 L). L'implémentation sera écrite à partir du Java vanilla seulement.

**Points tranchés (2026-10-18, par Claude à la demande de l'utilisateur ; à confirmer à la relecture).**

| Sujet | Choix |
|---|---|
| Nombre | **Plusieurs pompes par réseau** (le logiciel affiche le nombre de pompes en service). Chacune a ses barils ; un point d'eau à portée de deux pompes est desservi par la plus proche |
| Raccordement à l'onduleur | Menu et fil électrique, comme les autres équipements (D-3, D-19) |
| Raccordement d'un baril | Menu « Raccorder un baril » sur la pompe ou sur le baril. Baril **à côté** de la pompe : l'une de ses 8 cases voisines, même étage. Coût : **1 tuyau en métal `Base.MetalPipe`** par baril, rendu au débranchement. Jusqu'à **8 barils** par pompe |
| Points d'eau desservis | Points d'eau raccordés situés dans une pièce, dans un cercle de **15 cases** autour de la pompe (nouvelle option sandbox `PumpRange`, 5 à 30, choix de l'utilisateur du 2026-10-18) et ±3 étages (`GeneratorVerticalPowerRange`) |
| Visualisation (choix de l'utilisateur, 2026-10-18) | Option « Afficher les points d'eau alimentés » sur la pompe : cercle bleu au sol (portée) et surbrillance bleue des points d'eau desservis, des barils raccordés et de la pompe. **Voyant bleu** sur le dessus de la pompe tant qu'elle dessert au moins un point d'eau (calque de tuile 80-83) |
| Priorité vanilla | La pompe **ne pose jamais de relais** au-dessus d'un point d'eau qui a déjà une autre source (baril vanilla à l'étage, réseau d'eau encore en service, autre mod). Le vanilla et les autres mods passent d'abord, ce qui règle aussi la coexistence avec LG Extended Plumbing sans déclarer d'incompatibilité |
| Invisibilité du relais | Tuile transparente dédiée dans `batman_livewire_01`, sans propriété de collision. Objet non attaquable (`setIsThumpable(false)`), traversable, sans nom de meuble, donc pas ramassable au curseur. Marque ModData `LiveWire_relay` |
| Case au-dessus absente (maison de plain-pied sans case à l'étage) | Le serveur crée la case `z + 1` avant de poser le relais. Le cas est à valider en premier dans le prototype (voir ci-dessous) |
| Retrait | Pompe ramassée ou détruite : le serveur retire tous ses relais. Point d'eau retiré ou débranché : son relais est retiré au pas suivant. L'eau d'un relais retiré est perdue (10 L au plus) |
| Désinstallation du mod | Commande admin et debug « Retirer tous les relais d'eau », d'après le registre serveur des relais. À lancer avant de retirer le mod, et à documenter dans le README et la page Workshop |
| Écran LCD et logiciel | **Seulement deux informations** (choix de l'utilisateur, 2026-10-18) : le **nombre de pompes en service** et le **débit des pompes** (litres par heure de jeu). Rien d'autre : ni litres en réserve, ni barils, ni points d'eau. L'état d'un baril refusé se lit à son raccordement, dans son menu |
| Usure | Comme les sources : usure lente, réparation au tournevis avec déchets électroniques. Hors service à 0 % |
| Son | Bourdonnement léger de moteur pendant la marche, entendu à 4,5 cases ; les zombies l'entendent à 2 cases. Rien quand la pompe est à l'arrêt. |
| Multijoueur | Le serveur pose, remplit et retire les relais, et les transmet aux clients (`transmitAddObjectToSquare`). La prise d'eau d'un client est appliquée par le serveur (`useFluid` n'agit que sur l'autorité, `IsoObject.java:2690-2700`). Les commandes client de raccordement sont revérifiées sur le serveur (distance, fluide, objets en main) |

**Plan de repli si le relais échoue au prototype** (invisibilité, sauvegarde ou multijoueur) : la pompe remplit à la place un récupérateur vanilla que le joueur pose lui-même à l'étage, au-dessus des points d'eau. C'est de la plomberie 100 % vanilla, moins confortable mais sans objet caché.

**Prototype à faire en premier (P-pompe), avant tout le reste.**
1. Créer sur le serveur un `IsoThumpable` relais avec un `FluidContainer` ajouté par `GameEntityFactory.AddComponent`, le transmettre, puis vérifier sur un client MP qu'il voit le relais, que le menu « Raccorder » apparaît et que l'eau tirée diminue bien le relais côté serveur.
2. Vérifier sa sauvegarde et son rechargement (redémarrage du serveur, zone déchargée puis rechargée).
3. Vérifier qu'il reste invisible, non cliquable et non bloquant, y compris sur une case `z + 1` créée par script sous un toit.
4. Vérifier en jeu qu'un récupérateur vanilla et un baril Useful Barrels sans couvercle se remplissent sous la pluie pendant que la zone est déchargée.

---

### 3. Clôture électrifiée (Électricité 7)

**Principe.** Un électrificateur raccordé à l'onduleur, relié à une portion de grillage vanilla. Un zombie qui touche ou frappe la clôture reçoit une décharge : il est repoussé ou mis à terre, avec une étincelle et un claquement. Chaque décharge prélève de l'énergie dans les batteries.

**Intérêt en jeu.**
- C'est une défense de fin de partie, payée en énergie et non en munitions.
- Elle crée un arbitrage : une horde contre la clôture peut vider le stock et plonger la maison dans le noir. Les autres équipements (disjoncteur, alarme de batterie faible, générateur de secours) prennent alors tout leur sens.

**Règles proposées.**
- Consommation de veille faible, plus un coût fixe par décharge (par exemple 0,02 kWh).
- Longueur limitée par électrificateur, avec une case de grillage raccordée par fil.
- Aucun dégât mortel : le zombie est mis à terre ou repoussé. Pas de décharge sans courant ni avec le disjoncteur déclenché.
- Le joueur qui touche la clôture reçoit lui aussi une décharge. C'est une règle à trancher, qui demande au minimum une option sandbox et une règle pour le PvP.
- Le bruit des décharges attire d'autres zombies, avec un rayon court.

**Faisabilité (estimation, à vérifier).**
- Détection : sondage serveur des zombies proches des cases de clôture, borné et seulement dans les zones chargées. Le coût en performance est à mesurer.
- En multijoueur, un zombie est simulé par le client propriétaire. La cible de ses coups (`getThumpTarget`) est toujours `nil` côté serveur (`multiplayer.md`). Il faut détecter par proximité, ou faire rapporter le coup par le client propriétaire puis le revérifier.
- La mise à terre passe par la réaction de coup (`setHitReaction`), et les dégâts sont appliqués par l'autorité (`combat-and-xp.md`).
- Le grillage vanilla ne garde pas ses ModData de façon sûre selon son type d'objet. Le registre des cases électrifiées reste donc côté serveur, dans les données du réseau.

**À vérifier.**
- Quelles tuiles de grillage et de portail vanilla sont acceptées ? Le portail doit-il rester franchissable par les joueurs ?
- Le zombie touché doit-il lâcher la clôture et perdre sa cible, ou seulement tomber ?
- Faut-il un interrupteur pour couper la clôture et sortir sans risque ?

---

### 4. Installations abandonnées à récupérer (ajout de l'utilisateur)

**Principe.** De temps en temps, le joueur découvre une installation déjà en place dans le monde : des panneaux solaires sur un chalet, un onduleur dans un atelier, un banc de batteries dans un bâtiment technique. Certains composants sont récupérables tels quels, d'autres sont abîmés et à réparer avant usage.

**Intérêt en jeu.**
- Elle crée des destinations d'exploration, au-delà du butin trouvé dans les conteneurs (les équipements tout faits existent déjà dans le butin, voir le README).
- Elle récompense l'électricien : démonter proprement ou réparer demande le niveau d'Électricité de l'équipement.
- Elle peut aussi donner une base de départ : un chalet isolé déjà à moitié équipé devient un objectif de long terme.

**Règles proposées.**
- Lieux plausibles, tirés selon le type de pièce ou de bâtiment : chalets et maisons isolées (panneaux, parfois une éolienne), ateliers et garages (onduleur, powerbank), bâtiments techniques et fermes (banc de batteries, roue à aubes au bord d'une rivière).
- Rareté réglable par option sandbox (dont 0 = jamais).
- État au hasard : équipements usés (état 10 à 70 %), parfois hors service (« à réparer »), batteries presque vides et usées, une partie manquante (le banc a 1 ou 2 batteries sur 4, pas de fil).
- Installation **non raccordée** et éteinte : le joueur la démonte avec le curseur de meubles vanilla (tournevis et niveau exigés par la tuile), ou la remet en service sur place en la raccordant.
- Une seule tentative par bâtiment, même si la zone est rechargée.

**Faisabilité (estimation, à vérifier).**
- Les équipements sont déjà de vraies tuiles du mod, et ceux posés hors du crochet de pose sont déjà enregistrés au chargement du chunk (`LW_ChunkSync.lua`). Une tuile posée par le monde devient donc un équipement normal.
- La pose passe par la création des cases (`LoadGridsquare`, voir `world-placement.md`) : avant les histoires de bâtiment, avec une marque pour ne jamais poser deux fois, idéalement dans un registre global du serveur par bâtiment (`BuildingDef`, identifiant stable par `getIDString`).
- Les panneaux sur un toit plat exigent de trouver une case extérieure à ciel ouvert sur le toit. À défaut, on les pose au sol à côté du bâtiment.
- État et usure : écrits dans les données de l'équipement à sa création, comme pour un équipement ramassé puis reposé.

**À vérifier.**
- Comment reconnaître depuis Lua un « chalet » ou un « bâtiment technique » ? Par les types de pièces de la carte vanilla (relevé à faire dans les tuiles) ou par la position, comme une maison isolée loin d'une ville.
- Faut-il ajouter des indices pour guider le joueur (carte-cachette, note, émission radio) ou garder la découverte au hasard ?
- En multijoueur : qui « possède » une installation trouvée ? Proposition : personne, les règles de safehouse vanilla s'appliquent (D-7).

---

### 5. Onduleurs en parallèle (Électricité 6)

**Origine.** Question d'un joueur sur la page Workshop (2026-10-18) : « peut-on monter l'onduleur au-delà de 1 500 W ? ma base a 4 congélateurs ». Un autre joueur a répondu que « modifier un onduleur n'est pas réaliste ; plusieurs onduleurs serait plus réaliste ». Choix de l'utilisateur le 2026-10-18 : **onduleurs en parallèle**, la pratique réelle des installations autonomes, plutôt qu'un onduleur plus puissant ou des circuits par pièce.

**État : implémentée pour la 1.3.0, non testée en jeu.**

**Principe (comme dans la réalité).** Des onduleurs identiques sont couplés par un câble de synchronisation : un **maître** et jusqu'à **3 esclaves**. La maison voit un seul réseau, un seul parc de batteries, une seule zone alimentée ; la puissance disponible est la somme des onduleurs en service.

**Règles.**

| Sujet | Choix |
|---|---|
| Couplage | Clic droit sur un onduleur > « Coupler à un onduleur » > onduleur maître à portée de câble (`LinkRange`, 1 étage d'écart au plus). L'onduleur cliqué devient esclave. Coût : le fil électrique de la distance (comme un raccordement) et **1 kit de couplage** (`LiveWire.CouplingKit`, nouvelle recette, Électricité 6) |
| Conditions | L'esclave ne doit avoir aucun équipement raccordé (sources, powerbank, options, générateur, ordinateur, pompe) ni esclave à lui ; le maître ne doit pas être lui-même esclave ; 3 esclaves au plus par maître (4 onduleurs) |
| Capacité | 1 500 W par onduleur **en service** (allumé et en état) : jusqu'à 6 000 W. Le disjoncteur et la mise en sécurité comparent la demande à cette somme |
| Zone alimentée | Une seule : celle du maître. L'esclave n'a ni ancre, ni zone, ni sources, ni batteries à lui |
| Consommation à vide | 20 W par onduleur allumé |
| Usure | Chaque onduleur en service s'use comme aujourd'hui ; la charge lourde (plus de 80 % de la capacité totale) double l'usure de tous |
| Pannes | Un esclave éteint ou cassé compte pour 0 W. Si la demande dépasse alors ce qui reste, le réseau disjoncte (disjoncteur ou maître) |
| Marche et arrêt | Chaque esclave a son interrupteur (Allumer / Éteindre). La remise en marche après disjonction se fait sur le maître ou sur le disjoncteur, comme aujourd'hui |
| Découplage | « Découpler » sur l'esclave : il redevient un onduleur indépendant avec son propre réseau (vide), le kit de couplage est rendu, pas le fil |
| Maître ramassé ou détruit | Ses esclaves redeviennent indépendants, chacun avec son réseau vide |
| Affichage | Écran LCD (page État) et logiciel (carte de l'onduleur) : « Onduleurs couplés : n en service / total » et la capacité totale. Un esclave ouvre l'écran et le logiciel du maître |
| Raccordement d'un équipement | Refusé sur un esclave (« Raccordez-le au maître ») |

**Correctif lié : double comptage.** Aujourd'hui, deux onduleurs **indépendants** dont les zones se recouvrent comptent chacun tous les appareils de leur zone (`LW_Demand.lua:179-192`). Désormais, un appareil n'est compté que par l'onduleur allumé le plus proche qui le couvre (égalité : le plus petit identifiant). Si cet onduleur s'arrête, l'appareil passe au suivant au pas de calcul suivant.

**Limites.** Le moteur alimente une zone, pas un circuit : des circuits séparés par pièce restent hors de portée (voir la discussion du 2026-10-18).

---

## Idées écartées (2026-10-18)

Proposées puis refusées par l'utilisateur. Ne pas les reproposer sans nouvelle demande.

- **Capteurs de mouvement et projecteurs automatiques** : capteurs vanilla raccordés qui allument des lumières et déclenchent l'alarme.
- **Dynamo à pédales** : source manuelle de 80 W qui dépend de l'endurance.
- **Voiture raccordée** : batterie de stockage, alternateur source et recharge depuis le réseau.
- **Ligne aérienne et poteau relais** : zone alimentée secondaire dans un deuxième bâtiment.
- **Pannes à diagnostiquer avec le testeur** : défauts aléatoires à localiser puis réparer.
- **Alerte radio vers les talkies** : messages d'état de l'onduleur sur une fréquence choisie.
- **Priorités de charge réglables** : classement des appareils à la place du délestage fixe.

Déjà retirées lors des décisions de la v0.1 : parafoudre, programmateur horaire, régulateur solaire, onduleur renforcé.

## Transversal

- Le serveur fait autorité, comme pour le reste du mod : charge des piles, eau pompée et décharges de la clôture sont décidées sur le serveur, et l'expérience y est donnée (`addXp` est sans effet sur un client MP).
- Chaque appareil apparaît dans l'écran LCD (page Maison) et dans le logiciel de gestion (onglets Maison et Équipements).
- Les modèles et tuiles sont d'abord des formes simples marquées `placeholder`, comme pour la v0.1.
- Le socle n'a pas encore été testé en multijoueur. Ce test passe avant ces ajouts, qui alourdissent tous la logique serveur.
