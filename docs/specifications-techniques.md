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

`LWMakeVoltageTester`, `LWDismantleVoltageTester`, `LWSalvageSolarCell` (calculatrice → cellule + débris électroniques), `LWMakeSolarCellFromScrap`, `LWMakeSolarPanelKit`, `LWMakeInverterKit`, `LWMakeWindTurbineBlades`, `LWMakeWindTurbineMast`, `LWMakeWindTurbineKit`, `LWMakeWaterWheel`, `LWMakePowerBankKit`, `LWMakeBreakerKit`, `LWMakeWaterPump`, `LWMakeCouplingKit`, `LWMakeDeepCycleBattery`, `LWMakeBatteryAlarmKit`, `LWMakeSoundproofKit`. Ingrédients et niveaux : tableau généré [`wiki/fr/_tables.md`](wiki/fr/_tables.md) (`tools/make_doc_tables.py`, données de `tools/make_doc_images.RECIPES`).

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
| Actions | `LWCleanPanelAction`, `LWTestBatteryAction`, `LWSalvageAction` ; `LWReconditionAction` étendue. Mutations et coûts revérifiés dans `complete()` sur l'autorité |
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
- Les doublons de type, modèle, objet posable et sprite sont refusés. Les valeurs
  non finies sont refusées ; seuls les champs primitifs autorisés sont recopiés.
- `battery(fullType)`, `source(model)` renvoient une copie détachée ou `nil`.
- `gridAt(x,y,z)` : autorité seulement, avant initialisation → `nil,"not_ready"` ;
  position invalide → `nil,"invalid_position"`. Réseau dont le maître est le plus
  proche dans sa portée (égalité par id), instantané détaché ou `nil` sans réseau.
  Ne renvoie jamais le registre, ses objets Java ou ses tables mutables.
- Ces garanties portent sur les accès par l'API v1. Les modules internes de
  l'espace Lua partagé ne constituent pas une frontière de sécurité contre un
  autre mod qui remplacerait délibérément leurs fonctions ; ils ne font pas
  partie du contrat d'extension.
- Raisons d'enregistrement stables : `registration_closed`, `invalid_definition`,
  `duplicate_type`, `duplicate_model`, `duplicate_sprite`. `API.version=1`.

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
- 27 nouvelles clés traduites dans les dix langues, dont la mention du fabricant
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

Deux clés de traduction dans les dix langues :
`Sandbox_LiveWire_EquipmentLootMultiplier` et son suffixe `_tooltip`.
Le générateur de tableaux montre les poids à ×5 et estime la probabilité sous
condition de sélection de la liste : `1 − (1 − poids × modificateur / 100)^tirages`,
sans effet de densité de zombies, du temps ni limite de place. Cela ne mesure pas
la fréquence effective de découverte dans une carte ou une partie donnée.

## Fabrication des sources et composants (F32)

- Objets normaux : `LiveWire.WindTurbineBlades` (jeu de trois pales, poids 4),
  `LiveWire.WindTurbineMast` (4). Représentations vanilla temporaires :
  SheetMetal/MetalSheet et SteelRod_Full/SteelRod.
- Recettes `LWMakeWindTurbineBlades` et `LWMakeWindTurbineMast` en Metalworking,
  sans niveau requis, avec 2 XP d'Électricité chacune. Assemblage : niveau 6/30 XP éolienne,
  7/30 XP roue ; deux `Base.Amplifier` dans chaque recette. Démontage vanilla des
  haut-parleurs intégralement conservé, sans hook ni recette dédiée.
- Durée éolienne 180 + 180 + 240 = 600. Mât : `Base.MetalPipe` au lieu du tuyau
  plastique `Base.Pipe`, deux barres ; total des trois étapes : six vis.
- `Defs.devices.*.level` et `PickUpLevel=2` des sprites 4–11 concordent. Niveau
  natif partagé entre pose et ramassage. Tiledef 7174, tileset ID 1, indices,
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
Clé de recette traduite `LWDismantleVoltageTester` dans les dix langues.

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
`IGUI_LW_EquipmentCondition` est traduit dans les dix langues. Les marques
`Marks.get(obj).cond` déjà synchronisées alimentent le LCD powerbank et celui du
tableau ; indépendants, cassés et banques empilées utilisent leur propre objet.
La charge et l'état des batteries continuent de venir de la vue bancaire existante.
La hauteur du LCD powerbank est calculée à l'ouverture selon la police, avec les
boutons sous l'écran. La liste de raccordements réutilise son actualisation à une
seconde pour préparer les libellés d'état de ses objets déjà découverts. Aucun
parcours du monde, paquet, registre, schéma persistant ou cadence serveur ajouté.

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
