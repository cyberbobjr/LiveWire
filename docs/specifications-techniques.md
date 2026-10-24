# Live Wire — spécifications techniques

Contrats techniques du mod tels qu'ils existent dans le code de la **version 1.3.1** (relevé statique du 2026-10-21, `Contents/mods/batman_LiveWire/42.21`). Ce document fait foi pour les identifiants, formats et bornes ; les justifications sont dans [`architecture.md`](architecture.md), le comportement vu du joueur dans [`specifications-fonctionnelles.md`](specifications-fonctionnelles.md).

Toute modification d'un identifiant de ce document (type d'objet, clé de ModData, nom de modèle, nom de commande, nom d'option) casse les sauvegardes ou le multijoueur : elle exige une migration (§ 4.4).

---

## 1. Mods, versions et chargement

| Mod | `id` | Dossier | `require` | Rôle |
|---|---|---|---|---|
| Live Wire | `batman_LiveWire` | `Contents/mods/batman_LiveWire/42.21` | — | Mod principal |
| Live Wire - Viewpoint models | `batman_LiveWireViewpoint` | `Contents/mods/batman_LiveWireViewpoint/42.21` + `common` | `\batman_LiveWire` | Modèles 3D pour Project Viewpoint (facultatif) |

- `versionMin=42.21`, `modversion=1.3.1` dans les deux `mod.info`. Objet Workshop : `3821807453` (`workshop.txt`).
- Le mod principal déclare `pack=batman_livewire_01` et `tiledef=batman_livewire_01 7174`.
- Constantes de code (`media/lua/shared/LiveWire/LW_Core.lua`) : module réseau `LiveWire.MODULE = "LiveWire"`, schéma du registre `LiveWire.SCHEMA = 2`, pas nominal de simulation `STEP_HOURS = 1/6` (`EveryTenMinutes`). `LiveWire.VERSION` vaut encore `"0.1.2"` (non mis à jour depuis la 0.1.2 ; écart à corriger dans le code).
- Côtés : `shared` (définitions, physique, protocole, actions chronométrées), `server` (registre, simulation, commandes ; chaque fichier commence par `if isClient() then return end`), `client` (menus, écrans, sons). Détail des modules : [`architecture.md`](architecture.md) § 2.

## 2. Objets et scripts

### 2.1 Objets d'inventaire (`media/scripts/LiveWire_items.txt`, module `LiveWire`)

| Type complet | `ItemType` | Poids | Usage |
|---|---|---|---|
| `LiveWire.VoltageTester` | `base:normal` | 0,3 | Testeur de tension (lecture de l'état d'un appareil) |
| `LiveWire.SolarCell` | `base:normal` | 0,05 | Ingrédient du panneau solaire |
| `LiveWire.DeepCycleBattery` | `base:drainable` | 9,0 | Batterie à décharge profonde (`ConditionMax = 100`, `KeepOnDeplete`) |
| `LiveWire.SoundproofKit` | `base:normal` | 3,0 | Kit d'insonorisation d'un onduleur |
| `LiveWire.CouplingKit` | `base:normal` | 0,3 | Kit de couplage d'un onduleur esclave |
| `LiveWire.MonitorDisk` | `base:normal` | 0,1 | Disque du logiciel pour le Computer Mod |

### 2.2 Appareils posés (`LiveWire_moveables.txt`, module `Base`, et `LW_Defs.lua`)

Chaque appareil est une tuile de la feuille `batman_livewire_01` ; l'objet d'inventaire est un `base:moveable` posé au curseur de meubles vanilla (outil `Electrician`, niveau `PickUpLevel` de la tuile). Le **nom de modèle** est la clé stockée dans le registre : ne jamais le renommer.

| Modèle (`Defs.devices`) | Objet posable | Rôle | Tuiles (index, orientations) | Chiffres | Niveau | XP pose | Usure (`wearDays`) |
|---|---|---|---|---|---|---|---|
| `SolarPanel` | `Base.Mov_LiveWire_SolarPanel` | `source` / `solar` | 0, 4 | 100 W nominal, dehors | 3 | 10 | 10 |
| `WindTurbine` | `Base.Mov_LiveWire_WindTurbine` | `source` / `wind` | 4, 4 | 400 W nominal, dehors | 6 | 20 | 4 |
| `WaterWheel` | `Base.Mov_LiveWire_WaterWheel` | `source` / `hydro` | 8, 4 | 120 W nominal, dehors, rivière | 7 | 20 | 6 |
| `Inverter` | `Base.Mov_LiveWire_Inverter` | `inverter` | 12, 4 | 1 500 W max, 20 W à vide | 5 | 25 | 5 |
| `PowerBank` | `Base.Mov_LiveWire_PowerBank` | `storage` | 16, 4 | 4 batteries comptées, conteneur `livewirepowerbank` (capacité 50) | 2 | 5 | 30 |
| `Breaker` | `Base.Mov_LiveWire_Breaker` | `option` / `breaker` | 20, 2 (mural) | — | 3 | 5 | 15 |
| `BatteryAlarm` | `Base.Mov_LiveWire_BatteryAlarm` | `option` / `alarm` | 22, 2 (mural) | alerte sous 20 %, réarmée à 25 %, rappel toutes les 2 h | 2 | 5 | 30 |
| `WaterPump` | `Base.Mov_LiveWire_WaterPump` | `pump` | 72, 4 | 250 W, 5 L/min | 6 | 20 | 10 |

- Tuile `batman_livewire_01_76` : réservoir relais transparent de la pompe (`Defs.RELAY_SPRITE`), jamais reconnu comme appareil.
- Objets vanilla raccordés (rôles du registre sans tuile du mod) : générateur vanilla en secours (`role = "backup"`, modèle `BackupGenerator`, niveau 3) et ordinateur de bureau vanilla de gestion (`role = "computer"`, modèle `ManagementComputer`, niveau 6 ; délestage au niveau 7).

### 2.3 Batteries reconnues (`Defs.batteries`)

| Type | Capacité | Cycles de vie |
|---|---|---|
| `Base.CarBattery1` | 0,40 kWh | 150 |
| `Base.CarBattery2` | 0,60 kWh | 150 |
| `Base.CarBattery3` | 0,90 kWh | 150 |
| `LiveWire.DeepCycleBattery` | 1,50 kWh | 600 |

Constantes : rendement de charge 0,90 ; autodécharge 0,2 %/jour ; seuil de décharge profonde 20 % ; redémarrage à 2 % du stock ; lissage des sources τ = 0,5 h ; perte d'état à la disjonction sans disjoncteur 3 ; forte charge au-delà de 80 % ; usure ×1,25 d'un onduleur insonorisé. Rendement d'installation : 0,85 (niveau < 7), 0,95 (7-8), 1,0 (9-10). Échec de réparation : `max(5, 40 − 5 × niveau)` %, divisé par deux dès le niveau 8.

### 2.4 Recettes (`LiveWire_recipes.txt`, module `LiveWire`, catégorie `Electrical`)

`LWMakeVoltageTester`, `LWSalvageSolarCell` (calculatrice → cellule + débris électroniques), `LWMakeSolarCellFromScrap`, `LWMakeSolarPanelKit`, `LWMakeInverterKit`, `LWMakeWindTurbineKit`, `LWMakeWaterWheel`, `LWMakePowerBankKit`, `LWMakeBreakerKit`, `LWMakeWaterPump`, `LWMakeCouplingKit`, `LWMakeDeepCycleBattery`, `LWMakeBatteryAlarmKit`, `LWMakeSoundproofKit`. Ingrédients et niveaux : tableau généré [`wiki/fr/_tables.md`](wiki/fr/_tables.md) (`tools/make_doc_tables.py`, données de `tools/make_doc_images.RECIPES`).

### 2.5 Autres scripts

- `LiveWire_sounds.txt` (module `Base`) : `LiveWireInverterHum` (entendu à 1,5 case du centre de l'onduleur, `LW_Hum.lua`), `LiveWirePumpHum` (4,5 cases, pompe en marche).
- `LiveWire_models.txt` : modèles au sol provisoires des objets d'inventaire (`media/models_X/LiveWire/*.glb`).
- Butin : `media/lua/server/Items/LiveWire_Distributions.lua` (listes `ProceduralDistributions`) ; le disque `MonitorDisk` n'est ajouté que si le Computer Mod est actif. Tableau des chances : [`wiki/fr/09-tables-de-butin.md`](wiki/fr/09-tables-de-butin.md).

### 2.6 Actions chronométrées (`shared/LiveWire/TimedActions/LW_TimedActions.lua`)

`LWLinkAction` (raccorder, consomme le fil), `LWCoupleAction` (coupler un esclave), `LWLinkBarrelAction` (raccorder un baril, consomme un `Base.MetalPipe`), `LWRepairAction`, `LWInspectAction`, `LWMuffleAction` (insonoriser), `LWClearSnowAction`, `LWMeasureAction` (testeur), `LWReconditionAction`. Leur `complete()` s'exécute sur l'autorité et revérifie distance, niveau et objets.

## 3. Commandes réseau

Module `"LiveWire"` (`LW_Protocol.lua`). Client → serveur par `sendClientCommand` (`LW_ClientState.lua`, `Client.send`), traitées par `OnClientCommand` dans `server/LiveWire/LW_Commands.lua`.

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
| `setBrake` | `{ device, brake }` | éolienne, booléen, niveau d'Électricité 7 ajusté par sandbox, distance et safehouse via `checkDevice` | Frein explicite réversible ; production nulle lorsqu'il est serré |
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

### 3.5 Instantané (`Sim.snapshot`)

Champs principaux : `grid`, `rev` (révision croissante : la livraison n'est pas ordonnée), `name`, `inverter { id, model, state, cond, maxW, eff, powered, muffled }`, `demand`, `production`, `stock`, `capacity`, `lost`, `extra`, `banks`, `sources[] { id, model, kind, nominal, cond, w, raw, snow }`, `batteries[] { model, charge, capacity, cond, cycles }`, `options[] { id, model, cond, state }`, `appliances[] { cat, n, w }`, `coverage { radius, floors }`, `autonomyH`, et selon l'installation `coupled { n, total }`, `backup { id, state, fuel, maxFuel, w, start, stop }`, `computer { id, powered, shed }` avec `history[] { p, d, s }` et `dawnH`, `alarm { on, ack }`, `breaker { id, state }`, et les chiffres des pompes.

## 4. ModData et persistance

### 4.1 ModData globales

| Clé | Contenu | Diffusion |
|---|---|---|
| `LiveWire` | Registre de l'autorité : `schema`, `nextId`, `devices`, `grids`, `byPos`, `legacy`, `powerHistory`, `measureXp` | **Jamais** diffusée |
| `LiveWireAnchors` | `anchors[idOnduleur] = { x, y, z, on, log, log0 }` ; journal public limité à 16 changements, conservé pour compatibilité. Seuls les onduleurs maîtres et indépendants ont une ancre | À tous les clients, uniquement si l'état ou la position change |

### 4.2 Registre, schéma 2

- **Identifiants** `d<n>` (appareil) et `g<n>` (réseau), tirés de `nextId`, jamais réutilisés.
- **Appareil** (champs communs) : `id`, `role` (`source`, `inverter`, `storage`, `option`, `pump`, `backup`, `computer`), `model`, `x`, `y`, `z`, `grid`, `cond`, `eff`, `level` (niveau de l'installateur), `state`.
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
  5 L par minute, sans crédit accumulé au repos. Nettoyage sur tous les niveaux
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
| Ordinateur du Computer Mod | `ComputerModLiveWireInstalled` (données de l'ordinateur via `ComputerModComputerTypes`, préfixe imposé par la synchronisation de ce mod) | Logiciel installé |

### 4.4 Migrations

Complément du 2026-10-24 : la marque de l'onduleur porte `nm`, reflet du nom du
réseau pour préremplir le menu de renommage, sans nouvelle version de schéma.
Elle est actualisée après renommage et au chargement du chunk. Les constantes
inutilisées `C_REQUEST_ANCHORS`, `S_REFUSE`, `S_ANCHORS` et leur gestionnaire mort
sont retirés ; la table d'ancres continue de passer par `ModData.request/transmit`.

`server/LiveWire/LW_Migration.lua`, lancé à `OnInitGlobalModData`. Étapes idempotentes et journalisées ; aucune suppression (les données inconnues vont dans `legacy`). Étape 1 → 2 (0.1.1) : les appareils en sprites vanilla passent dans `legacy.schema1`, leurs ancres sont retirées. Un schéma plus récent que le code met le registre en lecture seule (simulation suspendue).

## 5. Options sandbox

`media/sandbox-options.txt`, page `LiveWire`, `VERSION = 1`. Lecture par `LW_Config.lua`.

| Option | Type | Défaut | Bornes | Effet |
|---|---|---|---|---|
| `LiveWire.ConsumptionProfile` | enum (`numValues = 4`, `valueTranslation`) | 3 | 1-4 | Profil de consommation (`LW_Consumption.lua`) : 1 ultra-réaliste 1993, 2 réaliste 1993, 3 valeurs du jeu, 4 confort. Valeur inconnue = 3 |
| `LiveWire.PowerScale` | double | 1,0 | 0,1-10 | Multiplie la consommation donnée par le profil (1 = aucun changement) |
| `LiveWire.SolarMultiplier` | double | 1,0 | 0-10 | Production solaire |
| `LiveWire.WindMultiplier` | double | 1,0 | 0-10 | Production éolienne |
| `LiveWire.HydroMultiplier` | double | 1,0 | 0-10 | Production de la roue à aubes |
| `LiveWire.BatteryCapacityMultiplier` | double | 1,0 | 0,1-10 | Capacité de chaque batterie |
| `LiveWire.BatteryWearMultiplier` | double | 1,0 | 0-10 | Usure des batteries (0 = aucune) |
| `LiveWire.DeviceWearMultiplier` | double | 1,0 | 0-10 | Usure des sources, onduleurs et équipements (0 = aucune) |
| `LiveWire.InverterNoiseRadius` | integer | 2 | 0-10 | Rayon du bruit entendu par les zombies (0 = silencieux) |
| `LiveWire.LinkRange` | integer | 12 | 4-30 | Distance maximale appareil-onduleur (1 étage d'écart au plus) |
| `LiveWire.PumpRange` | integer | 15 | 5-30 | Rayon des robinets alimentés par une pompe |
| `LiveWire.WirePerTiles` | integer | 4 | 0-20 | Un fil électrique par N cases de câble (0 = gratuit) |
| `LiveWire.StormDamage` | boolean | false | — | Orages et vents très forts abîment panneaux et éoliennes |
| `LiveWire.XPMultiplier` | double | 1,0 | 0-10 | Expérience donnée par les actions Live Wire |
| `LiveWire.SkillGates` | boolean | true | — | Désactivée : aucun niveau d'Électricité exigé |
| `LiveWire.SimulateUnloaded` | boolean | true | — | Production, consommation et usure continuent sans joueur proche |
| `LiveWire.BackupStartPercent` | integer | 20 | 0-90 | Démarrage du générateur de secours sous ce pourcentage de batterie |
| `LiveWire.BackupStopPercent` | integer | 90 | 10-100 | Arrêt du générateur ; seuil effectif relevé si nécessaire à démarrage + 5 points |

Portée de la zone alimentée : options vanilla `GeneratorTileRange` (20) et `GeneratorVerticalPowerRange` (3), lues par `LiveWire.Config.tileRange()` / `verticalRange()`.

## 6. Traductions

- Source unique : `tools/translations_src.py`, qui écrit `media/lua/shared/Translate/<LANGUE>/*.json` (JSON plat UTF-8 sans BOM, contrôlé par `tools/check_mod.py`).
- Langues : `EN` (référence), `FR`, `DE`, `ES`, `PT`, `PTBR`, `RU`, `CN`, `JP`, `KO`.
- Fichiers et préfixes (EN, 1.3.1) :

| Fichier | Préfixe des clés | Clés |
|---|---|---|
| `ContextMenu.json` | `ContextMenu_LW_` | 69 |
| `IG_UI.json` | `IGUI_LW_` (+ `IGUI_ContainerTitle_livewirepowerbank`) | 171 |
| `ItemName.json` | `Module.Objet` (`LiveWire.*`, `Base.Mov_LiveWire_*`) | 14 |
| `Moveables.json` | `Live_Wire_*` (noms des tuiles) | 8 |
| `Recipes.json` | nom de recette (`LWMake*`, `LWSalvageSolarCell`) | 14 |
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
| Autres mods d'énergie | Non pris en charge | — | — |

Multijoueur : conçu pour un serveur dédié autoritaire, **non testé en jeu en MP** à la version 1.3.1 (voir [`wiki/fr/12-multijoueur.md`](wiki/fr/12-multijoueur.md)).

## 8. Outillage et tests

- `tools/check_mod.py` : contrôles statiques (ordre de chargement, syntaxe Lua, ASCII, traductions, définitions ↔ scripts, options, modèles, événements connus d'après les sources de référence).
- `tests/test_physics.py`, `tests/test_simulation.py` : tests hors jeu sous Lua 5.1 (`lupa`) ; ils ne prouvent rien sur le moteur.
- `autotest.json` + `autotest/*.lua` : configuration de l'outil `pz-autotest` (tests en jeu non surveillés).
- Documentation générée : `tools/make_doc_images.py` (→ `docs/images/diagrams/`), `tools/make_doc_tables.py` (→ `docs/wiki/<langue>/_tables.md`).
- Protocole de test en jeu : [`annexes/tests/protocole-tests.md`](annexes/tests/protocole-tests.md).
