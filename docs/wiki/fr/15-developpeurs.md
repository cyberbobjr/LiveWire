> English version: [Developers](../en/15-developers.md)

# Développeurs : l'API de LiveWire

Cette page s'adresse aux auteurs de mods qui veulent faire fonctionner leur mod avec LiveWire : ajouter une batterie ou une source d'énergie, lire l'état d'un réseau, ou écrire une extension comme LiveWire Extended. Les joueurs n'en ont pas besoin.

Tout ce qui suit est l'API publique de LiveWire 2.0.2 (`LiveWire.API` version 1, révision 5). Elle se trouve dans `media/lua/shared/LiveWire/LW_API.lua` de `batman_LiveWire` : le fichier est court et chaque fonction y est commentée (en anglais).

## Le fonctionnement de LiveWire, en bref

- **Le serveur décide.** En multijoueur, le serveur (en solo, le jeu lui-même) tient le *registre* : chaque appareil LiveWire posé dans le monde, son réseau, son état et son usure. Les clients n'affichent que ce que le serveur leur envoie. Lisez le registre côté serveur ; un client reçoit la copie d'un réseau quand il s'abonne à un onduleur.
- **Un onduleur alimente une zone.** Chaque onduleur est une *ancre* : par défaut un disque de `GeneratorTileRange` cases et de `GeneratorVerticalPowerRange` étages autour de lui, comme un générateur vanilla. Les appareils de cette zone sont mesurés régulièrement et facturés à l'onduleur.
- **Un réseau** réunit un onduleur maître, les onduleurs couplés à lui et les appareils raccordés : sources (solaire, éolien, eau), powerbanks et leurs batteries, une pompe, un ordinateur de gestion. La simulation tourne sur le serveur toutes les 10 minutes de jeu.
- **Trois couches.** `shared` contient les définitions, la configuration et l'API ; `server` le registre, la simulation et les contrôles ; `client` les écrans et les menus. Une fonction de l'API qui a besoin du registre répond `nil`, `false`, `0` ou une liste vide là où le registre n'existe pas (sur un client, ou avant le chargement du monde).

## Règles d'utilisation

- **N'utilisez que `LiveWire.API` et les points d'extension documentés.** Les modules comme `LiveWire.Registry`, `LiveWire.Sim` ou `LiveWire.Demand` sont internes et changent d'une version à l'autre.
- **Vous recevez des copies.** Les tables rendues par l'API sont des copies détachées : les modifier ne change rien dans LiveWire. Les objets du jeu (`IsoObject`) sont les seules valeurs vivantes transmises.
- **Vérifiez qu'une fonction existe** avant de l'utiliser (`if LiveWire.API.onRangeView then`) : les fonctions s'ajoutent au fil des révisions (`LiveWire.API.revision`). La `version` ne change que si quelque chose casse.
- **Les enregistrements se ferment au chargement du monde** (`OnInitGlobalModData`). Ensuite, tout appel `register...` répond `false, "registration_closed"`.
- **Les erreurs sont des valeurs, pas des exceptions.** Un appel refusé rend `false` et une raison : `"invalid_definition"`, `"duplicate_type"`, `"duplicate_model"`, `"duplicate_sprite"`, `"already_registered"`, `"invalid_provider"`, `"registration_closed"`.
- **Les messages aux joueurs** passent par des clés de traduction : `LiveWire.notify(player, key, args, bad)` et `LiveWire.notifyNear(x, y, z, radius, key, args, bad)`. Le client traduit, car un serveur dédié ne charge pas les traductions des mods.

## Préparer son mod

Dans votre `mod.info`, exigez LiveWire pour qu'il soit chargé avant :

```
require=\batman_LiveWire
```

Placez votre fichier Lua dans `media/lua/shared/` et chargez l'API en tête :

```lua
require "LiveWire/LW_API"
```

## Référence

### Enregistrer du contenu

| Fonction | Côté | Rôle |
|---|---|---|
| `registerBattery(fullType, kWh, lifeCycles)` | shared | Une nouvelle batterie pour les powerbanks. L'objet doit être `ItemType = base:drainable`, `ConditionMax = 100`, `KeepOnDeplete = true`. |
| `registerSource(model, definition)` | shared | Une nouvelle source solaire, éolienne ou hydraulique (voir l'exemple 2). |
| `registerDebugKitItem(fullType, count)` | shared | Ajoute votre objet au kit de débogage de LiveWire (menu de débogage admin). |
| `addPlacementRule(rule)` | shared | `rule(spriteName, square, character)` rend `nil` (pas ma tuile), `true`, ou `false, cléInfobulle` : contrôlée par le curseur de meuble et par le serveur. |
| `registerSoftwareLines(fn)` | client | `fn(inverterId)` rend des lignes traduites pour l'onglet Maison du logiciel de gestion. Un seul fournisseur (LiveWire Extended l'utilise). |
| `onRangeView(fn)` | client | `fn(inverterId, shown)` est appelée quand la zone alimentée d'un onduleur est affichée ou masquée. |

### Lire

| Fonction | Côté | Résultat |
|---|---|---|
| `battery(fullType)`, `source(model)`, `model(name)` | les deux | La définition (une copie), ou `nil`. |
| `gridAt(x, y, z)` | serveur | L'instantané du réseau qui alimente cette case (onduleur le plus proche), ou `nil`. Champs notamment : `name`, `demand` et `production` (W), `stock` et `capacity` (kWh), `inverter = { id, model, state, cond, maxW, powered }`, `sources`, `batteries`, `appliances`, `links`. |
| `inverter(id)`, `inverterOfObject(obj)` | serveur | `{ id, x, y, z, role, coupled, master }`, ou `nil`. |
| `networkInverters(id)` | les deux | Les onduleurs du réseau, maître en premier : `{ id, x, y, z, master }`. Sur un client, après `subscribeInverter`. |
| `gridName(id)` | les deux | Le nom du réseau (`""` sans nom), ou `nil`. |
| `anchors()` | les deux | Toutes les zones alimentées connues de ce côté : `{ [inverterId] = { x, y, z, on } }`. |
| `mark(obj)`, `markOnSquare(sq, id)` | les deux | La marque LiveWire d'un objet posé (`id`, `model`…), ou l'objet portant cet id sur une case. |
| `watts(obj)`, `applianceKind(obj)`, `applianceCut(obj)` | les deux | Consommation d'un appareil en W, sa famille (`"light"`, `"fridge"`…), et s'il est coupé par un circuit. |
| `inventoryIds()`, `eachBilled(invId, fn)` | serveur | Les onduleurs qui ont mesuré des appareils, et `fn(objet, watts)` pour chaque appareil facturé à l'un d'eux. |
| `writable()`, `deviceKnown(id)` | les deux | Le registre est-il prêt et modifiable ici ? Cet id est-il un appareil LiveWire ? |
| `LiveWire.Config.get(name)` | les deux | Une option sandbox de LiveWire, par exemple `LinkRange` ou `GridCharging`. |

### Agir

| Fonction | Côté | Rôle |
|---|---|---|
| `subscribeInverter(id)` | client | Demande au serveur les instantanés d'un onduleur, comme les écrans de LiveWire. |
| `invalidateDemand(id)` | serveur | Demande une nouvelle mesure des appareils d'un onduleur (`nil` : tous). |
| `applyCircuits(obj)`, `topologyChanged()` | serveur | Réapplique la décision de circuit à un appareil, ou progressivement à tous. |
| `cableCheck(character, a, b, level)` | les deux | Les mêmes contrôles que le câble de LiveWire : étages, portée, niveau d'Électricité, fil. Rend `true, nil, fils` ou `false, clé, ...`. |
| `returnWires(character, n)`, `awardXp(character, key, amount, periodHours)` | serveur | Rend du fil avec le message de LiveWire ; XP d'Électricité au plus une fois par période. |
| `showRange(id, x, y, z, opts)`, `hideRange()` | client | Affiche ou masque un cercle de zone alimentée (`opts = { radius, color, floors }` dessine le vôtre). |

## Points d'extension

Trois points d'extension permettent à une extension de changer le comportement de LiveWire lui-même. Chacun accepte **un seul** fournisseur, enregistré pendant le chargement des fichiers Lua, et refuse le second avec `"already_registered"`.

| Point | Ce que change le fournisseur | Pris par LiveWire Extended ? |
|---|---|---|
| `LiveWire.Coverage.register(p)` | Les cases qu'alimente un onduleur : des cases en plus, ou une zone qui remplace le disque (`replacesDisc = true`). Fonctions `covers`, `bounds`, `positions`, `scan`, `step`, `idsAt`, `describe` facultative. | Oui |
| `LiveWire.CircuitProvider.register(p)` | Coupe plus d'appareils que les circuits de l'onduleur (jamais moins) : `blocked(o, kind, grid)`, `deviceBlocked(dev)` et `extraWatts(inv)` facultatives, la dernière pour les appareils d'autres mods. | Oui |
| `LiveWire.Coupling.register(p)` | Le couplage des onduleurs : `range()`, `inverters(sq)`, `menu(...)`, `slaveKeepsZone`. | Non |

Quand LiveWire Extended est actif, les points de couverture et de circuits sont pris. Un mod qui en a besoin doit se déclarer incompatible avec LiveWire Extended, ou tester le résultat de `register` et prévoir un repli.

## Exemples

Les commentaires du code restent en anglais, comme dans le reste du code de LiveWire.

### 1. Ajouter une batterie

Le script de votre objet (`media/scripts/MyMod_items.txt`) :

```
module MyMod
{
    item LithiumPack
    {
        DisplayCategory = VehicleMaintenance,
        ItemType = base:drainable,
        Weight = 8.0,
        UseDelta = 0.00001,
        ConditionMax = 100,
        KeepOnDeplete = true,
        Icon = CarBattery,
    }
}
```

Votre fichier Lua (`media/lua/shared/MyMod_LiveWire.lua`). L'objet doit exister au moment de l'enregistrement : enregistrez au démarrage du monde, qui précède la fermeture des enregistrements :

```lua
require "LiveWire/LW_API"

local function registerWithLiveWire()
    if not (LiveWire and LiveWire.API) then return end -- LiveWire not enabled
    -- 2.5 kWh, 1200 full cycles before it is worn out
    local ok, why = LiveWire.API.registerBattery("MyMod.LithiumPack", 2.5, 1200)
    if not ok then print("MyMod: LiveWire refused the battery: " .. tostring(why)) end
end

Events.OnInitWorld.Add(registerWithLiveWire)
```

Pour comparer : une batterie de voiture fait 0,4 à 0,9 kWh et 150 cycles ; la batterie à décharge profonde de LiveWire 1,5 kWh et 600 cycles.

### 2. Ajouter une source d'énergie

Une source est un objet posable à **4 orientations**, sur 4 tuiles consécutives de votre propre feuille de tuiles (`tile` à `tile + 3`), avec son objet déplaçable. LiveWire gère ensuite le raccordement, la production, l'usure, les menus et les écrans.

```lua
require "LiveWire/LW_API"

local function registerWithLiveWire()
    if not (LiveWire and LiveWire.API) then return end
    local ok, why = LiveWire.API.registerSource("MyBigPanel", {
        kind = "solar",                  -- "solar", "wind" or "hydro" (hydro needs a river)
        item = "Base.Mov_MyBigPanel",    -- the placeable item
        sheet = "mymod_tiles_01",        -- your tile sheet
        tile = 0,                        -- first of the 4 facings
        facings = 4,
        nominalW = 250,                  -- output in W in perfect conditions
        level = 3,                       -- Electrical level needed to link it
        wearDays = 10,                   -- days of work per condition point lost
        -- optional state lights, indices of sprites in your sheet (not on tiles 0 to 3)
        overlays = { linked = 8 },
    })
    if not ok then print("MyMod: LiveWire refused the source: " .. tostring(why)) end
end

Events.OnInitWorld.Add(registerWithLiveWire)
```

Valeurs des sources d'origine pour comparer : panneau solaire 100 W, niveau 3, 10 jours d'usure ; éolienne 400 W, niveau 2, 4 jours. Les sources se posent dehors.

### 3. Lire l'énergie à un endroit (serveur)

Une commande serveur qui indique à un joueur l'énergie du réseau autour de lui :

```lua
-- media/lua/server/MyMod_PowerInfo.lua
require "LiveWire/LW_API"

local function onClientCommand(module, command, player, args)
    if module ~= "MyMod" or command ~= "powerInfo" then return end
    if not (LiveWire and LiveWire.API) then return end
    local snap = LiveWire.API.gridAt(player:getX(), player:getY(), player:getZ())
    if not snap then
        LiveWire.notify(player, "IGUI_MyMod_NoPower", {}, true)
        return
    end
    -- %1: network name, %2: stored kWh, %3: capacity kWh, %4: demand W
    LiveWire.notify(player, "IGUI_MyMod_PowerInfo", {
        snap.name, string.format("%.1f", snap.stock), string.format("%.1f", snap.capacity), snap.demand })
end

Events.OnClientCommand.Add(onClientCommand)
```

`IGUI_MyMod_PowerInfo` est une clé de votre propre `Translate/FR/IG_UI.json`, par exemple `"Réseau %1 : %2 / %3 kWh, %4 W consommés"`.

### 4. Refuser une pose

Les règles sont contrôlées pour toute pose de meuble, pas seulement celles de LiveWire. Celle-ci interdit vos tuiles au sous-sol, avec un message en rouge sous le curseur :

```lua
require "LiveWire/LW_API"

if LiveWire and LiveWire.API and LiveWire.API.addPlacementRule then
    LiveWire.API.addPlacementRule(function(spriteName, square, character)
        if not spriteName or not string.find(spriteName, "^mymod_tiles_01_") then return nil end
        if square and square:getZ() < 0 then return false, "Tooltip_MyMod_NotUnderground" end
        return true
    end)
end
```

Celle-ci s'exécute au chargement du fichier, pas dans un événement : les règles de pose se ferment avec les autres enregistrements.

### 5. Suivre l'affichage de la zone alimentée (client)

Dessinez votre propre repère pendant qu'un joueur regarde la zone alimentée d'un onduleur :

```lua
-- media/lua/client/MyMod_RangeHint.lua
require "LiveWire/LW_API"

local shownFor = nil

if LiveWire and LiveWire.API and LiveWire.API.onRangeView then
    LiveWire.API.onRangeView(function(inverterId, shown)
        shownFor = shown and inverterId or nil
        -- start or stop your own rendering here
    end)
end
```

### 6. Une extension de couplage

Permettre le couplage des onduleurs de plus loin (70 cases au lieu de la portée du câble) :

```lua
require "LiveWire/LW_Coupling"

local ok, why = LiveWire.Coupling.register({
    range = function() return 70 end,
    slaveKeepsZone = true, -- each coupled inverter keeps its own powered zone
})
if not ok then print("MyMod: coupling refused: " .. tostring(why)) end
```

Avec une portée supérieure à ce que trouve un balayage de cases, fournissez aussi `inverters(sq)`, qui rend les onduleurs atteignables sous la forme `{ obj, dist }`, du plus proche au plus loin.

## Liste de contrôle multijoueur

- Enregistrez dans `shared`, pour que le serveur et chaque client connaissent les mêmes batteries, sources et règles.
- Lisez le registre (`gridAt`, `inverter`, `eachBilled`…) sur le serveur seulement ; envoyez les résultats aux clients par vos propres commandes.
- Ne modifiez jamais la ModData de LiveWire : rangez vos données sous votre propre clé, comme LiveWire Extended (`LiveWireExtended`).
- Testez sur un serveur dédié : certaines fonctions répondent `nil` sur un client, c'est voulu.

## Questions

Posez-les sur le [Discord](https://discord.gg/QEsBya7hUA) ou ouvrez un ticket sur [GitHub](https://github.com/cyberbobjr/LiveWire/issues). S'il vous manque une fonction, demandez-la plutôt que de lire les modules internes de LiveWire : c'est ainsi que les révisions 2 à 5 ont été ajoutées.
