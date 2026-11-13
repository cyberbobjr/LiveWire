> Version française : [Développeurs](../fr/15-developpeurs.md)

# For developers: the LiveWire API

This page is for mod authors who want their mod to work with LiveWire: add a battery or a power source, make an appliance draw power, read the state of a network, or build an add-on like LiveWire Extended. Players do not need it.

Everything below is the public API of LiveWire 2.0.3 (`LiveWire.API` version 1, revision 6; revision 6 adds the consumers of other mods). It lives in `media/lua/shared/LiveWire/LW_API.lua` of `batman_LiveWire`: the file is short and every function has a comment.

## How LiveWire works, in short

- **The server decides.** In multiplayer, the server (in solo, the game itself) owns the *registry*: every LiveWire device placed in the world, its network, its state and its condition. Clients only show what the server sends them. Read the registry on the server side; a client gets a copy of one network when it subscribes to an inverter.
- **An inverter powers a zone.** Each inverter is an *anchor*: by default a disc of `GeneratorTileRange` squares and `GeneratorVerticalPowerRange` floors around it, like a vanilla generator. The appliances in that zone are measured regularly and billed to the inverter.
- **A network** is one master inverter, the inverters coupled to it, and the devices linked to them: sources (solar, wind, water), power banks with their batteries, a pump, a management computer. The simulation runs on the server every 10 in-game minutes.
- **Three layers.** `shared` holds definitions, configuration and the API; `server` holds the registry, the simulation and the checks; `client` holds the screens and menus. A function of the API that needs the registry answers `nil`, `false`, `0` or an empty list where the registry does not exist (on a client, or before the world is loaded).

## Rules for using the API

- **Only use `LiveWire.API` and the documented extension points.** Modules such as `LiveWire.Registry`, `LiveWire.Sim` or `LiveWire.Demand` are internal and change between versions.
- **You get copies.** Tables returned by the API are detached copies: changing them changes nothing in LiveWire. Game objects (`IsoObject`) are the only live values handed out.
- **Check that a function exists** before using it (`if LiveWire.API.onRangeView then`): functions are added over revisions (`LiveWire.API.revision`). The `version` changes only if something breaks.
- **Registration closes when the world loads** (`OnInitGlobalModData`). After that, every `register...` call returns `false, "registration_closed"`.
- **Errors are values, not exceptions.** A refused call returns `false` and a reason: `"invalid_definition"`, `"duplicate_type"`, `"duplicate_model"`, `"duplicate_sprite"`, `"already_registered"`, `"invalid_provider"`, `"registration_closed"`.
- **Messages to players** go through translation keys: `LiveWire.notify(player, key, args, bad)` and `LiveWire.notifyNear(x, y, z, radius, key, args, bad)`. The client translates, because a dedicated server does not load mod translations.

## Set up your mod

In your `mod.info`, require LiveWire so it loads first:

```
require=\batman_LiveWire
```

Put your Lua file in `media/lua/shared/` and load the API at its top:

```lua
require "LiveWire/LW_API"
```

## Reference

### Register new content

| Function | Where | What it does |
|---|---|---|
| `registerBattery(fullType, kWh, lifeCycles)` | shared | A new battery for power banks. The item must be `ItemType = base:drainable`, `ConditionMax = 100`, `KeepOnDeplete = true`. |
| `registerSource(model, definition)` | shared | A new solar, wind or water source (see example 2). |
| `registerConsumer(id, definition)` | shared | An appliance of your mod that the game does not count draws power from LiveWire (revision 6, see example 7). |
| `registerDebugKitItem(fullType, count)` | shared | Adds your item to LiveWire's debug kit (admin debug menu). |
| `addPlacementRule(rule)` | shared | `rule(spriteName, square, character)` returns `nil` (not my tile), `true`, or `false, tooltipKey`: checked by the furniture cursor and by the server. |
| `registerSoftwareLines(fn)` | client | `fn(inverterId)` returns translated lines for the House tab of the management software. One provider only (LiveWire Extended uses it). |
| `onRangeView(fn)` | client | `fn(inverterId, shown)` is called when the powered area of an inverter is shown or hidden. |

### Read

| Function | Where | Returns |
|---|---|---|
| `battery(fullType)`, `source(model)`, `model(name)` | both | The definition (a copy), or `nil`. |
| `gridAt(x, y, z)` | server | The snapshot of the network that powers this square (nearest inverter), or `nil`. Fields include `name`, `demand` and `production` (W), `stock` and `capacity` (kWh), `inverter = { id, model, state, cond, maxW, powered }`, `sources`, `batteries`, `appliances`, `links`. |
| `inverter(id)`, `inverterOfObject(obj)` | server | `{ id, x, y, z, role, coupled, master }`, or `nil`. |
| `networkInverters(id)` | both | Inverters of the network, master first: `{ id, x, y, z, master }`. On a client, after `subscribeInverter`. |
| `gridName(id)` | both | The network name (`""` when unnamed), or `nil`. |
| `anchors()` | both | Every powered zone known on this side: `{ [inverterId] = { x, y, z, on } }`. |
| `mark(obj)`, `markOnSquare(sq, id)` | both | The LiveWire mark of a placed object (`id`, `model`...), or the object with that id on a square. |
| `watts(obj)`, `applianceKind(obj)`, `applianceCut(obj)` | both | Draw of an appliance in W, its family (`"light"`, `"fridge"`... `"consumer"` for a registered one), and whether a circuit cuts it. |
| `consumer(obj)` | both | Id of the registered consumer this placed object is, or `nil` (revision 6). |
| `consumerPowered(obj)` | both | `true` when a registered consumer has current (LiveWire, generator or public grid) and no circuit or breaker cuts it (revision 6). |
| `estimateWatts(w)` | both | `w` W with `PowerScale` and the consumption profile applied. |
| `inventoryIds()`, `eachBilled(invId, fn)` | server | Inverters that measured appliances, and `fn(object, watts)` for each appliance billed to one. |
| `writable()`, `deviceKnown(id)` | both | Is the registry ready and writable here? Is this id a LiveWire device? |
| `LiveWire.Config.get(name)` | both | A LiveWire sandbox option, for example `LinkRange` or `GridCharging`. |

### Act

| Function | Where | What it does |
|---|---|---|
| `subscribeInverter(id)` | client | Asks the server for the snapshots of an inverter, as LiveWire's screens do. |
| `invalidateDemand(id)` | server | Asks for a new measurement of an inverter's appliances (`nil`: all). |
| `applyCircuits(obj)`, `topologyChanged()` | server | Re-applies the circuit decision to one appliance, or to all of them progressively. |
| `cableCheck(character, a, b, level)` | both | Same checks as LiveWire's own cable: floors, reach, Electrical level, wire. Returns `true, nil, wires` or `false, key, ...`. |
| `returnWires(character, n)`, `awardXp(character, key, amount, periodHours)` | server | Gives wire back with LiveWire's message; Electrical XP at most once per period. |
| `showRange(id, x, y, z, opts)`, `hideRange()` | client | Shows or hides a powered-area circle (`opts = { radius, color, floors }` draws your own). |

## Extension points

Three extension points let an add-on change how LiveWire itself behaves. Each accepts **one** provider, registered while Lua files load, and refuses a second one with `"already_registered"`.

| Point | What the provider changes | Taken by LiveWire Extended? |
|---|---|---|
| `LiveWire.Coverage.register(p)` | Which squares an inverter powers: extra squares, or a zone that replaces the disc (`replacesDisc = true`). Functions `covers`, `bounds`, `positions`, `scan`, `step`, `idsAt`, optional `describe`. | Yes |
| `LiveWire.CircuitProvider.register(p)` | Cuts more appliances than the inverter's own circuits (never fewer): `blocked(o, kind, grid)`, optional `deviceBlocked(dev)` and `extraWatts(inv)` for appliances of other mods. | Yes |
| `LiveWire.Coupling.register(p)` | How inverters couple: `range()`, `inverters(sq)`, `menu(...)`, `slaveKeepsZone`. | No |

When LiveWire Extended is enabled, the coverage and circuit points are taken. A mod that needs them should say it is not compatible with LiveWire Extended, or test the result of `register` and fall back.

## Examples

### 1. Add a battery

Your item script (`media/scripts/MyMod_items.txt`):

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

Your Lua file (`media/lua/shared/MyMod_LiveWire.lua`). The item must exist when you register, so register when the world starts, which is before registration closes:

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

For comparison, a car battery is 0.4 to 0.9 kWh and 150 cycles; LiveWire's deep-cycle battery is 1.5 kWh and 600 cycles.

### 2. Add a power source

A source is a placeable object with **4 facings** on 4 consecutive tiles of your own tile sheet (`tile` to `tile + 3`), and a moveable item for it. LiveWire then handles linking, production, wear, the menus and the screens.

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

Built-in values for comparison: solar panel 100 W, level 3, 10 wear days; wind turbine 400 W, level 2, 4 wear days. Sources are placed outdoors.

### 3. Read the power at a spot (server)

A server command that tells a player how much energy the network around them holds:

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

`IGUI_MyMod_PowerInfo` is a key of your own `Translate/EN/IG_UI.json`, for example `"Network %1: %2 / %3 kWh, %4 W used"`.

### 4. Refuse a placement

Rules are checked for every furniture placement, not only LiveWire's. This one keeps your own tiles out of basements, with a message shown in red by the cursor:

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

This one runs when the file loads, not in an event: placement rules close with the other registrations.

### 5. Follow the powered-area view (client)

Draw your own marker while a player looks at an inverter's powered area:

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

### 6. A coupling add-on

Let inverters couple from further away (70 squares instead of the cable range):

```lua
require "LiveWire/LW_Coupling"

local ok, why = LiveWire.Coupling.register({
    range = function() return 70 end,
    slaveKeepsZone = true, -- each coupled inverter keeps its own powered zone
})
if not ok then print("MyMod: coupling refused: " .. tostring(why)) end
```

With a range beyond what a square scan finds, also give `inverters(sq)`, which returns the reachable inverters as `{ obj, dist }`, nearest first.

### 7. Make your appliance draw power (revision 6)

The game only knows that an object uses electricity when its Java class says so (lights, fridges, stoves...). An appliance whose power is handled by your own Lua code is invisible to a vanilla generator and to LiveWire. Declare it, and LiveWire bills it like a vanilla appliance: inverter screens, "Show consumers", panel circuits and LiveWire Extended breakers.

```lua
-- media/lua/shared/MyMod/MyMod_LiveWire.lua
local function register()
    local API = LiveWire and LiveWire.API
    if not (API and (API.revision or 0) >= 6) then return end
    local ok, why = API.registerConsumer("MyModPump", {
        -- exact sprite names; for a multi-tile object, the sprite of ONE piece only
        sprites = { "mymod_pumps_01_0", "mymod_pumps_01_1", "mymod_pumps_01_2", "mymod_pumps_01_3" },
        -- W while running, 0 when off (LiveWire applies PowerScale and the consumption profile)
        powerConsumption = function(o) return MyMod.isRunning(o) and 250 or 0 end,
        -- optional: refines a sprite also used by a non-electric version
        couldBePowered = function(o) return MyMod.isElectric(o) end,
        category = "other",      -- optional: light, tv, radio, stove, laundry, charger, fridge, other
        circuit = "equipment",   -- optional: "equipment" or "light" (panel circuit that cuts it)
        -- optional: what the management software shows (called on the server, translated by the client)
        display = function(o)
            return { name = "IGUI_MyMod_Pump",
                lines = { { "IGUI_MyMod_PumpFlow", string.format("%.1f", MyMod.flow(o)) } } }
        end,
        -- optional: one total per network, Equipment tab (called on the server, translated by the client)
        summary = function(objects)
            local running, flow = 0, 0
            for _, o in ipairs(objects) do
                if MyMod.isRunning(o) then running, flow = running + 1, flow + MyMod.flow(o) end
            end
            return { lines = { { "IGUI_MyMod_PumpsSummary", running, #objects, string.format("%.0f", flow) } } }
        end,
    })
    if not ok then print("MyMod: LiveWire refused the pump: " .. tostring(why)) end
end
Events.OnInitWorld.Add(register)
```

Then ask LiveWire before the machine works (both sides; LiveWire never switches your appliance off, and does not call you back):

```lua
if LiveWire and LiveWire.API.consumerPowered and not LiveWire.API.consumerPowered(pump) then
    return -- no current, or cut by a circuit or a breaker
end
```

Rules of `registerConsumer(id, definition)`:

| Field | Required | Rule |
|---|---|---|
| `id` | yes | `^[%a][%w_]*$`, at most 64 characters, unique |
| `sprites` | yes | 1 to 256 exact sprite names, no duplicates; a sprite belongs to one consumer only |
| `powerConsumption(o)` | yes | W while running, 0 when off; a non-number, negative or NaN value counts 0 |
| `couldBePowered(o)` | no | called only for objects with one of your sprites; `true` = it is the appliance |
| `category` | no | `"light"`, `"tv"`, `"radio"`, `"stove"`, `"laundry"`, `"charger"`, `"fridge"` or `"other"` (default) |
| `circuit` | no | `"equipment"` (default) or `"light"` |
| `display(o)` | no | `{ name = key, lines = { { key, arg1, ... }, ... } }`: keys `^[%w_]+$` of at most 64 characters from your own translations, 0 to 4 lines, 0 to 4 arguments per line (strings of at most 32 characters, or numbers shown as given). Anything else, or `nil`, keeps the usual row. Shown the same on LiveWire's computer screen and inside the Computer Mod window |
| `summary(objects)` | no | one total per network, shown in the Equipment tab: called once per snapshot with a new array of your appliances the network serves (idle ones included, those on the public grid excluded); same answer as `display` with at most 2 lines; anything else, or `nil`, shows nothing |

Refusals: `"registration_closed"`, `"invalid_definition"`, `"duplicate_consumer"`, `"duplicate_sprite"`. The definition is copied: changing it after registration does nothing.

Contract details:

- **When to register:** in a `shared` file, while Lua files load or in `Events.OnInitWorld`, so the server and every client register the same consumers. After `OnInitGlobalModData` the answer is `false, "registration_closed"`.
- **`o`** is always the placed world object (`IsoObject`) found by one of your sprites.
- **Multi-tile furniture:** name the sprite of **one** piece only (or let `couldBePowered` accept one piece), otherwise it is billed once per piece.
- **`powerConsumption(o)`** is read on the server each time LiveWire measures the zone (every 10 in-game minutes, and after a change): keep it fast, without side effects.
- **`consumerPowered(obj)`** works on both sides. On the server it reads the circuits; on a client it reads the cut the server synchronised. LiveWire never switches your appliance off: ask it when your machine starts, and at each step of its work.
- **`display(o)`** runs on the server, only when LiveWire builds the snapshot of a network: when a player opens an inverter screen, then every 10 in-game minutes while that player stays subscribed and nearby, on `gridAt`, and on an appliance inspection. Only for your appliances in that list (at most 200 rows). Keep it fast, without side effects.
- **`summary(objects)`** runs on the server at the same moments as `display`, once per snapshot for each consumer with at least one appliance on that network (master's zone, plus coupled inverters' zones when an add-on keeps them). Its lines appear in the Equipment tab, under LiveWire's own equipment, in registration order.
- **Translations of `display`:** the client translates `name` and each line with `getText(key, args...)`, so the keys must be in your mod's translation files (`media/lua/shared/Translate/EN/IG_UI.json` for `IGUI_` keys), for example:

```json
{
    "IGUI_MyMod_Pump": "Garden pump",
    "IGUI_MyMod_PumpFlow": "Flow: %1 L/h"
}
```

- **Removal:** a removed appliance leaves the bill at the next measurement; you have nothing to call.
- **Without LiveWire:** test `LiveWire and LiveWire.API and (LiveWire.API.revision or 0) >= 6` and keep your own power check (for example `ItemContainer.isObjectPowered(obj, true)`).

## Multiplayer checklist

- Register in `shared`, so the server and every client know the same batteries, sources, consumers and rules.
- A consumer's `display` runs on the server: return translation keys, never translated text.
- Read the registry (`gridAt`, `inverter`, `eachBilled`...) on the server only; send results to clients with your own commands.
- Never change LiveWire's ModData yourself: keep your data under your own key, like LiveWire Extended does (`LiveWireExtended`).
- Test on a dedicated server: some functions answer `nil` on a client by design.

## Questions

Ask on the [Discord](https://discord.gg/QEsBya7hUA) or open an issue on [GitHub](https://github.com/cyberbobjr/LiveWire/issues). If you need something the API does not offer, ask for a new function rather than reading LiveWire's internal modules: that is how revisions 2 to 6 were added.
