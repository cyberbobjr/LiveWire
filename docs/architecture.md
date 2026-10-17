# Live Wire — architecture

État : **conception, aucun code**. Rien n'a été prototypé ni testé en jeu.

Conventions :
- **Chemins.** Les chemins `java/…` et `media/…` sont relatifs à la racine du dépôt de référence `pz-source-42.21`.
- **Renvois.** « NM-n » renvoie à `docs/notes-moteur.md`, « D-n » à `docs/decisions-ouvertes.md`, « § F-n » à `docs/fonctionnel.md`.
- **Extraits de code.** Les extraits Lua sont **illustratifs** : ils montrent une intention, ce n'est pas du code livré.

---

## 1. Mécanisme d'alimentation

### 1.1 Contrainte du moteur

Une case n'est « alimentée par un générateur » que si `IsoGridSquare.haveElectricity()` est vrai. Cette méthode ne teste **que** les positions de générateur enregistrées sur le chunk (`java/zombie/iso/IsoGridSquare.java:8223-8228`, `java/zombie/iso/IsoChunk.java:4773-4783`).

Le réseau public est un drapeau global, `hasGridPower` = `!isNoPower() && doesPowerGridExist()` (`IsoGridSquare.java:10150-10156`, `java/zombie/SandboxOptions.java:1230`). Rien ne permet de rendre du courant à un seul lieu par ce réseau (`knowledge/power-and-lights.md:9-16`).

Tous les consommateurs sont en Java : lumières, conteneurs réfrigérés, cuisinières, radios (`java/zombie/inventory/ItemContainer.java:2195-2262`). Pour alimenter une base, il faut donc **des positions de générateur**, réelles ou posées par script.

### 1.2 Alternatives étudiées

| # | Mécanisme | Pour | Contre (preuves) | Verdict |
|---|---|---|---|---|
| A | **Positions virtuelles** (`IsoChunk:addGeneratorPos`) posées par le mod, sans objet | Aucun objet à protéger ; aucun bruit ; aucune toxicité | Purgées à chaque chargement de chunk quand la case existe sans générateur allumé (`IsoChunk.java:4785-4797`, appelé **avant** `LoadChunk`, `:3526` puis `:3612`) : il faut les reposer à chaque `LoadChunk`, voisins compris. **Jamais purgées** sur une case inexistante, donc possibles fuites de courant permanentes (`knowledge/power-and-lights.md:18-24`). Liste illisible depuis Lua. **Aucune consommation mesurée** : il faudrait balayer soi-même les appareils (`getGeneratorPowerConsumption`). Le comportement côté client MP dépend du tampon de chunk transmis (hypothèse, NM-7). | Écartée en mécanisme principal ; gardée en secours (risque R-1) |
| B | **Réseau public global** (décaler `ElecShutModifier`) | Toute la carte alimentée, sans objet | Global à toute la carte ; pompes à essence, lampadaires et alarmes reviennent aussi ; option réservée à l'admin en MP (`knowledge/power-and-lights.md:26-34`). Contraire au principe d'une installation locale. | Écartée |
| C | **Réseau global et zones `NoPower` partout sauf la base** | Une seule zone alimentée | L'éclairage des pièces lit le drapeau global `isHydroPowerOn` : les lumières se rallument sur toute la carte (`java/zombie/iso/LightingJNI.java:226`, `:308-330` ; `knowledge/power-and-lights.md:12`) | Écartée |
| D | **Générateur vanilla du joueur, alimenté en carburant par le mod** | Très simple | Bruit vanilla de rayon 20 à 25 (`media/scripts/generated/items/normal.txt:4800-4866`) ; toxicité en intérieur ; le joueur peut le ramasser, le remplir ou le réparer et casser la logique. Contraire à la promesse « silencieux ». | Écartée (idée gardée pour la charge depuis un générateur vanilla, v0.2) |
| **E** | **Onduleur = vrai `IsoGenerator` dédié, piloté par le mod** | Le moteur gère portée, chargement, consommation, synchronisation MP et rattrapage ; la consommation est **mesurée par le jeu** ; aucune position orpheline | Doit être protégé des actions vanilla ; son de boucle joué aux joueurs ; usure, incendie et toxicité à neutraliser ; sprite unique requis (détails au § 1.3) | **Retenue — à valider : D-2** |

### 1.3 Points vérifiés pour le mécanisme E

| Point demandé | Constat | Preuve | Conséquence pour Live Wire |
|---|---|---|---|
| Consommation mesurée | `getTotalPowerUsing()` = somme des appareils du disque × `GeneratorFuelConsumption`, par heure. Recalculée à l'allumage, au chargement et à chaque changement d'appareil (`updateGenerator`). | `java/zombie/iso/objects/IsoGenerator.java:251-322`, `:655-657` ; valeurs par appareil NM-5 | Demande (W) = `getTotalPowerUsing() / option × 1000 × PowerScale`. Si l'option vaut 0 : balayage propre au mod (`obj:getGeneratorPowerConsumption()`, `java/zombie/iso/IsoObject.java:4784-4798`) |
| Carburant comme réserve | Borné de 0 à 10. Débité à chaque passage d'heure, avec rattrapage. Arrêt à 0 **au passage d'heure seulement**. Synchronisé par `sync()`. | `IsoGenerator.java:182-239`, `:444-455` ; NM-3 | Le carburant n'est qu'un **miroir** du stock : `fuel = 10 × stock / capacité`, réécrit à chaque pas. Arrêt explicite par `setActivated(false)` quand le stock est vide |
| Toxicité | Seulement si la case n'est pas `exterior` **et** a un bâtiment (donc une pièce). Testée chaque heure de marche, à l'allumage et au chargement des régions. | `IsoGenerator.java:183-185`, `:466-468` ; `IsoGridSquare.java:7805-7811` ; NM-4 | Pose refusée si `sq:getRoom() ~= nil`. Un onduleur contre un mur extérieur suffit : la portée de 20 cases couvre la maison |
| Bruit | Rayon et volume tirés du script retrouvé **par le sprite** (tag `Generator`). 20 par défaut seulement si le champ vaut ≤ 0. Rayon divisé par 2 en pièce. Un rayon ≤ 0 n'émet rien. Le son FMOD vient de `GeneratorSound` du sprite et n'est pas réglable depuis Lua. | `IsoGenerator.java:137-181`, `:667-697` ; `java/zombie/core/TilePropertyAliasMap.java:63-69` ; NM-1, NM-2 | Script `InverterUnit` : `SoundRadius = 1`, `SoundVolume = 1`, sprite unique. Les zombies ne l'entendent presque pas ; les joueurs entendent la boucle vanilla jusqu'à la tuile définitive (D-2, R-2) |
| Portée | `GeneratorTileRange` (1 à 100, défaut 20) et `GeneratorVerticalPowerRange` (1 à 15, défaut 3), globales | `SandboxOptions.java:248-249` ; `IsoGenerator.java:115-119`, `:637-644` | Portée fixe, partagée avec les générateurs vanilla. Les relais (v0.4) servent à couvrir plus |
| Actions vanilla | Menu construit en Java, masquable dans `OnPreFillWorldObjectContextMenu`. Actions validées sur le serveur par leur `complete()`. Pose au sol d'un objet tagué `Generator` = nouveau générateur. | NM-6, NM-8, NM-9 | Défense en trois couches (§ 2.4) ; l'objet tagué n'est jamais en inventaire |
| Usure du générateur | Perte aléatoire d'état chaque heure ; incendie ou explosion sous 20 | NM-3 | `ConditionLowerChanceOneIn` très grand dans le script, et `setCondition(100)` à chaque pas. L'état « métier » de l'onduleur vit dans le registre |
| MP dédié | `update()` (carburant, bruit, toxicité) sur l'autorité. Son et calcul des positions sur chaque client à la réception du `sync`. Chaque setter synchronise vers **toutes** les connexions. | `IsoGenerator.java:158-166`, `:527-568` ; NM-7 | Réglages groupés, au plus un par pas de 10 minutes et par onduleur. À confirmer en jeu (prototype P1) : lumières allumées chez un client distant |

### 1.4 Conception de l'onduleur

**Script d'objet interne.** Illustratif, au format des scripts vanilla `normal.txt:4800-4815`. Les valeurs sont à confirmer au prototype P1.
```
module LiveWire
{
    item InverterUnit
    {
        /* placeholder: internal engine object, never in a player inventory */
        DisplayName = Inverter Unit,
        ItemType = base:normal,
        Weight = 8,
        Icon = CarBatteryCharger,
        Tags = base:generator,
        WorldObjectSprite = location_business_machinery_01_32,
        SoundRadius = 1,
        SoundVolume = 1,
        ConditionLowerChanceOneIn = 1000000,
        ConditionMax = 100,
    }
}
```

**Le sprite.** Il ne doit appartenir à aucun autre objet tagué `Generator` (NM-1).
- **Il doit porter une propriété de conteneur**, qui servira de **compartiment à batteries** (§ F-5.2, D-4).
- **Le moteur ne crée pas ce conteneur tout seul** : `IsoGenerator.addToWorld` n'appelle pas `IsoObject.addToWorld`, la méthode qui crée les conteneurs du sprite (`IsoGenerator.java:399-405`, `java/zombie/iso/IsoObject.java:4176-4182`). Le mod appelle donc lui-même `gen:createContainersFromSpriteProperties()` (méthode publique, `IsoObject.java:4900`) :
  - sur l'autorité, juste après la pose ;
  - sur chaque client, à la réception de l'objet ou au chargement de sa case.
- Une fois créé, le conteneur est sauvegardé avec l'objet : `IsoGenerator.save` appelle `IsoObject.save`, qui écrit les conteneurs (`IsoGenerator.java:384`, `IsoObject.java:1502-1510`).
- Le prototype P1 choisit ce sprite parmi ceux du tableau § F-2.3. Il vérifie que le compartiment s'ouvre, se sauvegarde et se synchronise en MP comme un meuble. En particulier, le transmission initiale de l'objet part avant la création du conteneur (`IsoGenerator.java:108-111`) : c'est une **hypothèse à tester**.
- **Repli** si ce n'est pas le cas : un sprite sans conteneur, et des batteries rangées seulement dans des bancs câblés.
- N'utiliser **jamais** `appliances_misc_01_*` : ce sont les sprites des générateurs vanilla, et leurs variantes tournées.

**Démontage.** L'action « Démonter » est refusée tant que le compartiment contient des objets. Ainsi, aucune batterie n'est perdue avec l'objet.

**Pose, sur l'autorité, dans le `complete()` de l'action d'installation** (illustratif) :
```lua
-- server-side, inside LWInstallAction:complete()
local item = instanceItem("LiveWire.InverterUnit")
item:getModData().fuel = 0.0              -- read by setInfoFromItem as a Double
local gen = IsoGenerator.new(item, getCell(), sq)  -- adds to square, transmits to clients
gen:getModData().LiveWire = { id = deviceId, s = 1 }
gen:setConnected(true)
gen:setCondition(100)
-- activation is decided by the next simulation step
```
Le constructeur ajoute l'objet à la case et le transmet aux clients (`IsoGenerator.java:102-113`). Le kit `InverterKit` est retiré de l'inventaire du joueur. La ModData du générateur est sauvegardée avec lui (`IsoGenerator.java:381-390`, `knowledge/power-and-lights.md:188-192`).

**Pilotage à chaque pas de simulation**, pour un onduleur chargé :
1. `gen:setCondition(100)` si l'état moteur est sous 100.
2. Mesure de la demande (§ 1.3).
3. Disjonction si la demande dépasse la puissance maximale : `setActivated(false)`, puis état `tripped` dans le registre.
4. `gen:setFuel(10 × stock / capacité)` si la valeur a changé de plus de 0,05.
5. `setActivated(stock > 0 et état ≠ tripped, broken ou off)`, seulement si l'état change. Chaque rallumage fait jouer `Starting` aux clients (`IsoGenerator.java:558-562`).

**Retrait** : pour l'action « Démonter », sur le serveur, appeler `setActivated(false)`, puis `sq:transmitRemoveItemFromSquare(gen)` (`IsoGridSquare.java:5076-5098`, `knowledge/power-and-lights.md:165`). Le registre est mis à jour, et le kit est rendu avec l'état métier.

---

## 2. Découpage en modules

### 2.1 Arborescence

Tout le contenu va sous `Contents/mods/batman_LiveWire/42.21/media/` (`CLAUDE.md`). `common/` reste vide en v0.1.

```
lua/shared/LiveWire/LW_Core.lua            table globale LiveWire, version, journal
lua/shared/LiveWire/LW_Config.lua          lecture des options sandbox
lua/shared/LiveWire/LW_Defs.lua            definitions des appareils et batteries (donnees)
lua/shared/LiveWire/LW_Physics.lua         fonctions pures : solaire, eolien, hydro, batteries
lua/shared/LiveWire/LW_Protocol.lua        noms de commandes, validation des arguments
lua/shared/LiveWire/LW_Marks.lua           lire / reconnaitre la marque ModData d'un objet
lua/shared/LiveWire/LW_VanillaGuards.lua   enveloppes complete() des actions vanilla (autorite)
lua/shared/LiveWire/TimedActions/LW_*.lua  actions chronometrees (complete() sur l'autorite)
lua/server/LiveWire/LW_Registry.lua        registre, index par position, identifiants
lua/server/LiveWire/LW_Migration.lua       migrations de schema
lua/server/LiveWire/LW_Simulation.lua      pas de simulation (EveryTenMinutes)
lua/server/LiveWire/LW_Inverter.lua        pilotage des IsoGenerator
lua/server/LiveWire/LW_Bank.lua            bancs de batteries (conteneurs)
lua/server/LiveWire/LW_Commands.lua        OnClientCommand, reponses
lua/server/LiveWire/LW_Xp.lua              experience (addXp sur l'autorite)
lua/client/LiveWire/LW_ContextMenu.lua     sous-menu "Live Wire"
lua/client/LiveWire/LW_HideVanilla.lua     OnPreFillWorldObjectContextMenu, filtres moveables
lua/client/LiveWire/LW_Dashboard.lua       fenetre du tableau de bord
lua/client/LiveWire/LW_ClientState.lua     cache des instantanes recus (OnServerCommand)
lua/shared/Translate/EN/*.json, FR/*.json  textes
scripts/LiveWire_items.txt, LiveWire_recipes.txt, LiveWire_models.txt
sandbox-options.txt
```

### 2.2 Règles de chargement

| Situation | Dossiers exécutés | Preuve |
|---|---|---|
| Solo et client | `shared` et `client` au démarrage, puis `server` au chargement de la partie | `java/zombie/Lua/LuaManager.java:1244-1245`, `java/zombie/gameStates/GameLoadingState.java:153` |
| Serveur dédié | `shared`, puis `client` en somme de contrôle seulement, puis `server` | `java/zombie/network/GameServer.java:1403-1405` |

- **Garde des fichiers `server/`.** Ils sont **aussi exécutés par les clients MP**. Chaque fichier `server/` commence donc par `if isClient() then return end` (modèle vanilla `media/lua/server/Map/MapObjects/MOGenerator.lua:1`).
- **Valeurs de `isClient()` et `isServer()`** :
  - solo : les deux sont faux ;
  - serveur dédié : `isServer()` est vrai ;
  - joueur hôte d'une partie hébergée : `isClient()` est vrai (`knowledge/multiplayer.md:21`, `:228`).
- **Notion d'« autorité ».** Dans ce document, « autorité » signifie `not isClient()`, c'est-à-dire le solo ou le serveur.

### 2.3 Espaces de noms

- **Table globale `LiveWire`.** Elle est la seule globale du mod. Sous-tables : `LiveWire.Config`, `.Defs`, `.Physics`, `.Protocol`, `.Marks`, `.Registry`, `.Sim`, `.Inverter`, `.Bank`, `.Xp`, `.Client`.
- **Actions chronométrées.** Elles sont nommées `LWInstallAction`, `LWDismantleAction`, `LWRepairAction`, `LWInspectAction`, `LWReconditionAction`, `LWClearSnowAction` et `LWMeasureAction`. Elles sont globales par nécessité, car `NetTimedAction` les retrouve par leur nom de classe (`java/zombie/core/NetTimedAction.java:145-172`).
- **Préfixe `LW`** pour tout le reste : recettes, clés de traduction et identifiants d'appareil.
- **Fichiers préfixés `LW_`.** L'ordre de chargement suit le tri par chemin relatif en minuscules (`knowledge/mod-loading.md:64-69`). Les dépendances internes passent donc par la table `LiveWire` au moment de l'appel, pas au chargement du fichier.
- **Contraintes Kahlua** (`CLAUDE.md`, `knowledge/kahlua-lua.md`) :
  - aucun littéral non ASCII dans les fichiers `.lua` : tous les textes passent par `getText` ;
  - `ZombRand` et `ZombRandFloat` au lieu de `math.random` ;
  - aucun abonnement répété aux événements : chaque `Events.X.Add` se fait une seule fois, au chargement du fichier.

### 2.4 Protection des objets Live Wire contre les actions vanilla

La protection est en trois couches. Toutes testent la marque `getModData().LiveWire` via `LiveWire.Marks.isOurs(obj)`.

**1. Client (affichage).** Les options vanilla n'apparaissent jamais.
- `Events.OnPreFillWorldObjectContextMenu` : si `ISWorldObjectContextMenu.fetchVars.generator` est un onduleur, le mettre à `nil`. Tout le sous-menu « Générateur » disparaît (`media/lua/client/ISUI/ISWorldObjectContextMenu.lua:183-209`, `java/zombie/iso/ISWorldObjectContextMenuLogic.java:1444-1445`).
- Enveloppes qui gardent la signature et le retour vanilla :
  - `ISMoveableSpriteProps:canPickUpMoveable` rend `false` ;
  - `ISMoveableSpriteProps:canScrapObject` rend un `craftValid = false` ;
  - `ISDestroyCursor:canDestroy` rend `false`

  (`media/lua/shared/Moveables/ISMoveableSpriteProps.lua:1202-1255`, `media/lua/server/BuildingObjects/ISDestroyCursor.lua:293`).

**2. Autorité (refus).** Un client modifié ne peut rien forcer.
- Enveloppes de `complete()` pour `ISTakeGenerator`, `ISAddFuel`, `ISPlugGenerator`, `ISActivateGenerator`, `ISFixGenerator`, `ISMoveablesAction` et `ISDestroyStuffAction`.
- Si la cible est marquée, la fonction retourne sans appeler l'original et journalise le refus.
- Le serveur n'appelle pas le `isValid` Lua d'une action réseau, donc `complete()` est le bon point (NM-9, `knowledge/multiplayer.md:43-49`, `:230`).
- On n'enveloppe **pas** `new`, pour ne pas casser la sérialisation (NM-9).

**3. Conception.**
- L'objet tagué `Generator` n'est jamais en inventaire (NM-6).
- Les appareils de production sont de simples `IsoObject` (pas de `IsoThumpable`), sans conteneur.
- Toute disparition d'un objet marqué est détectée par le registre (§ 6.3).

---

## 3. Modèle de données

### 3.1 Où vit chaque donnée

| Donnée | Lieu | Qui fait foi | Raison |
|---|---|---|---|
| Réseaux, appareils, énergie stockée hors chargement, état métier | ModData globale `LiveWire` (serveur) | **Autorité** | Seul stockage qui survit au déchargement et que les clients ne peuvent pas écraser (un `transmit` venu d'un client n'écrase rien côté serveur, `knowledge/multiplayer.md:115`) |
| Marque d'un objet posé | `obj:getModData().LiveWire = { id, s }` | Reflet | Sauvegardée avec `IsoObject` et `IsoGenerator` (`IsoObject.java:1512-1515`, `IsoGenerator.java:384`). Un client peut la réécrire par `transmitModData` (NM-11) : elle ne sert qu'à **reconnaître** l'objet, et le serveur la compare au registre |
| Charge d'une batterie | Utilisations de l'objet (`setCurrentUsesFloat`, 0..1) | Autorité, quand le banc est chargé | Synchronisée par `sendItemStats` pour un objet dans un meuble, contrairement à la ModData (NM-10, `knowledge/multiplayer.md:319-322`) |
| Usure d'une batterie | État de l'objet (`setCondition`) | Idem | Idem |
| Cycles d'une batterie (statistique) | ModData de l'objet | Autorité seulement | Pas besoin d'être vue par les clients |

**Piège de l'objet au sol** (vérifié, NM-10) :
- la ModData propre d'un `IsoWorldInventoryObject` n'est jamais sauvegardée ;
- `syncItemFields` sur un objet au sol ne transmet pas la ModData de l'objet d'inventaire.

Live Wire n'utilise donc **aucun objet posé au sol** comme appareil. Les batteries ne comptent que dans un meuble câblé, et une batterie au sol n'est qu'un objet d'inventaire ordinaire, dont la charge reste dans ses utilisations.

### 3.2 Schéma de la ModData globale (version 1)

```lua
-- ModData.getOrCreate("LiveWire")  -- illustrative shape, schema 1
{
  schema = 1,
  nextId = 42,                       -- monotonic, never reused
  devices = {
    ["d7"] = {
      id = "d7", kind = "solar",     -- solar | wind | hydro | inverter | bank
      x = 10512, y = 9620, z = 1,
      grid = "g2",                   -- nil if not linked
      cond = 87,                     -- 0..100, business condition
      eff = 0.95,                    -- installation efficiency (installer level)
      model = "SolarPanel",          -- key into LiveWire.Defs
      snow = 0.0,                    -- solar only
      state = "ok",                  -- ok | broken | off | tripped (inverter)
      seen = 1234.5,                 -- world age hours when last seen loaded
    },
  },
  grids = {
    ["g2"] = {
      id = "g2", name = "",          -- player-given name, max 24 chars
      inverter = "d5", bank = "d6",
      members = { d7 = true, d8 = true },
      energy = 2.35, capacity = 3.60,-- kWh, snapshot used while the bank is unloaded
      demand = 172.0,                -- W, last measured demand
      lastTick = 1234.5,             -- world age hours of the last step
      rev = 318,                     -- snapshot revision sent to clients
    },
  },
  byPos = { ["10512,9620,1"] = "d7" },  -- position index
}
```

- **Identifiants** : chaînes `d<n>` et `g<n>`, tirées de `nextId`. Elles ne sont jamais réutilisées et ne changent jamais (`CLAUDE.md` : préserver les identifiants persistants).
- **Champs réservés du moteur** : sur l'onduleur, ne pas toucher les clés moteur `totalPowerDraw`, `generatorFullType` et `fuel` (`IsoGenerator.java:129-135`, `:381-390`).
- **Taille** : environ 200 octets par appareil, donc moins de 50 Ko pour une très grosse partie. On ne transmet jamais la table entière (§ 5.3).

### 3.3 Versions et migration

- `schema` est un entier. `LW_Migration.run(data)` applique, dans l'ordre, des fonctions `[1] = function(d) … d.schema = 2 end`, etc.
- **Règles d'une migration** :
  - **idempotente** : la rejouer ne change rien ;
  - **journalisée** en anglais (`print("[LiveWire] migrated schema 1 -> 2")`) ;
  - elle ne supprime jamais un appareil : les données inconnues vont dans `d.legacy`.
- **Version trop récente.** Un `schema` supérieur à celui du code (retour à une ancienne version du mod) déclenche un mode **lecture seule** : simulation suspendue et erreur journalisée. Ainsi rien n'est écrasé.
- **Marques d'objet.** Elles portent `s` (version de marque). Le contrôle au chargement d'un chunk (§ 6.2) les met à jour.
- **Moment de la migration.** Elle se fait dans `OnInitGlobalModData`, où `getCell()` vaut `nil` (`knowledge/world-placement.md:105-113`). On n'y touche donc qu'aux données, jamais au monde.

---

## 4. Boucle de simulation (autorité)

### 4.1 Événements

| Événement | Rôle | Preuve |
|---|---|---|
| `OnInitGlobalModData` | Récupère la ModData globale et migre | `java/zombie/world/moddata/GlobalModData.java:53-57` |
| `OnServerStarted` (dédié) ; premier `EveryOneMinute` (solo) | Arme la simulation. `OnGameStart` ne part probablement pas sur un serveur dédié (hypothèse) | `java/zombie/Lua/LuaEventManager.java:788` ; `GameServer.java:1461` |
| `EveryTenMinutes` | **Pas de simulation** | `LuaEventManager.java:746` ; part au plus une fois par mise à jour, même après un saut (`java/zombie/GameTime.java:553-576`) |
| `LoadChunk` | Rattache les objets du chunk au registre, synchronise le banc, relance l'onduleur | `java/zombie/iso/IsoChunk.java:3612`, après la purge des générateurs (`:3526`) |
| `OnTick` (compteur, quelques ticks après `LoadChunk`) | Deuxième passage de rattachement, pour les voisins chargés plus tard | `knowledge/power-and-lights.md:24` |
| `OnClientCommand` | Commandes (§ 5) | `GameServer.java:2157` |

### 4.2 Un pas pour un réseau

1. **Durée écoulée.** `dt = now − lastTick` en heures de jeu, avec `now = getGameTime():getWorldAgeHours()` (`GameTime.java:830-834`). On ne fait rien si `dt ≤ 0`. Au-delà de 1 h, le pas est découpé en tranches d'une heure, plafonnées à 720 h (30 jours). Au-delà, l'énergie et l'usure sont calculées en bloc, sans sous-pas.
2. **Production.** Pour chaque producteur, `P × Δ` (§ F-3).
   - Le soleil se calcule **analytiquement** : intégrale de la sinusoïde sur la tranche, à partir de l'aube et du crépuscule du jour.
   - Pendant un rattrapage, la météo est la météo **actuelle** : l'historique n'existe pas, c'est une approximation assumée.
3. **Demande.**
   - Onduleur chargé : mesure moteur (§ 1.3).
   - Onduleur non chargé : `grid.demand`, la dernière mesure, si l'option `SimulateUnloaded` est vraie, sinon 0.
4. **Bilan** : `energy = clamp(energy + prod × 0,9 × Δ − demand / effOnduleur × Δ, 0, capacity)`. Si la valeur est plafonnée à `capacity`, le surplus est compté comme « production perdue ».
5. **Usure.** Appareils (§ F-4.4) ; batteries au prorata du débit d'énergie.
6. **Banc chargé** : le stock est réparti sur les batteries réelles (§ 4.4).
7. **Onduleur chargé** : pilotage (§ 1.4).
8. `lastTick = now`, `rev = rev + 1`. Un instantané est envoyé aux abonnés (§ 5.3).

### 4.3 Coût

- **Calcul.** Un pas coûte O(nombre d'appareils), avec quelques opérations par appareil. Pour une grosse partie, 100 appareils toutes les 10 minutes de jeu, soit environ toutes les 25 s réelles avec un jour de 1 h.
- **Objets du monde.** On n'y touche que pour les réseaux chargés : une case par onduleur et une par banc, retrouvées par `getCell():getGridSquare(x, y, z)`. La recherche de l'objet marqué se fait parmi les objets de la case.
- **Aucun balayage de zone en v0.1.** Seule exception : le repli « option de consommation à 0 » balaie le disque de l'onduleur, soit (2 × 20 + 1)² × 7 ≈ 11 800 cases au pire. Ce repli est limité à une fois par heure de jeu, et à mesurer en prototype P6.
- **Réseau.** Au plus un `setFuel` et un `setActivated` par onduleur et par pas : chaque appel diffuse un paquet à toutes les connexions (NM-7).

### 4.4 Batteries chargées : rapprochement avec les objets réels

- **Lecture.** Le serveur lit le **compartiment de l'onduleur**, puis le conteneur de chaque meuble câblé. Il ne garde que les objets reconnus par `LiveWire.Defs.batteries[fullType]`, avec 4 batteries au plus dans le compartiment.
- **Batteries réelles** : `capacité = Σ capacité_effective(état)` et `énergie_réelle = Σ charge × capacité_effective`. C'est l'**énergie réelle qui fait foi** quand le banc est chargé : un joueur a pu ajouter ou retirer des batteries.
- **Nouveau stock.** Après le bilan du pas, le nouveau stock est réparti au prorata (§ F-5.2). Pour chaque batterie modifiée : `setCurrentUsesFloat`, `setCondition`, puis `sendItemStats(item)` en MP (`java/zombie/Lua/LuaManager.java:3757-3762`).
- **Banc non chargé** : `grid.energy` et `grid.capacity` font foi. Personne ne peut toucher un conteneur non chargé.
- **Retrait de batterie pendant un pas.** L'énergie de la batterie retirée part avec elle, ce qui est voulu. Le rapprochement suivant le constate. Il n'y a pas de duplication possible, puisque l'énergie est toujours relue sur les objets présents.

---

## 5. Protocole réseau

### 5.1 Principes

- Module de commande : `"LiveWire"`.
- **Les actions longues** (installer, démonter, réparer, inspecter, reconditionner, déneiger, mesurer) sont des **actions chronométrées partagées**. Leur `complete()` s'exécute sur l'autorité, qui **revérifie tout** : le serveur n'appelle pas le `isValid` Lua (`knowledge/multiplayer.md:43-49`).
- **Les actions instantanées** passent par `sendClientCommand("LiveWire", cmd, args)`.
- **Joueur identifié.** Le serveur reçoit le joueur déduit de la connexion, qui ne peut pas être usurpé (`GameServer.java:2126-2157`).
- **Arguments** : nombres, chaînes, booléens et tables. Une table vide arrive en `nil` (`knowledge/multiplayer.md:182-187`, `:253-256`).
- **Ordre des réponses.** La livraison n'est pas ordonnée : chaque instantané porte `rev`, et le client ignore un `rev` plus ancien que celui qu'il a (`knowledge/multiplayer.md:213-218`).
- **Textes.** Le serveur ne connaît pas les traductions des mods. Il envoie des **clés** et des paramètres, que le client traduit (`knowledge/api-42-21.md:145-150`).

### 5.2 Commandes

| Sens | Commande | Arguments | Réponse ou effet |
|---|---|---|---|
| C → S | `subscribe` | `{ grid = "g2" }` | Instantané immédiat ; abonnement de 10 minutes réelles, renouvelé tant que la fenêtre est ouverte |
| C → S | `unsubscribe` | `{ grid }` | — |
| C → S | `link` | `{ device = "d7", inverter = "d5" }` | Raccordement ; fils retirés de l'inventaire par le serveur |
| C → S | `unlink` | `{ device }` | — |
| C → S | `wireBank` | `{ x, y, z, index }` (meuble conteneur de la case), `{ inverter }` | Crée l'appareil `bank` |
| C → S | `setInverter` | `{ inverter, on = true/false }` | Allumage ou extinction manuels |
| C → S | `reset` | `{ inverter }` | Réarme après une disjonction si la demande est revenue sous le maximum |
| C → S | `rename` | `{ grid, name }` | Nom ≤ 24 caractères, ASCII imprimable ou UTF-8 valide |
| S → C | `snapshot` | `{ grid, rev, inverter = {...}, producers = {...}, demand, energy, capacity, alerts = {...} }` | Mise à jour du cache client |
| S → C | `notify` | `{ key = "IGUI_LW_Tripped", args = {...} }` | Message au joueur (bulle de texte ou ligne de journal) |
| S → C | `refuse` | `{ cmd, key = "Tooltip_LW_TooFar" }` | Refus motivé |

### 5.3 Validation côté serveur, pour chaque commande

1. **Forme.** Types attendus, chaînes de 32 caractères au plus, identifiants au format `^[dg]%d+$`. Tout écart : refus sans effet.
2. **Joueur.** Vivant ; pas dans un véhicule pour les actions sur appareil.
3. **Existence.** L'appareil existe dans le registre ; sa case est chargée ; l'objet marqué s'y trouve et la marque correspond.
4. **Distance.** Distance de Tchebychev ≤ 3 cases et `floor(joueur:getZ()) == z`. `DistToProper` ignore z (`knowledge/multiplayer.md:70`).
5. **Droits.** Règle de la safehouse vanilla. L'API de test est à confirmer (R-9).
6. **Conditions métier.** Niveau d'Électricité **lu sur le serveur**, objets requis présents dans l'inventaire principal du joueur **côté serveur**, état compatible (on ne réarme pas un onduleur en panne, par exemple).
7. **Débit.** Au plus 4 commandes par seconde réelle et par joueur (`getTimestampMs()`). L'excédent est ignoré, et le premier dépassement par minute est journalisé. Le serveur ne limite rien par lui-même et journalise chaque commande hors filtre (`GameServer.java:2151-2153`).

**Diffusion.** Les instantanés vont **seulement aux abonnés** qui sont à moins de 30 cases de l'onduleur. On ne fait jamais `ModData.transmit("LiveWire")`, qui enverrait tout à tous (`GlobalModData.java:126-141`).

---

## 6. Persistance et reprise

### 6.1 Ce qui est sauvegardé, et par qui

| Élément | Sauvegarde | Preuve |
|---|---|---|
| Registre | Fichier `global_mod_data.bin` de la sauvegarde, avec le monde | `GlobalModData.java:221-268`, `ServerMap.java:397` |
| Onduleur | Avec son chunk : carburant, état, marche, `lastHour`, ModData | `IsoGenerator.java:381-390` |
| Appareils de production | Avec leur chunk (`IsoObject`, ModData comprise) | `IsoObject.java:1512-1515` |
| Batteries | Avec le conteneur du meuble : utilisations, état, ModData | `java/zombie/inventory/InventoryItem.java:1547-1549` |

- **Pas d'événement de sauvegarde.** Sur un serveur dédié, la sauvegarde périodique ne déclenche aucun `OnSave` (`knowledge/world-placement.md:154`) : le registre doit être **toujours cohérent en mémoire**, sans écriture différée.

### 6.2 Reprise après un redémarrage

- **`OnInitGlobalModData`** : migration du registre. Aucun accès au monde, qui n'est pas prêt.
- **Premier pas de simulation.** `dt` = temps de jeu écoulé depuis `lastTick` ; l'arrêt du serveur ne fait pas avancer le temps de jeu. Les réseaux non chargés sont simulés depuis le registre.
- **`LoadChunk`, pour chaque objet marqué du chunk** :
  - recherche dans le registre ;
  - si la position et le type correspondent, mise à jour de `seen` ;
  - sinon, objet « orphelin » : il est journalisé et laissé inerte (onduleur éteint), sans suppression automatique en v0.1.
- **Onduleur rechargé.** Le moteur rattrape les heures manquées avec l'ancienne consommation et peut l'éteindre si le carburant miroir s'épuise (NM-7). Le passage de rattachement, quelques ticks après le chargement, remet le carburant miroir et rallume si le stock le permet. Coupure maximale pour le joueur : quelques ticks (à mesurer, P4).

### 6.3 Incohérences et réparations

| Cas | Détection | Traitement |
|---|---|---|
| Objet du registre absent de sa case chargée (incendie, admin, mod tiers) | Rattachement ou pas de simulation | Après 2 constats à au moins 10 minutes de jeu d'intervalle : appareil retiré du registre, réseau recalculé, message au prochain abonné |
| Objet marqué inconnu du registre | `LoadChunk` | Inerte et journalisé. L'action « Inspecter » permet de l'adopter (réinscription) si un joueur de niveau requis le demande |
| Meuble du banc détruit ou déplacé | Rattachement | Banc retiré : `energy = 0`. L'énergie était dans les batteries, qui suivent le meuble ou tombent au sol |
| Plantage entre deux sauvegardes | Écart entre registre et monde | Le monde fait foi pour l'**existence** des objets ; le registre fait foi pour l'énergie hors chargement ; le banc chargé fait foi pour l'énergie réelle |

---

## 7. Traductions

- **Fichiers.** `media/lua/shared/Translate/EN/` (référence) et `FR/`. Chaque fichier est un objet JSON plat, et seuls les `.json` sont lus (`knowledge/api-42-21.md:100`).
- **Fichier selon le préfixe de clé** (`CLAUDE.md`) :

| Fichier | Clés |
|---|---|
| `ItemName.json` | `LiveWire.VoltageTester`, `LiveWire.SolarCell`, `LiveWire.SolarPanelKit`, `LiveWire.WindTurbineKit`, `LiveWire.WaterWheelKit`, `LiveWire.InverterKit`, `LiveWire.HeavyInverterKit`, `LiveWire.DeepCycleBattery`, `LiveWire.InverterUnit` |
| `Recipes.json` | `LWMakeVoltageTester`, `LWSalvageSolarCell`, `LWMakeSolarPanelKit`, `LWMakeSolarCellFromScrap`, `LWMakeInverterKit`, `LWMakeHeavyInverterKit`, `LWMakeWindTurbineKit`, `LWMakeWaterWheelKit`, `LWMakeDeepCycleBattery` (clé = nom de recette, `java/zombie/core/Translator.java:561-569`) |
| `ContextMenu.json` | `ContextMenu_LW_Root`, `_Measure`, `_Install`, `_Inspect`, `_Link`, `_Unlink`, `_Repair`, `_Overhaul`, `_ClearSnow`, `_Dismantle`, `_Dashboard`, `_TurnOn`, `_TurnOff`, `_Reset`, `_WireBank`, `_UnwireBank`, `_Recondition` |
| `Tooltip.json` | `Tooltip_LW_NeedLevel` (« Électricité niv. %1 requis »), `_NeedTool`, `_NeedItems`, `_NeedOutdoor`, `_NeedNoRoom`, `_NeedRiver`, `_TooFar`, `_NoInverterInRange`, `_Overlap` |
| `IG_UI.json` | `IGUI_LW_Dashboard_Title`, `_Production`, `_Demand`, `_Stock`, `_Autonomy` (« Autonomie : environ %1 h »), `_Lost`, `_Tripped`, `_Broken`, `_WornBatteries`, `_Measure_Powered`, `_Measure_Source_Grid`, `_Measure_Source_Generator`, `_Measure_Source_LiveWire`, `_Measure_Draw` (« %1 W ») |
| `Sandbox.json` | `Sandbox_LiveWire` (onglet), puis pour chaque option `Sandbox_LiveWire_<Option>` et `Sandbox_LiveWire_<Option>_tooltip` (`knowledge/api-42-21.md:143`, `:286`) |

- **Paramètres.** Arguments `%1`, `%2` ; un signe pour cent s'écrit `%%` (`knowledge/load-warnings.md:17-25`).
- **Contrôle automatique.** Un script de vérification hors jeu (étape E0) comparera les jeux de clés EN et FR et détectera les `%` non doublés.

---

## 8. Risques techniques classés

Les risques sont classés par gravité × probabilité. Chacun a son prototype de dérisquage. Tous les prototypes restent **à exécuter** : aucun n'a été fait.

| Rang | Risque | Gravité | Prototype de dérisquage |
|---|---|---|---|
| **R-1** | L'onduleur `IsoGenerator` ne se comporte pas comme prévu : courant absent chez un client MP distant, toxicité inattendue, compartiment à batteries inutilisable, état ou carburant écrasés. **Tout le mod en dépend.** | Bloquante | **P1** — commande de débogage (autorité) qui pose un `InverterUnit` devant une maison et règle `fuel = 5`, puis `setActivated(true)`. Vérifier : lumières et réfrigérateur alimentés dans la maison ; aucun moodle de toxicité après 2 h ; menu vanilla absent ; compartiment ouvrable, batteries rangées puis retrouvées après sauvegarde et rechargement ; transfert vu par l'autre client. Mêmes constats sur un 2e client d'un serveur dédié. Repli si le compartiment échoue : bancs câblés seulement. Repli si le courant échoue : mécanisme A, positions virtuelles (§ 1.2) |
| **R-2** | Les joueurs entendent un ronflement de générateur (boucle FMOD vanilla) : la promesse « silencieux » n'est tenue que pour les zombies | Forte (expérience) | **P1 bis** — écouter sur place et à 10 cases. Mesurer le rayon de bruit perçu par les zombies : un zombie à 3, 6 puis 10 cases, la nuit. Solution définitive : tuile de mod avec sa propre valeur `GeneratorSound` et ses sons (NM-2), à prototyper dès que l'outillage des tuiles existe |
| **R-3** | Contournement par une action vanilla oubliée : ramassage comme meuble, destruction, dépôt, menu d'admin, autre mod | Forte | **P2** — liste de contrôle : tenter chaque action vanilla sur un onduleur et un panneau, en solo puis en MP avec un client normal. Option : un client de test qui envoie directement l'action vanilla, pour vérifier le refus par `complete()` |
| **R-4** | Chunk déchargé : extinction après le rattrapage au rechargement, coupure visible, voisins alimentés gratuitement | Moyenne | **P4** — base alimentée ; s'éloigner de 2 cellules pendant 2 jours de jeu ; revenir. Mesurer le délai de rallumage et l'écart d'énergie entre registre et batteries |
| **R-5** | Banc de batteries : synchronisation `sendItemStats` incomplète, duplication pendant un transfert, meuble conteneur inadapté (type, MP) | Moyenne | **P3** — deux joueurs déplacent des batteries pendant qu'un pas s'exécute (vitesse ×3). Comparer la somme des charges avant et après. Vérifier que l'affichage de la charge se met à jour chez l'autre client |
| **R-6** | Équilibrage météo faux : vent rarement au-dessus de 10 km/h, ou presque toujours au maximum ; nuages trop pénalisants | Moyenne | **P5** — enregistreur serveur qui journalise toutes les heures `getWindspeedKph`, `getCloudIntensity`, `isSnowing`, l'aube et le crépuscule pendant 30 jours de jeu accélérés ; histogramme hors jeu ; ajustement des seuils de § F-3.3 |
| **R-7** | Coût : diffusion à toutes les connexions à chaque `setFuel` ou `setActivated`, nombre d'instantanés, repli de balayage | Faible à moyenne | **P6** — 10 réseaux de 10 appareils sur un serveur dédié avec 4 clients : mesurer le temps d'un pas (`getTimestampMs`) et le débit réseau |
| **R-8** | Mesure de la demande faussée : option `GeneratorFuelConsumption` à 0, recouvrement avec un générateur vanilla, appareils de mod non comptés | Faible | **P1 ter** — mêmes appareils avec l'option à 0,1, 1, puis 0 ; puis avec un générateur vanilla voisin allumé |
| **R-9** | Conflits avec d'autres mods qui enveloppent les mêmes fonctions vanilla ; API de safehouse à confirmer | Faible à moyenne | **P7** — relire les points d'enveloppe et garder les signatures et retours. Charger le mod avec un mod de test qui enveloppe aussi `ISTakeGenerator:complete`. Vérifier la règle de safehouse dans les sources avant l'étape E9 |
| **R-10** | Pose invalide : case `isOutside()` sous un arbre, rive mal détectée hors des 6 zones de rivière vanilla, toit plat refusé | Faible | **P5 bis** — poser sur 10 sites connus (toits plats, berges de la rivière principale, étangs) et noter les refus |
| **R-11** | Migration ou identifiants instables entre versions | Faible (si discipline) | **P8** — sauvegarde de test v0.1 conservée, rejouée à chaque version ; test de migration à blanc sur une copie |

---

## 9. Plan d'implémentation par étapes testables

**Chaque étape se termine par un protocole en solo, puis en MP dédié** : serveur Linux local, deux clients, le second sans droits d'admin. Rien n'est livré tant que le protocole n'est pas passé **en jeu par l'utilisateur**. Les étapes ne présupposent aucun test déjà fait.

| Étape | Contenu | Protocole solo | Protocole MP dédié |
|---|---|---|---|
| **E0 — Squelette** | `mod.info` à jour, table `LiveWire`, journal, `sandbox-options.txt`, traductions EN et FR vides mais valides, script de contrôle des clés | Le mod se charge ; aucune erreur dans `console.txt` ; l'onglet sandbox s'affiche dans les deux langues | Le serveur charge le mod (journal) ; un client se connecte ; aucune erreur `server/` côté client |
| **E1 — Prototype onduleur (P1, P1 bis, P1 ter)** | Script `InverterUnit`, commande de débogage, choix du sprite | Protocole P1 : maison alimentée, pas de toxicité, menu absent, bruit | Lumières visibles chez le 2e client ; `setActivated(false)` éteint chez les deux. **Décision : le mécanisme E est-il confirmé ?** |
| **E2 — Registre et persistance** | `LW_Registry`, `LW_Migration`, marques, `LoadChunk` | Créer 3 appareils de débogage, sauvegarder, quitter, recharger : registre intact, marques retrouvées | Redémarrer le serveur : registre intact ; client déconnecté puis reconnecté |
| **E3 — Simulation abstraite** | `LW_Simulation`, `LW_Physics`, onduleur piloté par un stock fictif | Stock fictif de 1 kWh, réfrigérateur et lumières : extinction prévisible (calcul à la main) ; rallumage au retour du stock | Mêmes constats ; le client voit l'extinction ; vitesse ×3 sans dérive |
| **E4 — Batteries réelles** | `LW_Bank` : compartiment de l'onduleur, puis câblage d'un meuble, rapprochement | Mettre 2 batteries de voiture dans le compartiment et observer leur charge baisser la nuit ; en ajouter une 5e : ignorée et signalée ; retirer une batterie : le stock baisse d'autant ; même essai avec un banc câblé | Protocole P3 : deux joueurs, transferts pendant un pas, aucune duplication |
| **E5 — Producteurs** | Kits solaire et éolien, actions `LWInstallAction` et `LWDismantleAction`, raccordement, recettes | Fabriquer, poser sur un toit plat, raccorder ; production le jour, nulle la nuit ; éolienne arrêtée sans vent | Pose par le 2e client (non-admin) ; refus si trop loin ou si le niveau manque, vérifiés côté serveur |
| **E6 — Diagnostic et tableau de bord** | Testeur, `LW_Dashboard`, abonnements, instantanés | Mesures cohérentes aux niveaux 0, 2 et 4 ; fenêtre mise à jour | Fenêtre ouverte par deux joueurs ; aucune diffusion hors abonnés (journal) |
| **E7 — Compétence, usure, pannes** | `LW_Xp`, paliers, usure, réparation, disjonction, reconditionnement | Expérience gagnée et visible ; disjonction avec un lave-linge et sèche-linge superposés ; réparation | Expérience gagnée par le client non-admin (preuve que `addXp` est appelé sur le serveur) |
| **E8 — Protection vanilla (P2)** | `LW_HideVanilla`, `LW_VanillaGuards` | Liste de contrôle P2 complète | Même liste côté client ; refus journalisés par le serveur |
| **E9 — Durcissement MP** | Validation complète, limite de débit, safehouse, rattachement après déchargement (P4) | Protocole P4 | Protocoles P4 et P6 ; client qui envoie des commandes forgées (débogage) : toutes refusées |
| **E10 — Équilibrage et finition** | Protocole P5, ajustement des valeurs, textes, `workshop.txt` | Partie de 30 jours de jeu accélérée : bilan énergétique plausible | Session de 2 h à plusieurs, journal relu. Publication par l'utilisateur sur son poste (`CLAUDE.md`) |
