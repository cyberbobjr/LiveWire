# Live Wire — notes sur le moteur

Références techniques utilisées par le projet. Les numéros restent stables :
« NM-n » dans les spécifications désigne la note n de ce document.

- **Sources** : Java décompilé et fichiers vanilla de la Build 42.21.0.
  Les chemins `java/…` et `media/…` sont relatifs à la racine de ces sources.
  Les numéros de ligne correspondent à cette version, pas aux versions ultérieures.
- **Lecture statique** : comportement relevé dans les sources, sans preuve en jeu.
- **Confirmation en jeu** : essai identifié dans la note, avec son périmètre.
- **Hypothèse / à vérifier** : comportement déduit ou vérification encore manquante.

Les dates et niveaux de validation sont propres à chaque note. Les résultats
SP/MP récents du mod sont regroupés dans le [bilan de validation](../tests/validation.md) ;
ils ne valident pas automatiquement l'ensemble des mécanismes décrits ici.

## 1. Le script d'un générateur est retrouvé par son sprite, pas par `generatorFullType`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Pour le bruit et l'usure, `IsoGenerator.update` lit le script d'objet donné par `getGeneratorItemType()` (`java/zombie/iso/objects/IsoGenerator.java:167`).
  - Cette méthode cherche le nom du sprite dans une table construite une fois : les objets tagués `ItemTag.GENERATOR` qui ont un `WorldObjectSprite` (`:137-147`). À défaut, elle rend `Base.Generator` (`:149-155`).
  - La clé ModData `generatorFullType`, posée par `setInfoFromItem` (`:129-135`), n'y sert pas. Si deux objets tagués ont le même sprite, le dernier écrase l'autre (`:143`).
- Conséquence : un générateur de mod qui veut ses propres `SoundRadius`, `SoundVolume` et `ConditionLowerChanceOneIn` a besoin d'un sprite qu'aucun autre objet tagué `Generator` n'utilise.

## 2. Bruit d'un générateur : valeurs du script, rayon nul possible, son FMOD impossible à couper depuis Lua
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Rayon et volume valent 20 **seulement** si le script est introuvable ou si le champ vaut 0 ou moins. Dans une pièce, le rayon est divisé par 2 en entier. L'émission passe par `addSoundRepeating` à chaque mise à jour, sur l'autorité (`IsoGenerator.java:168-181`).
  - Un rayon ≤ 0 n'émet rien (`java/zombie/WorldSoundManager.java:110`).
  - Les générateurs vanilla ont `SoundRadius` 20 à 25 et `SoundVolume = 1` (`media/scripts/generated/items/normal.txt:4800-4866`).
  - Le son entendu par les joueurs est joué **côté client** : boucle `<préfixe>Loop` relancée dans `update` (`IsoGenerator.java:160-166`, `:688-697`). Le préfixe vient de la propriété de sprite `GeneratorSound`, sinon c'est `Generator` (`:667-676`).
  - Une valeur de propriété de tuile n'est acceptée que si elle a été préenregistrée par les définitions de tuiles chargées. Une valeur inconnue devient l'indice 0 (`java/zombie/core/TilePropertyAliasMap.java:63-69`).
  - L'émetteur est un champ public (`java/zombie/iso/IsoObject.java:229`), que Kahlua ne lit pas, et aucune méthode publique ne l'arrête.
- Conséquences :
  - Avec `SoundRadius = 1` dans une pièce, aucun bruit n'attire les zombies. Hors pièce, le rayon minimal est 1.
  - Sans tuile de mod qui enregistre sa propre valeur `GeneratorSound` (associée à des sons de mod `<valeur>Loop`, `Starting`, `Stopping`, `Backfire`, `FailedToStart`), un générateur de mod fait entendre aux joueurs le ronflement d'un générateur vanilla (hypothèse sur l'absence de tout autre levier).

## 3. Usure horaire, incendie et explosion ; `setFuel(0)` n'éteint pas tout de suite
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve (`IsoGenerator.java:182-239`) :
  - À chaque passage d'heure, en rattrapant les heures écoulées depuis `lastHour`, l'état perd 1 ou 2 points avec une chance de 1 sur `ConditionLowerChanceOneIn`. Le champ est lu dans le script, et vaut 30 si le script est introuvable.
  - La boucle s'arrête dès que le carburant ou l'état tombe à 0.
  - À 0 de carburant ou d'état : `setActivated(false)`.
  - État ≤ 40, 30 ou 20 : retour de flamme à 1 chance sur 15, 10 ou 5, avec un bruit de rayon 40 et de volume 60.
  - État ≤ 20 : 1 chance sur 10 d'incendie, sinon 1 sur 20 d'explosion, chaque heure.
  - `setFuel` ne fait que borner la valeur entre 0 et 10 et synchroniser (`:448-455`). L'arrêt par manque de carburant n'arrive qu'au passage d'heure suivant.
- Conséquences : un générateur piloté par un mod doit :
  - avoir un `ConditionLowerChanceOneIn` très grand dans son script ;
  - être remis à `setCondition(100)` régulièrement ;
  - être éteint explicitement par `setActivated(false)` quand l'énergie manque.

## 4. Toxicité : seulement si la case est dans une pièce et sans drapeau `exterior`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Chaque heure de marche : `if (!sq.has(exterior) && sq.getBuilding() != null) building.setToxic(activated)` (`IsoGenerator.java:183-185`). Même test à l'allumage et à l'extinction (`:466-468`).
  - `getBuilding()` passe par `getRoom()` (`java/zombie/iso/IsoGridSquare.java:7805-7811`) : une case sans pièce n'a pas de bâtiment.
  - Au chargement des régions, un générateur allumé remet la toxicité (`java/zombie/iso/areas/isoregion/metagrid/WorldRegionToMetaGrid.java:551-553`).
- Conséquence : un générateur posé sur une case sans pièce (`sq:getRoom() == nil`), même collée au mur extérieur d'une maison, ne rend jamais le bâtiment toxique, et sa portée de 20 cases couvre la maison voisine.

## 5. Consommation par appareil, unité et recalcul
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Valeurs par heure : base du générateur 0,02 (`IsoGenerator.java:253`) ; réfrigérateur et congélateur 0,13, l'un des deux seul 0,08, pompe à essence 0,03 (`java/zombie/iso/IsoObject.java:4784-4797`) ; lumière 0,002 (`IsoLightSwitch.java:769-770`) ; télévision 0,03 (`IsoTelevision.java:224-225`) ; radio sur secteur 0,01 (`IsoRadio.java:34-35`) ; cuisinière ou micro-ondes 0,09 (`IsoStove.java:489-490`) ; lave-linge ou sèche-linge 0,09 ; lave-linge et sèche-linge superposés 0,9 par partie active ; chargeur de batterie 0,05 (`IsoCarBatteryCharger.java:337`).
  - `getTotalPowerUsing()` = somme × option `GeneratorFuelConsumption` (`IsoGenerator.java:655-657`). Cette option va de 0 à 100 et vaut 0,1 par défaut (`java/zombie/SandboxOptions.java:146`). Unité : litres par heure.
  - Le balayage (`setSurroundingElectricity`, `IsoGenerator.java:251-290`) exclut les objets déjà alimentés par le réseau public, **pas** ceux qu'alimente un autre générateur. Deux générateurs qui se recouvrent paient donc chacun l'appareil commun (déduit).
  - Recalcul : à l'allumage, au chargement, au chargement d'un chunk voisin, et à chaque `updateGenerator(sq)` appelé par les appareils qui changent d'état ou par la pose et le retrait d'un objet. Il n'est pas périodique.
- Conséquence : la consommation réelle mesurée par le moteur se lit sur l'autorité par `gen:getTotalPowerUsing() / GeneratorFuelConsumption`, mais cette lecture est impossible si l'option vaut 0. Repli : sommer soi-même `obj:getGeneratorPowerConsumption()` (méthode publique) sur les cases dans la portée.

## 6. Poser au sol un objet tagué `Generator` crée un `IsoGenerator`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve : `IsoGridSquare.AddWorldInventoryItem` transforme en `new IsoGenerator(item, …)` tout objet dont le type contient `.Generator`, ou qui est tagué `GENERATOR` et a un `WorldObjectSprite` (`java/zombie/iso/IsoGridSquare.java:5210-5214`). C'est le chemin de tout dépôt au sol vanilla.
- Autres usages du tag :
  - option d'inventaire « prendre à deux mains » (`media/lua/client/ISUI/ISInventoryPaneContextMenu.lua:274`, `:406-408`) ;
  - type de butin `Generator` (`java/zombie/inventory/ItemPickerJava.java:1394`).
- Conséquence : l'objet-générateur d'un mod ne doit **jamais** se trouver dans un inventaire de joueur. Le joueur manipule un « kit » sans ce tag, et l'autorité crée l'objet tagué par `instanceItem` au seul moment de la pose.

## 7. Positions d'alimentation recalculées par chaque client ; chunk du générateur déchargé
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (sauf mention)
- Preuve :
  - À la réception d'un changement d'état allumé, le client appelle lui-même `setSurroundingElectricity` sur ses chunks (`IsoGenerator.java:550-568`). Au chargement, `updateSurroundingNow` est appelé depuis `LightingJNI.java:223-224`.
  - Quand le chunk du générateur est déchargé, plus rien n'est consommé. Les positions déjà posées sur les chunks voisins y restent tant que la case du générateur est `null` (`java/zombie/iso/IsoChunk.java:4791-4792`) : ces voisins restent alimentés.
  - Au rechargement, le rattrapage horaire se fait avec le `totalPowerDraw` sauvegardé, avant tout recalcul (`IsoGenerator.java:182`, `:242`, `:381-390`).
  - Chaque `setFuel`, `setCondition`, `setActivated` ou `setConnected` envoie un `SyncIsoObject` à toutes les connexions (`IsoGenerator.java:527-539`, `IsoObject.java:1002-1008`). Le coût réseau d'un appel par minute est une hypothèse.
- Conséquence : un mod qui pilote le carburant doit :
  - simuler lui-même la consommation pendant que le chunk est déchargé ;
  - accepter l'extinction possible par le rattrapage au rechargement, puis rallumer ;
  - régler l'objet au plus une fois par tranche de 10 minutes.

## 8. Menu contextuel du générateur : construit en Java, masquable avant sa construction
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `ISWorldObjectContextMenu.createMenu` remplit `fetchVars`, déclenche `OnPreFillWorldObjectContextMenu`, puis délègue à `ISWorldObjectContextMenuLogic.createMenuEntries` (`media/lua/client/ISUI/ISWorldObjectContextMenu.lua:183-209`).
  - `doGeneratorMenu` ne lit que `fetch.generator` (`java/zombie/iso/ISWorldObjectContextMenuLogic.java:1444-1445`).
  - Les rappels Lua (`onTakeGenerator`, `onPlugGenerator`, `onActivateGenerator`, `onFixGenerator`, `onAddFuelGenerator`, `onInfoGenerator`) sont retrouvés par leur nom à chaque construction du menu (par exemple `:1465`, `:1514`).
  - Le menu « Ajouter du carburant » exige un générateur arrêté (`:1493`), mais l'action `ISAddFuel` ne le vérifie pas (`media/lua/shared/TimedActions/ISAddFuel.lua:5-9`).
- Conséquences :
  - Mettre `ISWorldObjectContextMenu.fetchVars.generator = nil` dans `OnPreFillWorldObjectContextMenu` supprime tout le sous-menu pour ce générateur.
  - Côté serveur, il faut en plus envelopper le `complete()` de `ISTakeGenerator`, `ISAddFuel`, `ISPlugGenerator`, `ISActivateGenerator`, `ISFixGenerator`, `ISMoveablesAction` et `ISDestroyStuffAction`.
  - Il faut aussi les filtres `ISMoveableSpriteProps:canPickUpMoveable`, `ISMoveableSpriteProps:canScrapObject` et `ISDestroyCursor:canDestroy`.

## 9. Enveloppe d'une action chronométrée : garder les noms de paramètres de `new`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Le client sérialise l'action en lisant **les noms des paramètres** de la fonction `new` (`prototype.locvars`), puis il prend sur l'action les champs de même nom (`java/zombie/core/NetTimedAction.java:42-58`).
  - Le serveur rappelle `new` avec ces valeurs. Si `new` échoue ou rend `nil`, l'action est rejetée (`:145-172`, `java/zombie/network/packets/NetTimedActionPacket.java:63-83`).
- Conséquence : une enveloppe `function(self, ...)` transmet zéro argument en MP. Une enveloppe de `new` doit garder la signature exacte de l'original. Envelopper plutôt `complete` pour rejeter une action.

## 10. ModData d'un objet posé au sol : seule celle de l'objet d'inventaire compte
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoWorldInventoryObject.save` écrit l'objet d'inventaire (avec sa ModData), mais n'appelle pas `super.save` (`java/zombie/iso/objects/IsoWorldInventoryObject.java:478-498`). La ModData propre de l'`IsoObject` au sol n'est donc jamais sauvegardée. `IsoThumpable` et `IsoGenerator`, eux, appellent `super.save`.
  - Sur le serveur, `item:syncItemFields()` d'un objet au sol envoie un paquet `ItemStats` **sans ModData** (`InventoryItem.java:4166-4169`, `network/packets/ItemStatsPacket.java:226-300`).
  - `sendItemStats(item)` (objet rangé dans un meuble) transporte les utilisations et l'état, mais pas la ModData.
- Conséquence : pour un objet stocké hors inventaire de joueur, garder l'état utile aux clients dans les champs moteur (`setCurrentUsesFloat`, `setCondition`), synchronisés par `sendItemStats`. La ModData ne sert qu'à l'autorité.

## 11. `transmitModData` d'un objet du monde : le serveur applique ce que le client envoie
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve : `ObjectModDataPacket` charge la ModData reçue d'un client dans l'objet du serveur, puis la relaie, sans aucun contrôle (`java/zombie/network/packets/ObjectModDataPacket.java:50-72`, `:99-101`).
- Conséquence : la ModData d'un objet posé n'est qu'un reflet d'affichage. L'état qui fait foi vit dans un registre serveur, en ModData globale (un `transmit` venu d'un client n'écrase rien côté serveur).

## 12. Météo sur un serveur dédié : simulée sur l'autorité, globale, sans position du soleil
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - La simulation du climat avance une fois par minute de jeu, hors client MP (`java/zombie/iso/weather/ClimateManager.java:793-803`, `:832-836`). Elle est envoyée aux clients toutes les 10 minutes de jeu (`:868-871`).
  - `getWindspeedKph()` = `windPower × 120` (`:514-516`) ; hors période météo, l'intensité de base plafonne à 0,65 (`java/zombie/iso/weather/ClimateValues.java:265-270`).
  - `getCloudIntensity()` va de 0 à 1. `getDayLightStrength()` baisse avec le vent et l'avancée de l'année (`ClimateValues.java:283-289`) : il ne convient pas comme ensoleillement.
  - Aucun angle ni aucune élévation du soleil n'est calculé.
  - `getSeason()` (`ErosionSeason`) donne `getDawn()`, `getDusk()`, `getDaylight()` et `getDayHighNoon()` en heures décimales, pour une latitude fixe de 38° (`java/zombie/erosion/ErosionConfig.java:425`, `java/zombie/erosion/season/ErosionSeason.java:79-80`, `:165-195`).
  - Les valeurs de climat sont globales (singleton), sauf `getAirTemperatureForSquare`.
- Conséquence : les productions solaire et éolienne se calculent sur le serveur, sans case chargée, à partir de l'heure, de l'aube et du crépuscule de la saison, des nuages, de la neige et du vent.

## 13. Rivière ou lac : le courant (`getFlow`) ne permet pas de les distinguer
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoWaterGeometry.getFlow()` rend un angle et `getSpeed()` une vitesse (`java/zombie/iso/IsoWaterGeometry.java:149-152`).
  - `IsoWaterFlow.getFlow` interpole les trois points de courant les plus proches, sans distance maximale (`java/zombie/iso/IsoWaterFlow.java:72-105`) : un lac hérite du courant de la rivière la plus proche.
  - Le vanilla distingue la rivière par six rectangles codés en dur, `Fishing.isRiver(x, y)` (`media/lua/shared/Fishing/FishingZones.lua:3-11`, `:40-47`), dans un fichier `shared`.
  - Aucun gel des étendues d'eau n'existe.
  - L'eau n'existe qu'au niveau 0.
- Conséquence : pour reconnaître une rive de rivière, chercher une case de terre voisine d'une case `water` dont `Fishing.isRiver` est vrai, au moment de la pose. Le gel d'hiver ne peut être qu'une règle de mod.

## 14. Chargeur de batterie vanilla : accepte tout objet drainable
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoCarBatteryCharger.setBattery` accepte n'importe quel `DrainableComboItem` (`java/zombie/iso/objects/IsoCarBatteryCharger.java:345-356`). Seul le menu Lua filtre les batteries de voiture (`media/lua/client/ISUI/ISWorldObjectContextMenu.lua:61-63`, `:471-475`).
  - Il charge à 1/6 par heure (`:45`, `:125-158`), à condition que la case ait du courant.
- Conséquence : un chargeur de piles peut reposer sur cette classe vanilla (idée n° 2), alimentée par l'onduleur, qui compte 0,05 dans la consommation.

## 15. Alarme de maison : désarmable sur le serveur, liée au réseau public
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `BuildingDef:isAlarmed()` et `setAlarmed(b)` (`java/zombie/iso/BuildingDef.java:447-453`). Le déclenchement est testé hors client MP (`IsoGameCharacter.java:8214-8221`).
  - L'état est sauvegardé dans `map_meta` (`IsoMetaGrid.java:922-927`).
  - La sirène exige `hasGridPower(alarmDecay)` (`java/zombie/AmbientSoundManager.java:184-197`).
- Conséquence : l'idée n° 3 est faisable sur l'autorité ; elle n'a d'intérêt que tant que l'alarme peut encore sonner.

## 16. Cuisinière : vrai état « cassé » ; réfrigérateur : aucun levier Lua
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (sauf mention)
- Preuve :
  - `IsoStove` a `isBroken` et `setBroken`. Une cuisinière cassée refuse `setActivated` (`java/zombie/iso/objects/IsoStove.java:320-323`, `:414-420`). L'état ne semble pas transmis par `SyncIsoObject` (hypothèse, `:274`).
  - Le froid d'un réfrigérateur est entièrement en Java (`ItemContainer.java:2218-2262`, `Food.java:688-698`, `:1990-2006`).
- Conséquence : la réparation d'appareils (idée n° 5) est faisable proprement pour les cuisinières et micro-ondes. Pour le froid, le seul levier est de ne pas alimenter.

## 17. Un `IsoGenerator` ne crée pas les conteneurs de son sprite
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; comportement MP du conteneur ajouté par script : hypothèse
- Preuve :
  - `IsoGenerator.addToWorld` ne fait qu'ajouter l'objet aux listes de mise à jour, sans appeler `super.addToWorld` (`java/zombie/iso/objects/IsoGenerator.java:399-405`). C'est pourtant `IsoObject.addToWorld` qui appelle `createContainersFromSpriteProperties()` (`java/zombie/iso/IsoObject.java:4177-4182`).
  - Cette méthode est publique (`IsoObject.java:4900`) ; elle ne fait rien si un conteneur existe déjà.
  - `IsoGenerator.save` et `load` passent par `IsoObject.save` et `load` (`IsoGenerator.java:369`, `:384`), qui écrivent les conteneurs (`IsoObject.java:1502-1510`).
- Conséquence : pour donner un compartiment à un générateur de mod, il faut appeler `createContainersFromSpriteProperties()` sur l'autorité et sur chaque client qui reçoit l'objet. Une fois créé, le conteneur serait sauvegardé avec l'objet. À vérifier en jeu : transmission initiale et transferts MP.

## 18. Positions de générateur : envoyées aux clients avec le chunk, purgées aussi chez eux, et `LoadChunk` des deux côtés
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; effet visible chez un client : hypothèse
- Preuve :
  - Le client télécharge chaque chunk et le relit par `LoadFromBuffer` (`java/zombie/iso/WorldStreamer.java:661`). Cette lecture lit aussi la liste `generatorsTouchingThisChunk` (`java/zombie/iso/IsoChunk.java:3318-3331`).
  - La purge `IsoGenerator.chunkLoaded` (`IsoChunk.java:3526`) est suivie de l'événement `LoadChunk`, déclenché sans condition de côté (`IsoChunk.java:3612`).
  - `addGeneratorPos` et `removeGeneratorPos` ne transmettent rien. Seul un vrai générateur fait recalculer ses positions au client, par `syncIsoObjectReceive` (`java/zombie/iso/objects/IsoGenerator.java:550-568`).
  - Pour trouver un chunk, `IsoCell.getChunkForGridSquare` passe par `ServerMap` sur un serveur, alors que `IsoCell.getChunk(wx, wy)` ne lit que les cartes des joueurs locaux (`java/zombie/iso/IsoCell.java:361-388`).
- Conséquences : un mod qui pose des positions par script doit :
  - les reposer dans `LoadChunk` sur l'autorité **et** sur chaque client ;
  - envoyer aux clients ses changements d'état ;
  - utiliser `getChunkForGridSquare` sur le serveur.

  Une position posée sur une case qui existe (par exemple celle d'un objet de mod) est purgée au chargement suivant si le mod a disparu : il n'y a pas de fuite de courant à la désinstallation.

## 19. `checkHaveElectricity` : effets côté client d'un changement d'alimentation
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoObject.checkHaveElectricity()` ne fait rien sur un serveur. Sur un client, elle :
    - met un réfrigérateur alimenté dans la liste des objets mis à jour ;
    - démarre son bourdonnement (`FridgeHumLogic`) ;
    - rafraîchit le son d'ambiance et la source de lumière (`java/zombie/iso/IsoObject.java:4800-4812`).
  - Le moteur l'appelle sur chaque appareil du disque quand un générateur change d'état (`IsoGenerator.java:279`).
- Conséquence : après avoir posé ou retiré des positions par script, appeler `obj:checkHaveElectricity()` côté client sur les appareils du disque.

## 20. Toxicité : dégâts à chaque mise à jour, état transmis par paquet
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Dans un bâtiment toxique, un personnage non protégé gagne 1e-4 de fatigue et perd 0,1 point de santé au torse (et à la tête si la fatigue dépasse 0,8), **à chaque mise à jour**, multipliés par `getThirtyFPSMultiplier()` (`java/zombie/characters/IsoGameCharacter.java:8192-8202`).
  - L'état du bâtiment est envoyé aux clients par le paquet `ToxicBuilding` (`java/zombie/iso/areas/IsoBuilding.java:509-513`, `java/zombie/network/GameServer.java:3571-3582`, `java/zombie/network/GameClient.java:795-805`).
- Conséquence : on ne peut pas « effacer » après coup la toxicité d'un générateur posé en intérieur sans dégâts répétés. Un générateur de mod qui doit pouvoir se poser à l'intérieur ne peut pas être un vrai `IsoGenerator`.

## 21. Modèles 3D d'un mod : `.fbx`, `.glb` ou `.x`, pas `.obj`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; échelle et orientation d'un `.glb` d'objet : hypothèse
- Preuve :
  - Le chargeur de maillage cherche, dans l'ordre, `media/models_x/<nom>.fbx`, `.glb`, `.x`, puis `media/models/<nom>.txt`. Le nom est mis en minuscules ; la recherche dans les fichiers des mods ne tient pas compte de la casse (`java/zombie/core/skinnedmodel/model/FileTask_AbstractLoadModel.java:63-122`, `java/zombie/ZomboidFileSystem.java:321-339`).
  - Les trois formats passent par Assimp. Il n'existe aucun chemin pour `.obj` ni `.gltf`.
  - Texture d'un modèle : `media/textures/<texture>.png`.
  - Sans champ `texture`, c'est le nom du maillage qui sert (`java/zombie/scripting/objects/ModelScript.java:186-187`).
- Conséquence : des formes simples générées en glTF binaire (`.glb`) suffisent comme modèles provisoires. Live Wire les produit avec `tools/make_placeholder_models.py`. Leur échelle en jeu reste à vérifier.

## 22. Noms d'objets, recettes et `OnCreate` en 42.21
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - **Nom affiché d'un objet** : clé `Module.Type` dans `ItemName.json`, sans préfixe `ItemName_` (`java/zombie/core/Translator.java:476-490`, `media/lua/shared/Translate/EN/ItemName.json:899`).
  - **Nom d'une recette** : clé = nom de la recette dans `Recipes.json` (`Translator.java:561-569`).
  - **Champ `OnCreate`** : chemin global pointé (`CraftRecipe.java:425-426`), appelé avec `(craftRecipeData, character)` (`CraftRecipeData.java:424-434`), après l'ajout des sorties.
  - **Où `OnCreate` s'exécute** : seulement en solo ou sur le serveur (`media/lua/shared/Entity/TimedActions/ISHandcraftAction.lua:191-234`).
  - **`Icon = X`** cherche la texture `Item_X`. Une icône vanilla peut servir à un objet de mod (`java/zombie/scripting/objects/Item.java:2031-2038`).
  - **Résolution des noms** : un nom sans module se résout dans `Base` (`ScriptBucketCollection.java:82`). Il faut qualifier `WorldStaticModel = LiveWire.X`.
- Conséquence : les fichiers de traduction et les scripts de Live Wire suivent ces formats. Les effets d'un `OnCreate` doivent être synchronisés vers le client du joueur (`syncItemFields`).

## 23. `setCondition` d'un objet joue un son
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `InventoryItem.setCondition` joue le son de casse ou de dégât.
  - `setConditionNoSound` règle la même valeur sans son (`java/zombie/inventory/InventoryItem.java:2549-2553`).
  - La valeur est bornée à `ConditionMax`, puis `setBroken(c <= 0)` est appelé (`:2504-2518`).
- Conséquence : un script qui fait vieillir un objet régulièrement (usure d'une batterie) utilise `setConditionNoSound`.

## 24. Son local sur un émetteur libre : `playSoundImpl`, pas `playSound`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; boucle de `FridgeHumA` : hypothèse
- Preuve :
  - Sur un client MP, `playSound` et `playSoundLooped` lancés sur un émetteur sans parent sont relayés aux autres joueurs par `PlayWorldSound`. Leur arrêt, lui, n'est pas relayé (`java/fmod/fmod/FMODSoundEmitter.java:380-461`, `:955-961`).
  - `playSoundImpl(nom, false, nil)` reste local. La forme `playSoundImpl(nom, nil)` prend la surcharge `IsoGridSquare` et lève une NPE (`java/fmod/fmod/FMODSoundEmitter.java`, surcharges de `playSoundImpl`).
  - Les émetteurs de `getWorld():getFreeEmitter` sont avancés par le moteur, puis rendus à la réserve quand ils sont vides (`java/zombie/iso/IsoWorld.java:500-504`, `:2785-2802`).
  - `FridgeHumA` est l'événement FMOD `Object/Fridge/FridgeA/Running`. Le moteur le joue en lui donnant le paramètre `Generator` (`java/zombie/audio/ObjectAmbientEmitters.java:675-705`).
- Conséquence : le ronronnement de l'onduleur Live Wire est joué par chaque client pour lui seul, avec `playSoundImpl`. Il reste à vérifier en jeu que le son boucle sans ce paramètre.

## 25. Texte de halo envoyé par le serveur : chaîne finale, donc sans traduction de mod
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Sur un serveur, `HaloTextHelper.addText` envoie le paquet `HaloText` avec le texte déjà composé (`java/zombie/characters/HaloTextHelper.java:109-131`, `HaloTextPacket.java:57`).
  - Au démarrage, le serveur dédié charge les traductions avant les mods ; sans rechargement explicite des tables, les clés des mods restent absentes (`java/zombie/network/GameServer.java:637-639, 1354-1355`, `java/zombie/core/Translator.java:145-149, 267-279`).
- Conséquence : le serveur envoie une clé et ses paramètres par `sendServerCommand`, et le client appelle `getText` puis `HaloTextHelper` (`LW_Notify.lua`, `LW_ClientState.lua`).

## 26. Murs d'une case et objets muraux
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; noms des variantes `walls_decoration_01_104` à `_107` : hypothèse
- Preuve :
  - `IsoGridSquare.getWall(true)` rend le mur nord de la case, et `getWall(false)` le mur ouest (`java/zombie/iso/IsoGridSquare.java:3962`). Un mur est ou sud appartient à la case voisine.
  - Les drapeaux de sprite `attachedN` et `attachedW` existent (`java/zombie/iso/SpriteDetails/IsoFlagType.java:79-82`). On les lit par `getSprite(nom):getProperties():has(IsoFlagType.attachedN)` (`java/zombie/core/properties/PropertyContainer.java:84`).
- Conséquence : un objet mural se pose sur la case qui porte le mur, avec la variante de sprite dont le drapeau correspond au mur. Pour un clic devant un mur est ou sud, on prend la case voisine.

## 27. La portée réelle d'un générateur est une valeur statique
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoGenerator.isPoweringSquare`, appelé par `haveElectricity`, lit les champs **statiques** `generatorRadius` (20), la portée verticale (3) et la portée en chunks (`java/zombie/iso/objects/IsoGenerator.java:65, 67, 89, 637-644`).
  - Ces champs ne sont relus dans les options sandbox qu'à la construction d'un `IsoGenerator` (`:97-119`).
- Conséquence :
  - Tant qu'aucun générateur n'a été construit depuis le lancement, un `GeneratorTileRange` différent de 20 n'est pas appliqué par le moteur.
  - Une ancre posée par un mod alimente donc le disque du moteur, pas forcément celui de l'option.
  - Live Wire ne compte, ancre allumée, que les appareils dont la case est réellement alimentée (`sq:haveElectricity()`).

## 28. `OnObjectAdded` ne part que chez les clients MP
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Le seul déclenchement de `OnObjectAdded` est dans `AddItemToMapPacket.processClient` (`java/zombie/network/packets/AddItemToMapPacket.java:59, 90`).
  - `OnObjectAboutToBeRemoved` part des deux côtés (`java/zombie/iso/IsoGridSquare.java:4905`).
- Conséquence : en solo et sur un serveur, un objet posé n'est pas signalé. Il faut le détecter par un balayage périodique ; Live Wire refait l'inventaire de la demande toutes les 30 minutes de jeu.

## 29. Sprites de pendule : aiguilles animées sur tout objet
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - `IsoObject` dessine des aiguilles pour tout sprite qui a un script d'horloge (`java/zombie/iso/IsoObject.java:5683-5701`).
  - `walls_decoration_01_104` et `_105` ont un tel script (`media/scripts/generated/clocks.txt:45, 66`).
  - `getSprite` sur un nom inconnu crée et garde en mémoire un sprite vide (`java/zombie/iso/sprite/IsoSpriteManager.java:53-58`).
- Conséquence : ne pas prendre une pendule comme sprite de substitution. Une applique murale utilisable comme substitut est `lighting_indoor_02_44` à `_47`, dont les orientations sont connues (`newtiledefinitions.tiles.txt:103406-103502`). Posée comme simple `IsoObject`, elle n'éclaire pas.

## 30. Objets muraux vanilla : posés sur la case cliquée, détruits avec leur mur
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve :
  - Un objet tourné vers l'ouest exige un mur sur la case **est** voisine, et un objet tourné vers le nord un mur sur la case **sud**, tandis que l'objet reste sur la case cliquée (`media/lua/shared/Moveables/ISMoveableSpriteProps.lua:2651-2661`).
  - Détruire un mur retire aussi les objets accrochés : `attachedN` / `attachedW` sur sa case, `attachedS` / `attachedE` sur la case voisine (`media/lua/shared/TimedActions/ISDestroyStuffAction.lua:163-200`).
- Conséquence : le disjoncteur Live Wire reste sur la case cliquée, et son orientation (N, W, S ou E) est notée dans sa marque. La destruction vanilla d'un mur qui le porte est refusée.

## 31. Conteneur créé par un mod sur un objet posé : le marquer « fouillé »
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; synchronisation MP du conteneur ajouté : hypothèse
- Preuve :
  - `ItemContainer.new(type, case, objet)` existe (`java/zombie/inventory/ItemContainer.java:143`).
  - `IsoObject.setContainer(c)` rattache le conteneur à l'objet (`java/zombie/iso/IsoObject.java:1883-1886`).
  - `createContainersFromSpriteProperties` ne fait rien si l'objet a déjà un conteneur (`IsoObject.java:4900-4907`), et `addToWorld` l'appelle (`:4176-4182`).
  - Un conteneur dont `isExplored()` est faux est rempli de butin :
    - quand un client le demande (`java/zombie/network/packets/RequestItemsForContainerPacket.java:44`) ;
    - par `ItemPickerJava` (`java/zombie/inventory/ItemPickerJava.java:1474`) ;
    - au chargement de la case (`java/zombie/LoadGridsquarePerformanceWorkaround.java:68`).
  - Le titre affiché dans la fenêtre de butin est `IGUI_ContainerTitle_<type>` (`media/lua/client/ISUI/ISInventoryPage.lua:1714-1719`). L'icône vient de `ContainerButtonIcons[type]` (`:1498-1499`).
- Conséquence : la powerbank de Live Wire crée son conteneur (type `livewirepowerbank`) **avant** `transmitAddObjectToSquare`, avec `setExplored(true)` et `setHasBeenLooted(true)`. Elle ajoute la clé de titre et reprend l'icône de la caisse militaire. À vérifier en jeu : un 2e client voit le conteneur et ses transferts.

## 32. Générateur vanilla piloté par un mod : `setActivated`, `setFuel`, consommation horaire
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement, y compris le double décompte au rechargement
- Preuve :
  - `setActivated(b)` ne fait rien si l'état ne change pas ; sinon il rend le bâtiment toxique (case intérieure), remet `lastHour` à l'heure courante au démarrage, joue `Starting` / `Stopping`, recalcule la zone alimentée et se synchronise sur serveur et client (`java/zombie/iso/objects/IsoGenerator.java:462-490`).
  - `setFuel` borne à [0, 10] et se synchronise (`:448-456`) ; `getMaxFuel()` rend 10 (`:444-446`).
  - Le carburant ne baisse que dans `update`, donc seulement quand la case est chargée, une fois par heure de jeu entière écoulée depuis `lastHour`, de `totalPowerUsing × GeneratorFuelConsumption` (`:182-206`). Vide ou état à 0 : il s'arrête de lui-même (`:200-208`).
- Conséquence : un mod peut démarrer et arrêter un générateur vanilla depuis le serveur, et y ajouter sa propre consommation par `setFuel`. Hors chargement, il doit tenir le compte lui-même et l'appliquer au chargement. `lastHour` est sauvegardé et relu (`IsoGenerator.java:377, 389`) : un générateur sauvegardé en marche brûle, à sa première mise à jour, toutes les heures de l'absence (boucle `:190-197`, arrêt à carburant ou état nul), en plus du décompte du mod. `getTotalPowerUsing()` rend ce débit horaire (`:655-657`). `setActivated(true)` remet `lastHour` à l'heure courante (`:470`) : l'arrêter puis le relancer au chargement annule ce rattrapage (avec les sons Stopping/Starting et le rafraîchissement des frigos de `setActivated`). Live Wire le fait dans `Backup.restore` et ne retire en marche que la part de carburant que le vanilla ne brûle pas déjà.

## 33. Sons de bip vanilla : aucun n'est déclaré en boucle dans les scripts
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; comportement de l'événement FMOD : hypothèse
- Preuve : `TelevisionTestBeep` (événement `Object/Television/TestTone`, `media/scripts/generated/sounds/objects/sounds_object_television.txt:3-10`) et `TrapTimerLoop` (`Weapon/Throwable/Timer/Beep`, `sounds/weapons/sounds_throwable.txt:253-260`) n'ont pas `loop = true`, au contraire de `VehicleBackUpBeeper` (`sounds/vehicles/sounds_vehicle_foley.txt:3-12`). La boucle peut toutefois être définie dans l'événement FMOD lui-même, invisible ici.
- Conséquence : jouer un tel son localement (`playSoundImpl(nom, false, nil)`) et l'arrêter soi-même après une durée fixe, qu'il boucle ou non.

## 34. Outils de debug d'un mod : solo `-debug` et admin MP
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (`java/zombie/Lua/LuaManager.java:2913-2919` ; contrôle de rôle décrit ci-dessous)
- Preuve : `isDebugEnabled()` rend `Core.debug` ; `checkPermissions` rend vrai hors serveur MP et quand la connexion est introuvable ; `ChangeAndReloadServerOptions` n'appartient qu'au rôle `admin` intégré.
- Conséquence : côté client, `getRole():hasCapability(cap)` pour l'affichage ; côté serveur, `checkPermissions(p, cap)` **et** `p:getRole():hasCapability(cap)` ; en solo, `isDebugEnabled()`. Sur un serveur dédié, `isDebugEnabled()` est faux sauf `-Ddebug` : ne pas l'utiliser pour les admins.

## 35. Scripts `.txt` : un `/*` à l'intérieur d'un commentaire `/* … */` le laisse ouvert
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (algorithme rejoué hors jeu) ; plantage observé dans `console.txt`
- Preuve : `ScriptParser.stripComments` (`java/zombie/scripting/ScriptParser.java:51-71`) part du dernier `*/` et remonte au `/*` **le plus proche** ; il gère les commentaires imbriqués mais pas un `/*` isolé dans un commentaire (par exemple un chemin `dossier/*.glb`). Seule la partie `/*.glb … */` est retirée ; le début du commentaire reste dans le texte, sans erreur de chargement, et colle à l'en-tête du bloc suivant, qui est perdu. Une recette qui produit cet objet fait ensuite échouer le monde au chargement : `ScriptManager.PostWorldDictionaryInit> … <recette> item not found: <Module>.<Objet>` (`OutputMapper.java:98`), puis `WorldDictionaryException: World loading could not proceed`.
- Conséquence : ne jamais écrire `/*` (ni `*/`) dans le texte d'un commentaire de script. Un « item not found » sur un objet pourtant défini : chercher d'abord un commentaire de ce genre juste au-dessus de sa définition.

## 36. Meuble de mod à conteneur : le conteneur vient de la tuile, sans butin
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé en jeu (test en jeu automatique en solo, 2026-10-17) ; classe `IsoThumpable` : confirmé statiquement
- Preuve : `ISMoveableSpriteProps:placeMoveableInternal` appelle `createContainersFromSpriteProperties()` puis `setExplored(true)` sur chaque conteneur (`media/lua/shared/Moveables/ISMoveableSpriteProps.lua:2486-2489`). En jeu, une tuile de mod `container = <type>`, `ContainerCapacity = 50`, posée par `placeMoveable`, a un conteneur de ce type, vide, de capacité 50, qui accepte une batterie de voiture. Une tuile `solidtrans` (ou `solid`) devient une `IsoThumpable` à la pose (`:2350-2390`), donc frappable par les zombies.
- Conséquence : pour un meuble de mod à conteneur, déclarer le conteneur dans la tuile plutôt que d'en créer un par script. Ne jamais emprunter un sprite vanilla qui porte `container` pour un objet qui ne doit pas en avoir : le jeu le remplit de butin quand il n'est pas marqué exploré.

## 37. Pose et ramassage d'un meuble : niveau, outil et fonctions à envelopper
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; règle ajoutée confirmée en jeu
- Preuve :
  - `PickUpLevel` sert aussi à la pose : `hasRequiredSkill` lit `self.pickUpLevel` pour les deux modes (`ISMoveableSpriteProps.lua:485-494`). L'outil `Electrician` = tournevis et compétence Électricité (`ISMoveableDefinitions.lua:313`).
  - Sur l'autorité, la pose passe par `placeMoveable` → `canPlaceMoveableInternal` (`:2049`), pas par `canPlaceMoveable` (curseur). Une règle de pose propre au mod s'écrit donc dans une enveloppe de `canPlaceMoveableInternal`, et sa raison dans `getInfoPanelDescription` (`:577`, panneau du curseur).
  - La rotation est un ramassage puis une pose sur la même case (`rotateMoveable`, `:2881-2902`). `pickUpMoveableInternal` recopie `movableData` dans l'objet d'inventaire **avant** de retirer l'objet (`:1400-1404`, puis `OnObjectAboutToBeRemoved` `:1491-1494`) : un état à garder doit être écrit dans la marque avant l'appel d'origine.
  - `OnObjectAdded` est déclenché **après** `transmitCompleteItemToClients` (`:2537-2541`) : une ModData posée ensuite n'atteint les clients que par `transmitModData()`.
- Conséquence : envelopper `placeMoveableInternal`, `pickUpMoveableInternal` et `rotateMoveable` en gardant tous leurs arguments ; garder un identifiant de mod dans `movableData` pendant une rotation (vérifié en jeu : même identifiant, liens conservés).

## 38. Ligne « overrides media/tilegeometry.txt » d'un mod à tuiles : sans effet sur le vanilla
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement
- Preuve : le journal écrit `mod "<id>" overrides media/tilegeometry.txt` pour le `common/media/tileGeometry.txt` minimal d'un mod. Mais `TileGeometryManager.initGameData` et `TileDepthTextureManager.initGameData` lisent la géométrie vanilla dans `ZomboidFileSystem.getMediaRootPath()`, puis celle de chaque mod dans son propre dossier `common` (`java/zombie/tileDepth/TileGeometryManager.java:34-50`, `TileDepthTextureManager.java:51-70`).
- Conséquence : ce fichier, nécessaire pour charger la profondeur du mod, ne masque pas la géométrie vanilla.

## 39. Lire un menu clic droit dans un test automatique
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé en jeu (test en jeu automatique en solo, 2026-10-17)
- Preuve : `ISWorldObjectContextMenu.createMenu(0, { objet }, x, y)` rend le menu ; `menu:getOptionFromName(texte)` trouve une option, `option.subOption` et `menu:getSubMenu(option.subOption)` donnent le sous-menu, `option.notAvailable` dit si elle est grisée (`media/lua/client/ISUI/ISContextMenu.lua:889-895, 1075-1077, 1226-1232`).
- Conséquence : un test en jeu peut vérifier le texte réel d'un menu de mod, et laisser le menu ouvert pour la capture.

## 40. Nourriture d'un frigo : vieillissement rattrapé d'un coup, avec l'électricité du moment
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement ; cas « joueur absent » confirmé en jeu (test en jeu automatique en solo, 2026-10-17)
- Preuve : `Food.updateAge` applique tout le temps écoulé depuis `lastAged`, multiplié par `FridgeFactor` (0,2 par défaut) si `getSourceGrid():haveElectricity()` **au moment de l'appel** (`java/zombie/inventory/types/Food.java:668-702`). Les aliments d'un meuble ne sont pas mis à jour en continu : à l'ouverture, au passage d'un objet, et par le générateur vanilla **juste avant** chaque bascule (`IsoGenerator.updateFridgeFreezerItems`, `IsoGenerator.java:325-334`). En jeu : steak frais dans un frigo alimenté par un point d'alimentation de mod, joueur à 300 cases (zone déchargée), 10 heures de jeu, retour : +0,083 jour (froid), contre 0,417 sans courant.
- Conséquence : un mod qui alimente des cases doit rattraper l'âge des aliments des frigos chargés avant de changer l'alimentation, et rétablir l'alimentation au chargement de la zone avant toute consultation. Sans mod, une absence est comptée entière avec l'état trouvé au retour ; Live Wire rejoue les changements d'état de ses ancres (note 45).

## 41. `canPlaceMoveable` d'un objet mural rend l'objet mur, pas `true`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé en jeu
- Preuve : `canPlace = self.facing and self:getWallForFacing(_square, self.facing)` (`ISMoveableSpriteProps.lua`, branche `WallObject` de `canPlaceMoveableInternal`).
- Conséquence : tester la valeur comme un booléen Lua (vrai si non `nil`), jamais `== true`.

## 42. Calques posés par le client, contour d'une zone, zoom
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé en jeu (captures)
- `obj:addAttachedAnimSpriteByName(nom)` et `obj:RemoveAttachedAnim(i)` posés localement sur un client affichent un calque de tuile (voyant, pièce animée) sans paquet réseau ; en solo, ils sont sauvegardés avec l'objet : recalculer la liste à chaque mise à jour.
- La surbrillance des sols (`setHighlightColor` + `setHighlighted(true, false)` sur `square:getFloor()`) n'a rien montré en jeu en plein jour. Un cercle dessiné à l'écran depuis le `render` d'un `ISUIElement` de 1 × 1 (`drawLine` entre points projetés par `isoToScreenX/Y(joueur, x, y, z)`) est net et suit la caméra.
- `getCore():doZoomScroll(joueur, n)` change le zoom d'un cran par appel (positif : dézoom), utile avant une capture.
- Un meuble posable dont la tuile porte `CustomItem` garde l'icône de son script (`Moveable.java:128-141`, `getCustomIcon`) : utile quand la tuile seule n'est pas représentative (pales en calque).

## 43. Calque changé souvent : marquer l'objet « en animation » (rendu FBO)
- Build : 42.21.0 — Date : 2026-10-17 — Statut : cause confirmée statiquement ; disparition observée en jeu ; correction à vérifier en jeu
- Preuve : avec le rendu par chunks, un objet est dessiné dans la texture du chunk et redessiné seulement quand le chunk est invalidé. `FBORenderCell.isObjectRenderLayer_MinusFloor` sort de ce chemin les objets `isAnimating()` (`java/zombie/iso/fboRenderChunk/FBORenderCell.java:1627`), dessinés à chaque image. Les seuls calques « animés » reconnus sont les aiguilles d'horloge et les calques `_on_` (`IsoObject.hasAnimatedAttachments`, `IsoObject.java:5640-5650`). Le drapeau n'est remis à faux qu'à la fin d'une animation 3D d'objet (`IsoObjectAnimations.java:81`).
- Conséquence : un calque changé plusieurs fois par seconde (pales d'éolienne) disparaissait dès qu'il tournait. Appeler `obj:setAnimating(true)` sur l'objet, côté client.

## 44. Script de son : `distanceMin` et `distanceMax` sont des entiers ; en debug, une erreur de script bloque la partie
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé en jeu (crash au chargement) et statiquement
- Preuve : `GameSoundScript.LoadClip` lit `distanceMax` et `distanceMin` par `Integer.parseInt` (`java/zombie/scripting/objects/GameSoundScript.java:65-73`) ; `distanceMin = 0.5` lève `NumberFormatException`, le son est retiré (« removing script due to load error »). En mode debug, `ScriptManager.Load` lève alors `IOException: Script load errors` (`ScriptManager.java:1547`) et la partie ne se charge plus.
- Conséquence : valeurs entières seulement ; `tools/check_mod.py` le contrôle désormais.

## 45. Rejouer le vieillissement d'un aliment : accesseurs exposés, `lastFrozenUpdate` sans accesseur
- Build : 42.21.0 — Date : 2026-10-17 — Statut : accesseurs confirmés statiquement ; rattrapage alimentaire vérifié en SP/MP le 2026-10-24 (voir le bilan), sans validation exhaustive du gel/dégel
- Preuve :
  - `getAge/setAge/getLastAged/setLastAged` publics sur `InventoryItem` (`java/zombie/inventory/InventoryItem.java:2355-2368`), classes `Food` et `InventoryItem` exposées (`index-lua-exposed-classes.txt:298, 342`) ; `lastAged = -1` : jamais vieilli (`:155`).
  - `Food.setFreezingTime` borne à [0, 100] et ne change `frozen` qu'aux bornes ; `setFrozen`, `canBeFrozen`, `getFreezingTime` publics (`java/zombie/inventory/types/Food.java:1955-1988`).
  - `lastFrozenUpdate` n'a pas d'accesseur (`:117`) ; `updateAge` lance d'abord `updateFreezing` sur tout l'intervalle (`:671`, `:752-774`) puis ne vieillit pas si `lastAged` vaut l'heure courante (`:672-673`).
  - Facteurs : `FridgeFactor` 1..6 = 0,4/0,3/0,2/0,1/0,03/0, `FoodRotSpeed` 1..5 = 1,7/1,4/1,0/0,7/0,4 (`:642-661`) ; gel 4 h au congélateur alimenté, dégel 1,5 h (3 h au réfrigérateur alimenté) (`:757-768`) ; réseau public jusqu'à `ElecShutModifier × 24` h (`:691-697`).
- Conséquence : pour rejouer une absence par morceaux (courant puis coupure), calculer âge, temps de gel et drapeau, puis `setLastAged(maintenant)`, `updateAge()` (consomme l'intervalle de gel sans vieillir), `setFreezingTime`, `setFrozen`, `setAge`. Live Wire le fait au `LoadChunk` serveur d'après le journal d'état des ancres (`LW_FridgeCatchup.lua`).


## 46. Plomberie : la source d'un point d'eau raccordé est un `IsoThumpable` à fluide, à l'étage juste au-dessus
- Build : 42.21.0 — Date : 2026-10-18 — Statut : confirmé statiquement
- Preuve :
  - `ISPlumbItem:complete` pose `canBeWaterPiped = false`, `setUsesExternalWaterSource(true)` et envoie `IsoObjectChange.USES_EXTERNAL_WATER_SOURCE` (`media/lua/shared/TimedActions/ISPlumbItem.lua`).
  - Un objet raccordé renvoie toutes ses lectures et prises d'eau (`getFluidAmount`, `getFluidCapacity`, `useFluid`, `emptyFluid`…) vers sa source, recherchée de nouveau quand l'ancienne n'existe plus ou est vide (`checkExternalFluidSource`, `java/zombie/iso/IsoObject.java:2570-2578`, `:2580-2700`).
  - `FindExternalWaterSource(x, y, z)` ne regarde que `z + 1`, d'abord la case au-dessus puis les 8 voisines, et préfère un objet qui contient du fluide à un objet vide (`:2408-2429`). Un objet à grille de sprites cherche au-dessus de chacune de ses cases (`:2379-2399`).
  - `FindWaterSourceOnSquare` ne retient qu'un `IsoThumpable` sans sprite `solidfloor`, non raccordé lui-même (pas de chaîne de sources), de capacité de fluide > 0 (`:2431-2441`).
  - Le menu « Raccorder » exige un point d'eau dans une pièce avec une source trouvée au-dessus, ou le réseau d'eau encore en service (`java/zombie/iso/ISWorldObjectContextMenuLogic.java:456-459`).
- Conséquence : un objet du monde qui n'est pas un `IsoThumpable` (par exemple un objet posé auquel un mod ajoute un composant `FluidContainer`) n'alimente jamais la plomberie vanilla. Pour desservir un point d'eau depuis une réserve placée ailleurs, il faut un `IsoThumpable` à fluide à `z + 1` dans le carré 3 × 3 au-dessus, rempli par script.

## 47. Récupérateurs d'eau en 42.21 : pluie par le système Java des entités, y compris hors zone chargée (`MetaEntity`)
- Build : 42.21.0 — Date : 2026-10-18 — Statut : confirmé statiquement ; remplissage hors zone chargée à vérifier en jeu
- Preuve :
  - `SRainBarrelSystem:isValidIsoObject` rend toujours `false` (`media/lua/server/RainBarrel/SRainBarrelSystem.lua:28-31`) : le système global Lua ne suit plus aucun récupérateur.
  - La pluie est ajoutée par `FluidContainerUpdateSystem.updateEntity`, sur l'autorité seulement (`GameClient.client` exclu), à tout `FluidContainer` d'une entité dehors avec `rainCatcher > 0` : `0.005 × intensité × (0,5 si neige) × rainCatcher × 2,4 s` par mise à jour, `Water` si le contenu est de l'eau propre, sinon `TaintedWater`, sans événement `OnWaterAmountChange` (`java/zombie/entity/components/fluids/FluidContainerUpdateSystem.java:41-85` ; `EntitySimulation.getGameSecondsPerTick` = 2,4, `java/zombie/entity/EntitySimulation.java:31-33`).
  - Un `FluidContainer` avec `rainCatcher > 0` « mérite le stockage méta » (`FluidContainer.java:1227-1229`). Au déchargement, ses composants passent dans une `MetaEntity` qui garde `isOutside` de la case (`MetaEntity.java:42`, `:132-134`), reste mise à jour (`FluidContainerUpdateSystem.java:54`) et est sauvegardée (`:65-84`) ; une `MetaTag` sur l'objet les lui rend au rechargement (`java/zombie/entity/GameEntityManager.java:190-200`, `:270-295`).
  - `RainFactor = 0.4` pour l'entité vanilla `RainCollector` (`media/scripts/generated/entities/outdoors/entity_raincollector.txt`).
- Conséquence : un récupérateur, ou tout objet auquel un mod ajoute un `FluidContainer` avec `setRainCatcher(> 0)`, se remplit de pluie même zone déchargée, sans code de mod. Ne pas remplacer ni vider le composant d'un tel objet pour le « simuler ». Un ajout de pluie ne se détecte que par sondage du contenu.

## 48. Plomberie : un point d'eau raccordé rend propre l'eau croupie de sa source
- Build : 42.21.0 — Date : 2026-10-18 — Statut : confirmé statiquement ; à vérifier en jeu
- Preuve :
  - `createSampleAndPurifyWater` copie le contenu de la source en changeant chaque `TaintedWater` en `Water` (`java/zombie/iso/IsoObject.java:2760-2772`).
  - Un point d'eau raccordé (`usesExternalWaterSource`) l'utilise pour remplir un récipient : l'eau purifiée va dans la cible, la quantité prise est retirée de la source, puis `OnWaterAmountChange` est déclenché **sur le point d'eau**, pas sur la source (`transferFluidTo`, `:2782-2800`).
  - Le nom affiché et le fluide principal viennent aussi d'un échantillon purifié (`getFluidUiName` `:2911-2921`, `getPrimaryFluid` `:2884-2893`), et `isTaintedWater` rend `false` dès que la source contient du fluide (`:2987-2997`).
  - Une prise directe (`useFluid`, `:2666-2700`) est renvoyée à la source, qui déclenche `OnWaterAmountChange` sur elle-même (`:2690-2697`).
- Conséquence : un baril d'eau de pluie (croupie) raccordé à la plomberie donne de l'eau potable par l'évier, la douche ou les toilettes. Pour suivre les prises d'eau d'une source, écouter `OnWaterAmountChange` à la fois sur la source et sur les points d'eau qui la tirent.

## 49. Les drainables quantifient leur fraction en usages entiers

- Build : 42.21.0 — Date : 2026-10-24 — Statut : confirmé statiquement et en jeu.
- Preuve : `DrainableComboItem.java:91–100`, `setCurrentUsesFloat` applique
  `Math.round(fraction / useDelta)` ; la lecture multiplie les usages par
  `useDelta`. Une extension de test à `UseDelta=0.01` reproduit l'arrondi.
- Conséquence : conserver une quantité continue par un simple setter de fraction
  peut créer ou perdre une graduation. Pour un modèle précis, arrondir la portion
  native vers le bas et conserver un reliquat positif borné à une graduation,
  associé à la dernière fraction et capacité écrites. Une modification native
  externe invalide le reliquat. Tester aussi mille petits pas successifs.

## 50. L'alimentation des conteneurs passifs n'a pas de setter Lua par objet

- Build : 42.21.0 — Date : 2026-10-24 — Statut : confirmé statiquement.
- Preuve : `ItemContainer.java:2218–2266`, `IsoObject.java:6271–6280`,
  `IsoGridSquare.java:8223` ; la lecture dépend de l'électricité publique et des
  positions de générateur du chunk. Le setter obsolète d'électricité d'une case
  actualise les lumières sans remplacer cette décision.
- Conséquence : retirer les watts d'un frigo d'un bilan ne coupe pas son service.
  Une température personnalisée ne change pas les chemins de conservation et de
  gel qui interrogent `isPowered()` (`Food.java:764,1995–2006`). Une vraie séparation
  de circuits exige un mécanisme moteur démontré.

## 51. Arrêter un service frigorifique sans couper le courant de sa case

- Build : 42.21.0 — Date : 2026-10-24 — Statut : confirmé statiquement et en jeu.
- Preuve : `ItemContainer.java:2557,3560–3578`, `Food.java:688,2500–2505`,
  `IsoObject.java:4784`. Le type natif `none` fait retourner faux à
  `isFridge/isFreezer` avant le repli vers la propriété `IsFridge` du sprite.
  `setType` ne remplace ni le conteneur ni ses objets ; le type est sauvegardé.
- Conséquence : mémoriser les types exacts par index, mettre les aliments à jour
  avant la transition, puis restaurer ces mêmes types permet d'interrompre froid,
  gel et consommation frigorifique native tout en gardant l'éclairage sous tension.
  Vérifier aussi le dégel et le vieillissement réel ; `isPowered()` peut rester
  vrai car il décrit le courant disponible à la prise.
- Maintenir le cache de consommateurs du chunk lors du rétablissement. Éviter
  `IsoObjectChange.CONTAINERS` pour une simple bascule : `IsoObject.java:4391`
  supprime les contenus clients avant de recharger les conteneurs. Préférer un
  miroir ciblé des types, sans toucher aux inventaires. Les types inertes exigent
  une restauration avant de retirer le code qui en connaît les types d'origine.

## 52. La mesure mémoire Kahlua porte sur le tas JVM complet

- Build : 42.21.0 — Date : 2026-10-24 — Statut : confirmé statiquement.
- Preuve : `se/krka/kahlua/stdlib/BaseLib.java:371–391`. `collectgarbage("count")`
  lit `Runtime.totalMemory/freeMemory`, en Kio ; `collect` appelle `System.gc()`.
- Conséquence : la valeur inclut les autres objets Java du jeu. Une hausse de RAM
  du processus ne prouve pas une fuite Lua ; un relevé post-GC court ne prouve pas
  son absence. Réserver les GC forcés au banc et séparer tas JVM, allocations
  natives et ressources GPU. Vérifier aussi les chemins de rétention des caches
  et les objets UI effectivement retirés du gestionnaire natif.

## 53. L'itérateur des tables J2SE copie leurs clés

- Build : 42.21.0 — Date : 2026-10-24 — Statut : confirmé statiquement.
- Preuve : `se/krka/kahlua/j2se/KahluaTableImpl.java:164–197` : l'itérateur
  capture `delegate.keySet().toArray()` puis lit les valeurs depuis la table.
- Conséquence : une purge peut retirer l'entrée courante sans invalider un
  itérateur Java de la carte. Le parcours alloue néanmoins un tableau de clés ;
  éviter de parcourir de gros caches à chaque image. Ce constat concerne cette
  implémentation de table, pas toutes les collections Java exposées à Lua.

## 54. Lire une couleur Java par ses accesseurs Lua

- Build : 42.21.0 — Date : 2026-10-24 — Statut : accesseurs confirmés dans les
  sources ; échec de la lecture comme champs observé dans le journal en jeu.
- Preuve : `IsoObject.java:4709–4710,4733–4738` renvoie un `ColorInfo` depuis
  `getHighlightColor` ; `ColorInfo.java:88–108` définit `getR/getG/getB/getA`.
  La classe est exposée dans `LuaManager.java:1815`.
- Conséquence : utiliser `color:getR()`, `getG()`, `getB()` et `getA()` pour
  comparer ou sauvegarder les composantes. Les champs Java publics ne garantissent
  pas des valeurs numériques accessibles comme une table Lua `{r,g,b,a}` ; une
  soustraction peut échouer avec `__sub not defined for operands`.
- Un double de test qui fournit seulement une table RGBA masque cette différence
  d'API. Faire refuser l'accès aux champs dans le double et vérifier aussi un
  second rafraîchissement, puis le retrait et la restauration de la teinte.

## 55. Catalogue des ingrédients construit après les données globales

- Build : 42.21.0 — Date : 2026-10-25 — Statut : confirmé statiquement.
- Preuve : `IsoWorld.java:1908` initialise les données globales et déclenche
  `OnInitGlobalModData`. `WorldDictionary.init` puis
  `ScriptManager.PostWorldDictionaryInit` arrivent ensuite (`:1923–1924`).
- `InputScript.java:110–111` expose le cache `getPossibleInputItems`, encore
  initialement vide. `OnPostWorldDictionaryInit` remplit ce cache à partir des
  noms de `getItems`/`loadedItems` (`:877–899`). Les contrôles `containsItem`
  (`:510–511`) et `canUseItem` (`:949–962`) lisent ce catalogue.
- Conséquence : une adaptation d'ingrédients à `OnInitGlobalModData` doit porter
  sur la déclaration chargée ; modifier seulement le cache encore vide sera
  écrasé par sa construction ultérieure. Pour supporter un catalogue déjà
  construit, traiter aussi le cache. Retirer une référence Java par objet ou
  une chaîne par valeur ; éviter la surcharge ambiguë `remove(int)` en Lua.
- Les doubles de test doivent couvrir les deux états : cache vide puis
  construction depuis les noms chargés, et cache déjà initialisé. Cela ne vaut
  pas validation en jeu de l'interface, de la consommation ou du réseau.

## 56. Aperçu d'artisanat et icône calculée d'un meuble

- Build : 42.21.0 — Date : 2026-10-25 — Statut : confirmé statiquement.
- Preuve : `scripting/entity/components/crafting/CraftRecipe.java:802–820`
  utilise `Item.getNormalTexture` sur la sortie pour l'icône de recette, sauf
  déclaration explicite `Icon`. `scripting/objects/Item.java:2031–2036`
  résout `Item_<Icon>` et prend `media/inventory/Question_On.png` si absent.
- `inventory/types/Moveable.java:118–218` calcule séparément l'icône d'une
  instance depuis le sprite du monde. Cela ne remplace pas la texture de la
  déclaration d'objet consultée par la recette : un meuble peut avoir une
  icône correcte dans l'inventaire et un « ? » dans son aperçu d'artisanat.
- Correction déclarative : fournir une vraie icône `Icon=<Nom>` dans l'objet
  et `media/textures/Item_<Nom>.png`. `core/textures/Texture.java:416–447`
  confirme ce repli vers le fichier du mod, avec casse exacte. Une recette
  à plusieurs sorties peut fixer son icône principale via son propre `Icon`.
  Aucun wrapper de rendu ou calcul par image n'est nécessaire.

## 57. La purge des positions de générateur précède `LoadChunk` et déborde sur les chunks voisins
- Build : 42.21.0 — Date : 2026-10-28 — Statut : confirmé statiquement
- Preuve :
  - `IsoChunk.doLoadGridsquare` appelle `IsoGenerator.chunkLoaded(this)` (`java/zombie/iso/IsoChunk.java:3526`) puis déclenche `LoadChunk` à la toute fin de la même méthode (`:3612`).
  - `IsoGenerator.chunkLoaded` appelle `checkForMissingGenerators()` sur le chunk qui arrive **et sur tous ceux à ±`generatorChunkRange`** (`java/zombie/iso/objects/IsoGenerator.java:593-603`), soit ±3 chunks pour le rayon vanilla (`generatorChunkRange = generatorRadius / 8 + 1`, `:118`).
  - `checkForMissingGenerators` retire toute position dont la case ne porte pas un `IsoGenerator` activé (`IsoChunk.java:4785-4797`). Une position virtuelle posée par `addGeneratorPos` est donc toujours retirée.
  - `IsoGridSquare.haveElectricity()` ne lit que cette liste (`java/zombie/iso/IsoGridSquare.java:8223-8227`, via `IsoChunk.isGeneratorPoweringSquare`, `:4773-4783`).
- Conséquence : un seul chunk qui arrive retire la couverture d'une ancre sur un carré de 7 × 7 chunks (56 × 56 cases) déjà chargés, jusqu'à l'exécution de l'abonné `LoadChunk`. Cet abonné doit donc s'exécuter **dans l'appel du moteur** : un mod qui remplace la table `Events.LoadChunk` pour étaler les abonnés sur plusieurs images laisse la zone sans courant entre-temps (voir note 59).

## 58. Qui vieillit un aliment, et quand : une seule passe suffit à tout perdre
- Build : 42.21.0 — Date : 2026-10-28 — Statut : confirmé statiquement
- Preuve :
  - `Food.updateAge` applique **toute** la durée écoulée depuis `lastAged` avec l'état électrique de l'instant, puis écrit `lastAged = maintenant` (`java/zombie/inventory/types/Food.java:668-712`).
  - Les aliments d'un meuble entrent dans la liste de suivi dès les `addToWorld` du chargement du chunk (`IsoObject.addToWorld` → `ItemContainer.addItemsToProcessItems`, `java/zombie/iso/IsoObject.java:4177-4182`), donc avant `LoadChunk`.
  - `IsoCell.ProcessItems` tourne à chaque image en solo, **une fois toutes les 5 s sur un serveur dédié**, et jamais sur un client MP (`java/zombie/iso/IsoCell.java:3499-3503`).
  - Dans `Food.update`, `updateAge(false)` n'est appelé que sur un serveur dédié (`Food.java:351-353`) ; en solo, seul `updateRotting` peut le faire, pour les objets à `ReplaceOnRotten` ou si `DaysForRottenFoodRemoval >= 0` (défaut −1, `java/zombie/SandboxOptions.java:161`).
  - En solo, le vieillissement vient surtout de l'interface : `ISInventoryPane` appelle `updateAge()` sur chaque objet affiché, à chaque image (`media/lua/client/ISUI/ISInventoryPane.lua:2266`, `:2573`).
  - `Food.finishupdate` retire la plupart des aliments de la liste après une seule passe (`Food.java:1162-1180`).
- Conséquence : un rattrapage qui compare `getLastAged()` à l'heure courante n'a plus rien à corriger dès que le moteur est passé une fois. La fenêtre est d'une image en solo dès que le joueur regarde le contenu du meuble, et de 0 à 5 s sur un serveur dédié sans aucun geste du joueur. Tout mécanisme qui corrige l'âge au chargement d'un chunk doit s'exécuter dans l'appel du moteur, pas une image plus tard.

## 59. La table `Events.X` est remplaçable : l'ordre de chargement décide de l'immunité
- Build : 42.21.0 — Date : 2026-10-28 — Statut : confirmé statiquement
- Preuve :
  - `Events.X` est une table Kahlua ordinaire qui porte deux fonctions Java. Un mod peut la remplacer par une table à lui : tout `Events.X.Add` ultérieur arrive chez lui, tandis que le déclencheur Java continue d'appeler sa propre liste, où le mod a inscrit un seul répartiteur.
  - Les abonnés inscrits **avant** ce remplacement sont déjà dans la liste Java et restent exécutés dans l'appel du moteur, dans leur ordre d'origine.
  - Observé sur un mod de lissage de performances qui capture ainsi `LoadGridsquare` et `LoadChunk` et rejoue les abonnés sous un budget de quelques millisecondes par tick, en jetant ceux dont le chunk s'est déchargé. Il expose `<Mod>.Gate.addRaw(événement, fonction)`, qui inscrit par l'`Add` d'origine.
- Conséquence : un abonné dont l'instant d'exécution fait partie du contrat ne peut pas supposer qu'il tourne dans l'appel du moteur. Deux parades : s'inscrire avant le mod captureur (ordre de chargement), ou passer par la porte qu'il expose, en testant sa présence (`type(T.Gate.addRaw) == "function"`) plutôt que la liste des mods, avec repli sur `Events.X.Add`. Les deux ordres de chargement donnent alors le bon résultat.
