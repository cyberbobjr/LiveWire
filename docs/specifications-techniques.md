# Live Wire — spécifications techniques

Contrats techniques du mod tels qu'ils existent dans le code de la **version 1.6.1** (relevé initial du 2026-10-21, actualisé le 2026-10-25, `Contents/mods/batman_LiveWire/42.21`). Ce document fait foi pour les identifiants, formats et bornes ; les justifications sont dans [`architecture.md`](architecture.md), le comportement vu du joueur dans [`specifications-fonctionnelles.md`](specifications-fonctionnelles.md).

Toute modification d'un identifiant de ce document (type d'objet, clé de ModData, nom de modèle, nom de commande, nom d'option) casse les sauvegardes ou le multijoueur : elle exige une migration (§ 4.4).

---

## 1. Mods, versions et chargement

| Mod | `id` | Dossier | `require` | Rôle |
|---|---|---|---|---|
| Live Wire | `batman_LiveWire` | `Contents/mods/batman_LiveWire/42.21` | — | Mod principal |
| Live Wire - Viewpoint models | `batman_LiveWireViewpoint` | `Contents/mods/batman_LiveWireViewpoint/42.21` + `common` | `\batman_LiveWire` | Modèles 3D pour Project Viewpoint (facultatif) |

- `versionMin=42.21`, `modversion=1.5.0` dans les deux `mod.info`. Objet Workshop : `3821807453` (`workshop.txt`).
- Le mod principal déclare `pack=batman_livewire_01` et `tiledef=batman_livewire_01 7174`.
- Constantes de code (`media/lua/shared/LiveWire/LW_Core.lua`) : module réseau `LiveWire.MODULE = "LiveWire"`, schéma du registre `LiveWire.SCHEMA = 2`, pas nominal de simulation `STEP_HOURS = 1/6` (`EveryTenMinutes`). `LiveWire.VERSION = "1.5.0"`, alignée sur les deux `mod.info` et vérifiée par `tools/check_mod.py`.
- Côtés : `shared` (définitions, physique, protocole, actions chronométrées), `server` (registre, simulation, commandes ; chaque fichier commence par `if isClient() then return end`), `client` (menus, écrans, sons). Détail des modules : [`architecture.md`](architecture.md) § 2.

## 2. Objets et scripts

### 2.1 Objets d'inventaire (`media/scripts/LiveWire_items.txt`, module `LiveWire`)

| Type complet | `ItemType` | Poids | Usage |
|---|---|---|---|
| `LiveWire.VoltageTester` | `base:normal` | 0,6 | Testeur de tension (lecture de l'état d'un appareil) |
| `LiveWire.SolarCell` | `base:normal` | 0,1 | Ingrédient du panneau solaire |
| `LiveWire.DeepCycleBattery` | `base:drainable` | 12,0 | Batterie à décharge profonde (`ConditionMax = 100`, `KeepOnDeplete`) |
| `LiveWire.SoundproofKit` | `base:normal` | 13,0 | Kit d'insonorisation d'un onduleur |
| `LiveWire.CouplingKit` | `base:normal` | 0,7 | Kit de couplage d'un onduleur esclave |
| `LiveWire.MonitorDisk` | `base:normal` | 0,1 | Disque du logiciel pour le Computer Mod |

### 2.2 Appareils posés (`LiveWire_moveables.txt`, module `Base`, et `LW_Defs.lua`)

Chaque appareil est une tuile de la feuille `batman_livewire_01` ; l'objet d'inventaire est un `base:moveable` posé au curseur de meubles vanilla. Pose, rotation et ramassage demandent un tournevis (`PlaceTool = Electrician`, `PickUpTool = Electrician`, D-59), sans niveau : la tuile ne porte pas de `PickUpLevel`. Le niveau d'Électricité est vérifié au **branchement** (`Defs.devices.*.level`, D-29). Le **nom de modèle** est la clé stockée dans le registre : ne jamais le renommer.

**Poids** : `PickUpWeight / 10` de la tuile (`Moveable.java:145-150`), sauf l'éolienne et, depuis 1.8.0, la roue à aubes, dont les tuiles portent `CustomItem` et qui prennent le `Weight` du script (`Moveable.java:129-134`). Le `Weight` de chaque script reprend celui de la tuile. Règle : jamais moins que la somme des composants de la recette (poids vanilla), relevé au poids réaliste à l'échelle du jeu. Panneau 9, éolienne 15, roue à aubes 30, onduleur 12, armoire onduleur 30, powerbank 10, tableau 3, alarme 1, pompe 8.

| Modèle (`Defs.devices`) | Objet posable | Rôle | Tuiles (index, orientations) | Chiffres | Niveau (branchement) | XP (1er branchement) | Usure (`wearDays`) |
|---|---|---|---|---|---|---|---|
| `SolarPanel` | `Base.Mov_LiveWire_SolarPanel` | `source` / `solar` | 0, 4 | 100 W nominal, dehors | 3 | 10 | 10 |
| `WindTurbine` | `Base.Mov_LiveWire_WindTurbine` | `source` / `wind` | 4, 4 | 400 W nominal, dehors | 2 | 20 | 4 |
| `WaterWheel` | `Base.Mov_LiveWire_WaterWheel` | `source` / `hydro` | 8, 4 | 120 W nominal, dehors, rivière | 2 | 20 | 6 |
| `Inverter` | `Base.Mov_LiveWire_Inverter` | `inverter` | 12, 4 | 1 500 W max, 20 W à vide | 3 | 25 | 5 |
| `PowerBank` | `Base.Mov_LiveWire_PowerBank` | `storage` | 16, 4 | 4 batteries comptées, conteneur `livewirepowerbank` (capacité 50) | 2 | 5 | 30 |
| `Breaker` | `Base.Mov_LiveWire_Breaker` | `option` / `breaker` | 20, 2 (mural) | — | 3 | 5 | 15 |
| `BatteryAlarm` | `Base.Mov_LiveWire_BatteryAlarm` | `option` / `alarm` | 22, 2 (mural) | alerte sous 20 %, réarmée à 25 %, rappel toutes les 2 h | 2 | 5 | 30 |
| `WaterPump` | `Base.Mov_LiveWire_WaterPump` | `pump` | 72, 4 | 250 W, 5 L/min | 3 | 20 | 10 |

- Tuile `batman_livewire_01_76` : réservoir relais transparent de la pompe (`Defs.RELAY_SPRITE`), jamais reconnu comme appareil.
- Objets vanilla raccordés (rôles du registre sans tuile du mod) : générateur vanilla en secours (`role = "backup"`, modèle `BackupGenerator`, niveau 2) et ordinateur de bureau vanilla de gestion (`role = "computer"`, modèle `ManagementComputer`, niveau 3 pour le branchement ; délestage sans niveau requis).

### 2.3 Batteries reconnues (`Defs.batteries`)

| Type | Capacité | Cycles de vie |
|---|---|---|
| `Base.CarBattery1` | 0,40 kWh | 150 |
| `Base.CarBattery2` | 0,60 kWh | 150 |
| `Base.CarBattery3` | 0,90 kWh | 150 |
| `LiveWire.DeepCycleBattery` | 1,50 kWh | 600 |

Constantes : rendement de charge 0,90 ; autodécharge 0,2 %/jour ; seuil de décharge profonde 20 % ; redémarrage à 2 % du stock ; lissage des sources τ = 0,5 h ; perte d'état à la disjonction sans disjoncteur 3 ; forte charge au-delà de 80 % ; usure ×1,25 d'un onduleur insonorisé. Rendement d'installation (niveau de celui qui branche, D-29) : 0,85 (niveau < 7), 0,95 (7-8), 1,0 (9-10). Échec de réparation : `max(5, 40 − 5 × niveau)` %, divisé par deux dès le niveau 8.

### 2.4 Recettes (`LiveWire_recipes.txt`, module `LiveWire`, catégorie `Electrical`)

`LWMakeVoltageTester`, `LWDismantleVoltageTester`, `Base.DismantleElectronics` du jeu, non redéfinie : son OnCreate `RecipeCodeOnCreate.dismantleFlashlight` est enveloppé par `LW_Recipes.lua` (effet vanilla, puis une cellule par calculatrice ; une recette redéfinie ajouterait ses entrées à celle du jeu), `LWMakeSolarCellFromScrap`, `LWMakeSolarPanelKit`, `LWMakeInverterKit`, `LWMakeWindTurbineBlades`, `LWMakeWindTurbineMast`, `LWMakeWindTurbineKit`, `LWMakeWaterWheel`, `LWMakePowerBankKit`, `LWMakeBreakerKit`, `LWMakeWaterPump`, `LWMakeCouplingKit`, `LWMakeDeepCycleBattery`, `LWMakeBatteryAlarmKit`, `LWMakeSoundproofKit`, `LWDismantleWindTurbineBlades`, `LWDismantleWindTurbineMast`, `LWDismantleDeepCycleBattery`. Ingrédients et niveaux : tableau généré [`wiki/fr/_tables.md`](wiki/fr/_tables.md) (`tools/make_doc_tables.py`, données de `tools/make_doc_images.RECIPES`).

### 2.5 Autres scripts

- `LiveWire_sounds.txt` (module `Base`) : `LiveWireInverterHum` joue le fichier du mod `media/sound/LiveWireInverterHum.ogg` (volume 0,045, distances min/max 1/2) ; `LiveWirePumpHum`, `media/sound/LiveWirePumpHum.ogg` (0,05, 1/4), produits par `source/sound/make_hum.sh` et `make_pump.sh`. Les événements vanilla `Object/CarBatteryCharger/Running` et `Object/ClothingWasher/Running`, utilisés du 2026-11-02 au 2026-11-13, jouaient (`isPlaying` vrai) mais restaient inaudibles en jeu, même au volume 1,0 et sans distance imposée (constaté en jeu par l'utilisateur, 2026-11-13). Le réglage de volume Live Wire est conservé. Le mixage des effets, la spatialisation et l'atténuation sont natifs ; aucun contrôle Lua de distance ou d'étage. `LW_Hum.sync` adapte seulement les marques marche/arrêt et insonorisation, depuis la découverte et la réconciliation visuelle existantes (environ 1 s pour une marque modifiée). Suppression, déchargement et fin de session nettoient les boucles. Le bip garde un OnTick temporaire pendant ses trois secondes, retiré après le dernier bip.
- `LiveWire_models.txt` : modèles au sol provisoires des objets d'inventaire (`media/models_X/LiveWire/*.glb`).
- Butin : `media/lua/server/Items/LiveWire_Distributions.lua` (listes `ProceduralDistributions`) ; le disque `MonitorDisk` n'est ajouté que si le Computer Mod est actif. Tableau des chances : [`wiki/fr/09-tables-de-butin.md`](wiki/fr/09-tables-de-butin.md).

### 2.6 Actions chronométrées (`shared/LiveWire/TimedActions/LW_TimedActions.lua`)

`LWLinkAction` (raccorder, consomme le fil), `LWCoupleAction` (coupler un esclave), `LWLinkBarrelAction` (raccorder un baril, consomme un `Base.MetalPipe`), `LWRepairAction`, `LWInspectAction`, `LWMuffleAction` (insonoriser), `LWClearSnowAction`, `LWMeasureAction` (testeur), `LWReconditionAction`. Leur `complete()` s'exécute sur l'autorité et revérifie distance, niveau et objets.

LiveWire Extended ajoute `LWXEnlargeAction` (`shared/LiveWireExtended/TimedActions/LWX_TimedActions.lua`, base `LWBaseAction`,
durée 300, sujet `target`, orientation vers l'objet ; D-55). Son `complete()` appelle `X.Panels.enlarge`
(`server/LiveWireExtended/LWX_Panels.lua`, `PS.enlarge`), qui revérifie `P.enlargeCheck` (`shared/LiveWireExtended/LWX_Panel.lua` :
tournevis, niveau `X.LEVEL` = 3, `P.ENLARGE_COST` = 1 `Base.SmallSheetMetal` et 4 `Base.Screws`), consomme les matériaux
(`LiveWire.API.consume`), pose la tuile `batman_livewireext_01_<indice + 2>` (`setSpriteFromName`, puis
`transmitUpdatedSpriteToClients` sur serveur dédié) et met `record.size` à jour avant de transmettre. `P.enlargedIndex` :
tuiles 8-9 vers 10-11 (8 vers 16 modules), tuiles 10-11 vers 12-13 (16 vers 24), rien au-delà de `P.MAX_SIZE` = 24. Les
coffrets vanilla `industry_02_*` ne portent pas de tuile `batman_livewireext_01` : ils n'ont pas l'action. `record.size` se relit
de la tuile au raccordement (`kind.onLink` → `P.size`), donc une reconstruction (`X.Recovery`, `SL.restore`) garde la
taille agrandie.

## 3. Commandes réseau

Module `"LiveWire"` (`LW_Protocol.lua`). Client → serveur par `sendClientCommand` (`LW_ClientState.lua`, `Client.send`), traitées par `OnClientCommand` dans `server/LiveWire/LW_Commands.lua`.

Un argument de position `{ x, y, z }` se lit par `Protocol.parsePos(args)` : trois entiers (nombres ou chaînes numériques,
arrondis vers le bas), `|x|` et `|y|` au plus 1 000 000, étage de -32 à 31 ; `nil` sinon (champ absent, non numérique,
`NaN`, infini, hors bornes). La règle de refuge se lit par `Commands.canTouch(player, sq)`. Les codes de refus sont les
valeurs de `Commands.ERR` (`INVALID`, `TOO_FAR`, `SAFEHOUSE`, `NEED_SCREWDRIVER`) : chacune est la clé de traduction
envoyée au client.

### 3.1 Contrôles communs (serveur)

1. Registre prêt et non en lecture seule ; joueur présent et vivant.
2. Débit : au plus **4 commandes par seconde réelle et par compte** ; l'excédent est ignoré (un seul avertissement journalisé).
3. Identifiants : chaîne de 32 caractères au plus, motif `^d%d+$` (appareil) ou `^g%d+$` (réseau).
4. `checkDevice` : appareil connu, case chargée, distance de Tchebychev ≤ 3 cases au même étage (`floor(getZ())`), règle de refuge `SafeHouse.isSafehouseAllowInteract`. Refus = `notify` avec une clé `Tooltip_LW_Invalid`, `Tooltip_LW_TooFar` ou `Tooltip_LW_Safehouse`, `bad = true`.
5. Gestionnaire exécuté sous `pcall` ; une erreur est journalisée en anglais.

### 3.2 Client → serveur

| Commande | Arguments | Contrôles propres | Effet |
|---|---|---|---|
| `subscribe` | `{ inverter, via? }` | onduleur à 30 cases au plus et à `verticalRange()` étages au plus, **ou** `via` valide (ci-dessous) | Abonne au tableau de bord ; renvoie un `snapshot` |
| `unsubscribe` | `{ inverter }` | — | Désabonne |
| `unlink` | `{ device }` | à 3 cases de l'appareil **ou** de l'onduleur de son réseau | Débranche ; un générateur ou ordinateur vanilla sort du registre |
| `uncouple` | `{ inverter }` | esclave couplé | Le rend indépendant (nouveau réseau vide), rend `LiveWire.CouplingKit` |
| `unlinkBarrel` | `{ pump, x, y, z }` | baril raccordé à cette pompe | Débranche le baril, rend `Base.MetalPipe` |
| `setInverter` | `{ inverter, on, via? }` | `on` booléen ; `checkDevice` sur l'onduleur **ou** `via` valide | `off` → `on`, ou `on`/`tripped` → `off` |
| `reset` | `{ inverter, via? }` | `checkDevice` sur l'onduleur **ou** `via` valide ; onduleur `tripped` (un esclave renvoie au maître) ; demande mesurée ≤ capacité | `state = "on"`, 1 XP limité par appareil |
| `resetBreaker` | `{ device }` | disjoncteur `tripped` ; demande ≤ capacité | `state = "ok"` |
| `ackAlarm` | `{ device }` | alarme sonnante | `grid.alarmAck = true` |
| `rename` | `{ inverter, name, via? }` | nom nettoyé (caractères de contrôle retirés, 24 caractères), proximité de l'onduleur ou ordinateur raccordé alimenté via `checkVia`, safehouse | Renomme le réseau depuis le menu de l'onduleur ou l'onglet Équipements du logiciel ; vide efface le nom |
| `adopt` | `{ x, y, z }` | à 40 cases et 3 étages au plus ; refuge | Enregistre une tuile Live Wire posée sans marque valide |
| `debug` | `{ action, device }` | `Debug.allowed` (§ 3.4) | Action de debug |
| `setBrake` | `{ device, brake }` | éolienne, booléen, distance et safehouse via `checkDevice` ; aucun niveau d'Électricité | Frein explicite réversible ; production nulle lorsqu'il est serré |
| `resumeBackup` | `{ device }` | générateur de secours, distance et safehouse via `checkDevice` | Quitte le mode manuel, reprend l'hystérésis automatique |

`via = { x, y, z }` : position de l'ordinateur sur lequel tourne le logiciel de gestion (`SoftwareApp:via()`). `Commands.checkVia` l'accepte si un ordinateur de gestion (`role = "computer"`) du réseau de l'onduleur est sur cette case, alimenté (`Computer.powered`), si le joueur est à 6 cases au plus de cette case au même étage (`Commands.SOFTWARE_RANGE`, distance de fermeture de l'écran) et si la règle de refuge l'autorise sur cette case. Un ordinateur du Computer Mod non raccordé par câble n'a pas d'entrée au registre : ses commandes restent soumises à `checkDevice`.

Les actions longues (raccorder, réparer, inspecter…) ne sont pas des commandes : ce sont les actions chronométrées du § 2.6.

### 3.3 Serveur → client

| Commande | Arguments | Usage |
|---|---|---|
| `snapshot` | instantané du réseau (§ 3.5) | Aux abonnés, après chaque pas ou changement |
| `notify` | `{ key, args, bad }` | Message à traduire côté client (`args` remplace `%1`, `%2`… ; une valeur peut elle-même être une clé, par exemple `IGUI_LW_Model_<modèle>`) |
| `beep` | `{ x, y, z }` | Bip de l'alarme de batterie faible |

Diffusion supplémentaire : `ModData.transmit("LiveWireAnchors")` à chaque changement d'ancre ; `transmitModData()` des objets marqués.

### 3.4 Debug et administration

`LW_Debug.lua`, `LW_DebugCommands.lua`. Autorisé : en solo avec `isDebugEnabled()` ; sur serveur, `checkPermissions(joueur, Capability.ChangeAndReloadServerOptions)` **et** `getRole():hasCapability(...)`. Portée 30 cases. `removeRelays` pose `data.pumpsDisabled = true` (registre) : `Pump.maintain` et `Pump.step` ne font plus rien ; les relais chargés sont retirés et **toutes** les entrées `dev.relays` sont vidées, si bien que `Pump.onLoadChunk` retire les relais des zones non chargées au chargement de leur chunk. `enablePumps` efface le drapeau et relance `Pump.maintain` sur chaque pompe. Actions : `spawnKit`, `removeRelays` et `enablePumps` (sans appareil), `dump`, `battery100`, `battery50`, `battery15`, `battery0`, `advance1`, `advance12`, `repairAll`, `damageInverter`, `trip`, `refuel`, `reanchor`.

Les cinq préréglages par appareil sont définis dans `Debug.CONDITIONS` :
`deviceMinus10` (delta −10), `device50`, `device10`, `deviceBreak` (0) et
`deviceRestore` (100). Le serveur ignore toute valeur numérique fournie par le client,
borne l'état à 0–100, contrôle le registre disponible, le joueur vivant, les droits,
`checkDevice`, le modèle/rôle et `Devices.find`. Un appareil non raccordé est accepté.
À 0, onduleur/pompe passent à `broken`, les sources ont `pOut=raw=0`. Restaurer un
onduleur cassé donne `off`, une pompe cassée `idle`. Marques et instantané du réseau
sont actualisés par les services existants, prévisions invalidées. Pas de mutation
directe des slots/charge/état/cycles des batteries, d'XP ou d'objets ; `Sim.refresh`
réévalue normalement la physique. Aucun nouveau paquet, événement périodique ou
schéma persistant. `damageInverter` est conservé pour compatibilité des outils,
mais retiré du menu réseau, remplacé visuellement par les commandes par appareil.

### 3.5 Instantané (`Sim.snapshot`)

Champs principaux : `grid`, `rev` (révision croissante : la livraison n'est pas ordonnée), `name`, `inverter { id, model, state, cond, maxW, eff, powered, muffled }`, `demand`, `production`, `stock`, `capacity`, `lost`, `extra`, `banks`, `sources[] { id, model, kind, nominal, cond, w, raw, snow }`, `batteries[] { model, charge, capacity, cond, cycles }`, `options[] { id, model, cond, state }`, `appliances[] { cat, n, w }`, `coverage { radius, floors }`, `autonomyH`, et selon l'installation `coupled { n, total }`, `backup { id, state, fuel, maxFuel, w, start, stop }`, `computer { id, powered, shed }` avec `history[] { p, d, s }` et `dawnH`, `alarm { on, ack }`, `breaker { id, state }`, et les chiffres des pompes.

## 4. ModData et persistance

### 4.1 ModData globales

| Clé | Contenu | Diffusion |
|---|---|---|
| `LiveWire` | Registre de l'autorité : `schema`, `nextId`, `devices`, `grids`, `byPos`, `legacy`, `powerHistory`, `measureXp` | **Jamais** diffusée |
| `LiveWireAnchors` | `anchors[idOnduleur] = { x, y, z, on, log, log0 }` ; journal public limité à 16 changements, conservé pour compatibilité. Seuls les onduleurs maîtres et indépendants ont une ancre | À tous les clients, uniquement si l'état ou la position change |
| `LiveWireExtended` (LiveWire Extended) | Données du sous-mod (`inverters[idOnduleur].areas`, tableaux, bornes, points) ; `adopted` vaut vrai une fois faite l'adoption du premier démarrage (D-65, `server/LiveWireExtended/LWX_Adopt.lua`) | Diffusée par `ModData.transmit` à chaque changement de l'autorité |

### 4.2 Registre, schéma 2

- **Identifiants** `d<n>` (appareil) et `g<n>` (réseau), tirés de `nextId`, jamais réutilisés. Un identifiant
  repris d'une marque d'objet (`addDevice` avec `id`) fait passer `nextId` au-delà (`Registry.reserveId`).
- **Raccordement** : `wires`, fil électrique dépensé par le raccordement d'un membre ou le couplage d'un esclave,
  rendu au joueur qui défait le lien (débranchement, découplage, ramassage, déplacement vers un autre onduleur) ;
  absent sur les liens plus anciens ou récupérés, il est alors recalculé par la règle de câble sur la distance
  (`Devices.linkWires`). Un appareil détruit ne rend rien. `relink` : onduleur nommé par la marque d'un appareil
  récupéré, en attente de sa propre récupération (§ 4.5).
- **Appareil** (champs communs) : `id`, `role` (`source`, `inverter`, `storage`, `option`, `pump`, `backup`, `computer`), `model`, `x`, `y`, `z`, `grid`, `cond`, `eff`, `level` (meilleur niveau d'Électricité de ceux qui ont branché l'appareil, D-29), `state`.
  - `state` : onduleur `on` / `off` / `tripped` / `broken` ; source et équipement `ok` / `tripped` / `broken` ; pompe `idle` / `running` ; secours `standby`…
  - Source : `pOut` (W lissés), `raw`, `snow`. Onduleur : `muffled`, `coupled` (id du maître pour un esclave). Powerbank : `wearFactor`, `slots[] { id, model, charge, cond, cycles }` (instantané des batteries quand la case n'est pas chargée). Pompe : `barrels[posKey]`, `relays[posKey]`. Secours : `fuel`, `fuelSeen`, `connected`.
- **Réseau** : `id`, `name`, `inverter`, `members { [idAppareil] = true }`, `slaves`, `demand`, `production`, `stock`, `capacity`, `lost`, `powered`, `lastTick` (âge du monde en heures), `rev`, et selon les équipements `alarmOn`, `alarmAck`, `alarmAt`, `computerOn`, `history`, `historyAt`, `backupW`, `shed`, `appliances`.
- **Index** : `byPos["x,y,z"] = { idAppareil, … }`. Les index dérivés de session
  `Registry.byChunk["cx,cy"][id] = true` et `Registry.inverters[id] = true` sont
  reconstruits depuis les appareils au démarrage ; `devicesInChunk` renvoie une
  liste détachée, sûre pendant un retrait.
- **Frein d'éolienne** : `dev.brake`, conservé au ramassage via `br` ; aucun effet
  implicite de l'inspection. Bloque la production et les dégâts de tempête.
- **Secours manuel** : `dev.manual` et `dev.lastSet` persistants. Une bascule physique
  observée qui diffère de `lastSet` met le secours en mode manuel (`state = "manual"`).
  L'automatisation ne réécrit plus son activation jusqu'à `resumeBackup`. Le carburant
  simulé hors zone est rapproché au chargement en conservant ce choix.
  Au passage en manuel (bascule observée ou raccordement d'un générateur déjà en marche),
  les joueurs à moins de 30 cases reçoivent une seule fois `IGUI_LW_BackupManual` (arguments
  `ContextMenu_LW_Root`, `IGUI_LW_Model_BackupGenerator`, `ContextMenu_LW_ResumeBackup`,
  traduits par le client) ; `resumeBackup` envoie `IGUI_LW_BackupAuto`. L'instantané garde
  `backup.state = "manual"` : l'écran (`IGUI_LW_LCD_BackupManual`) et le logiciel
  (`IGUI_LW_Backup_ManualHint`) y ajoutent l'action de reprise (C28).
- **Historique électrique privé** : `powerHistory[id] = { x, y, z, on, log0,
  since, retired?, log[] { t, on } }`. `LW_PowerHistory` conserve 60 jours de jeu,
  purge les anciennes transitions chaque heure et garde l'état à la borne de
  rétention dans `log0`. Une position abandonnée garde son historique jusqu'à
  expiration ; un déplacement archive l'ancienne position. Reprise des journaux
  publics existants par copie, sans inventer les événements perdus. Champs
  optionnels ajoutés au schéma 2, sans changer les identifiants persistants.
- **Simulation partielle** : `Physics.stepGrid` retourne `onHours`, durée servie
  depuis le début du sous-pas, et `on`, état à sa fin. `servedW` est une moyenne
  sur le sous-pas entier. La simulation date les transitions privées au début du
  service et à l'épuisement du stock, compte la décharge réelle pour l'usure et
  ne publie que l'état final. La résolution météo reste celle des sous-pas.
- **XP des mesures** : `measureXp[compte] = { heuresDesGains }`, au plus cinq gains
  de 1 XP de base par heure de jeu glissante, toutes cases confondues, avant les
  multiplicateurs sandbox/vanilla. Budget autoritaire sauvegardé ; reconnexion et
  redémarrage ne le réinitialisent pas. Purge horaire des budgets expirés. Le
  délai d'une heure par case reste appliqué ; une mesure refusée pour l'XP garde
  son résultat de diagnostic.
- **Pompes concurrentes** : candidats raccordés, non cassés et ayant un baril,
  indépendamment de l'alimentation instantanée. Distance 3D au point sous le
  relais, dans le rayon horizontal et la portée verticale configurés ; égalité
  départagée par identifiant. Les robinets qui partagent un relais suivent ce
  point commun pour éviter les réattributions oscillantes. Transfert du même
  objet, sans perte de fluide ; les sources vanilla gardent la priorité. Une
  découverte initiale inachevée conserve les relais sauvegardés. Débit limité à
  5 L par minute, sans crédit accumulé au repos.
- **Remplissage des relais** : la pose et la propriété des relais ne changent
  pas, mais `needsOf` ne retient un relais non plein que si
  `Pump.feedsPlumbedFixture` trouve, sur `z-1` dans sa case ou les 8 voisines, un
  objet `waterPiped` avec `getUsesExternalWaterSource()` vrai dont
  `IsoObject.FindExternalWaterSource` rend ce relais (un relais vide suffit à
  l'option vanilla « Plumb »). Au plus 9 cases par relais et par minute, sans
  cache : un raccordement est pris en compte à la minute suivante. L'eau d'un
  relais devenu inutile reste en place ; l'état `idle`, le débit et
  `Pump.demandW` ne comptent que les relais utiles. Nettoyage sur tous les niveaux
  renvoyés par le chunk.
- **Marques** : si la tuile du modèle existe encore sur la position du registre,
  `Devices.find/validate` restaurent la marque au lieu de supprimer l'appareil ou
  de l'adopter une seconde fois. Un objet vanilla portant seulement son id ne
  remplace pas la tuile. L'adoption d'une tuile inconnue utilise un rendement
  fixe de 0,85 et un niveau neutre, indépendants de la personne qui la signale.
- **Seuils du secours** : démarrage borné à 0–90 %, arrêt effectif au moins cinq
  points plus haut et au plus 100 %. Une configuration corrigée est journalisée
  une fois par paire de réglages et l'instantané affiche les seuils effectifs.

Exemple commenté (schéma 1) et explication des champs : [`architecture.md`](architecture.md) § 3.2.

### 4.3 ModData des objets

| Objet | Clé | Format |
|---|---|---|
| Appareil posé du mod | `modData.movableData.LiveWire` (seule partie reportée par le vanilla au ramassage d'un `IsoObject`) | `{ s = 2, id, model, cond, eff, level, inv, st, pw, muf, x, y, z, nb, nr, cpl, br }` — reflet seulement, le registre fait foi |
| Batterie dans une powerbank | `LiveWireCycles` | Nombre de cycles (lu par le serveur seulement) ; charge = utilisations de l'objet, usure = état |
| Générateur vanilla de secours | `LiveWireBackup` | `{ id, inverter, manual }` |
| Ordinateur vanilla de gestion | `LiveWireComputer` | `{ id, inverter }` |
| Réservoir relais de la pompe | `LiveWireRelay` | `{ pump = idAppareil }` |
| Baril raccordé | `LiveWireBarrel` | `{ pump = idAppareil, x, y, z }` ; anciennes marques sans position validées puis complétées sur l'autorité ; une position ou appartenance invalide libère le baril |
| Borne ou tableau de LiveWire Extended raccordé | `LiveWireExtendedLink` (hors `movableData`) | `{ inv, x, y, z, ix, iy, iz, wires, slots, prewired }` : copie du raccordement (disjoncteurs sans étiquettes ni points), écrite au raccordement et toutes les dix minutes, effacée au débranchement (§ 4.5) |
| Ordinateur du Computer Mod | `ComputerModLiveWireInstalled` (données de l'ordinateur via `ComputerModComputerTypes`, préfixe imposé par la synchronisation de ce mod) | Logiciel installé |

### 4.4 Migrations

Complément du 2026-10-24 : la marque de l'onduleur porte `nm`, reflet du nom du
réseau pour préremplir le menu de renommage, sans nouvelle version de schéma.
Elle est actualisée après renommage et au chargement du chunk. Les constantes
inutilisées `C_REQUEST_ANCHORS`, `S_REFUSE`, `S_ANCHORS` et leur gestionnaire mort
sont retirés ; la table d'ancres continue de passer par `ModData.request/transmit`.

`server/LiveWire/LW_Migration.lua`, lancé à `OnInitGlobalModData`. Étapes idempotentes et journalisées ; aucune suppression (les données inconnues vont dans `legacy`). Étape 1 → 2 (0.1.1) : les appareils en sprites vanilla passent dans `legacy.schema1`, leurs ancres sont retirées. Un schéma plus récent que le code met le registre en lecture seule (simulation suspendue).

### 4.5 Récupération des appareils orphelins

La carte est sauvegardée par chunk, la ModData globale à l'enregistrement : après un arrêt brutal ou une
sauvegarde restaurée, un objet peut porter une marque dont le registre ignore l'identifiant (hypothèse de
cause, non reproduite en jeu). Toute commande est alors refusée (`Tooltip_LW_Invalid`) et les écrans attendent
leurs données sans fin ; l'adoption client (`LW_Adopt.lua`) ne voit que les objets sans marque.

- Le parcours de découverte des chunks (`LW_Circuits.lua`) appelle les visiteurs inscrits par
  `Circuits.addChunkVisitor(fn)` pour chaque objet chargé, réparti sur les ticks.
- `Devices.recover(obj)` réinscrit un objet du mod dont la marque, écrite pour sa case, nomme un appareil absent
  à cette case : même identifiant s'il est libre (sinon un nouveau), état, niveau, efficacité, nom du réseau.
  Un appareil du registre de ce modèle sur la case passe d'abord (`Devices.find`). Le lien vers l'onduleur de la
  marque (`inv`, ou `cpl` d'un esclave) est rétabli s'il respecte les règles de câble, sinon il attend dans
  `relink` que cet onduleur soit récupéré ; un identifiant connu qui n'est pas un onduleur maître l'annule.
  Ni fil ni expérience. Barils de pompe et choix des circuits ne sont pas rétablis.
- LiveWire Extended : `X.Recovery.visit(obj)` (`LWX_Recovery.lua`) reconstruit l'enregistrement d'une borne ou
  d'un tableau à partir de `LiveWireExtendedLink` si l'onduleur est connu à la case `ix, iy, iz`, sinon le
  réessaie toutes les dix minutes. Zone dessinée, étiquettes et points câblés reviennent aux valeurs d'un
  nouveau raccordement. L'élagage horaire garde un enregistrement dont l'onduleur manque au registre tant que
  sa case n'est pas chargée ou porte encore un onduleur marqué de cet identifiant.

## 5. Options sandbox

`media/sandbox-options.txt`, page `LiveWire`, `VERSION = 1`. Lecture par `LW_Config.lua`.

| Option | Type | Défaut | Bornes | Effet |
|---|---|---|---|---|
| `LiveWire.ConsumptionProfile` | enum (`numValues = 4`, `valueTranslation`) | 3 | 1-4 | Profil de consommation (`LW_Consumption.lua`) : 1 ultra-réaliste 1993, 2 réaliste 1993, 3 valeurs du jeu, 4 confort. Valeur inconnue = 3 |
| `LiveWire.EquipmentLootMultiplier` | double | 5,0 | 1–20 | Multiplicateur des poids des objets LiveWire uniquement, cellules incluses ; appliqué au démarrage sur les prochains tirages |
| `LiveWire.PowerScale` | double | 1,0 | 0,1-10 | Multiplie la consommation donnée par le profil (1 = aucun changement) |
| `LiveWire.SolarMultiplier` | double | 1,0 | 0-10 | Production solaire |
| `LiveWire.WindMultiplier` | double | 1,0 | 0-10 | Production éolienne |
| `LiveWire.HydroMultiplier` | double | 1,0 | 0-10 | Production de la roue à aubes |
| `LiveWire.BatteryCapacityMultiplier` | double | 1,0 | 0,1-10 | Capacité de chaque batterie |
| `LiveWire.BatteryWearMultiplier` | double | 1,0 | 0-10 | Usure des batteries (0 = aucune) |
| `LiveWire.DeviceWearMultiplier` | double | 1,0 | 0-10 | Usure des sources, onduleurs et équipements (0 = aucune) |
| `LiveWire.InverterNoiseRadius` | integer | 2 | 0-10 | Rayon du bruit entendu par les zombies (0 = silencieux) |
| `LiveWire.LinkRange` | integer | 12 | 4-30 | Distance horizontale maximale appareil-onduleur |
| `LiveWire.LinkVerticalRange` | integer | 3 | 0-10 | Écart maximal en étages, au-dessus ou au-dessous, pour les raccordements et couplages ; 0 = même étage |
| `LiveWire.PumpRange` | integer | 15 | 5-30 | Rayon des robinets alimentés par une pompe |
| `LiveWire.WirePerTiles` | integer | 4 | 0-20 | Un fil électrique par N cases de câble (0 = gratuit) |
| `LiveWire.StormDamage` | boolean | false | — | Orages et vents très forts abîment panneaux et éoliennes |
| `LiveWire.XPMultiplier` | double | 1,0 | 0-10 | Expérience donnée par les actions Live Wire |
| `LiveWire.SkillGates` | boolean | true | — | Désactivée : aucun niveau d'Électricité exigé pour brancher ni mettre en service |
| `LiveWire.SimulateUnloaded` | boolean | true | — | Production, consommation et usure continuent sans joueur proche |
| `LiveWire.GridCharging` | boolean | true | — | Entrée `gridW` de `Physics.stepGrid` : 20 % (`Defs.GRID_CHARGE_RATIO`) de la puissance continue du réseau, tant que `getElecShutModifier() × 24` n'est pas dépassé et que la case de l'onduleur est dans une pièce sans `isNoPower` (mémorisé dans `inv.gridSite` pour les pas hors chargement) |
| `LiveWire.BackupStartPercent` | integer | 20 | 0-90 | Démarrage du générateur de secours sous ce pourcentage de batterie |
| `LiveWire.BackupStopPercent` | integer | 90 | 10-100 | Arrêt du générateur ; seuil effectif relevé si nécessaire à démarrage + 5 points |

Portée de la zone alimentée : options vanilla `GeneratorTileRange` (20) et `GeneratorVerticalPowerRange` (3), lues par `LiveWire.Config.tileRange()` / `verticalRange()`.

## 6. Traductions

- Source unique : `tools/translations_src.py`, qui écrit `media/lua/shared/Translate/<LANGUE>/*.json` (JSON plat UTF-8 sans BOM, contrôlé par `tools/check_mod.py`).
- Langues : `EN` (référence), `FR`, `DE`, `ES`, `PT`, `PTBR`, `RU`, `CN`, `JP`, `KO`, `TR`.
- Fichiers et préfixes (EN, 1.3.1) :

| Fichier | Préfixe des clés | Clés |
|---|---|---|
| `ContextMenu.json` | `ContextMenu_LW_` | 69 |
| `IG_UI.json` | `IGUI_LW_` (+ `IGUI_ContainerTitle_livewirepowerbank`) | 171 |
| `ItemName.json` | `Module.Objet` (`LiveWire.*`, `Base.Mov_LiveWire_*`) | 14 |
| `Moveables.json` | `Live_Wire_*` (noms des tuiles) | 8 |
| `Recipes.json` | nom de recette (`LWMake*`, `LWDismantle*`) | 31 |
| `Sandbox.json` | `Sandbox_LiveWire_` (+ `Sandbox_LiveWire` pour la page) | 35 |
| `Tooltip.json` | `Tooltip_LW_` | 39 |
| `UI.json` | `UI_LW_` | 3 |

- Le serveur n'envoie que des **clés** (`notify`) : un serveur dédié ne charge pas les traductions des mods.
- Messages de journal en anglais, préfixe `[LiveWire]` (`LiveWire.log`, `LiveWire.warn`).

## 7. Compatibilités

| Mod ou système | Nature | Mécanisme | Statut |
|---|---|---|---|
| Générateurs vanilla | Coexistence ; générateur raccordable en secours | Ancre = position de générateur ; clé `LiveWireBackup` | Confirmé statiquement ; essai en jeu du secours non consigné |
| Computer Mod `ComputerModkum` (3725497089), Laptop `ComputerModLaptop` (3798992436) | Facultatif | Détection `LW_Compat.isModActive` ; vue `LIVEWIRE` ajoutée par enveloppe de `ComputerScreenUI` | Confirmé en jeu en solo pendant le développement |
| Barils d'un mod (ex. Useful Barrels) | Facultatif | Tout objet à fluide d'au moins 20 L posé à côté de la pompe | Confirmé statiquement |
| Project Viewpoint | Facultatif, mod `batman_LiveWireViewpoint` | Modèles `.obj` dans `common/media/livewire-viewpoint` | Non revérifié ici |
| Let Me Drive! `LetMeDrive` (3805307651) | Facultatif ; correctif à sens unique | Les abonnés `LoadChunk` de `LW_Anchor` et `LW_ChunkSync` s'inscrivent par `LW_Compat.addLoadChunk`, qui passe par `LetMeDrive.Gate.addRaw` quand cette fonction existe, sinon par `Events.LoadChunk.Add`. Voir NM-57 à NM-59 | Confirmé statiquement ; essai en jeu non consigné |
| Autres mods d'énergie | Non pris en charge | — | — |

Multijoueur : serveur dédié autoritaire ; tests automatisés en jeu en solo et sur serveur dédié Windows avec deux clients, sauvegardes et redémarrages complets compris. Voir le [bilan de validation](annexes/tests/validation.md).

## 8. Outillage et tests

- `tools/check_mod.py` : contrôles statiques (ordre de chargement, syntaxe Lua, ASCII, traductions, définitions ↔ scripts, options, modèles, événements connus d'après les sources de référence).
- `tests/test_physics.py`, `tests/test_simulation.py` : tests hors jeu sous Lua 5.1 (`lupa`) ; ils ne prouvent rien sur le moteur.
- `tests/test_compat.py` : inscription des abonnés `LoadChunk` critiques selon la présence de la porte de sortie de Let Me Drive!, repli compris.
- `autotest.json` + `autotest/*.lua` : configuration de l'outil `pz-autotest` (tests en jeu non surveillés).
- Documentation générée : `tools/make_doc_images.py` (→ `docs/images/diagrams/`), `tools/make_doc_tables.py` (→ `docs/wiki/<langue>/_tables.md`).
- Protocole de test en jeu : [`annexes/tests/protocole-tests.md`](annexes/tests/protocole-tests.md).

## 9. Campagne IXX locale après v1.5.0

Non publiée ; métadonnées de version inchangées en attendant un ordre de livraison.
Architecture et schéma 2 conservés. Les champs suivants sont optionnels et prennent
leur valeur par défaut à la première lecture ; aucune identité n'est recréée.

| Donnée | Contrat |
|---|---|
| Source solaire | `facing` 0=S, 1=E, 2=N, 3=W, relu de la tuile ; `dirt` 0..0,5 ; `snow` 0..1. Saleté/neige suivent le ramassage dans la marque |
| Powerbank | `outside`, actualisé depuis la case chargée, conservé hors zone |
| Batterie | Charge native = fraction de la capacité à chaud ; `LiveWireCycles` inchangé ; `LiveWireRepairs` défaut 0, plafond 4 ; `LiveWireCondition` porte l'usure fractionnaire ; `LiveWireEnergyRemainder` conserve le reliquat inférieur à une graduation native. Réparation +15 état, plafond 80 ; niveau 4 ou 6 si morte ; tournevis, 1 déchet électronique, 1 fil et 0,5 L d'eau ; énergie du modèle conservée, sans arrondi natif vers le haut |
| Froid | Facteur 1 à 15 °C, 0,8 à 0 °C, 0,6 à −15 °C, borné 0,6..1. Réserve inaccessible = minimum de l'énergie stockée et de la capacité perdue ; réserve conservée dans la fraction native, sans perte au dégel |
| Réseau | `events[] { t, tod, key, args }`, 30 derniers ; `eventState` ; `stormWarned` ; `forecastAt`, `forecast` ; `lightsOff`, `equipmentOff`, `mainOff` défaut faux ; migration des anciens `lightChoices` locaux |
| Appareil | `ModData.LiveWireCircuit { v=1, kind, owner, cut, on?, dry?, watts, category, types? }` ; choix individuels et types d'origine indexés ; aucune copie des objets d'inventaire |
| Identité de service MP | `ModData.LiveWireService { id="cN", rev, media, types={ [index]=true } }` ; ajout paresseux par l'autorité, révision accrue après une intervention ; conservé après restauration. Aucun contenu d'inventaire ni ancien choix radio à rejouer |
| Historique | `powerHistory[].panelLog[] { t,off }`, `panel0` ; circuit distinct du courant de l'ancre, même fenêtre privée de 60 jours |
| Instantané | `origin`, `links[] { id, model, role, x, y, z }`, `consumers[] { x,y,z,cat,w,requestedW,owned,served,circuitOff }` (200 premières lignes triées), `events`, `sources[].facing/dirt`, `batteries[].reserve`, `forecast` seulement avec ordinateur alimenté ; `breaker.lightsOff/equipmentOff/mainOff/equipmentControl=true` |
| Commande | `setCircuit { device, circuit=lights/equipment/main, off:boolean }` ; proximité du disjoncteur, refuge, registre modifiable ; choix identique sans mutation ni énergie avancée |
| Miroir | `circuitService { id,rev,x,y,z,sprite,types,media,on,request=0 }`, serveur vers joueurs proches après intervention ; identité stable puis sprite unique en repli ; aucun renvoi d'inventaire |
| Réconciliation | `readCircuitServices { seq, services[]={id,x,y,z} }`, 16 appareils maximum ; identité, coordonnées entières, joueur vivant et distance de 100 cases revérifiés sous la limitation de débit existante. Réponse au demandeur : `circuitServices { services[]={...instantané de service...,request=seq} }`, relisant l'état natif courant |
| Actions | `LWCleanPanelAction`, `LWTestBatteryAction` ; `LWReconditionAction` étendue. Mutations et coûts revérifiés dans `complete()` sur l'autorité |
| Options | `SolarOrientation=true`, `SolarDirt=true`, `BatteryCold=false`, `LiveWorkRisk=true` ; booléens, page LiveWire |

Le bilan énergétique utilise exclusivement la charge accessible ; réserve et capacité
à chaud servent à écrire la fraction native. Une réparation ne réinitialise pas les
cycles. La réserve peut subir l'autodécharge et la perte de capacité par usure.

Prévision : cache horaire, trois `DayForecast` officiels, vent normalisé ×120 km/h,
nuages diurnes, lever/coucher du jour prévu. Production horaire via `Sim.sourceRaw`,
donc orientation, neige, saleté, état, rendement, frein et multiplicateurs partagés.
Demande moyenne des échantillons disponibles sur 48 h ; capacités et pertes respectées
par `Physics.stepGrid` sur un stock projeté détaché. Aujourd'hui, le contrôle de réserve
commence à l'heure courante. Les chiffres journaliers couvrent le jour entier.
Météo moyenne, entretien et capacité accessibles supposés constants ; pas de garantie
sur le vent horaire ni de prise en compte d'un secours futur ou d'une panne future.

### API publique v1

Charger `require "LiveWire/LW_API"` dans le Lua partagé de l'extension.
Enregistrer pendant le chargement des fichiers, avant `OnInitGlobalModData` qui ferme
le registre des définitions. Extension identique sur serveur et clients.

- `registerBattery(fullType, kWh, lifeCycles)` → `true` ou `false, raison`.
  Type complet `Module.Objet`, capacité 0,001..1000 kWh, vie 1..1 000 000 cycles.
  L'objet doit être une batterie drainable à état 0..100, conservée vide par son script.
- `registerSource(model, definition)` → même contrat. Champs obligatoires : `item`,
  `kind` (`solar`, `wind`, `hydro`), `sheet`, `tile` entier, `facings=4`, `nominalW`
  1..100 000, `level` 0..10, `wearDays` 1..100 000. Sources extérieures, hydraulique
  sur berge. Fournir les traductions `IGUI_LW_Model_<model>` et les propriétés de tuiles.
  Champ facultatif `overlays` (D-53) : voyants dessinés par-dessus la tuile, dans la **feuille de la source**.
  Clés `linked`, `on`, `fault`, `muffle`, `tripped`, `powered`, `ringing` (premier sprite d'un voyant, le
  sprite de l'orientation f est `valeur + f`), `rotor` (premier de 4 images de pales de 4 sprites) et
  `blinkWhenBraked` (booléen). Valeurs entières 0..100 000, aucune ne doit tomber sur les 4 tuiles de
  l'appareil ; toute autre clé ou valeur → `invalid_definition`. Règles d'allumage : commentaire de
  `LW_Defs.lua`. Un sprite de voyant absent de la feuille (texture introuvable) n'est simplement pas dessiné ;
  sans `overlays`, aucun voyant.
- Les doublons de type, modèle, objet posable et sprite sont refusés. Les valeurs
  non finies sont refusées ; seuls les champs primitifs autorisés sont recopiés.
- `battery(fullType)`, `source(model)` renvoient une copie détachée ou `nil`.
- `gridAt(x,y,z)` : autorité seulement, avant initialisation → `nil,"not_ready"` ;
  position invalide → `nil,"invalid_position"`. Réseau dont le maître est le plus
  proche dans sa portée (égalité par id), instantané détaché ou `nil` sans réseau.
  La portée est la couverture de `LW_Coverage` : le disque, plus les cases d'un fournisseur.

### Points d'extension à un seul inscrit (`LW_Extension`)

`LiveWire.Extension.single(name, schema [, { closed = true }])` rend `{ register(p), get(), active() }`. `register` rend
`true`, ou `false` et `"registration_closed"` (après `OnInitGlobalModData`), `"already_registered"`, `"invalid_provider"`
(non table, ou champ qui ne respecte pas le schéma), dans cet ordre. Le schéma associe un champ à son type Lua
(`"function"`, `"boolean"`…) ; `?` à la fin le rend facultatif, `"any?"` accepte tout ; `closed` refuse aussi les champs
inconnus. Le scellement est commun (`Extension.isSealed()`, aussi lu par `LiveWire.API.registerBattery/registerSource`).
`Coverage`, `CircuitProvider` et `Coupling` en dépendent par un `require` explicite (leur nom de fichier trie avant
`LW_Extension`).

### Point d'extension « couverture » (D-32, 2026-11-08)

`require "LiveWire/LW_Coverage"` (Lua partagé). Sans fournisseur, la couverture d'un onduleur est **exactement** le
disque de D-12 : `GeneratorTileRange` autour de la case de l'onduleur, ±`GeneratorVerticalPowerRange` étages. Un seul
fournisseur peut s'inscrire, pendant le chargement des fichiers, avant `OnInitGlobalModData` :
`LiveWire.Coverage.register(provider)` → `true`, ou `false` et `"invalid_provider"`, `"already_registered"`,
`"registration_closed"`. Il **ajoute** des cases au disque, sans jamais en retirer (D-33), sauf s'il porte le champ
facultatif `replacesDisc = true` (D-44) : il **remplace** alors le disque. `Coverage.hasDisc()` rend `false`,
`Coverage.inDisc` rend toujours `false`, aucun parcours ni position de disque n'existe : un onduleur n'alimente que
les cases du fournisseur (`covers`, `positions`, `scan`, `idsAt`). Sans ce champ, rien ne change.

| Fonction du fournisseur | Rôle |
|---|---|
| `covers(id, a, x, y, z)` | La case est-elle dans la couverture ajoutée de l'onduleur `id` (ancre publique `a` = `{x, y, z, on}`) ? |
| `bounds(id, a)` | Rectangle `minX, minY, maxX, maxY` de la couverture ajoutée, ou `nil` |
| `positions(id, a)` | Positions de générateur à déclarer : `{ cx, cy, x, y, z }` par bloc, chacune sur une case réelle (purgée par le moteur au retrait du mod) |
| `scan(id, a)`, `step(job, budget, visit)` | Parcours borné et reprenable des cases ajoutées (`done, used`, comme `SquareScan.step`) |
| `idsAt(x, y, z)` | Onduleurs dont la couverture ajoutée contient la case (attribution des circuits) |
| `describe(id)` *(facultative)* | Lignes `{ key, args }` affichées sur la page « Maison » de l'écran de l'onduleur |

Utilisateurs dans la base : `LW_Anchor` (pose et retrait des positions, réapplication après purge, effets visuels,
vieillissement des frigos), `LW_Demand` (inventaire, onduleur le plus proche), `LW_Circuits.owner`,
`LW_FridgeCatchup`, `LW_ChunkSync`, `LW_API.gridAt` et la mesure au testeur ; à l'affichage, `LW_RangeView` (contour
des blocs de 8 × 8 cases ajoutés, à l'étage du joueur) et `LW_InverterPanel` (lignes de `describe`). Le cas « case ajoutée » ne s'évalue
qu'après le test du disque : sans fournisseur, aucun appel de plus par case ni par image. `Anchor.reshape(id, fn)`
retire les positions de l'onduleur de ce côté, vieillit la nourriture des deux zones, exécute `fn` (changement des
données du fournisseur), puis déclare les nouvelles positions et rafraîchit les effets visuels.

### Point d'extension « circuits » (D-35, D-37, 2026-11-08)

`require "LiveWire/LW_CircuitProvider"` (Lua partagé, utilisé sur l'autorité seulement). Sans fournisseur, un appareil
vanilla n'est coupé que par les circuits de son tableau (I21). Un seul fournisseur peut s'inscrire avant
`OnInitGlobalModData` : `LiveWire.CircuitProvider.register(provider)` → `true`, ou `false` et `"invalid_provider"`,
`"already_registered"`, `"registration_closed"`. Sa fonction `blocked(o, kind, grid)` rend `true` pour couper
l'appareil `o` (famille I21 `kind`, tableau propriétaire `grid`, éventuellement `nil`). Elle ne peut que couper
davantage : un circuit ouvert sur le tableau de la base (disjoncteur général) reste ouvert. `LW_Circuits` l'interroge
dans `Circuits.blocked` et `Circuits.applyObject`, avec les mêmes adaptateurs de service, la même file et la même
persistance qu'I21. `LiveWire.Demand.each(inv, fn)` appelle `fn(objet, watts)` pour chaque appareil facturé à
l'onduleur par la dernière mesure, sans copie (charge par circuit, D-35).

### Point d'extension « couplage » (D-45, 2026-11-09)

`require "LiveWire/LW_Coupling"` (Lua partagé). Un seul add-on peut s'inscrire avant `OnInitGlobalModData` :
`LiveWire.Coupling.register(p)` → `true`, ou `false` et `"invalid_provider"`, `"already_registered"`,
`"registration_closed"`. Champs, tous facultatifs (un champ inconnu ou mal typé est refusé) :
`slaveKeepsZone` (booléen : un onduleur couplé garde son ancre et sa zone), `range()` (distance de couplage en cases,
lue par `Install.checkCouple` et le menu ; valeur invalide → `LinkRange`), `inverters(sq)` (onduleurs atteignables pour
un couplage, au format de `Install.invertersInRange`), `menu(menu, player, obj, mark, isSlave)` (client : options
ajoutées au menu Live Wire d'un onduleur). Lecture : `Coupling.active()`, `slaveKeepsZone()`, `range()`,
`inverters(sq)`, `inverterById(sq, id)`. Avec `slaveKeepsZone` : `Registry.couple` garde l'ancre, `invertersNear`
inclut les couplés, `Demand.measureGrid(grid, inv)` additionne les zones des couplés en service (dernière valeur gardée
si une zone n'est pas mesurable), `Circuits.apply` traite leurs listes, la simulation allume chaque couplé avec le
maître, `Computer.shed` éteint aussi leurs lumières. Avec un inscrit quelconque, l'abonnement à l'écran et les
commandes d'onduleur acceptent un joueur proche d'un onduleur couplé du réseau. Compléments (D-57, 2026-11-10) : `inverterById(sq, id)` cherche ensuite l'onduleur sur la case de son ancre, à toute distance, si elle est chargée ; l'écran de l'onduleur reste ouvert à moins de 30 cases de l'ancre du maître, de l'objet d'où il a été ouvert ou de n'importe quel onduleur de `snapshot.network` ; au chargement (`Registry.init`), sans inscrit `slaveKeepsZone`, `Registry.dropCoupledAnchors()` retire les ancres restées aux onduleurs couplés (add-on retiré). Tests : `tests/test_coupling_api.py`.
  Ne renvoie jamais le registre, ses objets Java ou ses tables mutables.
- Ces garanties portent sur les accès par l'API v1. Les modules internes de
  l'espace Lua partagé ne constituent pas une frontière de sécurité contre un
  autre mod qui remplacerait délibérément leurs fonctions ; ils ne font pas
  partie du contrat d'extension.
- Raisons d'enregistrement stables : `registration_closed`, `invalid_definition`,
  `duplicate_type`, `duplicate_model`, `duplicate_sprite`, `duplicate_consumer`. `API.version=1` ; `API.revision=6`
  (services pour sous-mods, ci-dessous ; révision 3 : réseau et vue de zone, D-57 ; révision 5 : kit de débogage ; révision 6 : consommateurs des autres mods, ADR-002). `registerBattery`, `registerSource`, `battery`, `source`,
  `gridAt` sont inchangées.

### API publique : services pour sous-mods (révision 2, D-47, 2026-11-09)

Un add-on (LiveWire Extended) n'appelle de la base que `LiveWire.API.*`, les points d'extension (`Coverage`,
`CircuitProvider`, `Coupling`), la lecture de `LiveWire.Config.*`, `LiveWire.UIScale`, `LiveWire.notify` /
`notifyNear` et `LiveWire.Anchor.reshape`. Chaque fonction ci-dessous cherche son module interne **au moment de
l'appel** (les modules serveur ne sont pas chargés partout), ne rend que des copies détachées des tables d'état,
et rend `nil`, `false`, `0` ou une liste vide quand le registre n'existe pas (client, avant l'initialisation).
Tests : `tests/test_api_submods.py`.

| Fonction | Rôle |
|---|---|
| `API.inverter(id)` | `{ id, x, y, z, role, coupled (booléen), master (id ou nil) }` d'un onduleur du registre, ou `nil` (autorité) |
| `API.inverterOfObject(obj)` | idem, pour l'objet posé qui porte la marque, s'il est sur sa case enregistrée ; `nil` sinon (autorité) |
| `API.deviceKnown(id)` | l'id existe-t-il au registre (tout rôle) ? |
| `API.writable()` | registre prêt et non en lecture seule |
| `API.inventoryIds()` | ids des onduleurs ayant un inventaire d'appareils (nouveau tableau) |
| `API.eachBilled(invId, fn)` | `fn(objet, watts)` pour chaque appareil facturé à l'onduleur par la dernière mesure |
| `API.invalidateDemand(id)` | demande une nouvelle mesure (`nil` : tous les onduleurs) |
| `API.applyCircuits(obj)` | applique la décision de circuit à un appareil |
| `API.topologyChanged()` | revisite progressivement les appareils des inventaires |
| `API.addChunkVisitor(fn)` | inscrit `fn` au parcours de chunks ; `false` si impossible |
| `API.screwdriver(ch)`, `API.showScrewdriver(action)` | tournevis utilisable ; affichage de l'outil dans l'action |
| `API.countType(ch, type)`, `API.hasLevel(ch, niveau)` | compte d'objets ; niveau d'Électricité (sandbox appliqué) |
| `API.consume(ch, type, n)`, `API.giveItem(ch, type)`, `API.returnWires(ch, n)` | retirer, donner, rendre des fils (avec message) |
| `API.distance(x1,y1,z1,x2,y2,z2)`, `API.wiresFor(dist)` | distance horizontale et étages ; fils pour une distance |
| `API.invertersInRange(sq)` | onduleurs à portée de câble de la case, du plus proche : `{ obj, dist }` (nouveau tableau) |
| `API.cableCheck(ch, caseA, caseB, niveau, cléNiveau)` | étages, portée, niveau (seulement si `niveau` est donné ; clé de refus `cléNiveau`, défaut `Tooltip_LW_NeedLevel`), fils : `true, nil, fils` ou `false, clé, arg1, arg2` ; passe par `API.distance/hasLevel/wiresFor/countType` |
| `API.awardXp(ch, clé, xp, heures)` | XP d'Électricité limitée par (joueur, clé) |
| `API.estimateWatts(w)` | consommation estimée d'une charge que le moteur ne compte pas, `PowerScale` et facteur du profil appliqués (`Consumption.estimate`) |
| `API.watts(obj)`, `API.applianceKind(obj)`, `API.applianceCut(obj)` | consommation, famille et coupure d'un appareil posé |
| `API.mark(obj)`, `API.markOnSquare(sq, id)`, `API.model(nom)` | marque (copie), objet marqué d'une case, définition d'un modèle (copie) |
| `API.pumpId(obj)`, `API.computerId(obj)` | id de la pompe ou du lien d'ordinateur que porte l'objet |
| `API.registerSoftwareLines(fn)` | **un seul** fournisseur (type fonction validé ; un second, différent, est refusé : `false, "already_registered"` ; `false, "invalid_provider"` si ce n'est pas une fonction) de lignes pour la page « Maison » du logiciel de l'onduleur (client). Remplace le champ `SoftwareApp.houseProvider` |
| `API.softwareLines(id)` | lignes du fournisseur (nouveau tableau de chaînes ; vide sans fournisseur), lues par le logiciel |
| `API.registerDebugKitItem(type, n)`, `API.debugKitItems()` | révision 5 : objets qu'un sous-mod ajoute au kit du menu de débogage (« spawnKit », `LW_DebugCommands`) ; `n` entier de 1 à 100, un type déjà inscrit change de nombre ; `false, "invalid_definition"` sinon. Lecture : nouveau tableau de `{ type, n }` dans l'ordre d'inscription. Extended y inscrit sa borne, ses tableaux, ses disjoncteurs et ses interrupteurs crépusculaires (`LWX_Core.lua`) |
| `API.networkInverters(id)` | révision 3 : onduleurs du réseau de l'onduleur `id` (maître ou couplé), maître en tête : nouveau tableau de `{ id, x, y, z, master }`, ou `nil`. Autorité : registre ; client : `snapshot.network` de l'onduleur abonné (id du maître) |
| `API.anchors()` | révision 3 : copie `{ [id] = { x, y, z, on } }` de la table publique des ancres (serveur et client), sans le journal |
| `API.showRange(id, x, y, z, opts)`, `API.hideRange()`, `API.rangeShown(id)`, `API.rangeColor()` | révision 3, client : afficher, masquer, tester (`nil` : une vue quelconque) la zone d'un onduleur, couleur de la ligne (copie) ; `false`/`nil` sur un serveur |
| `API.onRangeView(fn)` | révision 3 : `fn(id, affichée)` à l'ouverture ou à la fermeture de la vue de zone d'un onduleur (pas d'une pompe ni d'un cercle `opts`) ; appelable depuis n'importe quel fichier, une même fonction n'est gardée qu'une fois ; `false` si `fn` n'est pas une fonction |
| `API.addPlacementRule(rule)` | révision 4, D-62 : `rule(nomTuile, case, personnage)` rend `nil` (tuile non concernée), `true`, ou `false` et une clé de traduction ; consultée pour toute tuile par `canPlaceMoveableInternal` (client et autorité) et affichée en rouge dans le panneau du curseur ; un refus de l'autorité est envoyé au joueur (`LiveWire.notify`). Inscription au chargement des Lua (`false` après `OnInitGlobalModData` ou si `rule` n'est pas une fonction ; la même fonction n'est gardée qu'une fois). Tests : `tests/test_placement_rules.py` |
| `API.enclosure()` | D-54 (mise à jour de D-47, 2026-11-09) : rend le module `LiveWire.Enclosure` (`client/LiveWire/LW_Enclosure.lua`) lui-même, non une copie, pour le dessin des fenêtres de coffret. `nil` sur serveur dédié, où le module n'est pas chargé. Appelé à l'ouverture d'une fenêtre seulement ; le module ne touche à aucun état de jeu |

[Preuves et portée exactes des circuits](annexes/recherches/circuits-42-21.md) :
adaptateurs natifs, reprise des choix, pièces, recouvrements et migration additive.
Les contrôles d'actions commencent par la classification d'un objet posé :
`IsoObject`, hors `IsoWorldInventoryObject`, puis service effectivement pris en
charge. Les `Radio` d'inventaire, `VehiclePart` et propriétaires de fluides hors
de ce périmètre ne sont pas inspectés comme des meubles, même s'ils renvoient
une case. Leurs validations, arguments et retours vanilla sont conservés.
Cette frontière s'applique sur le client MP comme sur l'autorité ; le refus
dépend ensuite des marques synchronisées ou du circuit autoritaire habituel.
Le garde-fou porte sur le type avant toute lecture de méthode : la classe native
`IsoObject` garantit les accès conteneurs/sprite utilisés par la classification.
Une sonde `objet.methode` sur un propriétaire Java non exposé peut elle-même lever
une erreur ; elle ne remplace donc pas cette frontière. Un futur propriétaire
hors de ce type est ignoré sans lire ses membres, et un sous-type natif sans
service électrique reconnu ne reçoit aucun contrôle du tableau.
Application des circuits : autorité seulement, créneaux espacés d'au moins 20 ms
réelles pour les commandes/découvertes en attente, 100 ms pour l'entretien seul ;
16 unités de travail au maximum et arrêt entre unités après environ 1 ms, sans
rattrapage en rafale. Une unité visite un objet ou saute au plus 32 cases vides
d'un chunk. La fin d'un travail de réseau déclenche sa réévaluation physique et
sa publication habituelles, dont le coût reste distinct du budget des unités.
Les choix des commandes et les refus d'actions sont immédiats ; l'application
aux appareils est progressive. La pose d'un objet reste ciblée et immédiate.
Les mesures sont signalées indisponibles pendant le travail du circuit.
Les objets isolés/en attente de courant sont suivis indépendamment du cache de
consommation ; leur passage d'entretien est relancé au plus chaque seconde.
Une unité native individuelle peut dépasser le budget de temps.

Client MP : lecture des services après découverte d'une identité et reprise des
messages dont l'objet manque. File limitée à 512 identités, expiration après
60 secondes, 16 entrées examinées par créneau de 250 ms, requêtes espacées de
500 ms au moins et nouvelle demande du même appareil après 2 secondes au moins.
Un chargement ultérieur peut relancer la lecture. Les révisions et séquences
empêchent un ancien message de remplacer une lecture plus récente. Aucun objet
ambigu n'est modifié ; les files sont libérées à la sortie de session.

La facturation garde toutes les mesures et ne trie aucune ligne d'affichage.
À la première demande d'instantané, un tas borné sélectionne les 200 meilleurs
consommateurs en O(N log 200) ; il est réutilisé jusqu'à la mesure suivante.
Les textes des onglets de détail sont mémorisés pour l'instantané et l'onglet.
La prévision invalide son cache après une commande ; lorsqu'un circuit est ouvert,
elle utilise la demande actuelle au lieu des anciens échantillons tous circuits fermés.
L'énergie de pompage déjà dépensée avant une coupure reste facturée, mais n'est pas
projetée comme une charge future lorsque le circuit équipements est ouvert.


Précision des batteries : `LiveWireEnergyRemainder { fraction, capacity, kWh }`
conserve un reliquat positif d'au plus une graduation native. La charge native
est arrondie vers le bas si son setter l'arrondit au-dessus de la cible ; le
modèle additionne ensuite ce reliquat. Une modification externe de fraction ou
de capacité invalide le reliquat. L'état fractionnaire n'est utilisé que si son
arrondi correspond à l'état natif ; une modification externe reste prioritaire.
Ces champs optionnels migrent implicitement les anciennes batteries à leur
prochaine écriture. Les sauvegardes sans ces champs conservent leur charge native.
L'orientation des panneaux existants est relue sur leur tuile chargée même si
l'usure est désactivée ; le défaut sud ne sert qu'à un ancien appareil hors zone
dont l'orientation physique n'a pas encore pu être relue.
Le diagnostic en inventaire affiche la capacité à chaud ; la powerbank indique
la fenêtre accessible et la réserve froide, avec le même modèle d'état et d'énergie.

Le principal `mainOff` coupe réellement l'ancre et consigne la transition dans
l'historique d'alimentation. Il laisse l'onduleur en marche et les sources charger.
Il ne supprime pas les alimentations vanilla ou les autres réseaux indépendants.

Caches de session : instantanés client plafonnés à 64 réseaux, TTL de cinq minutes
réelles après dernier accès/réception ; effacement à la déconnexion/au menu.
Inventaires consommateurs, rapports et découverte libérés au retrait d'un onduleur
ou à la purge des zones déchargées (dix minutes de jeu). Abonnements serveur purgés
à la minute de jeu, y compris ceux des joueurs partis et des réseaux supprimés.
Ces purges ne modifient aucun identifiant ni donnée persistante ; aucun nouveau
schéma de sauvegarde et aucun appel au ramasse-miettes dans le mod de production.


## Contrats du complément d'interface local

### API publique : consommateurs des autres mods (révision 6, ADR-002, 2026-11-13)

Un appareil que le moteur ne compte pas (`couldBePoweredByGenerator()` faux ou `getGeneratorPowerConsumption()` nul)
est déclaré par son mod ; contrat complet, arguments et exemple : [ADR-002](ADR/002-api-consommateurs.md#contrat-de-lapi-révision-6),
wiki développeurs (exemple 7). Registre `shared/LiveWire/LW_Consumers.lua` (index par nom de sprite, scellé à
`OnInitGlobalModData`) ; famille `consumer` en tête de `LW_ApplianceFamilies` (`stateless`, `category` et `circuit`
fonctions de l'objet). Aucun abonnement à un événement : le recensement existant de `LW_Demand` liste aussi les objets
inscrits, `OnObjectAboutToBeRemoved` les invalide. Tests : `tests/test_api_consumers.py`.

| Fonction | Rôle |
|---|---|
| `API.registerConsumer(id, définition)` | shared, avant `OnInitGlobalModData` : `sprites` (1 à 256 noms exacts), `powerConsumption(o)` (W en marche, 0 à l'arrêt), facultatifs `couldBePowered(o)`, `category`, `circuit` (`equipment`/`light`), `display(o)`, `summary(objects)`. `true`, ou `false` et `registration_closed`, `invalid_definition`, `duplicate_consumer`, `duplicate_sprite` |
| `API.consumer(obj)` | id du consommateur inscrit qui reconnaît l'objet posé, ou `nil` |
| `API.consumerPowered(obj)` | les deux côtés : `ItemContainer.isObjectPowered(obj, true)` et aucune coupure (circuits du panneau, fournisseur de circuits ; sur un client, coupure lue dans la ModData `LiveWireCircuit` synchronisée) ; `false` pour un objet non inscrit |

- Facturation : `Consumption.watts` lit d'abord le consommateur (valeur moteur remplacée), applique
  `Consumption.estimate` (`PowerScale`, facteur du profil) et rend 0 quand l'appareil est coupé ; Live Wire n'appelle
  jamais de méthode d'état de l'objet (`capture`/`apply` sans champ `on`).
- Coupure : `Circuits.panelOpen` suit `ApplianceFamilies.circuit(o, kind)` (`light` pour les lampes et les consommateurs
  `circuit = "light"`, `equipment` sinon).
- Affichage (D07) : `Demand.consumers` joint `info = { name, lines }` à la ligne d'un objet inscrit qui a `display` ;
  copie bornée (`Consumers.info`) : clés `^[%w_]+$` de 64 caractères au plus, 4 lignes, 4 arguments (chaîne de 32
  caractères au plus ou nombre). `LW_SoftwareApp` (écran Live Wire et fenêtre du Computer Mod) traduit le nom à la place
  de la famille et ajoute les lignes en retrait dans l'onglet « Consommateurs ».
- Résumé par réseau (D08) : `Sim.snapshot` joint `consumerSummaries = { { id, name, lines }, ... }` (ordre d'inscription) ; `Consumers.summaries` groupe par consommateur les objets que `Demand.eachServedOfGrid` parcourt (zone du maître et des couplés en service si `Coupling.slaveKeepsZone`, lectures non nulles, appareils possédés, réseau public exclu), appelle `summary(objects)` une fois par consommateur présent et garde une copie bornée à 2 lignes. `App:summaryRows` traduit une fois par instantané ; affichage dans l'onglet « Équipements ».
- Extended : `LWX_CircuitProvider.extraWatts` ignore un objet inscrit (pas de double facture) ; son adaptateur vanilla
  reconnaît la famille `consumer` comme tout appareil (`API.applianceKind`).

### Wattmètre du tableau (F28)

- `snapshot.demandReady` : booléen additif. `Demand.ready(inv)` exige un inventaire
  de session non sale, mesuré après sa dernière reconstruction et la case de
  l'onduleur chargée. `entry.measured` devient faux à la fin du job de construction,
  vrai après `Demand.measure`. Aucun champ de sauvegarde, migration ou historique
  d'énergie ajouté. Le chargement d'une zone invalide toujours l'inventaire existant.
- `snapshot.pumps.w` : puissance arrondie déduite des débits déjà mesurés, avec
  le même rapport cyclique que `Pump.demandW`. Construction d'instantané en lecture
  seule : ne pas appeler `demandW`, qui consommerait le compteur de litres.
- `BreakerPanel.readings` somme `appliances[].w`, catégorie `light` séparée,
  toutes les autres plus `pumps.w` dans équipements. Le total est la somme des
  deux lignes ; veille, pertes, production et charge des batteries exclues.
  Ne pas utiliser `consumers`, dont la présentation est plafonnée à 200 lignes.
- Réseau non alimenté, principal ouvert ou protection déclenchée : zéro. Mesure
  inconnue : tirets et « Actualisation… » ; circuit ouvert connu sans charge :
  « 0 W / coupé ». En recouvrement, conserver les watts mesurés d'une charge
  dépendant d'un autre tableau mais facturée à cette ancre, sans les masquer.
- `Client.discardSnapshot(id)` libère les caches solo/MP de cet onduleur à
  l'ouverture du tableau et lors d'un changement de raccordement. En solo, cela
  force aussi la relecture du drapeau de fraîcheur à révision inchangée. En MP,
  la souscription existante fournit le nouvel instantané, sans nouvelle commande.
- Calcul des trois lignes seulement quand la référence d'instantané change ;
  libération à la fermeture. Le dessin utilise `UIFont.Small` et `drawTextRight`
  vanilla, compatibles CJK. Rafraîchissement selon la simulation existante, pas
  un relevé de consommation à chaque image. Aucune nouvelle diffusion globale.

### Lecture de la powerbank

- `readBank` (client → serveur) : `{device,seq}`, ID persistant d'un stockage,
  séquence entière 1..1 000 000 000. Réutilise la limite de commandes existante,
  `Commands.checkDevice` (case chargée, même étage, portée 3, refuge autorisé).
- `bank` (serveur → demandeur) : primitives détachées `{device,seq,model,slots,
  extra,stock,capacity,reserve,batteries}` ; batteries : `{model,charge,capacity,
  cond,coldFactor}`. Les énergies sont en kWh utiles, condition en pourcentage.
  Pas d'objet Java, pas de référence au registre, pas d'écriture d'énergie.
  Lecture toutes les deux secondes pendant l'ouverture, une seule réponse en cache.
  Les réponses d'une ancienne banque ou d'une séquence antérieure sont ignorées.
- `LWUnlinkAction(character,target,device)` : action native après déplacement,
  cible encore présente, marque concordante, autorité prête, proximité et refuge
  revérifiés ; délègue à `C_UNLINK`. Aucune nouvelle règle métier de débranchement.
- Instantané des consommateurs : ajout facultatif de `objectIndex` (position dans
  la liste Java, base zéro) et `sprite`. Ces champs n'entrent pas en sauvegarde.
  Résolution cliente une fois par seconde sur les seules cases signalées (200 objets
  maximum) ; index vérifié par sprite, sinon sprite unique. Jamais un identifiant
  persistant ; aucune migration de données.
- Surbrillance native par joueur, persistante entre rendus, purement cliente.
  Pas de copie d'objet, de baisse d'alpha des appareils, de nouveau paquet pour
  activer/masquer la vue ni de parcours du monde dans `render`.
- 27 nouvelles clés traduites dans les onze langues, dont la mention du fabricant
  et les commandes/refus d'empilage.
  Les éléments des panneaux
  sont dessinés avec les classes ISUI et les primitives natives existantes.


## Contrat d'empilage des powerbanks

- Les sprites existants 16–19 du tileset existant reçoivent seulement les propriétés
  `IsTable`, `IsStackable` et `Surface=18`. Même tiledef, mêmes indices, même pack,
  mêmes profondeurs. Le rack culmine à environ 0,44 m ; 18 unités natives représentent
  environ 0,46 m. Le décalage supérieur est géré par la pose et l'empilage vanilla.
- `shared/LW_Stack.lua` possède les règles locales : deux banques au plus, support
  autorisé, ordre des unités et protection d'un support portant un autre objet.
  Aucun registre, cache global d'objets, abonnement de tick ni commande réseau ajouté.
- `LW_Placement` utilise ces règles dans la validation de pose, ramassage et rotation,
  ainsi qu'avant les opérations de retrait/rotation. Le démontage pour pièces vérifie
  aussi le support sur l'autorité. Les autres modèles et les signatures vanilla sont
  conservés. Le refus de pose précède le retrait d'inventaire vanilla.
- Deux banques sur une case ont deux ID persistants. L'index `byPos` du registre
  contient déjà une liste d'ID ; les conteneurs et batteries sont résolus par marque,
  jamais par le seul couple case/modèle. Les contenus et instantanés restent séparés.
- Le LCD recalcule le numéro de banque pendant sa lecture toutes les deux secondes
  ou lors d'un clic de sélection ; la liste de raccordement le calcule pendant son
  rafraîchissement explicite. Le curseur vanilla vérifie seulement la case visée
  pendant la pose ou le déplacement ; aucun balayage du monde ou entretien continu
  des piles n'est ajouté.
- Pas de migration de schéma ni de conversion des objets, batteries ou données de
  réseau. Les propriétés natives nouvelles sont relues au prochain démarrage.

## Butin d'équipements configurable (F31)

`LiveWire_Distributions.lua` conserve le périmètre autoritaire (retour immédiat
sur client MP). À `OnPreDistributionMerge`, ajout ou mise à jour idempotente des
poids de base ; à `OnInitGlobalModData`, lecture de `Config.get` après chargement
des options de la partie, bornage 1–20, puis poids absolu `base × multiplicateur`.
`ItemPickerJava.Parse()` est rappelé uniquement si des poids ont changé ; les
multiplicateurs vanilla de butin restent intacts. Aucune lecture par tick, aucun
parcours du monde, remplissage forcé ou commande réseau supplémentaire.

Neuf types d'équipement et deux composants, 88 couples type/liste contre 31 précédemment : panneaux,
testeurs, batteries stationnaires, onduleurs, disjoncteurs, powerbanks, alarmes et
éoliennes. Les nouvelles catégories sont `CrateElectronics`, `ElectronicStoreMisc`,
`CrateMetalwork`, `ToolStoreMetalwork`, `MechanicShelfTools`, `CrateMechanics`,
`CampingStoreGear` et `ElectronicStoreAppliances`, selon l'équipement. Les cellules
utilisent douze listes (quatre ajoutées). Tous les ajouts sont des types propres à LiveWire,
y compris ses meubles déclarés sous `Base.Mov_LiveWire_*`. Les entrées vanilla
existantes restent identiques : aucune suppression, insertion d'objet vanilla,
modification de poids, de nombre de tirages ou de catégorie de conteneur. Les
pièces vanilla ne sont jamais multipliées. Aucun cache de poids vanilla.
CD inchangé. Les roues sont désormais trouvables ; les pompes ne sont pas ajoutées au butin.

Valeur par défaut 5, y compris pour une sauvegarde sans option enregistrée ; 1
retrouve les anciens poids dans les anciennes catégories, en gardant les lieux
supplémentaires. Pas de migration de données. Changement appliqué au redémarrage
complet du jeu/serveur, pour les tirages futurs, réapparition vanilla comprise si
activée. Aucun effet rétroactif sur le contenu sauvegardé des conteneurs.

Deux clés de traduction dans les onze langues :
`Sandbox_LiveWire_EquipmentLootMultiplier` et son suffixe `_tooltip`.
Le générateur de tableaux montre les poids à ×5 et estime la probabilité sous
condition de sélection de la liste : `1 − (1 − poids × modificateur / 100)^tirages`,
sans effet de densité de zombies, du temps ni limite de place. Cela ne mesure pas
la fréquence effective de découverte dans une carte ou une partie donnée.

Étagères de garage (2026-11-03). Les étagères des garages de maison tirent surtout
`GarageCarpentry`, `GarageMechanics` et `GarageMetalwork` (un conteneur au plus par
pièce pour chacune), rarement `GarageTools`. Ajouts, poids de base avant multiplicateur :
`GarageMechanics` reçoit le testeur (1), l'onduleur (0,3), le disjoncteur (0,3) et
l'alarme (0,3) ; `GarageMetalwork` reçoit le testeur (0,5), le disjoncteur (0,3),
l'éolienne (0,2), les pales (0,7) et le mât (0,7). Panneau solaire : `GarageMetalwork`
0,2 → 0,5, `GarageMechanics` 0,3. Total : 98 couples type/liste procéduraux.

Véhicules (2026-11-03). Table `VEHICLE` sur les listes partagées de `VehicleDistributions` :
`ElectricianTruckBed` (4 tirages ; testeur 2, cellules 2, disjoncteur 1, alarme 1,
onduleur 0,5, banque d'énergie 0,5, panneau 0,5), `ElectricianGloveBox` et
`ElectricianSeat` (1 tirage ; testeur 1), `MetalWelderTruckBed` (4 tirages ; pales 1,
mât 1, éolienne 0,3, panneau 0,3). Profil électricien : utilitaires `Van_LectroMax`,
`VanPluggedInElectrics`, `Van_VoltMojo`, et profil tiré parmi d'autres pour
camionnettes, fourgons et pick-up. Même multiplicateur et même mise à jour
idempotente ; `ItemPickerJava.Parse()` relit aussi `VehicleDistributions[1]`, dont les
profils partagent ces tables par référence. Le fichier ne fait **pas** de
`require "Vehicles/VehicleDistributions"` : il s'exécuterait avant les tables de
déchets des véhicules et laisserait leurs `junk` vides ; la table n'est lue que
dans les événements. 13 couples véhicule. Un véhicule déjà apparu n'est pas re-rempli.

## Fabrication des sources et composants (F32)

- Objets normaux : `LiveWire.WindTurbineBlades` (jeu de trois pales, poids 4,1),
  `LiveWire.WindTurbineMast` (4,6). Représentations vanilla temporaires :
  SheetMetal/MetalSheet et SteelRod_Full/SteelRod.
- Recettes `LWMakeWindTurbineBlades` et `LWMakeWindTurbineMast` en Metalworking,
  sans niveau requis, avec 2 XP d'Électricité chacune. Assemblage : niveau 3/30 XP éolienne,
  4/30 XP roue ; deux `Base.Amplifier` dans chaque recette. Démontage vanilla des
  haut-parleurs intégralement conservé, sans hook ni recette dédiée.
- Durée éolienne 180 + 180 + 240 = 600. Mât : `Base.MetalPipe` au lieu du tuyau
  plastique `Base.Pipe`, deux barres ; total des trois étapes : six vis.
- `Defs.devices.*.level` est le niveau de **branchement** ; il n'est plus relié à
  `PickUpLevel` (tuiles sans `PickUpLevel` ni `PlaceTool`, D-29). Tiledef 7174, tileset ID 1, indices,
  sprites, packs, profondeur et état des machines conservés. Pas de migration
  des objets publiés. Le type intermédiaire de prototype non publié est retiré,
  sans conversion d'éventuels inventaires de test ; aucune sauvegarde n'est éditée.
- Butin : 88 couples type/liste pour neuf équipements et deux nouveaux composants,
  plus douze listes de cellules et le CD indépendant. Éolienne sur dix listes,
  roue sur sept ; pales et mât sur six chacun. Catégories réellement référencées
  par les salles installées. Entrées vanilla, dont Amplifier, strictement conservées.
  Aucun traitement périodique ni paquet ajouté.

Redémarrage complet requis. Aucune conversion d'anciens réseaux.

### Icônes des résultats d'artisanat

Le menu consulte `CraftRecipe.OnPostWorldDictionaryInit`, qui prend
`Item.getNormalTexture` sur le résultat. `Icon=default` donne ici le repli « ? »
(`Item.java`, analyse du paramètre Icon), même si `Moveable.ReadFromWorldSprite`
calcule ensuite une icône sur l'objet créé. Les huit équipements ont donc une
déclaration `Icon=LiveWire<Nom>` ; sept PNG RGBA 64×64 sont extraits de leurs
sprites existants par `source/icons/extract_equipment_icons.py --forge <outil>`.
L'éolienne garde son icône avec pales. Résolution par
`Texture.trygetTexture` → `media/textures/Item_LiveWire<Nom>.png`, casse exacte.
La recette de récupération de cellule déclare `Icon=LiveWireSolarCell` puisque
sa première sortie est aussi un déchet. Aucun callback d'UI ni paquet réseau.

### Recette de démontage du testeur

`LiveWire.LWDismantleVoltageTester` : `DismantleElectrical`, temps 60, catégorie
Electrical, tags InHandCraft/Electrical, sans apprentissage ou niveau requis,
2 XP d'Électricité. Entrées : tournevis par tag `base:screwdriver`, mode keep,
NoBrokenItems ; un `LiveWire.VoltageTester`, mode destroy, ItemCount/ResearchInput.
Sortie unique : un `Base.ElectronicsScrap`. Consommation et synchronisation natives,
aucun callback ou hook ajouté. Identifiants existants et sauvegardes inchangés.
Clé de recette traduite `LWDismantleVoltageTester` dans les onze langues.

### Recettes de démontage des pièces intermédiaires — D-64

`LWDismantleWindTurbineBlades` : `DismantleElectrical`, temps 60, catégorie
Electrical, tags InHandCraft/Electrical, sans niveau requis, 1 XP d'Électricité ;
tournevis par tag `base:screwdriver` (keep, NoBrokenItems) ; un
`LiveWire.WindTurbineBlades`, mode destroy. Sorties : `Base.SheetMetal`, `Base.Screws`.
Pas d'OnCreate ni de partie électronique.

`LWDismantleWindTurbineMast` : même forme, temps 60, 1 XP ; tournevis et clé à tuyau
(`base:pipewrench`, MayDegradeVeryLight) ; un `LiveWire.WindTurbineMast`, mode destroy.
Sorties : `Base.MetalPipe`, `Base.MetalBar`, `Base.Screws`. Pas d'OnCreate.

`LWDismantleDeepCycleBattery` : temps 120, 2 XP ; tournevis ; un
`LiveWire.DeepCycleBattery`, mode destroy ; `Tooltip_LW_Dismantle` et
`OnCreate = LiveWire.Recipes.onDismantle`. Sortie fixe : `Base.ScrapMetal`.
`LW_Recipes.lua` ajoute `Base.ElectricWire` (2 au plus) selon l'état de la batterie,
lu sur l'objet (`getCondition()`, la batterie n'a pas de marque) : entrée
`LiveWire.Recipes.DISMANTLE`, puis `salvaged`.

Chaque total reste sous sa fabrication (`test_dismantling_always_returns_less_than_the_crafting_recipe`).
Clés traduites dans les onze langues (`tools/translations_ixx.py`, EN et FR via
`tools/translations_src.py`).

## Risque sous tension et XP — règle révisée le 2026-10-25

`Maintenance.shockChance(level)` : `floor(50 × max(0, 6 − level) / 6 + 0,5)` ;
niveaux réels 0–5 : 50, 42, 33, 25, 17, 8 pour cent ; nul dès 6.
`LiveWorkRisk` est activé par défaut. Pas de tirage si l'option est désactivée,
le réseau/onduleur absent, ou `inv.state == "off"`. Le contrôle ne dépend plus de
`grid.powered` : principal, circuits, protection, panne ou stock vide n'isolent pas
les bornes. Un seul tirage sur l'autorité par intervention admissible.

`Install.screwdriverHand(character)` teste séparément les mains équipées, sans
`ipairs` sur une table à trou. Tournevis valide en primaire → `Hand_R` ; sinon
en secondaire → `Hand_L` ; outil d'inventaire → primaire/droite. Si les deux
mains ont un tournevis valide, primaire prioritaire. `Install.showScrewdriver`
emploie le même choix pour l'animation et passe l'InventoryItem réel à
`setOverrideHandModels`, sans transfert d'inventaire ni état client autoritaire.

Conséquences inchangées : douleur additionnelle au moins 10 et BurnTime au moins
5 sur cette main, sans réduire une blessure préexistante ; lâcher natif des objets
tenus, synchronisation des dégâts, notification et journal. Retour avant dépense
des matériaux et XP de réparation. Appels : raccordement, débranchement,
réparation/remise à neuf et démontage pour pièces. Le débranchement exige désormais
un tournevis valide sur l'autorité, y compris par la commande directe.

Arrêt d'urgence : `setInverter(on=false)` permet aussi de passer de broken/tripped
à off ; les commandes client LCD et menu proposent cet arrêt. Condition et
identifiants restent inchangés. La physique traite toujours un convertisseur
d'état nul comme broken, même interrupteur off : aucune reprise de charge due au
seul changement d'interrupteur. Une réparation reste nécessaire.

Réparations réussies : `min(15, 5 + floor(état gagné))` XP, par `LW_Xp` sur
l'autorité ; reconditionnement batterie : 8 XP. Chaque craftRecipe LiveWire a
un `xpAward=Electricity:<positif>` natif. Ajout de 2 XP sur pales et mât, sans
niveau requis ; autres coûts, durées et XP conservés. Aucune nouvelle persistance,
migration, boucle périodique ou commande réseau.


### Défaut du risque électrique et sauvegardes

`sandbox-options.txt` et le repli `Config.DEFAULTS` déclarent `LiveWorkRisk=true`.
Une valeur explicite enregistrée `false` reste prioritaire : aucune réécriture des
options d'une partie ni migration forcée. Pour une ancienne partie désactivée,
activer « Risque sous tension » dans ses options sandbox. La règle de sécurité et
les probabilités restent celles ci-dessus ; aucun contrôle par image ajouté.


### État affiché dans les panneaux — F29

`Client.equipmentCondition(cond)` formate la valeur numérique bornée à 0–100,
arrondie au pourcentage ; nil/invalide donne « -- », jamais 100 par défaut.
`IGUI_LW_EquipmentCondition` est traduit dans les onze langues. Les marques
`Marks.get(obj).cond` déjà synchronisées alimentent le LCD powerbank et celui du
tableau ; indépendants, cassés et banques empilées utilisent leur propre objet.
La charge et l'état des batteries continuent de venir de la vue bancaire existante.
La hauteur du LCD powerbank est calculée à l'ouverture selon la police, avec les
boutons sous l'écran. La liste de raccordements réutilise son actualisation à une
seconde pour préparer les libellés d'état de ses objets déjà découverts. Aucun
parcours du monde, paquet, registre, schéma persistant ou cadence serveur ajouté.

### Écrans LCD (D-56)

Un seul vert rétroéclairé pour tous les écrans : fond 0.62/0.74/0.40, encre 0.08/0.13/0.05 (batterie, appareils,
onduleur allumé, afficheur et bande d'état du tableau de Live Wire et d'Extended). Pompe : fond 0.38/0.64/0.82,
encre 0.05/0.11/0.20. Onduleur éteint : fond 0.16/0.19/0.14, texte d'attente 0.6/0.65/0.55 ; surcharge en
0.55/0.05/0.02. Cadre 0.06/0.07/0.06 et reflet blanc à 16 % sur 2 px en haut de chaque écran. Texte d'écran en
`LiveWire.Client.lcdFont()` (`UIFont.Code`, `UIFont.Small` en CN, JP, KO, TH) ; le texte imprimé sur la façade du
tableau reste en `UIFont.Small`. Lignes trop longues : défilement aller-retour à 40 px/s de référence avec une
pause de 1,2 s à chaque bout (batterie, appareil, onduleur) ; sur le LCD du tableau, abrégées avec « ... » en ASCII
(`Lcd.ELLIPSIS`, la police d'écran n'a pas le caractère « … ») ; le texte imprimé sur la façade du tableau est abrégé
avec « … » (`LW_Enclosure.lua`, D-54).

### Fenêtres de coffret : kit commun (D-54)

Une seule fabrique de dessin pour la fenêtre du disjoncteur de Live Wire (`client/LiveWire/LW_BreakerPanel.lua`) et
celle du tableau d'Extended (`client/LiveWireExtended/LWX_BoardWindow.lua`) : `LiveWire.Enclosure`
(`client/LiveWire/LW_Enclosure.lua`), obtenu par `LiveWire.API.enclosure()` (tableau de l'API ci-dessus). Le module
n'est chargé que sur le client (`isServer()` : retour immédiat).

- Fonctions pures, sans dessin, testées hors jeu (`tests/test_enclosure.py`) : `columns` (R5 : 5, puis 3, 2, 1 colonnes), `abbreviate`
  (R3), `wrap` (R4), `plateText` (R7 : « 30 A », puis « 30 »), `twoPass` (R2 : contenu à l'échelle 1, facteur de
  fenêtre `LW_UIScale.factor`, puis contenu à ce facteur, abaissé une fois si la fenêtre ne tient pas), `needsCompact`
  (R6), `grid`, `layout` (positions de toutes les pièces, en unités de référence 1080p).
- Dessin : `frame` (fond crème, capot fumé, charnières, plaque, renfoncement, en-tête), `lcd` (bloc LCD, `LiveWire.Lcd`,
  D-56), `module` (levier, bande et plaque de calibre), `plate`, `closeButton` (croix de l'en-tête), `cellButton` et `setLook` (bouton, grisé
  sans sélection). Tout est multiplié par `ui.lwK` (`LW_UIKit`).
- R8 : les tailles se calculent à l'ouverture et au changement de contenu, jamais à chaque image.
- Commun aux deux fenêtres : en-tête, afficheur LCD, capot et plaque du fabricant (« legrand »), grille de modules
  sur rails, boutons en bas du coffret, texte d'aide. Propre à chaque fenêtre :
  - disjoncteur de Live Wire : taille de référence 750 × 477 (`Panel.BASE`), en-tête « Tableau électrique »
    (`IGUI_LW_BoardTitle`), LCD des lignes éclairage, équipements et total ;
  - tableau d'Extended : taille de la grille selon `record.size` (8, 16 ou 24 modules, `X.Panel.SIZES`), rangées de 8
    sauf si la fenêtre ne tient pas en hauteur : `X.Panel.gridColumns(size, fits)` (fonction pure, testée par
    `tests/test_extended_board_window.py`) essaie 8 colonnes, puis moins de rangées plus longues (24 → 12, 16 → 16) tant
    que la largeur tient ; `fits` refait le facteur (R2) et le choix du capot (R6) pour chaque essai, à l'ouverture
    seulement (R8) ; `moduleRect`, le clic et les rails suivent `L.cols`. En-tête
    « Tableau électrique : N modules occupés sur M » (`IGUI_LWX_BoardTitle`), boutons Étiquette, Localiser,
    crépusculaire et Retirer, glisser-déposer d'un disjoncteur sur un module vide, LCD du disjoncteur sélectionné
    ou du total (`IGUI_LWX_Lcd*`), nom du réseau par `API.gridName` (abonnement `API.subscribeInverter` à l'ouverture).

### Fermeture des panneaux et retrait différé

Les panneaux tableau, powerbank et raccordements marquent leur instance `closed`,
la masquent par `setVisible(false)`, puis demandent son retrait et libèrent leurs
références. Leur dessin, mise à jour et gestion des boutons sortent immédiatement
si l'instance est fermée. `close()` est idempotent : un ancien panneau ne peut ni
effacer l'instance suivante ni vider sa vue bancaire. Le moteur diffère le retrait
effectif de `UIManager.RemoveElement` ; aucune donnée d'affichage ne doit être
consultée après fermeture. Les écrans onduleur et logiciel masquent déjà leur
fenêtre avant retrait et ne libèrent pas les données utilisées par un dernier dessin.


### Lecture des LCD sources, pompe et alarme

- `readDevice` : `{device,seq}`, même séquence entière 1..1 000 000 000 que les
  lectures bancaires, même limite globale de quatre commandes/seconde/joueur.
  `Commands.checkDevice` : case chargée, même étage, portée 3, refuge autorisé ;
  `Devices.find` vérifie l'objet physique. Registre prêt/non readOnly et joueur
  vivant contrôlés par le dispatcher existant. Un joueur ordinaire peut lire.
- `device` : réponse au seul demandeur, `{device,seq,model,kind,cond,inverter?,name,
  state,w?,nominal?,flow?,dirt?,snow?,brake?}` ; aucune référence Java ou au registre.
  `DeviceView.snapshot` accepte source, pompe et alarme avec modèle/rôle concordants.
- Sources : `w` est `pOut` arrondi, c'est-à-dire le dernier relevé lissé déjà calculé
  avec météo, orientation, saleté et état. Sans réseau, cassé ou frein serré : zéro.
  La puissance nominale vient de la définition, neige/saleté des fractions existantes.
  Le LCD ne lance ni `Sim.stepGrid` ni `sourceRaw`.
- Pompe : son propre `flowLph` mesuré, watts de `pumpW * clamp(flowLph / (5*60),0,1)`.
  Même mesure de duty que l'instantané global, sans `Pump.demandW` qui consomme
  le compteur de litres. Si non alimentée, circuits ouverts, maître arrêté/cassé,
  pompe désactivée ou cassée : zéro débit/consommation. `pumped`, barils et relais
  ne sont pas modifiés. Les moyennes suivent le dernier pas de simulation.
- `Client.deviceView` : une seule vue. Séquences plus anciennes, autre appareil,
  fenêtre fermée ou appareil rouvert : réponses rejetées. `DevicePanel` interroge
  à deux secondes seulement s'il est ouvert et accessible ; un changement de lien
  efface l'ancien relevé avant la nouvelle requête. Fermeture sécurisée idempotente.
- `ConnectionPanel.deviceOnly` est vrai pour un équipement LiveWire autre qu'un
  onduleur : seule l'origine est listée. Changer l'onduleur réévalue ce seul objet.
  Depuis l'onduleur (maître/couplé), le mode global existant est conservé. Pas
  de transfert automatique entre réseaux : débrancher du réseau actuel d'abord.

Ces deux commandes additives sont nécessaires à la télémétrie individuelle des
pompes et des appareils indépendants, absente de l'instantané réseau. Aucun
abonnement/broadcast, tick serveur ou schéma de sauvegarde ajouté. Les anciens
identifiants, contrats `readBank`/`bank`, raccordement et simulation sont conservés.


### Voyants de pompe et de tableau — contrat de marque

Le booléen `pw` existant de la marque est désormais calculé aussi pour pompe et
disjoncteur par `Devices.stateOf`, puis diffusé par les chemins existants.
Pompe : réseau powered, maître on/intact, pompe intacte, ni mainOff ni equipmentOff,
service non désactivé. Tableau : réseau powered, maître on/intact, tableau intact,
ni mainOff ni tripped. La coupure des seuls circuits ne supprime pas son voyant.
`Devices.refreshStates` compare déjà `shownPw` : seuls les changements d'état
déclenchent la synchronisation. Aucun nouveau message, tick ou abonnement.

`Visuals.wanted` choisit 80–83 pour le bleu de la pompe selon `pw`, indépendamment
du nombre de relais ; 84–85 pour le vert du tableau, 64–65 rouges prioritaires en
disjonction. Le suivi borné existant des objets est conservé. Les indices 84/85
étaient réservés et vides ; tiledef, dimensions 88 cases, définitions des tuiles,
indices d'objets et autres pixels du pack/profondeur ne sont pas modifiés.
Pas de migration de sauvegarde. L'export Viewpoint ajoute seulement le modèle
`breaker_on` et les deux binds correspondants ; palette et anciens modèles conservés.

Recette : `source/tiles/breaker_power.py`, rendu par `build_livewire_tiles.py`
(groupe `breaker_on`). `install_breaker_power.py` conserve les cellules existantes,
installe les deux nouveaux sprites et leurs profondeurs raytracées, vérifie la
relecture et garde les preuves brutes dans le dossier de rendu ignoré.
Le modèle éditable `.blend` est conservé localement avec ces rendus ; les recettes
versionnables restent portables, sans chemins personnels. Le LCD de pompe emploie
une palette bleue et le débit FR une apostrophe ASCII : l'ancienne U+2019 n'est
pas couverte par la police LCD mono. Pas de modification du routage du clic.

### Armoire onduleur (1.7.0)

Second modèle d'onduleur, `Defs.devices.InverterCabinet` : `role = "inverter"`,
`maxW = 4500`, `idleW = 60`, niveau 3, XP 35, `wearDays = 5`, objet
`Base.Mov_LiveWire_InverterCabinet`, tuiles 88-91 (S, E, N, W). Recette
`LWMakeInverterCabinet` (Électricité 3) : 1 `Base.Mov_LiveWire_Inverter`, 4 déchets
électroniques, 2 amplificateurs, 4 fils, 1 plaque d'acier, 8 vis ; tournevis et pince
conservés. Absente des tables de butin. L'état d'un onduleur consommé par la recette
est perdu ; l'armoire est un appareil neuf.

Tout ce qui vise un onduleur passe par `role == "inverter"` ; les deux seuls endroits
liés au modèle sont devenus génériques :
- `Inverters.capacityW` et `Inverters.idleW` additionnent les valeurs de chaque onduleur selon son
  propre modèle (maître en service, esclaves en service ou allumés) ; un réseau d'un seul
  modèle garde exactement les anciens chiffres. Un onduleur et une armoire se couplent
  entre eux (`MAX_SLAVES` inchangé).
- `Visuals.wanted` lit les calques dans `def.overlays` (onduleur 24/28/68, armoire
  92/96/100, + orientation) et le bourdonnement suit tout onduleur. L'écran LCD affiche
  la marque du modèle (`def.lcdBrand`, `IGUI_LW_LCD_BrandCabinet`).

Le jeu de tuiles passe de 88 à 104 cases (13 rangées). Le modèle
`source/tiles/models/oso_inverter.glb` (0,90 × 0,74 × 2,00 m) est offert par
PewPewCricket, diffusé sous licence MIT avec son accord (crédits du `README.md`) ; les
modèles de tableau `breaker_panel_*.glb` sont gardés pour plus tard. Recette des tuiles :
groupes `cabinet*` de `build_livewire_tiles.py` (`import_glb`, couleurs du modèle en
peintures de la forge, lumières éteintes sur la tuile de base). Installation :
`equipment_models.py` + `install_equipment_models.py`, qui ajoutent les cases 88-103 au
pack, à la carte de profondeur et aux définitions de tuiles en vérifiant que les 88 cases
existantes (pixels, profondeur, propriétés) restent identiques. Icône par
`source/icons/extract_equipment_icons.py`. Viewpoint : palette complétée des couleurs du
modèle (`glb_paints()`), modèles `cabinet*` et liaisons 88-103 ; les autres modèles ne
changent que par leurs coordonnées de palette.

**Roue à aubes animée (1.8.0, D-58).** Comme l'éolienne, la tuile de la roue (8-11) ne
porte plus la roue : le client dessine toujours une des quatre images de roue,
`overlays.rotor = 104` (calque 104 + 4 × image + orientation, cases 104-119). La roue a
10 aubes et 5 rayons, donc une symétrie de 36° : quatre images de 9° bouclent sans saut.
`rotorFrame` (`LW_Visuals.lua`) suit le type de la source : vent pour `wind`, rivière pour
`hydro`. La roue tourne tant que `m.cond > 0` et sans `m.br` (la rivière est une règle de
pose), une image toutes les `HYDRO_PERIOD_MS = 250` ms divisées par `Physics.hydroFactor`
du mois (printemps plus vite, été plus lent). La boucle de 100 ms anime tout appareil qui
déclare `overlays.rotor` (avant : l'éolienne seule ; une source ajoutée par l'API avec un
`rotor` tourne donc aussi à cette cadence). `isOverlay` couvre 92-119.

Les tuiles 8-11 reçoivent `CustomItem = Base.Mov_LiveWire_WaterWheel` : ramassée, la roue
redevient l'objet du script et garde son icône (sans `CustomItem`, l'objet générique
`Moveables.<sprite>` prend l'icône découpée dans la tuile, désormais sans roue ;
`Moveable.java:118-175`). Poids identique (30), même nom. Une roue générique déjà dans un
inventaire se pose toujours : la pose cherche l'objet par `getWorldSprite()`
(`ISMoveableSpriteProps.findInInventory`, `ISMoveableSpriteProps.lua:1040-1060`) ; elle
garde l'icône tirée de la tuile.

Sauvegardes et multijoueur : aucun index ne bouge (les calques sont ajoutés à la fin), les
roues posées gardent leur sprite et leurs marques, et le calque est recalculé par chaque
client à partir de la marque ; rien de neuf ne passe par le réseau. Le jeu de tuiles passe
de 104 à 120 cases (15 rangées). Recette : `hydro_wheel` / `build_hydro_rotor` de
`build_livewire_tiles.py`. Installation : `hydro_rotor.py` + `install_hydro_rotor.py`,
qui redessinent 8-11 et ajoutent 104-119 au pack, à la carte de profondeur et aux
définitions, en vérifiant que toutes les autres cases (pixels, profondeur, propriétés)
restent identiques et que 8-11 ne gagnent que `CustomItem`. Viewpoint : modèle `hydro`
sans roue, modèles `hydro_rotor0-3` et liaisons 104-119.
