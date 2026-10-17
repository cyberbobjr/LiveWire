# Live Wire — documentation fonctionnelle

État : **conception, aucun code**. Rien n'a été prototypé ni testé en jeu. Les chiffres sont des **valeurs de départ** destinées à l'équilibrage. Les faits du moteur cités viennent du dépôt de référence `pz-source-42.21` (chemins relatifs à sa racine) et de `docs/notes-moteur.md` (« NM-n » = note n).

Les choix qui reviennent à l'utilisateur sont dans `docs/decisions-ouvertes.md` (« D-n »). Ce document applique partout la recommandation par défaut, marquée **à valider**.

---

## 1. Vision

### 1.1 L'idée en une phrase

**Le courant devient un métier.** Le générateur vanilla ne disparaît pas : il reste bruyant, gourmand et visible. L'électricien de Live Wire construit, à côté, une installation silencieuse et durable, faite de sources renouvelables (soleil, vent, eau), de batteries et d'un onduleur qui distribue le courant à la base.

Trois règles de conception :

1. **Le moteur reste juge de l'alimentation.** Une case est alimentée parce qu'un vrai générateur du moteur l'alimente. Le mod ne simule pas un réseau parallèle : il pilote un générateur particulier, l'**onduleur** (voir `architecture.md`, § 1). Réfrigérateurs, lumières, cuisinières et radios fonctionnent donc exactement comme avec un générateur vanilla.
2. **L'énergie se mérite et se lit.** Chaque watt a une origine (heure, nuages, vent, rivière) et une destination (appareils branchés). Le multimètre et le tableau de bord rendent tout cela lisible.
3. **La compétence Électricité compte à chaque étape** : fabriquer, installer, entretenir, réparer, diagnostiquer. Chaque geste utile rapporte de l'expérience.

### 1.2 La boucle de jeu, du premier jour à la base autonome

| Phase | Situation | Ce que fait le joueur avec Live Wire |
|---|---|---|
| **1. Avant la coupure** (réseau public actif) | Le courant est partout. | Il récupère des batteries de voiture, des fils électriques, de l'électronique, des calculatrices et des livres d'électricité. Il fabrique un **testeur de tension** (niv. 1) et apprend à lire une installation. |
| **2. La coupure** | Le générateur vanilla devient la seule source ; il attire les zombies. | Il installe un **onduleur** (niv. 5) à l'extérieur de la maison et range ses batteries de voiture dans son compartiment. Pour une grosse installation, il ajoute un banc câblé (niv. 2). Les batteries, chargées pendant le jour, permettent d'éteindre le générateur la nuit. *En v0.1, la charge depuis un générateur vanilla n'existe pas encore (§ 9) : la phase 2 repose sur les premières sources renouvelables.* |
| **3. Premières sources** | Le carburant se raréfie. | Il pose des **panneaux photovoltaïques** sur un toit plat ou en plein champ (niv. 3) et une **petite éolienne** (niv. 6). Il apprend que la production dépend de l'heure, des nuages, de la neige et du vent. |
| **4. Base autonome** | Plus de carburant du tout. | Il installe une **roue à aubes** sur une rive de rivière (niv. 7, v0.2), qui produit jour et nuit. Il dimensionne l'installation (assez de batteries pour la nuit, onduleur assez puissant), entretient les appareils et remplace les batteries usées. |
| **5. Fin de partie** (versions suivantes) | La base est stable. | Il ajoute une pompe électrique, des capteurs et une alarme, une clôture électrifiée, et des relais qui alimentent un grand bâtiment. |

**Tension de jeu recherchée.** Le joueur doit arbitrer :
- le silence (onduleur et batteries) contre la puissance (générateur vanilla) ;
- le dimensionnement : une nuit d'hiver dure environ 14 h (§ 3.2) ;
- l'entretien des appareils et des batteries, qui s'usent ;
- la surcharge : un onduleur trop petit disjoncte.

---

## 2. Objets, recettes et appareils posés

### 2.1 Principes

- **Module de script** : `LiveWire`. Tous les noms ci-dessous sont propres au mod.
- **Placeholders.** Aucun modèle ni tuile définitif n'existe. Chaque objet utilise une **icône et un modèle vanilla existants**, ou une **forme géométrique simple**. Chaque appareil posé utilise un **sprite vanilla de substitution**. Tous sont marqués `placeholder` dans les scripts et dans ce document. Les définitifs viendront plus tard (Blender, tuiles).
- **Objets vanilla réutilisés sans modification** : batteries de voiture `Base.CarBattery1/2/3`, `Base.ElectricWire`, `Base.ElectronicsScrap`, `Base.Calculator`, `Base.SmallSheetMetal`, `Base.SheetMetal`, `Base.Screws`, `Base.Pipe`, `Base.MetalBar`, `Base.Plank`, `Base.Nails`, `Base.Amplifier`, `Base.Speaker`, `Base.LightBulb`, `Base.DuctTape`, `Base.Glue`, `Base.Aluminum`, `Base.ScrapMetal`. Tous existent en 42.21 (`media/scripts/generated/items/normal.txt`, `drainable.txt`, `weapon.txt`).
- **Outils, par tag vanilla** : tournevis `base:screwdriver`, pinces `base:pliers`, marteau `base:hammer`. La syntaxe `craftRecipe` 42.21 accepte `item 1 tags[base:screwdriver] mode:keep` (`media/scripts/generated/recipes/recipes_traps.txt:99-121`).
- **Un objet d'inventaire = un kit.** Le joueur porte un **kit**. L'action « Installer » crée l'appareil dans le monde. L'action « Démonter » rend le kit avec son état. L'objet moteur de l'onduleur n'existe jamais dans un inventaire (NM-6).

### 2.2 Objets d'inventaire

| Objet (`LiveWire.…`) | Nom FR (EN) | Type | Poids | Placeholder | Rôle |
|---|---|---|---|---|---|
| `VoltageTester` | Testeur de tension (Voltage Tester) | normal | 0,3 | icône et modèle de `Base.Remote` (télécommande), **placeholder** | Diagnostic (§ 5.4) |
| `SolarCell` | Cellule photovoltaïque (Solar Cell) | normal | 0,05 | icône de `Base.ElectronicsScrap`, **placeholder** | Composant des panneaux |
| `SolarPanelKit` | Panneau photovoltaïque en kit (Solar Panel Kit) | normal | 6 | icône de `Base.SheetMetal`, modèle plan gris (forme simple), **placeholder** | Devient un panneau posé |
| `WindTurbineKit` | Éolienne en kit (Wind Turbine Kit) | normal | 12 | icône de `Base.MetalBar`, modèle cylindre (forme simple), **placeholder** | Devient une éolienne posée |
| `WaterWheelKit` | Roue à aubes en kit (Water Wheel Kit) | normal | 15 | icône de `Base.Plank`, modèle cylindre plat (forme simple), **placeholder** | Devient une roue posée (v0.2) |
| `InverterKit` | Onduleur en kit (Inverter Kit) | normal | 8 | icône et modèle de `Base.CarBatteryCharger`, **placeholder** | Devient l'onduleur posé |
| `HeavyInverterKit` | Onduleur renforcé en kit (Heavy Inverter Kit) | normal | 12 | idem, **placeholder** | Variante 3 kW (niv. 8) |
| `DeepCycleBattery` | Batterie stationnaire (Deep-Cycle Battery) | drainable | 9 | modèle `CarBattery` vanilla (`WorldStaticModel = CarBattery`, `media/scripts/generated/items/drainable.txt:2335-2351`), **placeholder** | Stockage longue durée |
| `InverterUnit` | *(interne, jamais en inventaire)* | normal, tag `base:generator` | — | sprite de substitution de l'onduleur | Objet moteur du générateur piloté (`architecture.md`, § 1.4) |

### 2.3 Appareils posés

Un appareil posé est un objet du monde portant une **marque Live Wire** (identifiant d'appareil). Il est enregistré dans le registre du serveur.

| Appareil | Sprite de substitution (**placeholder**) | Source du sprite | Contraintes de pose |
|---|---|---|---|
| Panneau photovoltaïque | `appliances_com_01_20` (antenne satellite) | `media/scripts/generated/items/moveable.txt:1854` | Case à ciel ouvert : `sq:isOutside()` (`java/zombie/iso/IsoGridSquare.java:7968-7970`). Toit plat accepté. |
| Éolienne | `industry_01_4` (climatiseur) | `moveable.txt:1755` | Case `isOutside()`. Bonus si posée en hauteur (§ 3.3). |
| Roue à aubes (v0.2) | `construction_01_5` (palette) | `moveable.txt:945` | Niveau 0, case de terre voisine d'une eau de rivière (§ 3.4). |
| Onduleur, **avec compartiment à batteries intégré** | `location_business_machinery_01_32` (armoire à outils, qui porte un conteneur), à confirmer au prototype P1 | `moveable.txt:1017` | Case **sans pièce** (`sq:getRoom() == nil`), pour éviter la toxicité (NM-4). |
| Banc de batteries supplémentaire (facultatif) | Aucun objet neuf : un **meuble conteneur vanilla** câblé (caisse en bois construite, caisse militaire, étagère métallique) | — | À portée de câble de l'onduleur, pour les grosses installations. **À valider : D-4.** |

**Câblage (à valider : D-3).** Chaque appareil se raccorde à un onduleur par l'action « Raccorder ». Celle-ci exige une distance d'au plus `LinkRange` cases (12 par défaut) et un écart d'au plus 1 étage. Elle consomme `Base.ElectricWire` à raison de 1 fil pour 4 cases, arrondi au-dessus, au moins 1. Il n'y a pas de câble visible en v0.1.

### 2.4 Recettes

Les noms de recette sont les clés de `Recipes.json` (`java/zombie/core/Translator.java:561-569`). Toutes ont `category = Electrical` et l'action `MakingElectrical`, comme `MakeTimer` (`recipes_traps.txt:99-121`).

| Recette | Niv. requis | Entrées (outils conservés entre crochets) | Sortie | XP Électricité |
|---|---|---|---|---|
| `LWMakeVoltageTester` | 1 | 1 `ElectronicsScrap`, 1 `ElectricWire`, 1 `LightBulb`, 1 `Base.Battery` ; [tournevis] | `VoltageTester` | 5 |
| `LWSalvageSolarCell` | 2 | 1 `Base.Calculator` ; [tournevis] | 1 `SolarCell` | 3 |
| `LWMakeSolarPanelKit` | 3 | 6 `SolarCell`, 1 `SheetMetal`, 2 `ElectricWire`, 4 `Screws`, 1 `Glue` ; [tournevis, pinces] | `SolarPanelKit` | 15 |
| `LWMakeSolarCellFromScrap` | 8 | 5 `ElectronicsScrap`, 1 `Aluminum` ; [pinces] | 1 `SolarCell` | 4 |
| `LWMakeInverterKit` | 5 | 4 `ElectronicsScrap`, 2 `Amplifier`, 3 `ElectricWire`, 1 `SmallSheetMetal`, 4 `Screws` ; [tournevis, pinces] | `InverterKit` | 25 |
| `LWMakeHeavyInverterKit` | 8 | 1 `InverterKit`, 4 `ElectronicsScrap`, 2 `Amplifier`, 2 `ElectricWire`, 1 `SheetMetal` ; [tournevis, pinces] | `HeavyInverterKit` | 30 |
| `LWMakeWindTurbineKit` | 6 | 2 `Speaker` (aimants), 3 `ElectricWire`, 4 `ElectronicsScrap`, 2 `SheetMetal`, 2 `MetalBar`, 1 `Pipe`, 6 `Screws` ; [tournevis, pinces, marteau] | `WindTurbineKit` | 30 |
| `LWMakeWaterWheelKit` (v0.2) | 7 | 8 `Plank`, 20 `Nails`, 2 `Speaker`, 3 `ElectricWire`, 4 `ElectronicsScrap`, 1 `MetalBar` ; [marteau, tournevis] | `WaterWheelKit` | 30 |
| `LWMakeDeepCycleBattery` | 6 | 2 `CarBattery1/2/3` (indifférent), 2 `ElectricWire`, 1 `ScrapMetal` ; [pinces] | `DeepCycleBattery` (charge 0, état = moyenne des deux) | 20 |

- **Apprentissage (à valider : D-6).** Pas de magazine de mod en v0.1. Chaque recette est connue automatiquement à son niveau requis (`AutoLearnAny = Electricity:n`, champ vanilla vu dans `recipes_traps.txt:99-121`).
- **Équilibrage voulu** : les calculatrices sont la porte d'entrée du solaire (phase 1). À partir du niveau 8, le joueur n'en dépend plus.

---

## 3. Production

### 3.1 Unités et pas de simulation

- **Puissance** en watts (W), **énergie** en kilowattheures (kWh). Le joueur ne voit que ces deux unités.
- **Pas de simulation** : le serveur calcule toutes les **10 minutes de jeu** (`architecture.md`, § 4). Énergie produite sur un pas = puissance × durée réelle écoulée en heures de jeu (1/6 h en général, davantage après une avance rapide).
- **Météo globale.** Toute la carte partage la même météo (NM-12) : deux panneaux posés au même endroit produisent autant. Seules comptent la pose (ciel ouvert, rive), l'état et le niveau de l'installateur.
- **Formule commune** :
  `P_réelle = P_nominale × facteur_source × facteur_état × facteur_pose × multiplicateur_sandbox`.
  - `facteur_état = 0,5 + 0,5 × état/100` : un appareil usé produit moins avant de tomber en panne.
  - `facteur_pose` vient du niveau d'Électricité de l'installateur (§ 4.3).
  - Un appareil d'état 0 est en panne et produit 0.

### 3.2 Solaire

`facteur_source = S(t) × (1 − 0,8 × nuages) × (1 − neige_sur_panneau)`

- **Courbe du jour** : `S(t) = max(0, sin(π × (t − aube) / (crépuscule − aube)))`.
  - `t` = heure décimale (`getGameTime():getTimeOfDay()`).
  - `aube` et `crépuscule` viennent de `getClimateManager():getSeason():getDawn()/getDusk()`, en heures décimales (`java/zombie/erosion/season/ErosionSeason.java:165-195`). Ne pas utiliser `getGameTime():getDawn()`, qui est un entier figé (`java/zombie/GameTime.java:1154-1164`).
  - Le moteur ne calcule aucune hauteur du soleil (NM-12). Cette sinusoïde en tient lieu.
- **Nuages** : `getClimateManager():getCloudIntensity()`, de 0 à 1 (`java/zombie/iso/weather/ClimateManager.java`, NM-12). Par temps couvert, il reste 20 % de la production.
- **Neige sur le panneau** (règle de mod) :
  - quand `isSnowing()`, `neige_sur_panneau` gagne 0,1 par heure × intensité de neige, jusqu'à 1 ;
  - elle fond de 0,05 par heure si la température dépasse 0 °C (`getTemperature()`) ;
  - l'action « Déneiger le panneau » la remet à 0.
- **Puissance nominale** : 100 W pour le panneau en kit.
- **Ordres de grandeur**, pour un panneau neuf, ciel clair, `facteur_pose` = 1 :
  - durée du jour : environ 14,8 h au solstice d'été et 9,5 h au solstice d'hiver, à la latitude fixe de 38° (calcul astronomique à partir de `ErosionSeason.java:79-80` et de `ErosionConfig.java:425`) ;
  - l'intégrale de la sinusoïde vaut 2/π × durée du jour, soit **≈ 0,94 kWh par jour d'été** et **≈ 0,60 kWh par jour d'hiver** ;
  - ciel moyennement couvert (nuages = 0,5) : 60 % de ces valeurs.

### 3.3 Éolien

`facteur_source = f(v)`, avec `v = getWindspeedKph() × (1 + 0,15 × min(z, 3))`.

- `getWindspeedKph()` va de 0 à 120 km/h (`ClimateManager.java:514-516`, NM-12).
- Le bonus de hauteur est une règle de mod : +15 % par étage, jusqu'au 3e (posée sur un toit au niveau 2 : +30 %).

| Vent `v` | `f(v)` |
|---|---|
| < 10 km/h (démarrage) | 0 |
| 10 à 45 km/h | `((v − 10) / 35)³` |
| 45 à 85 km/h | 1 (puissance nominale) |
| > 85 km/h (tempête) | 0, frein automatique ; risque de dégât (§ 4.5) |

- **Puissance nominale** : 400 W.
- **Ordres de grandeur** : brise de 25 km/h → 400 × (15/35)³ ≈ **31 W** ; vent de 40 km/h → ≈ **252 W** ; tempête → arrêt.
- **Point incertain.** On ne connaît pas encore la répartition réelle du vent en jeu : la base est plafonnée à environ 78 km/h hors période météo (`java/zombie/iso/weather/ClimateValues.java:265-270`). Le prototype P5 relèvera le vent pendant plusieurs jours de jeu avant de figer ces seuils.

### 3.4 Hydraulique (v0.2)

`facteur_source = 1 × saison × gel`

- **Validation du site, à la pose seulement.**
  - La case de pose est de la terre au niveau 0.
  - Au moins une case voisine porte le drapeau `water` (`sq:getProperties():has(IsoFlagType.water)`, `media/lua/shared/Fishing/FishingUtils.lua:4-9`).
  - Cette case d'eau est dans une rivière selon `Fishing.isRiver(x, y)` (`media/lua/shared/Fishing/FishingZones.lua:40-47`).
  - Le courant moteur (`getFlow`) ne permet pas de distinguer rivière et lac (NM-13). Un lac ou un étang est refusé, avec un message.
- **Saison** (règle de mod) : printemps × 1,2 ; été × 0,8 ; automne × 1,0 ; hiver × 1,0 (`getClimateManager():getSeasonName()`).
- **Gel** : le moteur ne gèle jamais l'eau (NM-13). Option sandbox `LiveWire.RiverFreeze` (désactivée par défaut) : si la température reste sous −5 °C pendant 24 h, la roue s'arrête jusqu'à 12 h de dégel.
- **Puissance nominale** : 120 W, **jour et nuit**, soit ≈ **2,9 kWh par jour**. La roue est la source la plus régulière, mais elle est liée à la géographie (rivières de Knox).

### 3.5 Exemple de bilan d'une base

Base : un réfrigérateur-congélateur et 10 lumières, soit 170 W en continu en comptant la veille de l'onduleur (§ 5.1). Cela fait environ **4,1 kWh par jour**.

| Installation | Été (kWh/jour) | Hiver (kWh/jour) | Verdict |
|---|---|---|---|
| 4 panneaux | 3,8 | 2,4 | Déficit, surtout l'hiver |
| 6 panneaux + 1 éolienne (vent moyen 25 km/h, environ 0,7 kWh) | 6,3 | 4,3 | Juste suffisant |
| 1 roue à aubes + 2 panneaux | 4,8 | 4,1 | Stable |

---

## 4. Compétence Électricité

### 4.1 Paliers

Les niveaux vanilla vont de 0 à 10 (`Perks.Electricity`, `java/zombie/characters/skills/PerkFactory.java:83`). Le tableau intègre les idées de `IDEES.md` (« I-n ») selon le plan de versions du § 9.

| Niv. | Débloque (version) | Effet continu |
|---|---|---|
| 0 | Lire un testeur fabriqué par un autre : « alimenté / non alimenté » seulement | — |
| 1 | Testeur de tension (I-1, v0.1) | Lecture détaillée de la case (§ 5.4) |
| 2 | Cellules de calculatrice (v0.1) ; câbler un banc de batteries (I-6, v0.1) ; chargeur de piles (I-2, v0.2) | Usure des batteries −5 % |
| 3 | Panneaux photovoltaïques (I-9, v0.1) ; désarmer une alarme de maison (I-3, v0.3) | Rendement des panneaux qu'il installe : 0,85 |
| 4 | Réparer les appareils, dont les cuisinières (I-5, v0.2) ; reconditionner une batterie (v0.1) | Lecture de l'autonomie du réseau |
| 5 | **Onduleur** (I-6, v0.1) | Rendement de l'onduleur qu'il installe : 0,85 |
| 6 | Éolienne (I-9, v0.1) ; batterie stationnaire (v0.1) ; pompe électrique (I-7, v0.2) | Usure des batteries −10 % |
| 7 | Roue à aubes (I-9, v0.2) ; capteurs et alarme de base (I-4, v0.3) | Rendement de pose 0,95 |
| 8 | Onduleur renforcé ; cellules à partir de déchets (v0.1) ; clôture électrifiée (I-8, v0.4) | Chance d'échec de réparation divisée par 2 |
| 9-10 | Onduleur relais : raccorder un grand bâtiment (I-10, v0.4) | Rendement de pose 1,0 ; usure des appareils −25 % |

### 4.2 Expérience

L'expérience est **toujours donnée sur le serveur** (`addXp` est sans effet sur un client MP : `java/zombie/Lua/LuaManager.java:9300-9316`, `knowledge/combat-and-xp.md:24`). Pour comparaison, le vanilla donne 5 XP pour réparer un générateur (`ISFixGenerator.lua:71`) et 2 pour démonter de l'électronique (`recipes_electrical.txt:37-81`).

| Geste | XP | Limite |
|---|---|---|
| Recette du mod | colonne XP du § 2.4 | — |
| Installer un appareil | 10 (panneau), 20 (éolienne, roue), 25 (onduleur) | — |
| Raccorder un appareil | 3 | — |
| Inspecter un appareil (action de 5 s) | 2 | 1 fois par appareil et par jour de jeu |
| Mesurer au testeur | 1 | 1 fois par case et par heure de jeu |
| Réparer un appareil | 5 + 1 par point de dégât réparé, au plus 15 | — |
| Reconditionner une batterie | 8 | — |
| Réarmer un onduleur disjoncté **en ayant corrigé la surcharge** | 5 | 1 fois par heure |

### 4.3 Effets du niveau à l'installation

- **Rendement de pose**, enregistré sur l'appareil au moment de l'installation : 0,85 (niv. 3 à 6), 0,95 (niv. 7-8), 1,0 (niv. 9-10).
  - **Réinstaller pour en profiter.** Un électricien qui progresse peut démonter puis réinstaller l'appareil pour améliorer son rendement.
- **Échec d'installation** : chance = `max(0, 30 − 5 × (niveau − niveau_requis))` %.
  - Un échec fait perdre le temps de l'action et 10 points d'état au kit.
  - Il ne se produit jamais au-delà de 6 niveaux au-dessus du niveau requis.

### 4.4 Usure

Chaque appareil a un **état** de 0 à 100.

| Appareil | Usure normale | Accélérateurs |
|---|---|---|
| Panneau | −1 par 10 jours de jeu | Grêle, tempête : 1 chance sur 20 par heure d'orage de perdre 5 |
| Éolienne | −1 par 4 jours de jeu | Vent > 85 km/h : 1 chance sur 6 par heure de perdre 5 à 15. Ignoré si le frein a été posé (niv. 7 et plus, réglage gratuit à l'inspection). |
| Roue à aubes | −1 par 5 jours de jeu | Gel (si l'option est active) : −5 au dégel |
| Onduleur | −1 par 7 jours de jeu | Chaque disjonction : −3 |
| Batterie | voir ci-dessous | — |

**Batteries (règle de mod).**
- La charge est portée par les utilisations de l'objet (`getCurrentUsesFloat`, de 0 à 1, `java/zombie/inventory/types/DrainableComboItem.java:91-100`). L'usure est portée par son état.
- Usure par cycle équivalent complet (1 capacité nominale déchargée) : `100 / durée_de_vie` points d'état.
  - Batterie de voiture : durée de vie de 150 cycles.
  - Batterie stationnaire : 600 cycles.
- Une décharge en dessous de 20 % double l'usure du pas.
- **Capacité effective** = `capacité_nominale × (0,4 + 0,6 × état/100)`.
- Une batterie d'état 0 est **morte** : elle ne stocke plus rien.
- Autodécharge : 0,2 % de la charge par jour.

**Capacités nominales.** Les trois batteries vanilla ont le même `UseDelta`. Leur capacité est donc une règle de mod (`drainable.txt:2336-2390`).

| Batterie | Capacité nominale |
|---|---|
| `Base.CarBattery1` | 0,40 kWh |
| `Base.CarBattery2` | 0,60 kWh |
| `Base.CarBattery3` | 0,90 kWh |
| `LiveWire.DeepCycleBattery` | 1,50 kWh |

### 4.5 Pannes et réparation

- **Panne** quand l'état atteint 0 : l'appareil produit 0 ; l'onduleur s'arrête.
- **Réparer** (action « Réparer », appareil arrêté ou en panne) :
  - consomme 1 `ElectronicsScrap` et 1 `ElectricWire` ;
  - rend `5 + niveau` points d'état ;
  - échoue avec une chance de `max(5, 40 − 5 × niveau)` % : la pièce est perdue, l'état reste le même ;
  - impossible au-delà de 90 : il faut « Remettre à neuf », niv. 8, avec 4 `ElectronicsScrap` et 2 `ElectricWire`, qui ramène à 100.
- **Reconditionner une batterie** (niv. 4, batterie hors du banc) :
  - consomme 1 `ElectronicsScrap` et 0,5 l d'eau ;
  - rend +15 points d'état, sans dépasser 80 ;
  - une batterie morte ne se reconditionne pas.
- **Disjonction de l'onduleur.** Si la demande dépasse sa puissance maximale (§ 5.1) au moment d'un pas de simulation :
  - l'onduleur s'éteint ;
  - il perd 3 points d'état ;
  - le joueur proche reçoit le message « L'onduleur a disjoncté (surcharge) » ;
  - il faut l'action « Réarmer ».

---

## 5. Stockage, distribution et consommation

### 5.1 L'onduleur

- **Ce que c'est.** L'onduleur est un vrai générateur du moteur, piloté par le mod. Le jeu le traite comme un générateur pour l'alimentation :
  - **portée** : `GeneratorTileRange` cases (20 par défaut) et ±`GeneratorVerticalPowerRange` étages (3), réglages globaux du serveur (`java/zombie/SandboxOptions.java:248-249`) ;
  - **consommation** : celle des appareils dans cette portée.
- **Il est silencieux pour les zombies** : bruit de rayon 1 et de volume 1 (NM-2). **Les joueurs proches entendent quand même un ronronnement de générateur** tant qu'aucune tuile propre n'existe (NM-2, D-2).
- **Il se pose dehors, sur une case sans pièce**, par exemple contre un mur extérieur ou sous un auvent ouvert, pour ne jamais intoxiquer la maison (NM-4). L'action « Installer » refuse toute case intérieure, avec un message.
- **Caractéristiques.** Rendement de pose : § 4.3.

| | Onduleur | Onduleur renforcé |
|---|---|---|
| Puissance maximale | 1 500 W | 3 000 W |
| Consommation à vide | 20 W | 20 W |

  La consommation à vide correspond à la base de 0,02 du moteur (`IsoGenerator.java:253`), à l'échelle du § 5.3.
- **Plusieurs onduleurs.** Un réseau n'a qu'un onduleur en v0.1. Les relais viendront en v0.4.

### 5.2 Les batteries : dans l'onduleur, ou dans un banc câblé

- **Dans l'onduleur.** L'onduleur a un **compartiment intégré**. Le joueur l'ouvre comme une caisse et y range ses batteries de voiture (`Base.CarBattery1/2/3`) ou ses batteries stationnaires. C'est le cas courant : un seul objet à poser, rien à câbler.
  - Le compartiment est le conteneur du sprite de substitution. Le moteur ne le crée pas tout seul pour un générateur : c'est le mod qui le crée (`architecture.md`, § 1.4).
  - Sa taille est celle du meuble de substitution. Le stock doit aussi rester borné par le jeu : 4 batteries au plus, les suivantes sont ignorées et signalées.
  - À confirmer au prototype P1 : un conteneur porté par un générateur se comporte comme un conteneur ordinaire, transferts MP compris (hypothèse).
- **Dans un banc câblé** (facultatif). Un meuble conteneur vanilla, **câblé** à l'onduleur, ajoute de la place pour les grosses installations.
- **Stock du réseau** : toutes les batteries reconnues du compartiment et des bancs câblés.
- **Autres objets.** Un objet qui n'est pas une batterie peut être rangé dans le compartiment, mais il n'est pas compté.
- **Charge et décharge uniformes** : à chaque pas, le surplus est réparti entre les batteries au prorata de la place libre, et le déficit au prorata de la charge.
- Rendement de charge : 0,90. Rendement de décharge : celui de l'onduleur.
- Un joueur peut ajouter ou retirer une batterie à tout moment : le stock est recalculé au pas suivant.
- **Surplus perdu.** Si les batteries sont pleines, le surplus est perdu : le tableau de bord affiche « Production perdue ».

### 5.3 Consommation : mesurée par le jeu

- **Mesure.** Le mod ne devine pas la consommation : il lit celle que le moteur calcule pour l'onduleur (`getTotalPowerUsing`, NM-5) et la convertit en watts.
- **Échelle** : 1 unité moteur par heure = **1 000 W** × `LiveWire.PowerScale` (1,0 par défaut). Cela donne :

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

  Ces valeurs sont confirmées statiquement (NM-5). L'échelle est une **décision à valider (D-5)**.
- **Bilan d'un pas** : `stock += (production × 0,9 − consommation / rendement_onduleur) × Δt`, borné par la capacité.
- **Lien avec le carburant.** Le carburant moteur de l'onduleur reflète le stock (§ 3 de `architecture.md`). Le joueur n'a jamais à le remplir, et le menu vanilla est masqué.
- **Stock vide** : l'onduleur s'éteint, le courant disparaît. Il se rallume seul quand le stock dépasse 2 % de la capacité.

### 5.4 Le testeur de tension (diagnostic)

| Niveau | Ce qu'affiche « Mesurer » sur une case |
|---|---|
| 0 | « Courant : oui / non » |
| 1+ | Source : réseau public (`hasGridPower`), générateur ou onduleur Live Wire (`haveElectricity`, `java/zombie/iso/IsoGridSquare.java:8223-8228`) |
| 2+ | Consommation de l'appareil visé (`getGeneratorPowerConsumption`, convertie en W) |
| 4+ | Pour l'onduleur visé : production, demande, stock et autonomie estimée (heures) |

**Avertissement de recouvrement** : « plusieurs sources alimentent cette zone, chacune paie les appareils communs ». Ce comportement du moteur est expliqué au § 8.

---

## 6. Interface

### 6.1 Menus contextuels (clic droit dans le monde)

Toutes les options vont dans un sous-menu **« Live Wire »**. Une option impossible est grisée, avec une infobulle qui dit pourquoi (niveau, outil, pièce manquante).

| Sur… | Options |
|---|---|
| Une case quelconque, testeur en inventaire | Mesurer |
| Un kit en inventaire, case visée | Installer ici (avec l'aperçu « case valide / invalide » et la raison) |
| Un appareil Live Wire | Inspecter · Raccorder à un onduleur · Débrancher · Réparer · Remettre à neuf · Déneiger (panneau) · Démonter |
| L'onduleur | Ouvrir le tableau de bord · Allumer / Éteindre · Réarmer (après disjonction) · Inspecter · Réparer · Démonter |
| L'onduleur (compartiment) | Ouvrir le compartiment : c'est l'ouverture de conteneur vanilla, avec les transferts d'objets habituels |
| Un meuble conteneur | Câbler comme banc de batteries · Décâbler |
| Une batterie hors du banc | Reconditionner |

Les options vanilla « Générateur » (infos, allumer, brancher, remplir, réparer, ramasser) n'apparaissent **jamais** sur l'onduleur. Les options « Ramasser », « Démonter » et « Détruire » vanilla sont refusées sur tous les appareils Live Wire (`architecture.md`, § 2.4).

### 6.2 Tableau de bord du réseau

Une fenêtre déplaçable, ouverte depuis l'onduleur. Elle est mise à jour toutes les 10 minutes de jeu tant qu'elle est ouverte et que le joueur reste à moins de 30 cases.

- **En-tête** : nom du réseau (modifiable), état de l'onduleur (marche, arrêt, disjoncté, en panne).
- **Production** : une ligne par appareil (type, état, puissance actuelle) et un total.
- **Consommation** : la demande actuelle, en watts, avec la puissance maximale de l'onduleur.
- **Stock** : barre de charge, en kWh et en %. Nombre de batteries, dont usées (état < 30).
- **Autonomie** : « environ N h au rythme actuel », seulement au niveau 4 et plus.
- **Alertes** : surcharge proche (> 90 %), batteries usées, appareil en panne, production perdue.

### 6.3 Textes à traduire

Les clés suivent les préfixes imposés par `CLAUDE.md`. Liste complète dans `architecture.md`, § 7.

| Famille | Fichier | Exemples de clés |
|---|---|---|
| Objets | `ItemName.json` | `LiveWire.VoltageTester`, `LiveWire.SolarPanelKit`, `LiveWire.InverterKit` |
| Recettes | `Recipes.json` | `LWMakeVoltageTester`, `LWMakeInverterKit` |
| Menus | `ContextMenu.json` | `ContextMenu_LW_Root`, `ContextMenu_LW_Install`, `ContextMenu_LW_Measure`, `ContextMenu_LW_Reset` |
| Infobulles | `Tooltip.json` | `Tooltip_LW_NeedOutdoor`, `Tooltip_LW_NeedNoRoom`, `Tooltip_LW_NeedRiver`, `Tooltip_LW_NeedLevel` |
| Interface | `IG_UI.json` | `IGUI_LW_Dashboard_Title`, `IGUI_LW_Production`, `IGUI_LW_Autonomy`, `IGUI_LW_Tripped` |
| Options | `Sandbox.json` | `Sandbox_LiveWire`, `Sandbox_LiveWire_PowerScale`, `…_tooltip` |

**Vocabulaire FR** repris du vanilla : « Électricité » pour la compétence (`IGUI_perks_Electricity`, `media/lua/shared/Translate/FR/IG_UI.json:214`), « générateur », « brancher », « coupure d'électricité » (`FR/Sandbox.json`, `ContextMenu.json`).

---

## 7. Options sandbox

Page `LiveWire`. Toutes les valeurs ci-dessous sont proposées par défaut, et l'ensemble est **à valider**.

| Option | Type | Bornes | Défaut | Effet |
|---|---|---|---|---|
| `LiveWire.PowerScale` | réel | 0,1 – 10 | 1,0 | Multiplie l'échelle « 1 unité moteur par heure = 1 000 W » (§ 5.3) : 2,0 rend chaque appareil deux fois plus gourmand |
| `LiveWire.SolarMultiplier` | réel | 0 – 10 | 1,0 | Production solaire |
| `LiveWire.WindMultiplier` | réel | 0 – 10 | 1,0 | Production éolienne |
| `LiveWire.HydroMultiplier` | réel | 0 – 10 | 1,0 | Production hydraulique |
| `LiveWire.BatteryCapacityMultiplier` | réel | 0,1 – 10 | 1,0 | Capacité de toutes les batteries |
| `LiveWire.BatteryWearMultiplier` | réel | 0 – 10 | 1,0 | 0 = pas d'usure |
| `LiveWire.DeviceWearMultiplier` | réel | 0 – 10 | 1,0 | 0 = pas d'usure |
| `LiveWire.LinkRange` | entier | 4 – 30 | 12 | Distance maximale de raccordement (cases) |
| `LiveWire.WirePerTiles` | entier | 0 – 20 | 4 | Cases par fil électrique ; 0 = câblage gratuit |
| `LiveWire.StormDamage` | booléen | — | vrai | Dégâts de tempête et d'orage |
| `LiveWire.RiverFreeze` | booléen | — | faux | Gel des roues à aubes |
| `LiveWire.XPMultiplier` | réel | 0 – 10 | 1,0 | Expérience donnée par le mod (s'ajoute au multiplicateur vanilla) |
| `LiveWire.SkillGates` | booléen | — | vrai | Faux = aucun niveau requis (parties détendues) |
| `LiveWire.SimulateUnloaded` | booléen | — | vrai | Production, consommation et usure continuent quand personne n'est à proximité |

- **Fichier** : `media/sandbox-options.txt`. Un seul fichier par mod est lu, sous `42.21/` sinon sous `common/` (`java/zombie/sandbox/CustomSandboxOptions.java:33-48`, `knowledge/mod-loading.md:146-152`).
- **Lecture des valeurs** : sur le serveur, `getSandboxOptions():getOptionByName("LiveWire.X"):getValue()`.

---

## 8. Multijoueur et compatibilité

### 8.1 Le multijoueur vu du joueur

- **Le serveur décide de tout** : production, stock, état, pannes et expérience. Un client modifié ne peut pas se donner de l'énergie (`architecture.md`, § 5).
- **Une installation est commune** : tout joueur proche peut lire le tableau de bord et utiliser les menus. Les droits d'une safehouse s'appliquent (option vanilla `safehouseAllowInteract`, `media/lua/client/ISUI/ISWorldObjectContextMenu.lua:211-214`). Il n'y a pas de propriétaire en v0.1 (**à valider : D-7**).
- **Latence** : une action (installer, raccorder, réarmer) prend effet à la réponse du serveur. Le tableau de bord peut avoir jusqu'à 10 minutes de jeu de retard.
- **Absence de tous les joueurs** : l'installation continue de vivre si `SimulateUnloaded` est actif. Si le serveur est mis en pause quand il est vide (option `PauseEmpty`), le temps s'arrête et l'installation aussi (`knowledge/api-42-21.md:177`).

### 8.2 Compatibilité avec les générateurs vanilla

- **Ils restent intacts** : même menu, même carburant, même bruit. Live Wire ne touche que ses propres générateurs, reconnus par une marque ModData (`knowledge/power-and-lights.md:188-192`).
- **Recouvrement.** Un générateur vanilla et un onduleur qui couvrent les mêmes appareils les paient **tous les deux** : le moteur n'exclut que les appareils déjà alimentés par le réseau public (NM-5). Le testeur avertit (§ 5.4). La bascule automatique (onduleur en veille quand un générateur vanilla tourne) est prévue en v0.2.
- **Options globales partagées.** `GeneratorTileRange`, `GeneratorVerticalPowerRange`, `GeneratorFuelConsumption` et `AllowExteriorGenerator` s'appliquent aussi à l'onduleur.
  - `GeneratorFuelConsumption` ne change pas l'énergie du mod : le mod divise par cette option (NM-5).
  - Si l'option vaut 0, le mod mesure lui-même la consommation (`architecture.md`, § 1.3).
- **Autres mods d'énergie.** Aucune dépendance et aucun code repris (`CLAUDE.md`). La coexistence avec un mod qui crée aussi des générateurs est probable, mais non vérifiée : deux mods qui intercepteraient les mêmes menus vanilla pourraient se gêner (`architecture.md`, risque R-9).

---

## 9. Périmètre des versions

Le tableau décide du sort des 10 idées de `IDEES.md` : chacune est intégrée à une version ou reportée explicitement. Il est **à valider (D-1)**.

| Version | Contenu | Idées |
|---|---|---|
| **0.1 — Socle de production** | Testeur de tension ; banc de batteries (batteries vanilla et stationnaire) ; onduleur et onduleur renforcé ; panneaux photovoltaïques ; éolienne ; tableau de bord ; usure, pannes, réparation, reconditionnement ; paliers et expérience ; options sandbox ; EN et FR ; MP dédié | I-1, I-6, I-9 (solaire et éolien) |
| **0.2 — Base autonome** | Roue à aubes ; charge du banc depuis un générateur vanilla ou le réseau public, en prélevant le carburant du générateur source ; bascule automatique ; chargeur de piles (classe vanilla `IsoCarBatteryCharger`, NM-14) ; réparation des cuisinières et micro-ondes (vrai état « cassé », NM-16) ; pompe électrique qui remplit un récupérateur placé au-dessus d'éviers raccordés à l'eau (`IsoObject:addFluid`, `java/zombie/iso/IsoObject.java:2700-2721`) | I-2, I-5 (partiel), I-7, I-9 (hydro) |
| **0.3 — Sécurité** | Désarmer l'alarme d'une maison (`BuildingDef:setAlarmed`, sur le serveur, NM-15) ou d'un véhicule (`BaseVehicle:setAlarmed`) ; capteurs de mouvement reliés à une lumière ou une sirène de base | I-3, I-4 |
| **0.4 — Fin de partie** | Clôture électrifiée (forte consommation, renversement des zombies) ; onduleurs relais pour alimenter un bâtiment au-delà de 20 cases | I-8, I-10 |
| **Reportées sans date** | Dynamo à vélo : pas de vélo vanilla, l'idée reste ouverte en manivelle (endurance contre courant, `CharacterStat.ENDURANCE`). Réparation des réfrigérateurs, télévisions et radios en panne : le froid d'un réfrigérateur ne peut pas être bloqué depuis Lua (NM-16). Panneaux « récupérés sur les toits » : aucune tuile solaire vanilla n'a été trouvée (hypothèse) | I-9 (vélo), I-5 (réfrigérateurs) |
| **Après les modèles définitifs** | Tuiles et modèles Blender ; son propre de l'onduleur (silence réel pour les joueurs, NM-2) ; câbles visibles | — |
