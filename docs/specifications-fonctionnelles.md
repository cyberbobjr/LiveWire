# Live Wire — documentation fonctionnelle

État au 2026-10-21 : **implémenté jusqu'à la version 1.3.1** du mod (`Contents/mods/batman_LiveWire/42.21`). Ce document est né en phase de conception (2026-10-17) : ses sections 1 à 9 décrivent la v0.1 et ses justifications ; la section 10 résume les fonctionnalités ajoutées ensuite. Les chiffres sont des **valeurs de départ** destinées à l'équilibrage. Les contrats techniques à jour (objets, commandes, ModData, options) sont dans [`specifications-techniques.md`](specifications-techniques.md) ; le guide du joueur est le [wiki](wiki/fr/Home.md).

- **Sources des faits du moteur** : le dépôt de référence `pz-source-42.21` (chemins relatifs à sa racine) et [`annexes/recherches/notes-moteur.md`](annexes/recherches/notes-moteur.md) (« NM-n » = note n).
- **Choix de l'utilisateur** : toutes les décisions de [`decisions.md`](decisions.md) (« D-n ») ont été **validées le 2026-10-17**. Ce document décrit ce qui est implémenté en v0.1 (non testé en jeu).

**Exigences de l'utilisateur** (2026-10-17), non négociables :
1. L'onduleur peut être posé **à l'intérieur** d'une maison.
2. L'installation fonctionne **même quand aucun joueur n'est dans la zone**.
3. L'onduleur peut **s'user** et faire un **très léger bruit**.
4. Trois rôles distincts : les **sources** fournissent la puissance, les **batteries** la stockent, l'**onduleur** la convertit.

---

## Identifiants des fonctionnalités

Identifiants stables, à citer dans les autres documents, le code et les tickets. « § F-n » (notation de [`architecture.md`](architecture.md)) désigne la section n de ce document.

| ID | Fonctionnalité | Section |
|---|---|---|
| F01 | Objets d'inventaire et recettes (catégorie Électricité) | § 2.1, 2.2, 2.5 |
| F02 | Appareils posés : panneau, éolienne, roue à aubes, onduleur, powerbank | § 2.3 |
| F03 | Équipements optionnels : disjoncteur, alarme de batterie faible, kit d'insonorisation, générateur de secours, ordinateur de gestion | § 2.4 |
| F04 | Production solaire | § 3.1, 3.2 |
| F05 | Production éolienne | § 3.3 |
| F06 | Production hydraulique (roue à aubes, rivières seulement) | § 3.4 |
| F07 | Compétence Électricité : paliers, expérience, effets à l'installation | § 4.1 à 4.3 |
| F08 | Usure, pannes, inspection, réparation, révision | § 4.4 |
| F09 | Batteries rangées dans une powerbank : stockage | § 5.1 |
| F10 | Onduleur : conversion, distribution, disjonction | § 5.2 |
| F11 | Consommation des appareils mesurée par le jeu | § 5.3 |
| F12 | Fonctionnement sans joueur et frigos pendant une absence | § 5.4 |
| F13 | Menus contextuels et raccordement au fil électrique | § 6.1 |
| F14 | Écran de l'onduleur et logiciel de gestion | § 6.2 |
| F15 | Testeur de tension | § 6.4 |
| F16 | Outils de debug et d'administration | § 6.5 |
| F17 | Options sandbox | § 7 |
| F18 | Multijoueur (autorité serveur, refuges) | § 8.1 |
| F19 | Coexistence avec les générateurs vanilla | § 8.2 |
| F20 | Pompe à eau (1.2.0) | § 10.1 |
| F21 | Onduleurs en parallèle (1.3.0) | § 10.2 |
| F22 | Logiciel dans le Computer Mod (facultatif) | § 10.3 |
| F23 | Modèles 3D pour Project Viewpoint (mod facultatif `batman_LiveWireViewpoint`) | § 10.4 |

---

## 1. Vision

### 1.1 L'idée en une phrase

**Le courant devient un métier.** Le générateur vanilla reste bruyant, gourmand et visible. L'électricien de Live Wire construit à côté une installation silencieuse et durable, en trois étages :

```
 SOURCES                        BATTERIES                ONDULEUR                   BASE
 panneaux solaires  ─┐
 éolienne           ─┼─►  courant continu  ◄──►  stockage   ──►  convertit  ──►  courant de la maison
 roue à aubes       ─┘    (produit)              (stocke)        (et répartit)   (frigo, lumières...)
```

| Rôle | Ce qu'il fait | Ce qu'il ne fait pas |
|---|---|---|
| **Source** (panneau, éolienne, roue à aubes) | Produit une puissance qui dépend du soleil, du vent ou de l'eau | Ne stocke rien et n'alimente pas directement la maison |
| **Batterie** (batterie de voiture, batterie stationnaire) | Stocke l'énergie ; se charge et se décharge ; s'use à chaque cycle | Ne produit rien ; ne fait pas fonctionner les appareils seule |
| **Onduleur** | Convertit le courant des sources pour charger les batteries, et celui des batteries pour alimenter les appareils de la base. Il a une **puissance maximale** et un **rendement** ; il s'use et bourdonne légèrement | Ne stocke rien : sans batterie, il ne transmet que la production du moment |

**Trois règles de conception :**
1. **Le jeu reste juge de l'alimentation.** Une case est alimentée parce que le moteur la voit alimentée, comme près d'un générateur. Réfrigérateurs, lumières, cuisinières et radios fonctionnent donc exactement comme en vanilla. Le comment technique est dans `architecture.md`, § 1.
2. **L'énergie se mérite et se lit.** Chaque watt a une origine (heure, nuages, vent, rivière) et une destination (appareils allumés). Le testeur et le tableau de bord rendent tout cela lisible.
3. **La compétence Électricité compte à chaque étape** : fabriquer, installer, raccorder, entretenir, réparer, diagnostiquer.

### 1.2 La boucle de jeu, du premier jour à la base autonome

| Phase | Situation | Ce que fait le joueur avec Live Wire |
|---|---|---|
| **1. Avant la coupure** (réseau public actif) | Le courant est partout. | Il récupère des batteries de voiture, du fil électrique, de l'électronique, des calculatrices et des livres d'électricité. Il fabrique un **testeur de tension** (niv. 1) et apprend à lire une installation. |
| **2. La coupure** | Le générateur vanilla devient la seule source et attire les zombies. | Il installe un **onduleur** dans la maison (niv. 5) et une **powerbank** à côté (niv. 2), raccordée à l'onduleur, dans laquelle il range ses **batteries de voiture**. La nuit, la maison vit sur les batteries, sans bruit. *En v0.1, ces batteries se chargent par les sources ; la charge depuis un générateur vanilla arrive en v0.2 (§ 9).* |
| **3. Premières sources** | Le carburant se raréfie. | Il pose des **panneaux photovoltaïques** sur un toit plat ou dans le jardin (niv. 3) et une **petite éolienne** (niv. 6). Il apprend que la production dépend de l'heure, des nuages, de la neige et du vent. |
| **4. Base autonome** | Plus de carburant. | Il ajoute une **roue à aubes** sur une rive de rivière (niv. 7), qui produit jour et nuit. Il dimensionne l'installation : assez de batteries pour la nuit, un onduleur assez puissant. Il entretient et remplace ce qui s'use. **Quand il part en expédition, la base continue de tourner** : le réfrigérateur reste froid. |
| **5. Fin de partie** (versions suivantes) | La base est stable. | Pompe électrique, capteurs et alarme, clôture électrifiée, relais pour un grand bâtiment. |

**Arbitrages proposés au joueur :**
- silence (onduleur et batteries) contre puissance (générateur) ;
- dimensionnement, car une nuit d'hiver dure environ 14 h (§ 3.2) ;
- entretien de tout ce qui s'use ;
- surcharge : un onduleur trop petit disjoncte.

---

## 2. Objets, recettes et appareils posés

### 2.1 Principes

- **Module de script** : `LiveWire`. Tous les noms ci-dessous sont propres au mod.
- **Placeholders.** Aucun modèle ni tuile définitif n'existe :
  - chaque objet d'inventaire utilise une **icône ou un modèle vanilla existant**, ou une **forme géométrique simple** ;
  - chaque appareil posé est une **tuile du mod** (`batman_livewire_01`, tiledef 7174) aux formes géométriques simples, rendue avec Blender (`source/tiles/build_livewire_tiles.py`) ;
  - tous sont marqués `placeholder` dans les scripts et dans ce document.
- **Objets vanilla réutilisés tels quels** : batteries de voiture `Base.CarBattery1/2/3`, `Base.ElectricWire`, `Base.ElectronicsScrap`, `Base.Calculator`, `Base.SmallSheetMetal`, `Base.SheetMetal`, `Base.Screws`, `Base.Pipe`, `Base.MetalBar`, `Base.Plank`, `Base.Nails`, `Base.Amplifier`, `Base.Speaker`, `Base.LightBulb`, `Base.Battery`, `Base.Glue`, `Base.Aluminum`, `Base.ScrapMetal`. Tous existent en 42.21 (`media/scripts/generated/items/normal.txt`, `drainable.txt`, `weapon.txt`).
- **Outils, par tag vanilla** : tournevis `base:screwdriver`, pinces `base:pliers`, marteau `base:hammer`. Syntaxe `craftRecipe` 42.21 : `item 1 tags[base:screwdriver] mode:keep` (`media/scripts/generated/recipes/recipes_traps.txt:99-121`).
- **Équipements : des meubles posables.** La recette donne un meuble `Base.Mov_LiveWire_*` (nom, poids et icône tirés de la tuile). On le pose, le tourne et le ramasse avec le **curseur de meubles vanilla** : fantôme de la tuile, quatre orientations (deux pour les objets muraux), tournevis et niveau d'Électricité exigés par la tuile (`PickUpTool = Electrician`, `PickUpLevel`). Ramassé, l'équipement garde son état.
- **Batteries : rangées dans une powerbank.** Une batterie ne se pose jamais au sol : on la range dans une powerbank, qu'on ouvre comme une caisse (§ 5.1). Elle reste un vrai objet, avec son icône et sa charge vanilla.

### 2.2 Objets d'inventaire

| Objet (`LiveWire.…`) | Nom FR (EN) | Type | Poids | Placeholder | Rôle |
|---|---|---|---|---|---|
| `VoltageTester` | Testeur de tension (Voltage Tester) | normal | 0,3 | icône et modèle de `Base.Remote`, **placeholder** | Diagnostic (§ 6.4) |
| `SolarCell` | Cellule photovoltaïque (Solar Cell) | normal | 0,05 | icône de `Base.ElectronicsScrap`, **placeholder** | Composant des panneaux |
| `DeepCycleBattery` | Batterie stationnaire (Deep-Cycle Battery) | drainable | 9 | modèle `CarBattery` vanilla (`WorldStaticModel = CarBattery`, `drainable.txt:2335-2351`), **placeholder** | Batterie longue durée |

Meubles posables (module `Base`, comme les `Mov_*` vanilla) : `Mov_LiveWire_SolarPanel`, `Mov_LiveWire_WindTurbine`, `Mov_LiveWire_WaterWheel`, `Mov_LiveWire_Inverter`, `Mov_LiveWire_PowerBank`, `Mov_LiveWire_Breaker`, `Mov_LiveWire_BatteryAlarm`. Noms dans `Moveables.json` (`Live_Wire_<CustomName>`).

**Aucun objet tagué `Generator`** n'est créé par le mod : poser au sol un tel objet créerait un générateur vanilla (NM-6).

### 2.3 Appareils posés

Un appareil posé porte une **marque Live Wire** (son identifiant) et est inscrit dans le registre du serveur.

| Rôle | Appareil | Aspect (**placeholder**) | Contraintes de pose |
|---|---|---|---|
| Source | Panneau photovoltaïque | tuiles 0-3 (panneau incliné sur un châssis) | Dehors, à ciel ouvert (`sq:isOutside()`) ; toit plat accepté ; niv. 3 |
| Source | Éolienne | tuiles 4-7 (mât, nacelle, trois pales) | Dehors (`isOutside()`) ; bonus en hauteur (§ 3.3) ; niv. 6 |
| Source | Roue à aubes | tuiles 8-11 (roue en bois, génératrice) | Dehors, niveau 0, case voisine d'une eau de rivière (§ 3.4) ; niv. 7 |
| **Onduleur** | Onduleur (un seul modèle, D-17) | tuiles 12-15 (armoire grise, écran, voyants) | **N'importe quelle case de sol, intérieure comprise.** Aucun conteneur, pas de toxicité : ce n'est pas un générateur du moteur (`architecture.md`, § 1) ; niv. 5 |
| **Stockage** | Powerbank (4 batteries de voiture ou stationnaires) | tuiles 16-19 (bac de batteries) ; conteneur de la tuile `livewirepowerbank`, capacité 50 | N'importe quelle case de sol, intérieur compris ; niv. 2 |
| Équipement | Disjoncteur | tuiles 20-21, objet mural (mur nord, mur ouest) | Sur un mur ; niv. 3 |
| Équipement | Alarme de batterie faible | tuiles 22-23, objet mural | Sur un mur ; niv. 2 |

Les règles « dehors » et « berge de rivière » s'ajoutent aux contrôles vanilla du curseur ; une case refusée est signalée en rouge dans le panneau d'information du curseur.

**Câblage (validé : D-3).**
- Chaque source, chaque powerbank et chaque équipement se raccorde à **un** onduleur par l'action « Raccorder ».
- Conditions : au plus `LinkRange` cases (12 par défaut) et un écart d'au plus 1 étage.
- Coût : `Base.ElectricWire`, à raison de 1 fil pour 4 cases, arrondi au-dessus, au moins 1.
- Pas de câble visible en v0.1.

**Réseau** = un onduleur, plus les sources, les powerbanks et les équipements raccordés à lui.

**Plusieurs sources par onduleur, rayon centré sur l'onduleur** (exigence de l'utilisateur, 2026-10-17) :
- **Sans limite de nombre.** On raccorde autant de sources que l'on veut à un même onduleur (panneaux, éoliennes, roues à aubes), et leurs productions s'additionnent.
- **Les sources se placent librement** dans la portée de câble : toit, jardin, à 12 cases au plus de l'onduleur.
- **Le rayon d'alimentation de la maison part de l'onduleur**, jamais d'une source. Le point d'alimentation est posé sur la case de l'onduleur (`architecture.md`, § 1.4).

### 2.4 Équipements optionnels

Le système de base reste **source → onduleur → maison**, avec une **batterie facultative**. Les sources ont toutes un micro-onduleur intégré (§ 3.1), qui n'est pas un équipement à part. Les équipements ci-dessous sont **tous optionnels** : aucun n'est nécessaire pour qu'une installation fonctionne. Chacun ajoute un seul avantage, facile à comprendre. Leur liste et leur version ont été validées (D-11).

| Équipement | Problème réglé | Effet en jeu | Niv. | Version proposée | Faisabilité |
|---|---|---|---|---|---|
| **Disjoncteur** (sécurité) | Une surcharge use l'onduleur (−3 d'état à chaque disjonction) | **Se fixe sur un mur, comme un vrai disjoncteur** (objet mural vanilla : mur nord ou ouest de sa case). Raccordé à un onduleur, il coupe **avant** l'onduleur : plus de dégât en cas de surcharge. Le réarmement reste manuel | 3 | 0.1 | Simple : règle du pas de simulation ; pose murale par le curseur vanilla (`MoveType = WallObject`) |
| **Ordinateur de gestion** | Le tableau de bord ne montre que l'instant présent | **Un vrai ordinateur de bureau du jeu** (`Mov_DesktopComputer`), trouvé dans une maison, raccordé à l'onduleur. Tant qu'il est alimenté, il ajoute au tableau de bord un **historique de 48 h** (un point par heure : production, consommation, stock) et une **prévision** : « les batteries tiendront jusqu'à l'aube » ou non. Avec le **délestage** (niv. 7 de la personne qui l'a raccordé), il éteint une fois les lumières quand le stock passe sous 15 % (réarmé au-dessus de 30 %), pour garder le réfrigérateur. On peut aussi ouvrir le tableau de bord depuis l'ordinateur | 6 | 0.1 | Moyenne : l'historique est un tableau circulaire ; extinction des lumières sur le serveur par `IsoLightSwitch:setActive(false)`, qui se synchronise (`knowledge/power-and-lights.md:194-197`) |
| **Alarme de batterie faible** | On découvre la panne trop tard | Bip (son vanilla `TelevisionTestBeep`, coupé après 3 s) et message aux joueurs à moins de 30 cases quand le stock passe sous 20 %. Rappel toutes les 2 h de jeu tant que le stock reste bas ; réarmée au-dessus de 25 % | 2 | 0.1 | Simple : `notify` du serveur et son local du client |
| **Générateur de secours** | Plusieurs jours sans soleil ni vent vident les batteries | **Un générateur vanilla**, raccordé à l'onduleur (niv. 3). Le mod le **démarre** quand les batteries passent sous 20 % et l'**arrête** à 90 % (options `BackupStartPercent`, `BackupStopPercent`). En marche, il fournit 1 200 W au réseau et brûle 1 L d'essence pour 3 kWh, **en plus** de sa consommation vanilla pour les appareils qu'il alimente lui-même. Il reste un générateur vanilla : il faut le brancher (option vanilla), le remplir, il fait du bruit, s'use, et **il est toxique à l'intérieur**. Vide, débranché ou en panne : il ne démarre pas, et le tableau de bord le dit. Sans batterie, il ne démarre jamais | 3 | 0.1 | Moyenne : `IsoGenerator.setActivated`, `setFuel` (NM-32) |

**Règles communes :**
- un équipement optionnel se pose et se raccorde à un onduleur comme une source (même action, même fil) ;
- il s'use peu (−1 par 15 jours de jeu) ;
- il n'apparaît sur le tableau de bord que s'il est présent ;
- **au plus un exemplaire de chaque type par réseau** : un second n'apporte rien, et l'action « Raccorder » le refuse avec un message.

**Aspect** : l'ordinateur de gestion et le générateur de secours sont de **vrais objets vanilla**, non modifiés ; le raccordement est seulement noté dans leur ModData (`LiveWireComputer`, `LiveWireBackup`). L'alarme est une tuile murale du mod (boîtier blanc, gyrophare rouge), **placeholder**.

**Aspect du disjoncteur (placeholder)** : tuile murale du mod (coffret gris, rangée d'interrupteurs). On ne peut pas détruire à la masse un mur qui le porte.

**Recettes** : disjoncteur au § 2.5. Alarme de batterie faible : « Fabriquer une alarme de batterie faible » (niv. 2 : tournevis gardé, 1 déchet électronique, 1 fil électrique, 1 amplificateur). L'ordinateur et le générateur ne se fabriquent pas : on les trouve dans le monde.

### 2.5 Recettes

Les noms de recette sont les clés de `Recipes.json` (`java/zombie/core/Translator.java:561-569`). Toutes sont en `category = Electrical`, avec l'action `MakingElectrical`, comme `MakeTimer` (`recipes_traps.txt:99-121`).

| Recette | Niv. | Entrées (outils conservés entre crochets) | Sortie | XP |
|---|---|---|---|---|
| `LWMakeVoltageTester` | 1 | 1 `ElectronicsScrap`, 1 `ElectricWire`, 1 `LightBulb`, 1 `Base.Battery` ; [tournevis] | `VoltageTester` | 5 |
| `LWSalvageSolarCell` (« Démonter une calculatrice ») | — | 1 `Base.Calculator` ; [tournevis] | 1 `ElectronicsScrap` + 1 `SolarCell` | 3 |
| `LWMakeSolarPanelKit` | 3 | 10 `SolarCell`, 1 `SheetMetal`, 2 `ElectricWire`, 4 `Screws`, 1 `Glue` ; [tournevis, pinces] | `Mov_LiveWire_SolarPanel` | 15 |
| `LWMakeSolarCellFromScrap` | 8 | 5 `ElectronicsScrap`, 1 `Aluminum` ; [pinces] | 1 `SolarCell` | 4 |
| `LWMakeInverterKit` | 5 | 4 `ElectronicsScrap`, 2 `Amplifier`, 3 `ElectricWire`, 1 `SmallSheetMetal`, 4 `Screws` ; [tournevis, pinces] | `Mov_LiveWire_Inverter` | 25 |
| `LWMakeWindTurbineKit` | 6 | 2 `Speaker` (aimants), 3 `ElectricWire`, 4 `ElectronicsScrap`, 2 `SheetMetal`, 2 `MetalBar`, 1 `Pipe`, 6 `Screws` ; [tournevis, pinces, marteau] | `Mov_LiveWire_WindTurbine` | 30 |
| `LWMakeWaterWheel` | 7 | 8 `Plank`, 20 `Nails`, 2 `Speaker`, 3 `ElectricWire`, 4 `ElectronicsScrap`, 1 `MetalBar` ; [marteau, tournevis] | `Mov_LiveWire_WaterWheel` | 30 |
| `LWMakePowerBankKit` | 2 | 2 `ElectronicsScrap`, 3 `ElectricWire`, 1 `SheetMetal`, 4 `Screws` ; [tournevis, pinces] | `Mov_LiveWire_PowerBank` | 8 |
| `LWMakeBreakerKit` | 3 | 2 `ElectronicsScrap`, 1 `ElectricWire`, 1 `SmallSheetMetal`, 2 `Screws` ; [tournevis] | `Mov_LiveWire_Breaker` | 8 |
| `LWMakeDeepCycleBattery` | 6 | 2 batteries de voiture (`CarBattery1/2/3` indifférentes), 2 `ElectricWire`, 1 `ScrapMetal` ; [pinces] | `DeepCycleBattery` (charge 0, état = moyenne des deux) | 20 |

- **Apprentissage (validé : D-6).** Recettes connues automatiquement à leur niveau (`AutoLearnAny = Electricity:n`, champ vu dans `recipes_traps.txt:99-121`).
- **Équilibrage.** Les calculatrices sont la porte d'entrée du solaire (10 par panneau) ; au niveau 8, on n'en dépend plus.
- **Butin.** Cellules photovoltaïques : garages, ateliers, électriciens (`GarageTools`, `CrateTools`, `GarageMetalwork`, `MechanicShelfElectric`, `ElectricianTools`, `MetalShopTools`, `WireFactoryElectric`, `ToolStoreMisc`). Panneaux tout faits, plus rares : garages, ateliers, quincailleries (`GarageTools`, `CrateTools`, `GarageMetalwork`, `ToolStoreMisc`, `ToolStoreTools`). Disque du logiciel (Computer Mod seulement) : magasins et caisses d'informatique, bureaux.

---

## 3. Sources : la production

### 3.1 Unités et pas de simulation

- **Unités.** Puissance en watts (W), énergie en kilowattheures (kWh).
- **Pas de simulation.** Le serveur calcule toutes les **10 minutes de jeu** (`architecture.md`, § 4), **que des joueurs soient présents ou non**.
- **Météo globale.** Toute la carte partage la même météo (NM-12). Ce qui distingue deux appareils, c'est leur pose (ciel ouvert, rive), leur état et le niveau de l'installateur.
- **Formule commune** : `P = P_nominale × facteur_source × facteur_état × facteur_pose × multiplicateur_sandbox`.
  - `facteur_état = 0,5 + 0,5 × état/100`.
  - Un appareil d'état 0 est en panne et produit 0.
  - `facteur_pose` : voir § 4.3.
- **Micro-onduleur intégré à chaque source** (lissage). Chaque source contient un petit onduleur qui **lisse** sa production. Ce n'est ni un objet à poser, ni un équipement optionnel : il fait partie de la source.
  - La puissance fournie au réseau suit la puissance brute avec un temps de réponse de 30 minutes de jeu : `P_fournie ← P_fournie + (P_brute − P_fournie) × min(1, Δt / 0,5 h)`. Pour un pas de 10 minutes, l'écart se réduit d'un tiers à chaque pas.
  - Effet : un nuage qui passe ou une rafale de vent ne fait plus varier brutalement le courant. Au coucher du soleil, la production décroît en une demi-heure au lieu de tomber d'un coup.
  - Équilibre énergétique : le lissage décale l'énergie dans le temps ; l'écart sur une journée est négligeable (règle de mod, sans équivalent dans le moteur).
  - Le tableau de bord affiche la puissance **fournie** (lissée) ; l'inspection d'une source montre aussi la puissance brute.

### 3.2 Panneau photovoltaïque

`facteur_source = S(t) × (1 − 0,8 × nuages) × (1 − neige_sur_panneau)`

- **Courbe du jour** : `S(t) = max(0, sin(π × (t − aube) / (crépuscule − aube)))`.
  - `t` est l'heure décimale (`getGameTime():getTimeOfDay()`).
  - L'aube et le crépuscule viennent de `getClimateManager():getSeason():getDawn()` et `getDusk()`, en heures décimales (`java/zombie/erosion/season/ErosionSeason.java:165-195`). Ne pas utiliser `getGameTime():getDawn()`, qui est un entier figé (`java/zombie/GameTime.java:1154-1164`).
  - Le moteur ne calcule pas la hauteur du soleil (NM-12) : la sinusoïde en tient lieu.
- **Nuages** : `getCloudIntensity()`, de 0 à 1 (NM-12). Par ciel couvert, il reste 20 % de la production.
- **Neige sur le panneau** (règle de mod) :
  - pendant `isSnowing()`, elle augmente de 0,1 par heure × intensité ;
  - elle fond de 0,05 par heure au-dessus de 0 °C ;
  - l'action « Déneiger » la remet à 0.
- **Puissance nominale : 100 W.**
- **Ordres de grandeur** (panneau neuf, ciel clair) : à la latitude fixe de 38°, le jour dure environ 14,8 h l'été et 9,5 h l'hiver (`ErosionSeason.java:79-80`, `java/zombie/erosion/ErosionConfig.java:425`). Cela donne **≈ 0,94 kWh par jour d'été** et **≈ 0,60 kWh par jour d'hiver**, et 60 % de ces valeurs par ciel moyennement nuageux.

### 3.3 Éolienne

`facteur_source = f(v)`, avec `v = getWindspeedKph() × (1 + 0,15 × min(z, 3))`.

- `getWindspeedKph()` va de 0 à 120 km/h (`java/zombie/iso/weather/ClimateManager.java:514-516`).
- La hauteur est une règle de mod : +15 % par étage, jusqu'au 3e.

| Vent `v` | `f(v)` |
|---|---|
| < 10 km/h | 0 |
| 10 à 45 km/h | `((v − 10) / 35)³` |
| 45 à 85 km/h | 1 |
| > 85 km/h | 0 (frein automatique) ; risque de dégât (§ 4.4) |

- **Puissance nominale : 400 W.** À 25 km/h, l'éolienne produit ≈ **31 W** ; à 40 km/h, ≈ **252 W**.
- **Point incertain** : la répartition réelle du vent n'est pas connue. La base plafonne vers 78 km/h hors période météo (`java/zombie/iso/weather/ClimateValues.java:265-270`). Le prototype P5 la mesurera.

### 3.4 Roue à aubes

`facteur_source = saison × gel`

- **Site validé à la pose** :
  - case de terre au niveau 0 ;
  - une case voisine porte le drapeau `water` (`media/lua/shared/Fishing/FishingUtils.lua:4-9`) ;
  - cette case est une rivière selon `Fishing.isRiver(x, y)` (`media/lua/shared/Fishing/FishingZones.lua:40-47`).
- **Pas de lac ni d'étang** : refusés, car le courant moteur ne permet pas de distinguer rivière et lac (NM-13).
- **Saison** (règle de mod) : printemps × 1,2 ; été × 0,8 ; automne et hiver × 1,0.
- **Gel** : le moteur ne gèle jamais l'eau (NM-13). L'option `RiverFreeze` envisagée n'est pas implémentée.
- **Multiplicateur** : option `LiveWire.HydroMultiplier`.
- **Puissance nominale : 120 W, jour et nuit**, soit ≈ **2,9 kWh par jour**.

### 3.5 Exemple de bilan

Base : un réfrigérateur-congélateur et 10 lumières allumées, plus la consommation à vide de l'onduleur. Cela fait environ **170 W**, soit **4,1 kWh par jour**.

| Installation | Été (kWh/j) | Hiver (kWh/j) | Verdict |
|---|---|---|---|
| 4 panneaux | 3,8 | 2,4 | Déficit |
| 6 panneaux + 1 éolienne (vent moyen 25 km/h, ≈ 0,7 kWh) | 6,3 | 4,3 | Juste suffisant |
| 1 roue à aubes + 2 panneaux | 4,8 | 4,1 | Stable |

**Stock pour une nuit d'hiver** de 14 h : 170 W × 14 h ≈ 2,4 kWh utiles. Il faut donc environ 4 batteries de voiture standard (§ 5.1), ou 2 batteries stationnaires.

---

## 4. Compétence Électricité

### 4.1 Paliers

Les niveaux vanilla vont de 0 à 10 (`Perks.Electricity`, `java/zombie/characters/skills/PerkFactory.java:83`). « I-n » renvoie à l'idée n de [`annexes/recherches/idees-initiales.md`](annexes/recherches/idees-initiales.md).

| Niv. | Débloque (version) | Effet continu |
|---|---|---|
| 0 | Lire un testeur : « alimenté / non alimenté » | — |
| 1 | Testeur de tension (I-1, v0.1) | Lecture détaillée de la case (§ 6.4) |
| 2 | Cellules de calculatrice ; **powerbank** (I-6, v0.1) ; chargeur de piles (I-2, v0.2) | Usure des batteries −5 % |
| 3 | Panneaux photovoltaïques (I-9, v0.1) ; désarmer une alarme (I-3, v0.3) | Rendement de pose 0,85 |
| 4 | Réparer les appareils, dont les cuisinières (I-5, v0.2) ; reconditionner une batterie (v0.1) | Lecture de l'autonomie |
| 5 | **Onduleur** (I-6, v0.1) | — |
| 6 | Éolienne (I-9, v0.1) ; batterie stationnaire (v0.1) ; pompe électrique (I-7, v0.2) | Usure des batteries −10 % |
| 7 | Roue à aubes (I-9, v0.1) ; capteurs et alarme de base (I-4, v0.3) | Rendement de pose 0,95 |
| 8 | Cellules à partir de déchets (v0.1) ; clôture électrifiée (I-8, v0.4) | Chance d'échec de réparation divisée par 2 |
| 9-10 | Onduleur relais : raccorder un grand bâtiment (I-10, v0.4) | Rendement de pose 1,0 ; usure des appareils −25 % |

### 4.2 Expérience

L'expérience est **toujours donnée sur le serveur**, car `addXp` est sans effet sur un client MP (`java/zombie/Lua/LuaManager.java:9300-9316`, `knowledge/combat-and-xp.md:24`). Pour repère, le vanilla donne 5 XP pour réparer un générateur (`ISFixGenerator.lua:71`).

| Geste | XP | Limite |
|---|---|---|
| Recette du mod | colonne XP du § 2.5 | — |
| Poser une source | 10 (panneau), 20 (éolienne, roue) | — |
| Poser un onduleur | 25 | — |
| Raccorder une source ou une batterie | 3 | — |
| Inspecter un appareil (5 s) | 2 | 1 fois par appareil et par jour de jeu |
| Mesurer au testeur | 1 | 1 fois par case et par heure de jeu |
| Réparer | 5 + 1 par point réparé, au plus 15 | — |
| Reconditionner une batterie | 8 | — |
| Réarmer un onduleur disjoncté après avoir corrigé la surcharge | 5 | 1 fois par heure |

### 4.3 Effets du niveau à l'installation

- **Rendement de pose.** Il est enregistré sur l'appareil quand on le pose (niveau de la personne qui pose) : 0,85 (niv. 3 à 6), 0,95 (niv. 7-8), 1,0 (niv. 9-10). Il s'applique à la production d'une source et au rendement d'un onduleur (§ 5.2).
- **Pas d'échec de pose** depuis 0.1.1 : la pose est celle d'un meuble vanilla, réservée au niveau requis.

### 4.4 Usure, pannes, réparation

| Appareil | Usure normale | Accélérateurs |
|---|---|---|
| Panneau | −1 par 10 jours de jeu | Orage, seulement si `StormDamage` est activée (désactivée par défaut) : 1 chance sur 20 par heure de perdre 5 |
| Éolienne | −1 par 4 jours de jeu | Vent > 85 km/h, seulement si `StormDamage` est activée : 1 chance sur 6 par heure de perdre 5 à 15 ; ignoré avec le frein (niv. 7+, posé à l'inspection) |
| Roue à aubes | −1 par 5 jours de jeu | Dégel (si l'option est active) : −5 |
| **Onduleur** | −1 par 5 jours de jeu **en marche** | Charge > 80 % de sa puissance maximale : usure × 2 ; chaque disjonction : −3 |
| **Batterie** | Voir ci-dessous | — |

**Batteries.**
- **Où vivent la charge et l'usure.** La charge est portée par les utilisations de l'objet (`getCurrentUsesFloat`, de 0 à 1, `java/zombie/inventory/types/DrainableComboItem.java:91-100`). L'usure est portée par son état.
- **Usure par cycle complet équivalent** : `100 / durée de vie` points. Durée de vie : 150 cycles pour une batterie de voiture, 600 pour une batterie stationnaire.
- **Décharge profonde.** Une décharge en dessous de 20 % double l'usure du pas.
- **Capacité effective** = `nominale × (0,4 + 0,6 × état/100)`. Une batterie d'état 0 est morte.
- **Autodécharge** : 0,2 % par jour.

**Réparer** (appareil arrêté ou en panne) :
- coût : 1 `ElectronicsScrap` et 1 `ElectricWire` ;
- gain : `5 + niveau` points d'état ;
- échec : `max(5, 40 − 5 × niveau)` %, la pièce est perdue ;
- au-delà de 90 points, il faut « Remettre à neuf » (niv. 8 : 4 `ElectronicsScrap` et 2 `ElectricWire`), qui ramène l'état à 100.

**Reconditionner une batterie** (niv. 4, batterie en inventaire) :
- coût : 1 `ElectronicsScrap` et 0,5 l d'eau ;
- gain : +15 points d'état, sans dépasser 80 ;
- impossible sur une batterie morte.

**Panne d'onduleur** (état 0) : la base n'est plus alimentée. La production des sources est **perdue**, car l'onduleur assure aussi la charge des batteries ; les batteries gardent leur charge.

---

## 5. Batteries et onduleur : stocker, convertir, distribuer

### 5.1 Batteries : stocker

Les batteries se rangent dans une **powerbank** : un appareil posé, raccordé à l'onduleur comme une source, qui **s'ouvre comme une caisse**. On y glisse ses batteries à la souris, avec l'inventaire vanilla, et on les reprend de la même façon.
- **4 batteries comptées** par powerbank. Les suivantes, et tout objet qui n'est pas une batterie, sont ignorés ; le tableau de bord le signale.
- La charge d'une batterie apparaît dans son infobulle vanilla.
- **Retirer une batterie** de la powerbank la sort du réseau : son énergie part avec elle.
- **Plusieurs powerbanks** peuvent être raccordées au même onduleur.
- Une powerbank **ne se démonte que vide**.
- **Aucune batterie au sol** : une batterie posée par terre n'est jamais comptée.

| Batterie | Capacité nominale |
|---|---|
| `Base.CarBattery1` | 0,40 kWh |
| `Base.CarBattery2` | 0,60 kWh |
| `Base.CarBattery3` | 0,90 kWh |
| `LiveWire.DeepCycleBattery` | 1,50 kWh |

Les trois batteries vanilla ont le même `UseDelta`, donc ces capacités sont une règle de mod (`drainable.txt:2336-2390`).

- **Stock du réseau** : somme des batteries raccordées.
- **Répartition** : le surplus est réparti au prorata de la place libre de chaque batterie, et le déficit au prorata de sa charge.
- **Rendement de charge** : 0,90 (pertes chimiques).

### 5.2 Onduleur : convertir et distribuer

**Ce qu'il fait.** L'onduleur est le **cœur du réseau** : sources et batteries s'y raccordent. Il remplit deux fonctions :
- **conversion vers les batteries** : il régule la charge à partir de la production des sources ;
- **conversion vers la base** : il fournit le courant aux appareils, à partir de la production du moment, puis des batteries.

**Caractéristiques :**

| | Onduleur |
|---|---|
| Puissance maximale | 1 500 W |
| Rendement (selon le niveau à la pose) | 0,85 à 1,0 |
| Consommation à vide (en marche) | 20 W |
| Bruit | **très léger bourdonnement** |

- **Bruit.** Les zombies l'entendent dans un rayon de 2 cases (option `InverterNoiseRadius`). Les joueurs à moins de 12 cases entendent le **ronronnement de réfrigérateur vanilla `FridgeHumA`** (choix de l'utilisateur, D-8), joué localement par chaque client (`playSoundImpl`, sans paquet réseau).
- **Portée : toute la maison, sans câblage.** Il alimente **tous les appareils** dans un rayon de `GeneratorTileRange` (20 par défaut) et sur ±`GeneratorVerticalPowerRange` étages (3 par défaut) : réfrigérateurs, lumières, cuisinières, télévisions, radios, machines à laver. On ne raccorde aucun appareil de la maison un par un ; seuls les équipements du mod (sources, powerbanks, disjoncteur) se raccordent à l'onduleur (choix de l'utilisateur, 2026-10-17). Ce sont les réglages vanilla des générateurs (`java/zombie/SandboxOptions.java:248-249`), et ils s'appliquent donc aussi aux générateurs vanilla.
- **Pose : n'importe où, intérieur compris.** Il ne rend jamais le bâtiment toxique ; il se pose comme un meuble, sur une case de sol libre.
- **États** : marche, arrêt (manuel), **disjoncté** (surcharge), **en panne** (état 0), **à vide** (plus d'énergie disponible).
- **Plusieurs onduleurs.** Un réseau n'a qu'un onduleur en v0.1, mais une base peut avoir plusieurs réseaux. Les onduleurs relais arrivent en v0.4.

### 5.3 Consommation : celle que le jeu attribue aux appareils

- **Valeurs vanilla.** Le mod reprend exactement les valeurs que le moteur attribue à chaque appareil allumé (`getGeneratorPowerConsumption`, NM-5).
- **Échelle** : 1 unité moteur par heure = **1 000 W** × `LiveWire.PowerScale` (validé : D-5).

| Appareil (valeur moteur) | Consommation |
|---|---|
| Lumière allumée (0,002) | 2 W |
| Radio sur secteur (0,01) | 10 W |
| Télévision (0,03) | 30 W |
| Réfrigérateur seul (0,08) | 80 W |
| Cuisinière ou micro-ondes allumé (0,09) | 90 W |
| Lave-linge, sèche-linge (0,09) | 90 W |
| Réfrigérateur-congélateur (0,13) | 130 W |
| Lave-linge et sèche-linge superposés (0,9 par partie active) | jusqu'à 1 800 W : fait disjoncter un onduleur simple |

**Bilan d'un pas** de durée `Δt` (en heures) :
```
utile_de_la_production = min(production × eff_onduleur, demande)
manque                 = demande − utile_de_la_production         (pris aux batteries)
surplus                = production − utile_de_la_production / eff_onduleur
stock                 += surplus × 0,90 × Δt              (régulation de charge et pertes chimiques)
                         − manque / eff_onduleur × Δt
```
`production` est la puissance des sources (W), `demande` celle des appareils (W) et `eff_onduleur` le rendement de l'onduleur.
Le stock est borné entre 0 et la capacité. Un surplus quand tout est plein est affiché « production perdue ».

**Surcharge et manque d'énergie :**
- **Surcharge.** Si la demande dépasse la puissance maximale, l'onduleur **disjoncte** : la base n'est plus alimentée, il perd 3 points d'état, et il faut « Réarmer ».
- **Manque d'énergie.** Si la production du moment et le stock ne couvrent plus la demande, l'onduleur passe **à vide** : le courant disparaît. Il se rallume seul quand le stock dépasse 2 % de la capacité, ou quand la production lissée couvre la demande. Grâce au micro-onduleur de chaque source (§ 3.1), la maison ne clignote pas au passage d'un nuage.

**Installation minimale : une source et un onduleur, sans batterie.**
- La maison est alimentée tant que la production du moment, multipliée par le rendement, couvre la demande. Exemple : 3 panneaux par beau temps alimentent un réfrigérateur-congélateur à midi, mais pas la nuit.
- **La batterie est facultative** : elle ne sert qu'à garder le surplus pour plus tard.

### 5.4 Quand aucun joueur n'est dans la zone

L'installation **continue de fonctionner** (option `LiveWire.SimulateUnloaded`, activée par défaut, D-9) :
- **les sources produisent** selon la météo et l'heure réelles du jeu ;
- **les batteries se chargent et se déchargent** ;
- **l'onduleur consomme** selon la dernière demande mesurée quand la zone était chargée. Elle ne peut pas être remesurée quand personne n'est là, car les appareils ne sont pas chargés ;
- **les appareils de la maison restent alimentés** tant que l'énergie dure. Le réfrigérateur garde la nourriture au froid pendant l'absence, comme près d'un générateur vanilla. Si l'énergie s'épuise pendant l'absence, la maison est trouvée sans courant au retour ;
- **l'usure continue.**

**Limite connue** : comme en vanilla, le jeu évalue la nourriture au retour d'après l'état du courant **au moment du retour** (`java/zombie/inventory/types/Food.java:688-698`). Si l'énergie s'est épuisée la veille du retour, toute l'absence est comptée sans courant pour la nourriture.

---

## 6. Interface

### 6.1 Menus contextuels (clic droit dans le monde)

Toutes les options sont dans un sous-menu **« Live Wire »**. Une option impossible est grisée, avec une infobulle qui dit pourquoi.

| Sur… | Options |
|---|---|
| Une case quelconque, testeur en inventaire | Mesurer |
| Une source, une powerbank, le disjoncteur, l'alarme | Le nom, puis l'état : « Raccordé à l'onduleur à N cases » (grisé) et « Débrancher de l'onduleur », ou « Non raccordé » et « Raccorder à un onduleur » → un onduleur à portée par ligne, « Onduleur à N cases (k fils) » ; « Aucun onduleur à moins de 12 cases » s'il n'y en a pas · Déneiger (panneau) · Inspecter · Réparer · Remettre à neuf |
| L'onduleur | Ouvrir le tableau de bord · Allumer ou Éteindre · Réarmer · « Raccorder un équipement » → chaque équipement libre à portée, avec distance et fils · « Débrancher un équipement » → chaque équipement raccordé · Inspecter · Réparer · Remettre à neuf |
| Une batterie en inventaire | Reconditionner |
| Un générateur vanilla (raccordé, ou onduleur à portée) | Générateur de secours → Raccorder à l'onduleur · Débrancher |
| Un ordinateur de bureau (raccordé, ou onduleur à portée) | Ordinateur de gestion → Ouvrir le tableau de bord · Raccorder à l'onduleur · Débrancher |
| N'importe où, en mode debug ou admin | Debug (§ 6.5) |

Poser, tourner et **ramasser** un équipement passent par le menu et le curseur de meubles vanilla. Ramasser un onduleur débranche tout son réseau ; une powerbank ne se ramasse que vide (règle vanilla des conteneurs). « Démonter » (ferraille) et « Détruire » à la masse restent refusés (`architecture.md`, § 2.4). Les batteries entrent et sortent de la powerbank par l'inventaire vanilla (§ 5.1).

### 6.1 bis Nouveautés 0.1.2

- **Disjoncteur** : il saute à la place de l'onduleur (demande des appareils > 1 500 W, vérifiée à chaque pas de simulation, toutes les 10 minutes de jeu et juste après une action) ; « Réarmer le disjoncteur » sur le disjoncteur, refusé tant que la demande reste trop forte. Lampe rouge quand il a sauté.
- **Onduleur** : écran LCD (« Ouvrir l'écran de l'onduleur ») avec 5 pages, boutons < et >, bouton I/O et voyant (vert en marche, rouge à l'arrêt, orange clignotant en défaut), RESET quand il a disjoncté. Écran allumé sur la tuile quand il est en marche. « Afficher la zone alimentée » : cercle au sol. Bourdonnement du mod tant qu'il est allumé.
- **Voyants** : vert « raccordé » sur les sources et la powerbank ; pales de l'éolienne qui tournent avec le vent (au-dessus de 10 km/h).
- **Alarme** : bip à chaque pas tant que la batterie reste sous 20 %, jusqu'à « Couper la sonnerie » ; gyrophare allumé jusqu'au retour au-dessus de 25 %.
- **Logiciel de gestion** : vue complète, sur un ordinateur raccordé ; barres de production et de consommation à la même échelle. Avec le Computer Mod : disque, installation, application sur le bureau.
- **Frigos** : l'âge des aliments des frigos et congélateurs chargés est rattrapé juste avant chaque coupure ou retour du courant, comme avec un générateur vanilla.
- **Bourdonnement** : une case autour de l'onduleur seulement ; volume par joueur dans *Options > Mods* (0 = coupé). **Kit d'insonorisation** (niv. 2) posé sur l'onduleur : silence pour les joueurs et les zombies, usure +25 %.

### 6.2 Interface de gestion de l'onduleur

**Ouverture.** Fenêtre déplaçable, ouverte par « Live Wire » → onduleur → « Ouvrir le tableau de bord ».
- Elle est mise à jour toutes les 10 minutes de jeu tant qu'elle est ouverte.
- Elle se ferme quand le joueur s'éloigne de plus de 30 cases.

**Boutons :** Allumer, Éteindre, Réarmer. Chaque demande est revérifiée par le serveur. Depuis le logiciel de gestion, les boutons agissent de l'ordinateur de gestion raccordé (alimenté, joueur à 6 cases au plus), quelle que soit la distance ou l'étage de l'onduleur dans la portée du câble.

**Sections**, de haut en bas :

| Section | Contenu |
|---|---|
| **Onduleur** | Nom du réseau, modèle, état (en marche, arrêté, à vide, disjoncté, en panne), état d'usure |
| **Production et consommation** | Production actuelle en W, avec une jauge rapportée à la puissance nominale des sources. Consommation de la maison en W, rapportée à la puissance maximale de l'onduleur, avec une jauge bleue, orange au-delà de 70 %, puis rouge au-delà de 90 % (avec alerte de surcharge) |
| **Batteries** | Nombre de powerbanks, stock total en kWh et en %, avec jauge. Autonomie estimée, à partir du niveau 4. Une ligne par batterie : charge en % et état d'usure ; orange si l'état est sous 30. Alertes : batteries non comptées (plus de 4 par powerbank), production perdue (batteries pleines) |
| **Sources** | Groupées par famille : **Solaire**, **Éolien**, **Hydraulique**. Pour chaque famille : nombre de sources et puissance totale ; puis une ligne par source avec sa puissance fournie, son état et la neige sur un panneau. L'hydraulique affiche « dans une prochaine version » tant que la roue à aubes n'existe pas (v0.2) |
| **Maison alimentée** | La zone couverte (rayon et étages). Puis les appareils en marche, **regroupés par famille** : réfrigérateurs et congélateurs, lumières, télévisions, radios, cuisinières et micro-ondes, lave-linge et sèche-linge, chargeurs de batterie, autres. Pour chaque famille : nombre d'appareils et consommation |
| **Alimentation de secours** | Si un générateur est raccordé : état (recharge les batteries, en veille, plus de carburant, non branché, en panne), puissance, carburant en % avec jauge, seuils de démarrage et d'arrêt |
| **Ordinateur de gestion** | Sans ordinateur : comment en raccorder un. Ordinateur sans courant : le dire. Sinon : trois graphiques à barres sur 48 h (production, consommation, stock), la prévision jusqu'à l'aube, le délestage s'il est actif. Puis l'état de l'alarme (en veille, déclenchée) |
| **Équipements** | Le disjoncteur et l'alarme, s'ils sont raccordés, avec leur état |

### 6.3 Textes à traduire

Les clés suivent les préfixes imposés par `CLAUDE.md`. La liste complète est dans `architecture.md`, § 7.

| Famille | Fichier | Exemples |
|---|---|---|
| Objets | `ItemName.json` | `LiveWire.VoltageTester`, `LiveWire.InverterKit` |
| Recettes | `Recipes.json` | `LWMakeInverterKit` |
| Menus | `ContextMenu.json` | `ContextMenu_LW_Root`, `ContextMenu_LW_Link`, `ContextMenu_LW_Reset` |
| Infobulles | `Tooltip.json` | `Tooltip_LW_NeedOutdoor`, `Tooltip_LW_NeedRiver`, `Tooltip_LW_NeedLevel` |
| Interface | `IG_UI.json` | `IGUI_LW_Dashboard_Title`, `IGUI_LW_Autonomy`, `IGUI_LW_Tripped` |
| Options | `Sandbox.json` | `Sandbox_LiveWire_PowerScale`, `…_tooltip` |

**Vocabulaire FR vanilla** à reprendre : « Électricité » (`IGUI_perks_Electricity`, `media/lua/shared/Translate/FR/IG_UI.json:214`), « générateur », « brancher », « coupure d'électricité ».

### 6.4 Le testeur de tension

| Niveau | « Mesurer » sur une case |
|---|---|
| 0 | « Courant : oui / non » |
| 1+ | Source du courant : réseau public, générateur vanilla ou onduleur Live Wire |
| 2+ | Consommation de l'appareil visé, en W |
| 4+ | Pour l'onduleur visé : production, demande, stock, autonomie |

**Avertissement de recouvrement** : « plusieurs sources alimentent cette zone » (§ 8.2).

---

### 6.5 Outils de debug

Pour tester sans attendre des jours de jeu. Sous-menu **« Live Wire » → « Debug »**, visible :
- en solo, seulement si le jeu est lancé avec `-debug` ;
- en multijoueur, seulement pour les **administrateurs** (capacité `ChangeAndReloadServerOptions`, que seul le rôle `admin` possède).

Le serveur revérifie ce droit à chaque commande et écrit chaque usage dans sa console.

| Outil | Effet |
|---|---|
| Donner un kit de test complet | Tous les équipements posables, tournevis, 20 fils, 10 déchets électroniques, testeur, 4 batteries de voiture, 2 batteries stationnaires |
| Afficher l'état du réseau | Résumé à l'écran, détail par source dans la console |
| Batteries à 100 / 50 / 15 % / vides | Règle toutes les batteries du réseau (15 % : déclenche l'alarme et le secours) |
| Faire tourner la simulation 1 h / 12 h | Rattrapage immédiat, comme après une absence |
| Réparer tout le réseau · Abîmer l'onduleur (état 10) · Faire disjoncter | Tester l'usure, la réparation, le réarmement |
| Remplir le générateur de secours | Carburant au maximum |
| Reconstruire la liste des appareils et la zone alimentée | Refait l'inventaire de la demande et repose l'ancre |

Le réseau visé est celui de l'appareil cliqué, sinon celui de l'onduleur le plus proche.

## 7. Options sandbox

Page `LiveWire`. Valeurs par défaut validées le 2026-10-17.

| Option | Type | Bornes | Défaut | Effet |
|---|---|---|---|---|
| `LiveWire.PowerScale` | réel | 0,1 – 10 | 1,0 | Multiplie l'échelle « 1 unité moteur par heure = 1 000 W » |
| `LiveWire.SolarMultiplier` | réel | 0 – 10 | 1,0 | Production solaire |
| `LiveWire.WindMultiplier` | réel | 0 – 10 | 1,0 | Production éolienne |
| `LiveWire.HydroMultiplier` | réel | 0 – 10 | 1,0 | Production hydraulique |
| `LiveWire.BatteryCapacityMultiplier` | réel | 0,1 – 10 | 1,0 | Capacité des batteries |
| `LiveWire.BatteryWearMultiplier` | réel | 0 – 10 | 1,0 | 0 = pas d'usure |
| `LiveWire.DeviceWearMultiplier` | réel | 0 – 10 | 1,0 | Usure des sources et des onduleurs ; 0 = aucune |
| `LiveWire.InverterNoiseRadius` | entier | 0 – 10 | 2 | Rayon du bourdonnement entendu par les zombies ; 0 = silence |
| `LiveWire.LinkRange` | entier | 4 – 30 | 12 | Distance maximale de raccordement |
| `LiveWire.WirePerTiles` | entier | 0 – 20 | 4 | Cases par fil électrique ; 0 = câblage gratuit |
| `LiveWire.StormDamage` | booléen | — | **faux** | Dégâts d'orage et de tempête (désactivés par défaut, choix de l'utilisateur) |
| `LiveWire.RiverFreeze` | booléen | — | faux | Gel des roues à aubes |
| `LiveWire.XPMultiplier` | réel | 0 – 10 | 1,0 | Expérience du mod |
| `LiveWire.SkillGates` | booléen | — | vrai | Faux = aucun niveau requis |
| `LiveWire.SimulateUnloaded` | booléen | — | vrai | L'installation fonctionne quand personne n'est à proximité |
| `LiveWire.BackupStartPercent` | entier | 0 – 90 | 20 | Le générateur de secours démarre sous ce pourcentage de batterie |
| `LiveWire.BackupStopPercent` | entier | 10 – 100 | 90 | Il s'arrête à ce pourcentage |

- **Fichier** : `media/sandbox-options.txt` (`java/zombie/sandbox/CustomSandboxOptions.java:33-48`, `knowledge/mod-loading.md:146-152`).
- **Lecture** : `getSandboxOptions():getOptionByName("LiveWire.X"):getValue()`.

---

## 8. Multijoueur et compatibilité

### 8.1 Le multijoueur vu du joueur

- **Le serveur décide de tout** : production, stock, état, pannes, expérience.
- **Installations communes**, sous les règles de safehouse vanilla (`media/lua/client/ISUI/ISWorldObjectContextMenu.lua:211-214`). Pas de propriétaire en v0.1 (validé : D-7).
- **Délais** : une action prend effet à la réponse du serveur ; le tableau de bord peut avoir jusqu'à 10 minutes de jeu de retard.
- **Absence de tous les joueurs** : l'installation continue (§ 5.4). Si le serveur est mis en pause quand il est vide (`PauseEmpty`), le temps s'arrête, et l'installation aussi (`knowledge/api-42-21.md:177`).

### 8.2 Compatibilité avec les générateurs vanilla

- **Rien ne change pour eux.** Les générateurs vanilla gardent leur menu, leur carburant, leur bruit et leur toxicité. Live Wire ne crée aucun générateur du moteur.
- **Zone couverte par les deux.** Un générateur vanilla allumé et un onduleur peuvent couvrir les mêmes appareils :
  - le générateur vanilla les compte dans sa consommation de carburant (NM-5) ;
  - l'onduleur les compte aussi dans sa demande ;
  - **les deux paient donc**, et le testeur avertit.

  En v0.2, une bascule automatique mettra l'onduleur en veille quand un générateur vanilla tourne dans sa zone (D-10).
- **Réglages globaux partagés.** `GeneratorTileRange` et `GeneratorVerticalPowerRange` fixent aussi la portée de l'onduleur. `AllowExteriorGenerator` désactivé coupe le courant des cases extérieures pour les deux, car `haveElectricity` est faux sur une case `exterior` (`java/zombie/iso/IsoGridSquare.java:8223-8228`). `GeneratorFuelConsumption` n'a **aucun effet** sur Live Wire.
- **Autres mods d'énergie.** Aucune dépendance, aucun code repris (`CLAUDE.md`). Un mod qui pose lui aussi des positions de générateur par script pourrait interférer (`architecture.md`, R-6).

---

## 9. Périmètre des versions (validé : D-1)

| Version | Contenu | Idées |
|---|---|---|
| **0.1 — Socle** | Testeur ; batteries posées et raccordées (vanilla et stationnaire), facultatives ; un onduleur ; panneaux ; éolienne ; roue à aubes ; disjoncteur (optionnel) ; tableau de bord ; usure, pannes, réparation, reconditionnement ; paliers et expérience ; sandbox ; EN et FR ; MP dédié ; fonctionnement sans joueur | I-1, I-6, I-9 (solaire, éolien, hydraulique) |
| **0.2 — Base autonome** | Charge des batteries depuis le réseau public (l'ordinateur de gestion, l'alarme et le générateur de secours sont avancés en 0.1, D-11, D-14) ; bascule automatique ; chargeur de piles (`IsoCarBatteryCharger`, NM-14) ; réparation des cuisinières et micro-ondes (NM-16) ; pompe électrique qui remplit un récupérateur au-dessus d'éviers raccordés (`IsoObject:addFluid`, `java/zombie/iso/IsoObject.java:2700-2721`) | I-2, I-5 (partiel), I-7 |
| **0.3 — Sécurité** | Désarmer l'alarme d'une maison (`BuildingDef:setAlarmed`, NM-15) ou d'un véhicule ; capteurs reliés à une lumière ou une sirène | I-3, I-4 |
| **0.4 — Fin de partie** | Clôture électrifiée ; onduleurs relais pour un grand bâtiment | I-8, I-10 |
| **Reportées sans date** | Dynamo à vélo : pas de vélo vanilla ; reste ouverte en manivelle, endurance contre courant (`CharacterStat.ENDURANCE`). Réparation des réfrigérateurs, télévisions et radios : le froid ne peut pas être bloqué depuis Lua (NM-16). Panneaux récupérés sur les toits : aucune tuile solaire vanilla trouvée (hypothèse) | I-9 (vélo), I-5 (réfrigérateurs) |
| **Après les modèles définitifs** | Tuiles définitives (les tuiles géométriques provisoires existent depuis 0.1.1) ; son propre de l'onduleur ; câbles visibles | — |

---

## 10. Fonctionnalités ajoutées après la 0.1

Conception et justification détaillées : [`annexes/recherches/idees-initiales.md`](annexes/recherches/idees-initiales.md) (idées 2 et 5). Guide du joueur : [wiki](wiki/fr/Home.md).

### 10.1 Pompe à eau (F20, version 1.2.0)

- Appareil posé `WaterPump`, Électricité 6 (fabrication et pose), raccordé à l'onduleur au fil électrique comme une source.
- Barils : collecteurs d'eau de pluie vanilla ou barils d'un mod (tout objet à fluide d'au moins 20 L), posés sur une des 8 cases voisines de la pompe, même étage ; 8 barils au plus ; 1 tuyau `Base.MetalPipe` consommé par baril, rendu au débranchement.
- Réservoirs relais invisibles de 25 L posés au-dessus des éviers, baignoires, douches et toilettes raccordés à moins de `PumpRange` cases (15 par défaut) et à 3 étages au plus : la plomberie vanilla y puise ; les robinets se raccordent à la clé à tuyau comme en vanilla.
- Consommation 250 W seulement pendant le pompage, débit 5 L par minute de jeu au plus ; arrêt quand tous les relais sont pleins. Seule l'eau est déplacée ; l'eau croupie d'un baril sort propre au robinet (comportement vanilla).
- Bourdonnement de moteur entendu à 4,5 cases ; bruit pour les zombies à 2 cases.
- Menu « Afficher les robinets alimentés » ; voyant bleu tant qu'au moins un robinet est alimenté.
- Action de debug et d'administration « Retirer tous les relais d'eau », à lancer avant de retirer le mod.

### 10.2 Onduleurs en parallèle (F21, version 1.3.0)

- Jusqu'à 3 onduleurs esclaves couplés à un onduleur maître (4 par réseau), avec un kit de couplage (`LiveWire.CouplingKit`, Électricité 6) et du fil électrique.
- Capacité du réseau = somme des onduleurs en service (6 000 W au plus) ; une seule batterie de stockage et une seule zone alimentée, celle du maître.
- Chaque onduleur garde son interrupteur et son usure ; un esclave éteint ou en panne baisse la capacité, et le réseau disjoncte si la demande dépasse alors la capacité. Un esclave ne disjoncte pas seul : on réarme le maître.
- « Découpler » rend un esclave indépendant et rend le kit (pas le fil).
- Deux onduleurs indépendants dont les zones se chevauchent ne comptent plus deux fois un appareil : il est compté par l'onduleur allumé le plus proche.

### 10.3 Logiciel dans le Computer Mod (F22)

- Mods facultatifs : Computer Mod (`ComputerModkum`, Workshop 3725497089) et son extension Laptop (`ComputerModLaptop`, 3798992436). Sans eux, rien ne change.
- Le disque `LiveWire.MonitorDisk` n'apparaît dans le butin que si le Computer Mod est actif. Clic droit sur un ordinateur ou portable du Computer Mod avec le disque : « Installer le logiciel Live Wire ».
- Le logiciel s'ouvre comme une application de ce mod (icône de bureau, fenêtre, barre des tâches), avec le même contenu que le logiciel de gestion de Live Wire.

### 10.4 Modèles pour Project Viewpoint (F23)

- Mod facultatif livré dans le même objet Workshop : `batman_LiveWireViewpoint` (`require=atman_LiveWire`), modèles 3D de tous les équipements, voyants, pales et mousse d'insonorisation pour Project Viewpoint. Sans Project Viewpoint, il ne fait rien.
