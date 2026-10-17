# Notes moteur — faits établis pour Live Wire

Faits nouveaux et réutilisables sur le moteur, établis pendant la conception de Live Wire, à reporter dans la base maîtresse `knowledge/`.

- **Sources** : dépôt de référence `cyberbobjr/pz-source-42.21`. Les chemins `java/…` et `media/…` sont relatifs à sa racine.
- **Statuts** :
  - « confirmé statiquement » : lecture du code, sans test en jeu ;
  - « hypothèse » : déduction non vérifiée.
- **Rien n'a été testé en jeu.**
- **Méthode** : la plupart des faits ont été relevés par des recherches en lecture seule menées en parallèle. Les points marqués « relu directement » ont été revérifiés ligne à ligne pendant la rédaction.

---

## 1. Le script d'un générateur est retrouvé par son sprite, pas par `generatorFullType`
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (relu directement)
- Preuve :
  - Pour le bruit et l'usure, `IsoGenerator.update` lit le script d'objet donné par `getGeneratorItemType()` (`java/zombie/iso/objects/IsoGenerator.java:167`).
  - Cette méthode cherche le nom du sprite dans une table construite une fois : les objets tagués `ItemTag.GENERATOR` qui ont un `WorldObjectSprite` (`:137-147`). À défaut, elle rend `Base.Generator` (`:149-155`).
  - La clé ModData `generatorFullType`, posée par `setInfoFromItem` (`:129-135`), n'y sert pas. Si deux objets tagués ont le même sprite, le dernier écrase l'autre (`:143`).
- Conséquence : un générateur de mod qui veut ses propres `SoundRadius`, `SoundVolume` et `ConditionLowerChanceOneIn` a besoin d'un sprite qu'aucun autre objet tagué `Generator` n'utilise.

## 2. Bruit d'un générateur : valeurs du script, rayon nul possible, son FMOD impossible à couper depuis Lua
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (relu directement, sauf la ligne de `WorldSoundManager`)
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
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (relu directement)
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
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (relu directement)
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
- Build : 42.21.0 — Date : 2026-10-17 — Statut : confirmé statiquement (relu directement)
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
  - Le menu « Ajouter du carburant » exige un générateur arrêté (`:1493`), mais l'action `ISAddFuel` ne le vérifie pas (`media/lua/shared/TimedActions/ISAddFuel.lua:5-9`). C'est une précision à `knowledge/power-and-lights.md:183`.
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
