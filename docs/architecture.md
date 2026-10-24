# Live Wire — architecture

État au 2026-10-21 : document de conception écrit pour la v0.1 (2026-10-17), complété par les mises à jour des sections 0 et 10. Le code est implémenté jusqu'à la version 1.3.1. Les contrats techniques **à jour** (registre schéma 2, commandes réseau, ModData des objets, options) sont dans [`specifications-techniques.md`](specifications-techniques.md), qui fait foi en cas d'écart avec les sections 3 et 5 ci-dessous.

- Les chemins `java/…` et `media/…` sont relatifs à la racine du dépôt de sources de référence de l'utilisateur (Java décompilé 42.21 et `media/` vanilla).
- « NM-n » renvoie à [`annexes/recherches/notes-moteur.md`](annexes/recherches/notes-moteur.md), « D-n » à [`decisions.md`](decisions.md), « § F-n » à la section n de [`specifications-fonctionnelles.md`](specifications-fonctionnelles.md) (identifiants F01… dans son tableau d'en-tête).
- Les extraits Lua sont **illustratifs** : ce n'est pas du code livré.

**Exigences de l'utilisateur** (2026-10-17), non négociables :
- onduleur posable **à l'intérieur** ;
- fonctionnement **sans joueur à proximité** ;
- onduleur qui **s'use** et fait un **très léger bruit** ;
- trois rôles distincts : **sources**, **batteries**, **onduleur**.

---

## 0. Mise à jour 0.1.1 (2026-10-17) : équipements en tuiles

Cette section prime sur le reste du document quand ils divergent.

- **Tuiles** : tileset `batman_livewire_01` (tiledef 7174, `common/media/texturepacks/batman_livewire_01.pack`, `common/media/batman_livewire_01.tiles`, profondeur `common/media/depthmaps/DEPTH_batman_livewire_01.png` et `common/media/tileGeometry.txt`). Index : panneau 0-3, éolienne 4-7, roue 8-11, onduleur 12-15, powerbank 16-19 (`container = livewirepowerbank`, `ContainerCapacity = 50`), disjoncteur 20-21 et alarme 22-23 (objets muraux S, E). Propriétés : `GroupName = Live Wire`, `PickUpTool = PlaceTool = Electrician`, `PickUpLevel` = niveau requis. Recette : `source/tiles/build_livewire_tiles.py`.
- **Pose, rotation, ramassage** : vanilla (`ISMoveableSpriteProps`). `LW_Placement.lua` enveloppe `canPlaceMoveableInternal` (dehors, berge de rivière), `getInfoPanelDescription` (raison du refus), `placeMoveableInternal`, `pickUpMoveableInternal` et `rotateMoveable`, en gardant arguments et retours. Sur l'autorité, `LW_Devices.lua` inscrit l'équipement à la pose (rendement d'après le niveau de la personne qui pose, expérience), écrit l'état dans la marque avant le ramassage, retire l'équipement au ramassage, et garde l'identifiant et les liens pendant une rotation (ramassage puis pose sur la même case).
- **Marque** : `modData.movableData.LiveWire = { id, model, cond, eff, level, inv }`, seule partie des ModData qu'un `IsoObject` garde au ramassage (`ISMoveableSpriteProps.lua:1400-1404`). `inv` est l'onduleur du réseau ; la marque est renvoyée aux clients (`transmitModData`) à chaque raccordement et débranchement, pour les menus.
- **Raccordement** : `Install.objectsInRange` parcourt les cases chargées à `LinkRange` (±1 étage) ; le menu de l'onduleur liste les équipements libres et raccordés. « Débrancher » est accepté près de l'équipement ou près de son onduleur.
- **Supprimés** : `LWInstallAction`, `LWDismantleAction`, l'onduleur renforcé, les kits d'inventaire et leurs modèles 3D.
- **Migration** : schéma 2. Les équipements du schéma 1 (sprites vanilla) passent dans `legacy.schema1` et leurs ancres sont retirées ; les anciens objets restent dans le monde comme simples meubles.
- **Test en jeu** : fait par l'utilisateur ([`annexes/tests/protocole-tests.md`](annexes/tests/protocole-tests.md)).

## 0 bis. Mise à jour 0.1.2 (2026-10-17)

- **États transmis** : la marque porte aussi `st` (onduleur : on/off/tripped/broken ; disjoncteur : ok/tripped ; alarme : ok/ringing) et `pw` (maison alimentée). `Devices.refreshStates(grid)`, appelé à chaque pas, réécrit les marques qui ont changé.
- **Visuels client** (`client/LW_Visuals.lua`) : repérage des équipements à 18 cases (toutes les 3 s), calques de tuile 24-67 posés et retirés localement, pales recalculées toutes les 100 ms selon `getClimateManager():getWindspeedKph()`.
- **Son** : `client/LW_Hum.lua`, son `LiveWireInverterHum` (`scripts/LiveWire_sounds.txt`, `sound/LiveWireInverterHum.ogg`).
- **Interfaces** : `client/LW_InverterPanel.lua` (écran LCD), `client/LW_SoftwareApp.lua` (logiciel de gestion, dessiné dans un rectangle de n'importe quel élément d'interface : `draw(ui, x, y, w, h)`, `onMouseDown(x, y)`), `client/LW_SoftwareScreen.lua` (notre écran d'ordinateur), `client/LW_RangeView.lua` (cercle de la zone), `client/LW_ComputerMod.lua` (Computer Mod facultatif), `shared/LW_Compat.lua` (mods facultatifs).
- **Computer Mod** : vue `LIVEWIRE` de `ComputerScreenUI`, sur le modèle de l'extension Musique de l'auteur. Enveloppes, qui rappellent toutes l'original : `getDesktopAppItems` (icône si le logiciel est installé), `activateDesktopItem` (ouvre la vue), `drawDesktop` (fenêtre `drawAppWindow` puis l'application dans `clientX/Y/W/H`), `onMouseDown`, `getWindowTitleForView`, `restoreMinimizedWindow`, `resumePoweredSession`, `shutdownComputer`, `hideComputerScreen`. Drapeau `ComputerModLiveWireInstalled` dans les données de l'ordinateur. Ouverture depuis notre menu : `ComputerContextMenu.openComputerUI`, puis la vue au premier affichage du bureau.
- **Commandes** : `C_RESET_BREAKER`, `C_ACK_ALARM` ; `Commands.handle` exécute un gestionnaire tout de suite (tests).
- **Frigos** : `Anchor.ageFridges` (autorité) avant chaque changement d'état d'une ancre.
- **Butin** : `server/Items/LiveWire_Distributions.lua`.

## 1. Mécanisme d'alimentation

### 1.1 Contrainte du moteur

- **Seules des positions de générateur alimentent une case.** Une case n'est alimentée « par générateur » que si `IsoGridSquare.haveElectricity()` est vrai, et cette méthode ne lit que les **positions de générateur** enregistrées sur le chunk (`java/zombie/iso/IsoGridSquare.java:8223-8228`, `java/zombie/iso/IsoChunk.java:4773-4783`).
- **Le réseau public ne peut pas servir.** C'est un drapeau global, qu'on ne peut pas rallumer pour un seul lieu (`IsoGridSquare.java:10150-10156`, `knowledge/power-and-lights.md:9-16`).
- **Les consommateurs sont en Java.** Lumières, conteneurs réfrigérés, cuisinières et radios sont tous gérés en Java (`java/zombie/inventory/ItemContainer.java:2195-2262`).

Il faut donc des positions de générateur. Reste à savoir **qui les pose** : un vrai `IsoGenerator`, ou le mod lui-même.

### 1.2 Pourquoi pas un vrai `IsoGenerator` comme onduleur

La première version de cette conception reposait sur un vrai `IsoGenerator` piloté par le mod. **Elle est incompatible avec l'exigence « onduleur à l'intérieur »** :

- **La toxicité est réévaluée chaque heure.** Un générateur allumé sur une case d'une pièce, sans drapeau `exterior`, met le bâtiment en toxique à l'allumage, puis à chaque passage d'heure (`java/zombie/iso/objects/IsoGenerator.java:183-185`, `:466-468`), et encore au chargement des régions (`java/zombie/iso/areas/isoregion/metagrid/WorldRegionToMetaGrid.java:551-553`). Aucun réglage ne l'évite (NM-4).
- **La toxicité abîme à chaque image.** Tant que le bâtiment est toxique, chaque personnage à l'intérieur sans masque perd 0,1 point de santé au torse **à chaque mise à jour** (multiplicateur 30 images/s), en plus de la fatigue (`java/zombie/characters/IsoGameCharacter.java:8192-8202`).
  - Remettre le drapeau à faux juste après coup laisserait passer des dégâts. Le client MP reçoit l'état par paquet, ce qui ajoute la latence (`java/zombie/iso/areas/IsoBuilding.java:509-513`, `java/zombie/network/GameClient.java:795-805`).
  - Ce n'est pas acceptable dans une maison habitée.
- **D'autres inconvénients s'ajoutent.** Le son de boucle d'un générateur vanilla est imposé aux joueurs (NM-2). L'usure moteur peut provoquer un incendie (NM-3). Enfin, il faut bloquer tout le menu vanilla du générateur (NM-8).

Les faits établis sur `IsoGenerator` (NM-1 à NM-9) restent utiles : pour comprendre les générateurs vanilla, et pour la charge depuis un générateur prévue en v0.2.

### 1.3 Alternatives étudiées

| # | Mécanisme | Pour | Contre | Verdict |
|---|---|---|---|---|
| A | **Ancre d'alimentation** : le mod pose lui-même la position de générateur de l'onduleur sur les chunks de sa portée, et la repose à chaque chargement | Onduleur posable partout, intérieur compris ; aucune toxicité, aucun incendie, aucun son imposé ; usure et bruit entièrement maîtrisés par le mod ; positions sauvegardées avec les chunks, donc courant **même sans joueur** | Purgées à chaque chargement (§ 1.4), donc il faut les reposer, sur le serveur **et** chez chaque client ; la consommation est mesurée par le mod (§ 1.5) ; les effets côté client (bourdonnement du réfrigérateur, lumière) sont à rafraîchir | **Retenue — validée : D-2** |
| B | Vrai `IsoGenerator` sur la case de l'onduleur | Le moteur fait tout | Toxicité en intérieur (§ 1.2) | Écartée (exigence 1) |
| C | Vrai `IsoGenerator` **caché** sur une case extérieure proche (« coffret de raccordement »), relié à l'onduleur intérieur | Le moteur mesure la consommation et gère le MP | Un second objet dehors ; disque de portée décentré ; immeubles sans case extérieure au même étage ; son de générateur vanilla imposé ; menu vanilla à bloquer | **Repli** si A échoue au prototype P1 |
| D | Réseau public global (`ElecShutModifier`) | Aucun objet | Toute la carte ; réservé à l'admin en MP (`knowledge/power-and-lights.md:26-34`) | Écartée |
| E | Réseau global avec zones `NoPower` partout sauf la base | Une seule zone | Les lumières se rallument sur toute la carte (`java/zombie/iso/LightingJNI.java:226`, `:308-330`) | Écartée |

### 1.4 L'ancre d'alimentation en détail

**Ce que fait le moteur, et ce qu'on reproduit.** Un générateur qui s'allume appelle `chunk:addGeneratorPos(x, y, z)` sur chaque chunk **chargé** qui touche son disque de portée, et `removeGeneratorPos` quand il s'éteint (`IsoGenerator.java:251-272`, `touchesChunk`). Les chunks font 8 cases de côté (`generatorChunkRange = rayon / 8 + 1`, `IsoGenerator.java:115-119`). L'ancre Live Wire fait la même chose avec la position **de la case de l'onduleur** :

```lua
-- illustrative: apply one anchor to every loaded chunk touching its disc
local function applyAnchor(a, on)               -- a = { x, y, z }
  local R = getSandboxOptions():getOptionByName("GeneratorTileRange"):getValue()
  local cell = getCell()
  for cy = math.floor((a.y - R) / 8), math.floor((a.y + R) / 8) do
    for cx = math.floor((a.x - R) / 8), math.floor((a.x + R) / 8) do
      -- server: getChunkForGridSquare goes through ServerMap (IsoCell.java:361-364)
      local chunk = cell:getChunkForGridSquare(cx * 8, cy * 8, a.z)
      if chunk and LiveWire.Anchor.touches(chunk, cx, cy, a, R) then
        if on then chunk:addGeneratorPos(a.x, a.y, a.z)
        else chunk:removeGeneratorPos(a.x, a.y, a.z) end
      end
    end
  end
end
```

- **Choix de l'appel selon le côté.**
  - Sur un serveur dédié, utiliser `getCell():getChunkForGridSquare(x, y, z)`, qui passe par `ServerMap`. `getCell():getChunk(wx, wy)` ne lit que les cartes des joueurs locaux, donc seulement côté client (`java/zombie/iso/IsoCell.java:361-388`).
  - Les deux classes sont exposées à Lua (`index-lua-exposed-classes.txt:352-353`).
- **Doublons et étages.** `addGeneratorPos` ignore un doublon exact, et `removeGeneratorPos` retire toutes les entrées égales (`IsoChunk.java:4748-4771`). Une seule position couvre déjà ±`GeneratorVerticalPowerRange` étages (`IsoGenerator.isPoweringSquare`, `:637-644`).

**La purge et comment s'en accommoder.**
- **Purge au chargement.** À chaque chargement de chunk, le moteur retire les positions dont la case existe **et** ne porte pas de générateur allumé, sur ce chunk et ses voisins (`IsoChunk.java:4785-4797`, `IsoGenerator.java:593-609`, appelé depuis `IsoChunk.java:3526`). La case de l'onduleur existe toujours : son ancre est donc purgée dès que son chunk ou un voisin se charge.
- **L'événement `LoadChunk` part juste après**, sans mise à jour du jeu entre les deux. Il est déclenché sans condition, donc **sur le serveur comme sur chaque client** (`IsoChunk.java:3613`). Le gestionnaire Live Wire, placé dans `shared/`, y **réapplique l'état voulu** de chaque ancre dont le disque touche le chunk chargé, sur tous les chunks chargés de ce disque. Un deuxième passage quelques ticks plus tard couvre les voisins chargés après (`knowledge/power-and-lights.md:24`).
- **Positions conservées sans joueur.** Les positions sont sauvegardées avec chaque chunk (`IsoChunk.java:4092-4101`). Les chunks voisins déchargés gardent donc la position, et tant que le chunk de l'onduleur n'est pas chargé, elle n'est pas purgée (case `null`, `IsoChunk.java:4791-4792`).
- **Positions transmises aux clients.** Elles sont relues depuis le tampon de chunk que le client télécharge (`IsoChunk.java:3318-3331`, via `LoadFromBuffer`, `java/zombie/iso/WorldStreamer.java:661`), mais elles sont purgées chez le client comme sur le serveur. D'où le gestionnaire `LoadChunk` partagé.
- **Bonne nouvelle : pas de fuite à la désinstallation.** Si le mod est retiré, l'onduleur reste comme simple décor. Sa case existe toujours, et son ancre est donc purgée au chargement suivant : **aucun courant fantôme**, contrairement à une position posée sur une case vide (`knowledge/power-and-lights.md:18-24`).

**Chez les clients MP.**
- **Ce qui n'est pas synchronisé.** Un `addGeneratorPos` fait sur le serveur n'est **pas** transmis aux clients qui ont déjà le chunk : seul un vrai générateur fait recalculer ses positions au client, par `sync` (`IsoGenerator.java:550-568`).
- **Comment les clients restent à jour.**
  - Le serveur maintient une petite table publique des ancres, `{ id = { x, y, z, on } }`, en ModData globale `LiveWireAnchors`. Il la diffuse par `ModData.transmit` à chaque changement (rare).
  - Chaque client l'applique à la réception (`OnReceiveGlobalModData`, `java/zombie/network/packets/service/GlobalModDataPacket.java:42-53`) et à chaque `LoadChunk`.
  - Elle ne contient aucun secret (`knowledge/multiplayer.md:110-115`).
- **Rafraîchir les effets visibles.** Le client appelle `obj:checkHaveElectricity()` sur les appareils du disque. C'est ce que fait le moteur à l'allumage d'un générateur (`IsoGenerator.java:279`). Cette méthode ne fait rien sur le serveur ; sur le client, elle démarre le bourdonnement du réfrigérateur, le son d'ambiance et la source de lumière (`java/zombie/iso/IsoObject.java:4800-4812`).

**Lumières des pièces.** Elles lisent `haveElectricity` à leur mise à jour (`java/zombie/iso/objects/IsoLightSwitch.java:408-420`). Le délai d'allumage après l'application de l'ancre est à mesurer au prototype P1.

### 1.5 Mesure de la consommation par le mod

Sans `IsoGenerator`, `getTotalPowerUsing` n'existe pas. Le mod reproduit donc la règle du moteur (`IsoGenerator.java:274-286`) :
- on garde les appareils du disque (rayon `GeneratorTileRange`, ±`GeneratorVerticalPowerRange` étages) dont `obj:getGeneratorPowerConsumption()` est positif (`IsoObject.java:4784-4798` et classes d'appareils, NM-5) ;
- on exclut ceux que le réseau public alimente déjà, comme le moteur ;
- s'ajoute la consommation à vide de l'onduleur.

**Coût maîtrisé** :
- un **inventaire** des appareils capables de consommer est construit par balayage du disque. Au pire, π × 20² × 7 ≈ 8 800 cases. Il est refait une fois par heure de jeu, et à chaque `OnObjectAdded` ou `OnObjectAboutToBeRemoved` dans le disque (`java/zombie/Lua/LuaEventManager.java:778-779`) ;
- à chaque pas, seuls les appareils de l'inventaire sont réévalués (quelques dizaines) ;
- quand l'onduleur n'est pas chargé, on garde la dernière demande mesurée.

### 1.6 Ce que sont les objets, techniquement

| Rôle | Objet du monde | Pourquoi |
|---|---|---|
| Onduleur | `IsoObject` simple, sprite de substitution **sans conteneur**, posé par `IsoObject.new` puis `sq:transmitAddObjectToSquare(obj, -1)` (`IsoGridSquare.java:5062-5070`) | Sauvegardé avec sa ModData (`IsoObject.java:1512-1515`) ; aucune logique vanilla attachée |
| Source | Idem, sprite de sa catégorie (§ F-2.3) | Idem |
| Équipement optionnel (disjoncteur, ordinateur de gestion, alarme de batterie faible : § F-2.4) | Idem | Idem. Rôle `option` dans le registre ; au plus un de chaque type par réseau. Il modifie seulement des paramètres du pas de simulation (§ 4.2) |
| Powerbank | `IsoObject` au sprite de caisse militaire, avec un **conteneur créé par le mod** à la pose : `ItemContainer.new("livewirepowerbank", sq, obj)` (`java/zombie/inventory/ItemContainer.java:143`), `setCapacity(40)`, `setExplored(true)` et `setHasBeenLooted(true)`, puis `obj:setContainer(c)` (`IsoObject.java:1883`), **avant** `transmitAddObjectToSquare`. Sans `setExplored`, le jeu remplirait le conteneur de butin (NM-31) | Le conteneur est sauvegardé et transmis avec l'objet ; les batteries y entrent par les transferts d'inventaire vanilla |

Le mod ne crée **aucun** objet tagué `Generator`, et aucun `IsoGenerator` (NM-6).

---

## 2. Découpage en modules

### 2.1 Arborescence

Tout le mod vit sous `Contents/mods/batman_LiveWire/42.21/media/` (`developpement.md`).

```
lua/shared/LiveWire/LW_Core.lua            table globale LiveWire, version, journal, cles ModData
lua/shared/LiveWire/LW_Config.lua          lecture des options sandbox
lua/shared/LiveWire/LW_Defs.lua            equipements (tuiles, roles), batteries (donnees)
lua/shared/LiveWire/LW_Physics.lua         fonctions pures : solaire, eolien, lissage, batteries, pas de reseau
lua/shared/LiveWire/LW_Protocol.lua        noms de commandes, validation des arguments
lua/shared/LiveWire/LW_Marks.lua           marque des equipements (modData.movableData.LiveWire)
lua/shared/LiveWire/LW_Placement.lua       enveloppes du curseur de meubles vanilla : regles de
                                           pose (dehors, riviere), pose, ramassage, rotation
lua/shared/LiveWire/LW_Anchor.lua          application des ancres (serveur ET clients), LoadChunk
lua/shared/LiveWire/LW_Install.lua         raccordement (portee, fils), recherche des onduleurs et
                                           equipements sur les cases chargees, outils d'inventaire
lua/shared/LiveWire/LW_Notify.lua          messages au joueur (cles traduites cote client)
lua/shared/LiveWire/LW_Recipes.lua         OnCreate de la batterie stationnaire
lua/shared/LiveWire/LW_VanillaGuards.lua   enveloppes demonter (ferraille) / detruire (affichage et autorite)
lua/shared/LiveWire/TimedActions/LW_TimedActions.lua
                                           raccorder, reparer, inspecter,
                                           deneiger, mesurer, reconditionner
lua/server/LiveWire/LW_Registry.lua        registre, index par position, table publique des ancres
lua/server/LiveWire/LW_Devices.lua         inscription a la pose, retrait au ramassage, rotation,
                                           equipements detruits (validate)
lua/server/LiveWire/LW_Migration.lua       migrations de schema
lua/server/LiveWire/LW_Simulation.lua      pas de simulation (EveryTenMinutes), instantanes
lua/server/LiveWire/LW_Demand.lua          inventaire des appareils et mesure de la demande
lua/server/LiveWire/LW_Batteries.lua       batteries posees : lecture, ecriture, rapprochement
lua/server/LiveWire/LW_ChunkSync.lua       au chargement d'un chunk : batteries, inventaires de demande
lua/server/LiveWire/LW_Commands.lua        OnClientCommand, validation, limite de debit
lua/server/LiveWire/LW_Xp.lua              experience (addXp sur l'autorite)
lua/client/LiveWire/LW_ClientState.lua     instantanes recus, messages traduits
lua/client/LiveWire/LW_ContextMenu.lua     sous-menu "Live Wire" (monde et inventaire)
lua/client/LiveWire/LW_Dashboard.lua       fenetre du tableau de bord
lua/client/LiveWire/LW_Hum.lua             ronronnement local de l'onduleur (FridgeHumA, D-8)
lua/shared/Translate/EN/*.json, FR/*.json  textes (generes par tools/translations_src.py)
scripts/LiveWire_items.txt, LiveWire_recipes.txt, LiveWire_models.txt
models_X/LiveWire/*.glb, textures/LiveWire/*.png   formes geometriques (tools/make_placeholder_models.py)
sandbox-options.txt
```

### 2.2 Règles de chargement

| Situation | Dossiers exécutés | Preuve |
|---|---|---|
| Solo et client | `shared` et `client`, puis `server` au chargement de la partie | `java/zombie/Lua/LuaManager.java:1244-1245`, `java/zombie/gameStates/GameLoadingState.java:153` |
| Serveur dédié | `shared`, puis `client` en somme de contrôle seulement, puis `server` | `java/zombie/network/GameServer.java:1403-1405` |

- **Fichiers `server/`.** Ils sont aussi exécutés par les clients MP : chacun commence donc par `if isClient() then return end` (modèle vanilla `media/lua/server/Map/MapObjects/MOGenerator.lua:1`).
- **« Autorité ».** Ce mot désigne `not isClient()`, c'est-à-dire le solo ou le serveur (`knowledge/multiplayer.md:21`, `:228`).
- **`LW_Anchor.lua` est volontairement dans `shared/`, sans garde** : il doit tourner des deux côtés (§ 1.4).

### 2.3 Espaces de noms et règles Kahlua

- **Une seule globale : `LiveWire`.** Ses sous-tables : `Config`, `Defs`, `Physics`, `Protocol`, `Marks`, `Anchor`, `Registry`, `Sim`, `Demand`, `Batteries`, `Xp`, `Client`.
- **Exception : les actions chronométrées.** Elles sont globales par nécessité, car `NetTimedAction` les retrouve par leur nom de classe (`java/zombie/core/NetTimedAction.java:145-172`) : `LWLinkAction`, `LWRepairAction`, `LWInspectAction`, `LWReconditionAction`, `LWClearSnowAction`, `LWMeasureAction`.
- **Préfixe `LW`** pour les recettes, les clés de traduction et les identifiants.
- **Règles Kahlua** (`developpement.md`, base moteur `kahlua-lua.md`) :
  - aucun littéral non ASCII dans les `.lua` ;
  - `ZombRand` plutôt que `math.random` ;
  - chaque abonnement à un événement se fait une seule fois, au chargement du fichier.

### 2.4 Protection des sources et de l'onduleur

Il n'y a plus de menu « Générateur » à masquer, car ces objets ne sont pas des générateurs. Il reste les gestes vanilla génériques. Les deux couches testent `LiveWire.Marks.isOurs(obj)`.

**1. Client (affichage).** Enveloppes qui gardent la signature et le retour vanilla :
- `ISMoveableSpriteProps:canPickUpMoveable` → `false` ;
- `ISMoveableSpriteProps:canScrapObject` → `craftValid = false` ;
- `ISDestroyCursor:canDestroy` → `false`.

Preuves : `media/lua/shared/Moveables/ISMoveableSpriteProps.lua:1202-1255`, `media/lua/server/BuildingObjects/ISDestroyCursor.lua:293`.

**2. Autorité (refus).**
- Enveloppes de `complete()` pour `ISMoveablesAction` et `ISDestroyStuffAction` : si la cible est marquée, retour sans appeler l'original, et refus journalisé. Le serveur n'appelle pas le `isValid` Lua (`knowledge/multiplayer.md:43-49`, `:230`).
- Ne **pas** envelopper `new` (NM-9).

**Powerbank.** Elle est protégée comme les autres appareils. On n'y touche que par son conteneur, et elle ne se démonte que vide.

---

## 3. Modèle de données

### 3.1 Où vit chaque donnée

| Donnée | Lieu | Qui fait foi |
|---|---|---|
| Réseaux, appareils, état métier, énergie des batteries non chargées | ModData globale `LiveWire` (serveur seulement) | **Autorité**. Un `transmit` venu d'un client n'écrase rien côté serveur (`knowledge/multiplayer.md:115`) |
| Ancres (position et marche) | ModData globale `LiveWireAnchors`, diffusée à tous | Autorité ; les clients n'en ont qu'une copie |
| Marque d'un onduleur ou d'une source | `obj:getModData().LiveWire = { id, s }` | Reflet seulement. Un client peut la réécrire par `transmitModData` (NM-11) : elle sert à **reconnaître** l'objet, et le registre fait foi |
| Charge d'une batterie | Utilisations de l'objet (`setCurrentUsesFloat`, de 0 à 1), dans le conteneur de la powerbank | Autorité, quand la powerbank est chargée |
| Usure d'une batterie | État de l'objet (`setConditionNoSound`) | Idem |
| Cycles d'une batterie | ModData de l'objet (`LiveWireCycles`), lue par le serveur seulement | Autorité |
| Instantané des batteries d'une powerbank déchargée | `slots` de l'appareil dans le registre : identifiant d'objet, type, charge, état, cycles | Autorité, tant que la powerbank n'est pas chargée |

**Synchronisation.** Une batterie rangée dans un meuble se synchronise par `sendItemStats(item)` : utilisations et état, pas la ModData (`java/zombie/Lua/LuaManager.java:3757-3762`, `knowledge/multiplayer.md:319-322`). Les clients voient la charge dans l'infobulle ; la ModData ne sert qu'au serveur.

### 3.2 Schéma de la ModData globale `LiveWire` (version 1)

```lua
{
  schema = 1,
  nextId = 42,                        -- monotonic, never reused
  devices = {
    ["d5"] = { id="d5", role="inverter", model="Inverter", x=10510, y=9618, z=0,
               grid="g2", cond=93, eff=0.95, state="on",  -- on|off|tripped|broken|idle
               maxW=1500, idleW=20 },
    ["d7"] = { id="d7", role="source", model="SolarPanel", x=10512, y=9620, z=1,
               grid="g2", cond=87, eff=0.95, state="ok", snow=0.0,
               pOut=64.0 },           -- W, smoothed output of the built-in micro-inverter
    ["d9"] = { id="d9", role="storage", model="PowerBank", x=10511, y=9618, z=0,
               grid="g2", cond=98, wearFactor=0.9,
               slots = { { id=1234567, model="Base.CarBattery2", charge=0.62, cond=74, cycles=31.5 } } },
    ["d11"] = { id="d11", role="option", model="Breaker", x=10509, y=9618, z=0,
                grid="g2", cond=100, state="ok" },             -- optional equipment
  },
  grids = {
    ["g2"] = { id="g2", name="", inverter="d5", members={ d7=true, d9=true },
               demand=172.0,          -- W, last measured demand
               lastTick=1234.5,       -- world age hours of last step
               rev=318 },
  },
  byPos = { ["10512,9620,1"] = { "d7" } },
}
```

- **Identifiants** : `d<n>` et `g<n>`. Jamais réutilisés, jamais modifiés (`developpement.md`).
- **Taille** : environ 200 octets par appareil. Cette table n'est **jamais** diffusée entière (§ 5).

### 3.3 Versions et migration

- **Migration pas à pas.** `schema` est un entier. `LW_Migration.run(data)` applique dans l'ordre des étapes `[n] = function(d) … d.schema = n + 1 end`.
- **Règles d'une migration** :
  - **idempotente** ;
  - **journalisée** en anglais ;
  - elle ne supprime jamais d'appareil : les données inconnues vont dans `d.legacy`.
- **Version trop récente.** Un `schema` plus récent que le code met le mod en **lecture seule** : simulation suspendue, ancres laissées telles quelles, erreur journalisée.
- **Moment de la migration.** Elle se fait dans `OnInitGlobalModData`, où `getCell()` vaut `nil` (`knowledge/world-placement.md:105-113`) : on n'y touche qu'aux données.

---

## 4. Boucle de simulation (autorité)

### 4.1 Événements

| Événement | Côté | Rôle | Preuve |
|---|---|---|---|
| `OnInitGlobalModData` | autorité | Récupère le registre et migre | `java/zombie/world/moddata/GlobalModData.java:53-57` |
| `OnServerStarted` (dédié) ; premier `EveryOneMinute` (solo) | autorité | Arme la simulation. `OnGameStart` ne part probablement pas sur un dédié (hypothèse) | `LuaEventManager.java:788`, `GameServer.java:1461` |
| `EveryTenMinutes` | autorité | **Pas de simulation** | `LuaEventManager.java:746` ; au plus une fois par mise à jour, même après un saut (`java/zombie/GameTime.java:553-576`) |
| `LoadChunk` | **les deux** | Réapplique les ancres ; côté autorité, rattache les objets marqués et écrit la charge des batteries | `IsoChunk.java:3613` |
| `OnTick` (compteur) | les deux | Deuxième passage d'ancres après un chargement | `knowledge/power-and-lights.md:24` |
| `OnObjectAdded`, `OnObjectAboutToBeRemoved` | autorité | Invalide l'inventaire des appareils d'un onduleur | `LuaEventManager.java:778-779` |
| `OnReceiveGlobalModData` | client | Reçoit la table des ancres | `GlobalModDataPacket.java:42-53` |
| `OnClientCommand` | autorité | Commandes (§ 5) | `GameServer.java:2157` |

### 4.2 Un pas pour un réseau, chargé ou non

1. **Durée écoulée.** `dt = now − lastTick`, avec `now = getGameTime():getWorldAgeHours()` (`GameTime.java:830-834`).
   - Si `dt ≤ 0`, on ne fait rien.
   - Au-delà de 1 h, le pas est découpé en tranches d'une heure, jusqu'à 720 h. Au-delà, le calcul se fait en bloc.
2. **Production** des sources (§ F-3), puis **lissage** par le micro-onduleur de chaque source : `P_fournie` est gardée dans le registre (champ `pOut`) et suit la puissance brute avec un temps de réponse de 0,5 h (§ F-3.1).
   - Le soleil est intégré analytiquement sur la tranche.
   - Pendant un rattrapage, on utilise la météo **actuelle**, car l'historique n'existe pas.
3. **Demande.**
   - Onduleur chargé : mesure (§ 1.5).
   - Sinon : `grid.demand` si `SimulateUnloaded` est actif, sinon 0.
4. **Onduleur** : disjonction si demande > maximum, sans perte d'état si un disjoncteur est raccordé ; consommation à vide ; usure (§ F-4.4).
   - Les équipements optionnels du réseau (§ F-2.4) n'agissent que par des paramètres de ce pas : perte d'état en cas de disjonction, seuil de délestage, seuil d'alerte.
5. **Bilan énergétique** (§ F-5.3) : répartition sur les batteries, au prorata.
6. **Batteries.**
   - Chargées (case chargée) : écriture sur les objets réels (§ 4.4).
   - Sinon : mise à jour de l'instantané du registre.
7. **État voulu de l'ancre.** Elle est allumée si l'onduleur est en marche **et** que la production du moment ou le stock couvre la demande. Si cet état change, l'autorité applique l'ancre (§ 1.4), met à jour `LiveWireAnchors` et la diffuse.
8. `lastTick = now`, `rev = rev + 1`, puis instantané aux abonnés.

**Pourquoi cela marche sans joueur.**
- Les positions de l'ancre sont **sauvegardées dans les chunks voisins** : quand un joueur revient, la maison est alimentée dès le chargement, si l'ancre était allumée.
- Pendant l'absence, le registre fait vivre production, consommation et usure.
- Si l'énergie s'épuise pendant l'absence, l'autorité met l'ancre à « éteinte ». Les chunks déchargés gardent la position, mais le gestionnaire `LoadChunk` applique l'état voulu (éteint) **dès leur chargement**, avant toute mise à jour des appareils.

### 4.3 Coût

- **Calcul.** Un pas coûte O(appareils), soit quelques opérations par appareil : 100 appareils toutes les 10 minutes de jeu (environ 25 s réelles avec un jour de 1 h).
- **Inventaire de la demande.** Au pire 8 800 cases par onduleur et par heure de jeu, seulement si l'onduleur est chargé. À mesurer (prototype P6).
- **Réseau.** Un `transmit` de `LiveWireAnchors` à chaque changement d'état d'une ancre : la table est petite et les changements rares. Plus un `syncItemFields` par batterie chargée dont la charge a bougé de plus de 1 %.

### 4.4 Batteries chargées : rapprochement avec les objets réels

- **Retrouver la batterie.** Pour chaque appareil `battery` du registre dont la case est chargée, on parcourt `sq:getWorldObjects()` et on cherche l'objet dont `getItem():getModData().LiveWire.id` correspond.
- **Si elle est trouvée** : on lit charge et état, ce sont eux qui font foi ; on applique le pas ; on écrit `setCurrentUsesFloat` et `setCondition`, puis `item:syncItemFields()` en MP.
- **Si elle est absente** : elle a été ramassée ou déplacée. Elle est débranchée, et son énergie est partie avec l'objet, ce qui est voulu. Si elle est reposée et raccordée de nouveau, elle redevient un appareil, avec un nouvel identifiant de lien.
- **Au chargement d'une case (`LoadChunk`).** L'instantané du registre est écrit sur l'objet : personne n'a pu y toucher pendant le déchargement.
- **Pas de duplication possible.** L'énergie d'une batterie chargée est toujours relue sur l'objet présent.

---

## 5. Protocole réseau

### 5.1 Principes

- **Module.** Les commandes utilisent le module `"LiveWire"`.
- **Actions longues.** Installer, démonter, raccorder, réparer, inspecter, reconditionner, déneiger et mesurer sont des **actions chronométrées partagées**. Leur `complete()`, exécuté sur l'autorité, revérifie tout (`knowledge/multiplayer.md:43-49`).
- **Actions instantanées.** Elles passent par `sendClientCommand("LiveWire", cmd, args)`.
- **Identité garantie.** Le joueur est déduit de la connexion (`GameServer.java:2126-2157`).
- **Ordre non garanti.** La livraison n'est pas ordonnée : chaque instantané porte `rev` (`knowledge/multiplayer.md:213-218`).
- **Traductions côté client.** Le serveur ne connaît pas les traductions des mods. Il envoie des **clés** avec leurs paramètres (`knowledge/api-42-21.md:145-150`).

### 5.2 Commandes

| Sens | Commande | Arguments | Effet |
|---|---|---|---|
| C → S | `subscribe` / `unsubscribe` | `{ inverter }` | Abonnement au tableau de bord (10 minutes réelles, renouvelé). Par identifiant d'onduleur, que le client lit dans la marque de l'objet |
| C → S | `unlink` | `{ device }` | Débranche une source ou un équipement. Une batterie se débranche en la ramassant |
| C → S | `setInverter` | `{ inverter, on }` | Allumage ou extinction manuels |
| C → S | `reset` | `{ inverter }` | Réarme après une disjonction, si la demande est revenue sous le maximum |
| C → S | `rename` | `{ inverter, name }` | Nom de 24 caractères au plus |
| S → C | `snapshot` | `{ grid, rev, inverter, sources, batteries, demand, energy, capacity, alerts }` | Cache du client |
| S → C | `notify` | `{ key, args }` | Message au joueur |
| S → C | `refuse` | `{ cmd, key }` | Refus motivé |
| S → tous | `ModData.transmit("LiveWireAnchors")` | — | Table des ancres (§ 1.4) |

**Raccorder** passe par l'action chronométrée `LWLinkAction`, qui consomme le fil côté serveur.

### 5.3 Validation côté serveur

1. **Forme.** Types attendus ; chaînes de 32 caractères au plus ; identifiants au format `^[dg]%d+$`.
2. **Joueur.** Vivant, pas dans un véhicule.
3. **Existence.** Appareil connu, case chargée, objet marqué présent et cohérent avec le registre.
4. **Distance.** Tchebychev ≤ 3 cases et même étage (`floor(getZ())`). `DistToProper` ignore z (`knowledge/multiplayer.md:70`).
5. **Droits.** Règle de safehouse vanilla ; l'API exacte est à confirmer (R-8).
6. **Conditions métier.** Niveau d'Électricité et objets requis vérifiés **côté serveur**.
7. **Débit.** Au plus 4 commandes par seconde réelle et par joueur ; l'excédent est ignoré. Le serveur ne limite rien de lui-même et journalise les commandes hors filtre (`GameServer.java:2151-2153`).

**Diffusion.** Les instantanés vont seulement aux abonnés à moins de 30 cases de l'onduleur. La table `LiveWire` n'est **jamais** diffusée.

---

## 6. Persistance et reprise

### 6.1 Ce qui est sauvegardé

| Élément | Sauvegarde | Preuve |
|---|---|---|
| Registre et ancres | `global_mod_data.bin`, avec le monde | `GlobalModData.java:221-268`, `java/zombie/network/ServerMap.java:397` |
| Positions d'ancre | Avec chaque chunk voisin | `IsoChunk.java:4092-4101` |
| Onduleur, sources | Avec leur chunk (`IsoObject` et ModData) | `IsoObject.java:1512-1515` |
| Batteries posées | Avec leur chunk : l'objet, ses utilisations, son état et sa ModData | `java/zombie/iso/objects/IsoWorldInventoryObject.java:478-489`, NM-10 |

**Pas d'`OnSave` sur un dédié.** Sur un serveur dédié, la sauvegarde périodique ne déclenche aucun `OnSave` (`knowledge/world-placement.md:154`) : le registre est donc toujours tenu cohérent en mémoire.

### 6.2 Reprise après un redémarrage

- **Démarrage.** `OnInitGlobalModData` migre le registre. Au premier pas de simulation, `dt` = temps de jeu écoulé depuis `lastTick`.
- **À chaque `LoadChunk` :**
  - ancres réappliquées ;
  - objets marqués rattachés ;
  - instantané des batteries écrit sur les objets.

  Un objet marqué inconnu du registre est journalisé et laissé inerte. L'action « Inspecter » permet de l'adopter.
- **Client qui se connecte.** Il demande `LiveWireAnchors` (`ModData.request`, `GlobalModData.java:152-205`) et l'applique aux chunks déjà chargés.

### 6.3 Incohérences et réparations

| Cas | Détection | Traitement |
|---|---|---|
| Onduleur ou source absent de sa case chargée | Rattachement ou pas de simulation | Après 2 constats espacés d'au moins 10 minutes de jeu : appareil retiré ; ancre éteinte et retirée de la table |
| Batterie absente | Pas de simulation | Débranchée (voulu) |
| Objet marqué inconnu | `LoadChunk` | Inerte ; adoption possible par « Inspecter » |
| Case de l'onduleur détruite (sol retiré) | Rattachement | Ancre retirée explicitement de tous les chunks chargés, puis des autres à leur chargement (une position sur une case `null` n'est jamais purgée par le moteur) |
| Plantage entre deux sauvegardes | Écart entre registre et monde | Le monde fait foi pour l'existence des objets ; les batteries chargées pour leur énergie ; le registre pour le reste |

---

## 7. Traductions

**Fichiers.** `media/lua/shared/Translate/EN/` (référence) et `FR/`, en objets JSON plats. Seuls les `.json` sont lus (`knowledge/api-42-21.md:100`).

| Fichier | Clés |
|---|---|
| `ItemName.json` | `LiveWire.VoltageTester`, `.SolarCell`, `.DeepCycleBattery`, `Base.Mov_LiveWire_SolarPanel`, `_WindTurbine`, `_WaterWheel`, `_Inverter`, `_PowerBank`, `_Breaker`, `_BatteryAlarm` |
| `Moveables.json` | `Live_Wire_Solar_Panel`, `_Wind_Turbine`, `_Water_Wheel`, `_Inverter`, `_Power_Bank`, `_Breaker_Panel`, `_Battery_Alarm` (nom des tuiles posées : `GroupName_CustomName`) |
| `Recipes.json` | `LWMakeVoltageTester`, `LWSalvageSolarCell`, `LWMakeSolarPanelKit`, `LWMakeSolarCellFromScrap`, `LWMakeInverterKit`, `LWMakeWindTurbineKit`, `LWMakeWaterWheel`, `LWMakePowerBankKit`, `LWMakeBreakerKit`, `LWMakeBatteryAlarmKit`, `LWMakeDeepCycleBattery` (clé = nom de recette, `java/zombie/core/Translator.java:561-569`) |
| `ContextMenu.json` | `ContextMenu_LW_Root`, `_Measure`, `_Inspect`, `_LinkTo`, `_InverterAt`, `_NoInverter`, `_LinkedTo`, `_LinkedFar`, `_NotLinked`, `_LinkDevice`, `_UnlinkDevice`, `_DeviceAt`, `_LinkedDeviceAt`, `_NothingToLink`, `_NothingLinked`, `_Unlink`, `_Repair`, `_Overhaul`, `_ClearSnow`, `_Dashboard`, `_TurnOn`, `_TurnOff`, `_Reset`, `_Recondition`, `_Debug*` |
| `Tooltip.json` | `Tooltip_LW_NeedLevel` (« Électricité niv. %1 requis »), `_NeedTool`, `_NeedItems`, `_NeedOutdoor`, `_NeedRiver`, `_TooFar`, `_NoInverterInRange`, `_Overlap`, `_NeedFloor` |
| `IG_UI.json` | `IGUI_LW_Dashboard_Title`, `_Sources`, `_Batteries`, `_Inverter`, `_Demand`, `_Stock`, `_Autonomy` (« Autonomie : environ %1 h »), `_Lost`, `_Tripped`, `_Broken`, `_Idle`, `_WornBattery`, `_Measure_Powered`, `_Measure_Source_Grid`, `_Measure_Source_Generator`, `_Measure_Source_LiveWire`, `_Measure_Draw` (« %1 W ») |
| `Sandbox.json` | `Sandbox_LiveWire`, puis `Sandbox_LiveWire_<Option>` et `Sandbox_LiveWire_<Option>_tooltip` (`knowledge/api-42-21.md:143`, `:286`) |

- **Paramètres.** `%1`, `%2` ; un signe pour cent s'écrit `%%` (`knowledge/load-warnings.md:17-25`).
- **Contrôle hors jeu.** Un script (étape E0) comparera les jeux de clés EN et FR.

---

## 8. Risques techniques classés

Tous les prototypes sont **à exécuter** : aucun n'a été fait.

| Rang | Risque | Gravité | Prototype de dérisquage |
|---|---|---|---|
| **R-1** | **L'ancre ne tient pas** : courant absent chez un client MP, lumières qui ne se rallument pas, purge plus tardive que prévu, courant qui disparaît au rechargement. Tout le mod en dépend. | Bloquante | **P1** — commande de débogage qui pose un onduleur de test dans une maison et applique l'ancre. Vérifier, en solo puis sur un dédié avec un 2e client : lumières et réfrigérateur alimentés ; aucun moodle de toxicité ; s'éloigner de 2 cellules puis revenir : courant présent dès l'arrivée ; ancre éteinte : courant coupé chez les deux clients ; mod retiré d'une copie de la sauvegarde : plus de courant après le rechargement. Repli : mécanisme C (§ 1.3) |
| **R-2** | **Mesure de la demande fausse ou coûteuse** : appareils oubliés, appareils de mods tiers, inventaire trop lent | Forte | **P6** — comparer, sur une même maison, la demande du mod à `getTotalPowerUsing()` d'un générateur vanilla de test posé au même endroit. Mesurer le temps d'inventaire (`getTimestampMs`) avec 10 onduleurs |
| **R-3** | **Simulation sans joueur incohérente** : énergie épuisée pendant l'absence mais maison alimentée au retour ; nourriture mal comptée | Moyenne | **P4** — vider volontairement le stock pendant une absence de 3 jours de jeu ; au retour, vérifier que le courant est coupé dès le chargement et l'état des aliments |
| **R-4** | **Powerbank** : conteneur absent chez un client, batterie non retrouvée après rechargement, charge non affichée chez l'autre client, transfert pendant un pas | Moyenne | **P3** — deux joueurs : poser, raccorder, ramasser, reposer pendant un pas en vitesse ×3 ; comparer l'énergie totale et l'infobulle chez les deux |
| **R-5** | **Bourdonnement côté joueur** : un émetteur en boucle qui ne s'arrête plus en MP (`knowledge/sounds-and-noise.md`) | Faible à moyenne | **P1 bis** — démarrer et arrêter le son dix fois, quitter la zone, revenir ; aucun son fantôme |
| **R-6** | **Conflit avec un autre mod** qui pose ou retire des positions de générateur, ou qui enveloppe les mêmes actions vanilla | Moyenne | **P7** — mod de test qui appelle `removeGeneratorPos` sur la position de l'onduleur ; vérifier que le pas suivant ou le prochain `LoadChunk` la rétablit. Garder signatures et retours dans toutes les enveloppes |
| **R-7** | **Équilibrage météo** faux | Moyenne | **P5** — journal horaire du vent, des nuages, de la neige, de l'aube et du crépuscule sur 30 jours de jeu ; histogramme hors jeu |
| **R-8** | **Contournement vanilla** (ramasser comme meuble, détruire) ; API de safehouse | Moyenne | **P2** — liste de contrôle, en solo et en MP, avec un client normal |
| **R-9** | **Pose invalide** : `isOutside()` sous un arbre, rive hors des 6 zones de rivière vanilla | Faible | **P5 bis** — 10 sites connus |
| **R-10** | **Migration** ou identifiants instables | Faible | **P8** — sauvegarde v0.1 conservée et rejouée à chaque version |

---

## 9. Plan d'implémentation par étapes testables

Chaque étape se termine par un protocole en **solo**, puis en **MP dédié** : serveur Linux local, deux clients, le second sans droits d'admin. Rien n'est considéré comme fait tant que le protocole n'a pas été passé **en jeu par l'utilisateur**.

| Étape | Contenu | Protocole solo | Protocole MP dédié |
|---|---|---|---|
| **E0 — Squelette** | `mod.info`, table `LiveWire`, journal, `sandbox-options.txt`, traductions EN et FR vides, script de contrôle des clés | Le mod se charge sans erreur dans `console.txt` ; l'onglet sandbox s'affiche dans les deux langues | Le serveur charge le mod ; un client se connecte ; aucune erreur `server/` côté client |
| **E1 — Prototype ancre (P1, P1 bis)** | `LW_Anchor`, table `LiveWireAnchors`, onduleur de débogage, rafraîchissement visuel | Protocole P1 | Protocole P1 côté 2e client. **Décision : mécanisme A confirmé ?** |
| **E2 — Registre et persistance** | `LW_Registry`, `LW_Migration`, marques, `LoadChunk` | 3 appareils de débogage ; sauvegarder, quitter, recharger : registre et marques intacts | Redémarrage du serveur ; reconnexion d'un client |
| **E3 — Simulation et demande** | `LW_Simulation`, `LW_Physics`, `LW_Demand` | Stock fictif de 1 kWh, réfrigérateur et lumières : coupure à l'heure calculée à la main ; protocole P6 (comparaison avec un générateur vanilla) | Coupure vue par le client ; vitesse ×3 sans dérive |
| **E4 — Powerbank** | `LW_Batteries`, conteneur de la powerbank, `LWLinkAction` | Ranger 2 batteries de voiture dans la powerbank raccordée : décharge la nuit ; en retirer une : stock réduit d'autant ; une 5e batterie est ignorée et signalée | Protocole P3 : deux joueurs rangent et retirent des batteries pendant un pas ; le 2e client voit la charge changer |
| **E5 — Sources** | Kits solaire et éolien, actions d'installation et de démontage, recettes | Fabriquer, poser sur un toit plat, raccorder ; production le jour, nulle la nuit ; éolienne arrêtée sans vent | Pose par le client non-admin ; refus côté serveur si trop loin ou niveau insuffisant |
| **E6 — Sans joueur (P4)** | `SimulateUnloaded`, rattrapage | Protocole P4 | Protocole P4 avec serveur sans joueur (`PauseEmpty` désactivé), puis reconnexion |
| **E7 — Diagnostic et tableau de bord** | Testeur, `LW_Dashboard`, abonnements | Mesures cohérentes aux niveaux 0, 2 et 4 | Deux joueurs ouvrent la fenêtre ; aucune diffusion hors abonnés |
| **E8 — Compétence, usure, pannes, bourdonnement** | `LW_Xp`, paliers, usure, réparation, disjonction, `LW_Hum` | Expérience gagnée ; disjonction avec un lave-linge et sèche-linge superposés ; bourdonnement audible de près seulement | Expérience gagnée par le client non-admin |
| **E9 — Protection et durcissement (P2, P7)** | `LW_HideVanilla`, `LW_VanillaGuards`, validation complète, débit | Liste P2 | Commandes forgées (débogage) toutes refusées ; protocole P7 |
| **E10 — Équilibrage et finition (P5)** | Valeurs, textes, `workshop.txt` | Partie de 30 jours accélérée | Session à plusieurs ; journal relu. Publication par l'utilisateur, sur son poste (`developpement.md`) |

---

## 10. État de l'implémentation v0.1 (2026-10-17)

**Statut : code écrit, vérifié hors jeu, jamais lancé dans le jeu.** Le protocole de test en jeu est dans [`annexes/tests/protocole-tests.md`](annexes/tests/protocole-tests.md).

**Vérifications hors jeu passées :**
- `python3 -I tools/check_mod.py` :
  - syntaxe Lua 5.1 et ASCII de tous les fichiers ;
  - chargement dans l'ordre du jeu pour trois contextes : solo, client MP, serveur dédié ;
  - clés de traduction EN et FR ;
  - gardes `isClient()` ;
  - fichiers des modèles ;
  - noms d'événements comparés à `LuaEventManager.java`.
- `python3 -I tests/test_physics.py` : formules (soleil, vent, lissage, batteries, pas de réseau).
- `python3 -I tests/test_simulation.py` : scénarios sans joueur à proximité :
  - 3 jours avec 6 panneaux et 4 batteries ;
  - source et onduleur sans batterie ;
  - surcharge avec et sans disjoncteur ;
  - rattrapage de 10 jours ;
  - générateur de secours (démarre sous 20 %, s'arrête à 90 %, brûle du carburant ; vide : `nofuel`), historique de 48 points de l'ordinateur, alarme (rappel après 2 h, réarmement au-dessus de 25 %) ;
  - commandes de debug refusées sans `-debug`, appliquées avec.

**Écarts avec les sections précédentes :**
- **Batteries** : rangées dans une **powerbank** à conteneur, choix de l'utilisateur. Plus aucune batterie au sol.
- **Interface de gestion** : abonnement par identifiant d'onduleur (§ 5.2). L'instantané porte en plus la zone couverte (`coverage`), la famille et la puissance nominale de chaque source, et la consommation par famille d'appareils (`appliances`, calculée par `LW_Demand.category` à partir des classes exposées `IsoLightSwitch`, `IsoTelevision`, `IsoRadio`, `IsoStove`, des quatre classes de lave-linge et sèche-linge, de `IsoCarBatteryCharger`, et des conteneurs `fridge` / `freezer`).
- **Disjoncteur** : tuile murale du mod (`MoveType = WallObject`), posée par le curseur vanilla sur le mur nord ou ouest de sa case. Un mur qui le porte est protégé de la masse.
- **Appareil disparu** : un équipement absent de sa case chargée (détruit par les zombies, par exemple) est retiré du registre au chargement du chunk et à chaque pas (`Devices.validate`).
- **Demande** : mêmes filtres que le moteur (`ItemContainer.isObjectPowered`, `AllowExteriorGenerator`, cases réellement alimentées : NM-27). Inventaire refait toutes les 30 minutes de jeu (NM-28).
- **Générateur de secours** (`server/LW_Backup.lua`) : appareil de rôle `backup`, lié à un `IsoGenerator` par la clé de ModData `LiveWireBackup`. Décision à chaque sous-pas avec le stock du début du sous-pas (hystérésis : marche sous `BackupStartPercent`, arrêt à `BackupStopPercent`), puissance ajoutée à la production avant `Physics.stepGrid`. Carburant brûlé par `setFuel` si la case est chargée ; sinon décompté dans le registre et appliqué au `LoadChunk` (`Backup.restore`).
- **Ordinateur de gestion** (`server/LW_Computer.lua`) : rôle `computer`, lié à l'ordinateur vanilla par la clé `LiveWireComputer` (avec l'identifiant de l'onduleur, pour ouvrir le tableau de bord côté client). `grid.history` : 48 points horaires `{p, d, s}`. Délestage par `IsoLightSwitch:setActive(false)` sur les interrupteurs de l'inventaire de demande, case chargée seulement.
- **Alarme** (`server/LW_Alarm.lua`, `client/LW_Beep.lua`) : option `kind = "alarm"`. Le serveur envoie `S_BEEP {x, y, z}` aux joueurs à moins de 30 cases ; chaque client joue le son localement et l'arrête après 3 s.
- **Objets vanilla raccordés** : `Registry.members` rend cinq listes (sources, powerbanks, options, secours, ordinateurs). Débrancher, démonter l'onduleur ou constater deux fois la disparition de l'objet efface la clé de ModData et retire l'appareil du registre (`Registry.forgetVanilla`) ; un générateur que le mod avait démarré est arrêté.
- **Debug** (`shared/LW_Debug.lua`, `server/LW_DebugCommands.lua`, `client/LW_DebugMenu.lua`) : commande unique `C_DEBUG {action, device}` enregistrée par `Commands.register`, droit revérifié, portée 30 cases, journalisée.
- **Roue à aubes** : en 0.1 depuis 0.1.1 (D-18), production `Physics.hydroFactor(mois)`.
- **Pas encore implémenté** : l'adoption d'un objet marqué inconnu du registre (§ 6.3). Un tel objet reste inerte.

**Points du moteur à confirmer en jeu, par ordre de risque :**
1. **L'ancre** (R-1) : courant chez le 2e client, rechargement des chunks, purge, rafraîchissement des lumières.
2. **Le ronronnement** `FridgeHumA` (R-5), qui dépend peut-être du paramètre FMOD `Generator` réglé d'habitude par le moteur.
3. **Le disjoncteur mural** : variantes de sprite et rendu contre le mur.
4. **Les modèles `.glb`** : échelle 1,0 et orientation.
5. **L'icône et la recette** de la batterie stationnaire (`mode:destroy` sur des objets à charge).
6. **Le générateur de secours** : démarrage et arrêt par `setActivated`, double décompte possible du carburant au rechargement de la zone (NM-32).
7. **L'ordinateur** : variantes de sprite tournées (`_73` à `_75` supposées), courant sur sa case, délestage des lumières.
8. **Le bip** `TelevisionTestBeep` : audible, coupé après 3 s (NM-33).

## 11. Correctifs des blocages et performances — 2026-10-24

Le pattern modulaire événementiel avec serveur autoritaire reste inchangé (règles
dans `developpement.md`). Le [bilan de validation](annexes/tests/validation.md)
regroupe les scénarios, résultats et limites de cette campagne.

- `shared/LW_SquareScan.lua` : curseur circulaire reprenable, sans dépendance au
  monde ni aux règles métier. Les services lui fournissent le traitement d'une case.
- `server/LW_Pump.lua` : inventaires de positions des points d'eau, invalidation,
  file de découverte unique et budget global de 250 positions par tick pour toutes
  les pompes. Réévaluation des sources d'eau depuis la liste mise en cache ; aucune
  règle d'attribution entre pompes n'est modifiée (C08 reste distinct).
- `client/LW_PumpView.lua` : même curseur pour découvrir les meubles, puis contrôle
  des objets connus toutes les deux secondes ; fermeture = abandon du travail.
- `shared/LW_Anchor.lua` : index des frigos chargés alimenté au chargement des chunks
  et à la pose de meubles. Les aliments vieillissent avant la bascule ; le
  rafraîchissement visuel est différé avec un budget global de 250 positions par tick.
  Les références aux frigos déchargés sont rejetées à l'usage et purgées chaque heure.
- `server/LW_Registry.lua` : index de session `byChunk` et ensemble des onduleurs,
  reconstruits à l'initialisation, maintenus sur ajout/déplacement/retrait. Aucun
  changement de schéma persistant. `ChunkSync` consomme une liste détachée du chunk.
- `client/LW_ClientState.lua` : cache solo lié au registre, au réseau et à `rev`.
- `server/LW_Backup.lua` : propriétaire du mode manuel et du dernier état physique
  observé ; restauration du carburant en conservant l'intention manuelle.
- `Commands` et `Xp` conservent chacun leur limiteur et sa purge. Les commandes du
  frein et du secours passent par les mêmes contrôles d'autorité que les autres.

## 12. Derniers correctifs CXX — 2026-10-24

Cette campagne conserve le même pattern et exclut les idées IXX, C20 et C11
(différé). Les résultats figurent dans le [bilan de validation](annexes/tests/validation.md).

- `Pump` possède l'attribution des relais et le débit. Il consulte l'index par
  chunk du registre pour les pompes concurrentes ; le transfert garde l'objet
  et son fluide. Les inventaires de découverte restent des caches de session et
  ne peuvent plus invalider un relais sauvegardé avant leur première complétion.
- `Physics` calcule la durée servie d'un pas avec les seules données numériques.
  `Simulation` traduit cette durée en transitions horodatées et orchestre l'usure,
  puis applique et publie seulement l'état final de l'ancre.
- `PowerHistory` est un service serveur sans interface ni émission réseau. Il
  possède la rétention, la reprise des anciennes données et la compaction du
  journal privé persistant ; `Registry` l'initialise et lui signale les commandes
  qui changent une ancre. `FridgeCatchup` consomme ce journal pour les aliments.
  Les contrats complets restent dans les spécifications techniques.
- `Devices` réconcilie l'identité du registre avec la tuile physique avant de lire
  ou de restaurer la marque. Les clients signalent une tuile inconnue ; ils ne
  choisissent ni son rendement d'adoption ni l'état d'un appareil déjà enregistré.
- `Xp` possède le plafond glissant des mesures et sa purge. Le registre ne fait
  que conserver ses données persistantes privées ; l'action appelle ce service.
