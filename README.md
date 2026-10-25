<p align="center"><img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/preview.png" width="256"></p>

# Live Wire

**The Electrical skill becomes a trade: silent solar, wind and water power for your whole house, with no fuel and no fumes.**

Project Zomboid Build 42.21 · mod id `batman_LiveWire` · EN/FR · MIT licence

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3821807453) · Questions, bug reports, ideas: [Discord](https://discord.gg/QEsBya7hUA)

Version française : [README_fr.md](README_fr.md)

![Solar panels and a wind turbine outdoors](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot4.png)

*Solar panels and a wind turbine outdoors, with green "connected" lights.*

## Version 1.6.0

A substantial minor update: control lighting and appliances from a working electrical panel, open an LCD on each device and manage its connections from one window. Stack two power banks, inspect consumers and cable links, and plan production with the three-day forecast and event log.

Solar orientation and dirt, battery testing and repair, salvage, electrical work risks, revised recipes and broader equipment loot add more depth to the Electrical skill. See the [changelog](CHANGELOG.md), [recipes](docs/wiki/en/08-recipes.md) and [maintenance guide](docs/wiki/en/10-electrical-skill-and-maintenance.md).

![Electrical panel with separate lighting and equipment circuits](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot6.png)

![Power-bank, inverter and electrical-panel screens on the same installation](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot7.png)

## Contents

1. [Overview](#overview)
2. [Equipment](#equipment)
3. [How to connect (wiring)](#how-to-connect-wiring)
4. [Inverter screen and management software](#inverter-screen-and-management-software)
5. [Optional equipment and the breaker](#optional-equipment-and-the-breaker)
6. [Water pump](#water-pump)
7. [Calculations](#calculations)
8. [Recipes](#recipes)
9. [Loot tables](#loot-tables)
10. [Wear and maintenance](#wear-and-maintenance)
11. [Electrical skill](#electrical-skill)
12. [Sandbox options](#sandbox-options)
13. [Multiplayer, status and installation](#multiplayer-status-and-installation)
14. [For developers](#for-developers)

## Overview

Solar panels, wind turbines and water wheels produce silent power. An inverter placed in the house powers every appliance around it. Batteries in a power bank store the surplus for the night. The server is authoritative (multiplayer-ready, designed for dedicated servers).

### Three roles, one network

- **Sources produce.** Solar panel 100 W, wind turbine 400 W, water wheel 120 W (nominal). Any number of sources per inverter; each must be within cable range (12 tiles, at most 1 floor apart).
- **Batteries store (optional).** Car batteries or deep-cycle batteries inside a power bank (4 counted per power bank, charge efficiency 0.90). Several power banks per inverter.
- **The inverter converts and distributes.** 1,500 W max (house demand), 20 W idle consumption, efficiency 0.85 to 1.0 (from the installer's level). One per network, can be placed indoors, no toxicity (it is not a game generator).
- **The house.** Every powered appliance within 20 tiles and ±3 floors of the inverter (vanilla options `GeneratorTileRange` / `GeneratorVerticalPowerRange`) is powered. No per-appliance wiring.

![How it works: sources, inverter, house and power bank](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_en.png)

*How it works: sources, inverter, house and power bank.*

**Minimal system:** one source + one inverter. Without batteries, the house runs on current production only (for example, three panels on a sunny day run a fridge-freezer at noon, not at night).

The game itself decides what is powered (a square is powered as if near a generator), so fridges, lights, stoves, TVs and radios work exactly as in vanilla.

**Fridges stay cold while you are away.** Fridges and freezers keep food cold while the area is unloaded, as long as there is power. Checked in game: a fresh steak in a powered fridge, player 300 tiles away, 10 game hours: aged 0.083 day (cold) instead of 0.417 day (warm). On returning, Live Wire replays power changes from a server-side history covering 60 game days. Older periods use the earliest retained state as an approximation; upgrading an existing save cannot recover changes already discarded by earlier versions.

## Equipment

Each recipe gives a placeable furniture item `Base.Mov_LiveWire_*`. Place, rotate and pick up with the vanilla furniture cursor (ghost, 4 facings, 2 for wall objects). The tile requires a screwdriver and the Electrical level below, also to pick up. A picked-up device keeps its condition.

Placement rules added by the mod: outdoors (open sky) for the solar panel and wind turbine; river bank, ground floor, next to river water for the water wheel (lakes and ponds are refused). A refused square shows the reason in red in the cursor panel.

![All devices with their key figures](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_en.png)

*All devices with their key figures.*

| Device | Role | Placement | Electrical level |
|---|---|---|---|
| Solar panel | Source, 100 W | Outdoors, open sky; flat roof OK | 3 |
| Wind turbine | Source, 400 W; blades turn with the wind | Outdoors; +15 % wind per floor up to the 3rd | 2 |
| Water wheel | Source, 120 W day and night | Ground floor, next to a river | 2 |
| Inverter | Heart of the network, 1,500 W | Any floor tile, indoors included | 5 |
| Power bank | Storage, 4 batteries counted; opens like a crate (capacity 50) | Anywhere; picked up only when empty | 2 |
| Breaker panel | Safety, optional | On a wall (north or west) | 3 |
| Low battery alarm | Alert, optional | On a wall | 2 |
| Water pump | Consumer, 250 W while pumping: moves barrel water to the taps | Any floor tile, indoors or outdoors | 6 |

Batteries are never placed on the floor: drag them into the power bank with the vanilla inventory.

| Battery | Nominal capacity | Life |
|---|---|---|
| Car battery `Base.CarBattery1` | 0.40 kWh | 150 cycles |
| Car battery `Base.CarBattery2` | 0.60 kWh | 150 cycles |
| Car battery `Base.CarBattery3` | 0.90 kWh | 150 cycles |
| Deep-cycle battery `LiveWire.DeepCycleBattery` | 1.50 kWh | 600 cycles |

Effective capacity = nominal × (0.4 + 0.6 × condition / 100) × `BatteryCapacityMultiplier`.

![Power bank opened like a crate](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot3.png)

*Power bank opened like a crate.*

**Lights on the tiles:** the inverter screen is lit when on and shows a red light on fault; sources and the power bank have a green "connected" light; the breaker has a green powered-distribution indicator and a red lamp when tripped; the alarm beacon is lit while ringing; the water pump has a blue light whenever powered, including while idle.

![Indoors: inverter, power bank, computer, wall alarm and breaker](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot5.png)

*Indoors: inverter, power bank, computer, wall alarm and breaker.*

## How to connect (wiring)

1. Craft the devices (see [Recipes](#recipes)) and place them with the furniture cursor.
2. Right-click a device > **Live Wire** > device name. It shows "Connected to the inverter N tiles away" or "Not connected", then **Connect to an inverter** > one line per inverter in range: "Inverter N tiles away (k wires)". Or right-click the inverter > **Connect equipment** (list of free equipment in range with distance and wires) / **Disconnect equipment**.
3. Pay the cost in electric wire `Base.ElectricWire`.
4. Respect the limits per network.

**Cost:** 1 wire per 4 tiles of distance, rounded up, at least 1 (sandbox `WirePerTiles`; 0 = free). Worked example: a source 9 tiles from the inverter costs ceil(9 / 4) = 3 wires.

**Range:** 12 tiles (sandbox `LinkRange`, 4-30), at most 1 floor apart.

**Limits per network:** at most one breaker, one alarm, one management computer and one backup generator.

**Vanilla objects:** the vanilla generator (backup) and the vanilla desktop computer (management) are linked the same way from their own right-click menu (**Live Wire** > Backup generator / Management computer > Connect to an inverter).

**Moving things:** picking up the inverter disconnects its whole network; rotating it keeps the links. Picking up a source keeps its condition; placed again, it is "Not connected".

**Inverter right-click menu:** Open the inverter screen, Turn on / Turn off, Reset (after a trip), Show the powered area (cyan circle on the ground), Connect equipment, Disconnect equipment, Soundproof the inverter, Inspect, Repair, Overhaul.

![The Live Wire right-click menu on the inverter](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot1.png)

*The Live Wire right-click menu on the inverter.*

## Inverter screen and management software

Left-click equipment for its own LCD and use **Connections** to manage its wiring. The software also lists consumers, the last 30 events and a three-day forecast with a powered management computer. See the [screen guide](docs/wiki/en/05-inverter-screen-and-software.md) and [electrical-panel guide](docs/wiki/en/06-optional-equipment.md#two-circuit-electrical-panel).

**LCD panel** (right-click the inverter > Open the inverter screen): backlit screen, 5 pages (Production/Load, Batteries, Sources, House, Status) with `<` and `>`; an I/O button with a light (green on, red off, blinking orange on fault); RESET when tripped; production and load bars on the same scale; long lines scroll.

![Inverter LCD panel, page 1 (production / load)](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/onduleur.png)

*Inverter LCD panel, page 1 (production / load).*

![Inverter LCD panel in the house](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot2.png)

*Inverter LCD panel in the house.*

**Management software "Live Wire Monitor"** has the tabs Overview, Batteries, Sources, House, History and Equipment.

- **Overview:** production and consumption in large figures with bars on the same scale, storage gauge and autonomy, inverter card (state light, condition, On/Off, Reset), alerts.
- **History:** 48 h graphs (production, consumption, battery stock) and the forecast "batteries will last until sunrise". It needs a linked management computer.

**Without the Computer Mod:** a vanilla desktop computer linked to the inverter opens the software on the mod's own computer screen (monitor, boot screen "Live Wire OS", status bar with game time).

![Management software on a vanilla computer, without the Computer Mod or Laptop Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/livewire_monitor_without_compute.png)

*Management software on a vanilla computer, without the Computer Mod or Laptop Mod.*

**With the optional Computer Mod (Workshop 3725497089) or Laptop Mod (3798992436):** the software comes on a disk, "Disk: Live Wire Management Software" (`LiveWire.MonitorDisk`), found in computer loot. Right-click the computer with the disk > **Install the Live Wire software**. It then appears as a "Live Wire" app on their desktop and runs inside their window (title bar, minimise, close, taskbar). It shows the inverter linked to that computer, or the nearest inverter in cable range.

![Desktop with the Live Wire icon](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/computermod.png)

*Computer Mod desktop with the Live Wire icon.*

![Live Wire Monitor, Overview tab, inside the Computer Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/livewire_computermod.png)

*Live Wire Monitor, Overview tab, inside the Computer Mod.*

![History tab: 48 h graphs and forecast](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/conso_livewire_computermod.png)

*History tab: 48 h graphs and forecast.*

![Equipment tab inside the Computer Mod](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/equipement_livewire_computermod.png)

*Equipment tab inside the Computer Mod.*

**Inverter hum:** a sound of the mod, heard only one tile around a switched-on inverter (same floor). Each player sets its volume in Options > Mods > Live Wire (0 = off). Zombies hear the inverter within 2 tiles (sandbox `InverterNoiseRadius`).

**Soundproofing kit** (`LiveWire.SoundproofKit`): fitted on the inverter with a screwdriver (**Soundproof the inverter**), removed with **Remove the soundproofing** (kit given back). Effects: no hum, zombies no longer hear it; the inverter runs warmer and wears 25 % faster. It follows the inverter when picked up.

A soundproofed inverter is covered with grey acoustic foam on its top, sides and back (the screen stays visible), and "Soundproofed" shows when it is inspected and on the Status page of its screen.

## Optional equipment and the breaker

| Equipment | Vanilla list | Where | Weight (×5) | Rolls | ≈ chance per container |
|---|---|---|---|---|---|
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarPanel.png" width="24" height="24"> **Solar Panel** (furniture: × 0.6 included) | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreTools` | Hardware store, tools | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 1.5 | 4 | 3.6 % |
|  | `GarageMetalwork` | Garage metalwork storage | 1 | 4 | 2.4 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/VoltageTester.png" width="24" height="24"> **Voltage Tester** | `ElectricianTools` | Electrician's tools | 15 | 3 | 24.6 % |
|  | `ToolStoreTools` | Hardware store, tools | 5 | 4 | 11.5 % |
|  | `GarageTools` | Garage tool storage | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 5 | 4 | 11.5 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 5 | 4 | 11.5 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 5 | 4 | 11.5 % |
|  | `MechanicShelfTools` | Mechanic shop, tools | 5 | 4 | 11.5 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/DeepCycleBattery.png" width="24" height="24"> **Deep-Cycle Battery** | `CarSupplyBatteries` | Car parts store, batteries | 10 | 4 | 21.9 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 5 | 4 | 11.5 % |
|  | `CrateMechanics` | Mechanic supply crates | 3.5 | 4 | 8.1 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `GarageMechanics` | Garage, mechanic storage | 1.5 | 4 | 3.6 % |
|  | `CampingStoreGear` | Camping store, gear | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Inverter.png" width="24" height="24"> **Inverter** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 2.5 | 3 | 4.4 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreAppliances` | Electronics store, appliances | 1.5 | 1 | 0.9 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 1.5 | 4 | 3.6 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1 | 4 | 2.4 % |
|  | `CrateTools` | Tool crates | 1 | 4 | 2.4 % |
|  | `GarageTools` | Garage tool storage | 0.5 | 4 | 1.2 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Breaker.png" width="24" height="24"> **Breaker Panel** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 5 | 3 | 8.7 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ToolStoreTools` | Hardware store, tools | 2.5 | 4 | 5.9 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/PowerBank.png" width="24" height="24"> **Power Bank** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 2.5 | 3 | 4.4 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2 | 4 | 4.7 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1.5 | 4 | 3.6 % |
|  | `CrateMechanics` | Mechanic supply crates | 1.5 | 4 | 3.6 % |
|  | `GarageTools` | Garage tool storage | 1 | 4 | 2.4 % |
|  | `GarageMechanics` | Garage, mechanic storage | 1 | 4 | 2.4 % |
|  | `CrateTools` | Tool crates | 1 | 4 | 2.4 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/BatteryAlarm.png" width="24" height="24"> **Low Battery Alarm** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 5 | 3 | 8.7 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbine.png" width="24" height="24"> **Wind Turbine** (furniture: × 0.6 included) | `WireFactoryElectric` | Wire factory, electrical | 2.5 | 4 | 5.9 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 2.5 | 4 | 5.9 % |
|  | `WireFactoryTools` | Wire factory, tools | 2.5 | 4 | 5.9 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1.5 | 4 | 3.6 % |
|  | `CrateElectronics` | Electronics crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateFarming` | Farming supply crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 1.5 | 4 | 3.6 % |
|  | `MechanicShelfTools` | Mechanic shop, tools | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WaterWheel.png" width="24" height="24"> **Water Wheel** (furniture: × 0.6 included) | `CrateCarpentry` | Carpentry crates | 2.5 | 4 | 5.9 % |
|  | `ToolStoreCarpentry` | Hardware store, carpentry | 2.5 | 4 | 5.9 % |
|  | `CrateFarming` | Farming supply crates | 2.5 | 4 | 5.9 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateMechanics` | Mechanic supply crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineBlades.png" width="24" height="24"> **Wind Turbine Blade Set** | `CrateMetalwork` | Metalwork crates | 5 | 4 | 11.5 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 3.5 | 4 | 8.1 % |
|  | `CrateFarming` | Farming supply crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 3.5 | 4 | 8.1 % |
|  | `WireFactoryTools` | Wire factory, tools | 3.5 | 4 | 8.1 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineMast.png" width="24" height="24"> **Wind Turbine Mast** | `CrateMetalwork` | Metalwork crates | 5 | 4 | 11.5 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 3.5 | 4 | 8.1 % |
|  | `CrateMechanics` | Mechanic supply crates | 3.5 | 4 | 8.1 % |
|  | `CrateFarming` | Farming supply crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 3.5 | 4 | 8.1 % |

### Parallel inverters (coupling)

Real off-grid systems get more power by adding identical inverters in parallel, not by pushing one beyond its rating. Live Wire does the same:

- Right-click an inverter > **Couple to an inverter** > a master inverter within cable range. The clicked inverter becomes a **slave**. Cost: the electric wire for the distance and 1 **inverter coupling kit** (recipe at Electrical 6).
- The slave must have no equipment of its own; a master takes at most 3 slaves (4 inverters).
- One network, one battery bank, one powered area (the master's). Capacity = 1,500 W × inverters in service; each switched-on inverter uses 20 W idle and wears as usual.
- A slave switched off or broken no longer counts: if the demand then exceeds what is left, the breaker (or the master) trips. Each slave has its own On/Off switch; reset on the master or the breaker.
- **Uncouple** on the slave makes it independent again (the kit is given back). A master picked up frees its slaves.
- The LCD Status page and the software show "Coupled: n / total in service" and the total capacity.
- Two independent inverters whose areas overlap no longer count the same appliances twice: each appliance is counted by the nearest switched-on inverter.

### When does the breaker trip?

When the demand of the house appliances exceeds the inverter maximum, 1,500 W (the 20 W idle is not counted). It is checked at each simulation step: every 10 game minutes and right after an action. Examples: a stacked washer + dryer running together (1,800 W with the game values); with the 1993 consumption profiles, an electric cooker or a dryer alone. Without a breaker, the inverter trips and loses 3 condition points (reset on the inverter).

## Water pump

A consumer placed like the other devices (level 6). It pumps water from water barrels into the house taps. Not tested in game yet.

- Link the pump to the inverter with electric wire, as for any device.
- Link each water barrel (vanilla rain collector, or a barrel of the optional mod Useful Barrels) with one **iron pipe** (`Base.MetalPipe`, given back when the barrel is disconnected). The barrel must stand next to the pump: one of its 8 neighbouring squares, same floor. Up to 8 barrels per pump. Only a barrel holding water (or empty) can be connected.
- Above each plumbed sink, bath, shower or toilet inside a room within **15 tiles** of the pump (sandbox `PumpRange`, 5-30) and up to 3 floors up or down, the pump keeps an invisible relay tank of 25 L. Vanilla plumbing takes the water from it: connect the tap with the pipe wrench as usual ("Plumb...").
- No relay is placed above a tap that already has another water source (vanilla barrel above, running water, another mod).
- While the network has power, the pump refills the relays from its barrels, at 5 L per game minute at most. It draws 250 W only while pumping, and stops when every tap is full. A light motor hum is heard within 4.5 tiles while it runs; zombies hear it within 2 tiles.
- Only water is moved, and the rain keeps filling the barrels as before. Tainted water comes out clean at the tap, as in vanilla.
- Right-click the pump > **Show the supplied taps**: a blue circle shows the range, and the supplied taps, the connected barrels and the pump are highlighted in blue. The pump has a blue light whenever powered, including while idle.
- Several pumps per network. The software Equipment tab shows the number of pumps in service and their flow (L/h), nothing else.
- **Before removing the mod**, run the debug action "Remove every water relay" (Live Wire menu > Debug, with administrator rights in multiplayer), otherwise the invisible relay tiles stay in the saved world. The action also stops every pump until the debug action "Enable the water pumps again".

## Calculations

Solar examples below assume clean, snow-free, south-facing panels. Other directions, dirt and weather change the result; use the management forecast for your installation.

The server computes every 10 game minutes, players present or not (sandbox `SimulateUnloaded`, default on).

![Solar day, wind curve and energy per day compared with a typical house](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_en.png)

*Solar day, wind curve and energy per day compared with a typical house.*

**Source power:** `P = nominal × source factor × condition factor × installation efficiency × sandbox multiplier`

- Condition factor = 0.5 + 0.5 × condition / 100.
- Installation efficiency (installer's Electrical level when placed): 0.85 (levels 3-6), 0.95 (7-8), 1.0 (9-10).
- Each source smooths its output (30 game minutes response): a passing cloud does not make the house flicker.

### Solar (100 W)

Sine curve between the season's dawn and dusk. Clouds leave 20 % at full overcast (factor × (1 − 0.8 × clouds)). Snow builds up on the panel during snowfall and melts above 0 °C (use the "Clear the snow" action). About 0.94 kWh per summer day and 0.60 kWh in winter (new panel, clear sky).

### Wind (400 W)

| Wind speed | Share of nominal power |
|---|---|
| Below 10 km/h | 0 |
| 10 to 45 km/h | ((v − 10) / 35)³ |
| 45 to 85 km/h | 100 % |
| Above 85 km/h | 0 (automatic brake) |

Wind gets +15 % per floor, up to the 3rd. Examples: 25 km/h ≈ 31 W, 40 km/h ≈ 252 W.

### Water wheel (120 W)

Runs day and night, about 2.9 kWh per day. Season factor: spring × 1.2, summer × 0.8, autumn and winter × 1.0. Rivers only (the engine cannot tell a lake's current).

### Batteries and inverter

- Charging: surplus × 0.90 (charge efficiency); self-discharge 0.2 % per day; when full, extra production is lost (shown as "production lost").
- The inverter supplies the demand from current production first (× efficiency), then from the batteries. It can only restart when production covers the demand or the batteries hold more than 2 % of their capacity.
- Appliance consumption depends on the sandbox `ConsumptionProfile` (below).

### Appliance consumption

The sandbox option **`ConsumptionProfile`** sets how much power each switched-on appliance draws. Values are **averages over a 10-minute step**, not start-up peaks: a fridge compressor cycles on and off, so a fridge-freezer that pulls 300-400 W while running averages about 130 W.

| Appliance (switched on) | Ultra-realistic 1993 | Realistic 1993 | Game values (default) | Comfort |
|---|---|---|---|---|
| Light (one switch, i.e. one room) | 100 W | 60 W | 2 W | 1 W |
| Radio on mains | 40 W | 20 W | 10 W | 5 W |
| Television | 120 W | 80 W | 30 W | 15 W |
| Fridge alone or freezer alone | 130 W | 90 W | 80 W | 40 W |
| Fridge-freezer | 180 W | 130 W | 130 W | 65 W |
| Electric cooker | 3,000 W | 2,000 W | 90 W | 45 W |
| Microwave | 1,500 W | 1,100 W | 90 W | 45 W |
| Washer | 700 W | 500 W | 90 W | 45 W |
| Dryer | 5,000 W | 3,000 W | 90 W | 45 W |
| Combination washer-dryer (washing / drying) | 700 / 3,000 W | 500 / 2,000 W | 90 W | 45 W |
| Stacked washer + dryer (each half running) | 700 + 5,000 W | 500 + 3,000 W | 900 + 900 W | 45 + 45 W |
| Car battery charger | 250 W | 150 W | 50 W | 25 W |
| Gas appliance (controls only) and appliances added by other mods | game value | game value | game value | half |

- **Game values** are the engine's own values, the ones the vanilla generator uses (1 engine power unit per hour = 1,000 W). A base therefore costs the same on an inverter as on a vanilla generator. They are very low for lights, TVs and cookers, and the vanilla stacked washer + dryer is oddly high (0.9 per half instead of 0.09).
- **Realistic 1993** uses typical household draws of the time: 60 W incandescent bulbs, a 25" CRT TV, a 1990s fridge-freezer (about 1,100 kWh a year), a 240 V electric range and dryer.
- **Ultra-realistic 1993** uses older, hungrier appliances: 100 W fixtures, a large CRT, a 1980s fridge, a full-power range and dryer.
- **Comfort** halves the game values and fixes the stacked washer + dryer.
- `PowerScale` multiplies the result of the profile (1 = no change). The inverter itself always uses 20 W idle.
- An appliance that spans two tiles with a fridge or freezer on each (large shop fridges) counts twice, like with a vanilla generator: it is a bigger appliance.
- The profile can be changed during a game: the demand follows at the next measurement.

#### What the realistic profiles change

The inverter limit stays **1,500 W** (up to 6,000 W with [coupled inverters](#optional-equipment-and-the-breaker)), in line with the off-grid inverters of the 1990s. In the 1993 profiles:

- An electric cooker (2,000 or 3,000 W) or a dryer trips a single inverter: cook on gas, a wood stove or a campfire, or couple inverters. A breaker panel protects the inverter.
- Lights become the main night load: switch off empty rooms.

### Sizing example

A reference day: one fridge-freezer all day, 10 lights for 6 hours, the TV for 3 hours, plus the inverter idle (20 W). Lights and TV are used at night. A winter night lasts 14 hours.

| Profile | Evening demand | Energy per day | Winter night | Batteries for the night |
|---|---|---|---|---|
| Ultra-realistic 1993 | 1,300 W | 11.2 kWh | 9.2 kWh | about 16 car batteries or 7 deep-cycle |
| Realistic 1993 | 810 W | 7.4 kWh | 5.9 kWh | about 10 car batteries or 4 deep-cycle |
| Game values | 180 W | 3.8 kWh | 2.3 kWh | about 4 car batteries or 2 deep-cycle |
| Comfort | 90 W | 2.1 kWh | 1.3 kWh | about 3 car batteries or 1 deep-cycle |

(Standard car battery: 0.6 kWh; deep-cycle battery: 1.5 kWh; new batteries in full condition.)

Winter production of the sources: solar panel about 0.6 kWh/day, water wheel about 2.9 kWh/day, wind turbine about 0.7 kWh/day with an average 25 km/h wind.

| Installation | Summer (kWh/day) | Winter (kWh/day) | Enough for |
|---|---|---|---|
| 4 solar panels | 3.8 | 2.4 | Comfort |
| 6 panels + 1 wind turbine | 6.3 | 4.3 | Game values |
| 1 water wheel + 8 panels | 9.8 | 7.7 | Realistic 1993 |
| 2 water wheels + 9 panels | 13.1 | 11.2 | Ultra-realistic 1993 (just) |

There is no limit on the number of solar panels; productions add up (100 W nominal each). The 1,500 W limit applies to the house demand, not to production.

## Recipes

The 17 Live Wire recipes are in the crafting menu. Electrical recipes unlock automatically at their required level; the blade set and mast are in **Metalworking** and need no Electrical level. Tools are kept (some can wear). Every recipe awards Electrical XP, including blades, masts and tester dismantling.

![Illustrated recipe board](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_en.png)

*Illustrated recipe board.*

| Ingredients | Tools (kept) | Skill | Result |
|---|---|---|---|
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/LightBulb.png" width="24" height="24"> Light Bulb<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Battery.png" width="24" height="24"> Battery | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | Electrical 1 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/VoltageTester.png" width="32" height="32"> **Voltage Tester** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/VoltageTester.png" width="24" height="24"> Voltage Tester | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | none | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="32" height="32"> **Scrap Electronics** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Calculator.png" width="24" height="24"> Calculator | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | none | 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="32" height="32"> **Scrap Electronics**<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarCell.png" width="32" height="32"> **Solar Cell** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SheetMetal.png" width="24" height="24"> Steel Sheet<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/PowerBank.png" width="32" height="32"> **Power Bank** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Amplifier.png" width="24" height="24"> Amplifier | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | Electrical 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/BatteryAlarm.png" width="32" height="32"> **Low Battery Alarm** |
| 4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Plank.png" width="24" height="24"> Plank<br>10 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Nails.png" width="24" height="24"> Nails<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/RippedSheets.png" width="24" height="24"> Rag | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Hammer.png" width="24" height="24"> | Electrical 2 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SoundproofKit.png" width="32" height="32"> **Inverter Soundproofing Kit** |
| 10 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarCell.png" width="24" height="24"> Solar Cell<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SheetMetal.png" width="24" height="24"> Steel Sheet<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Glue.png" width="24" height="24"> Glue | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 3 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarPanel.png" width="32" height="32"> **Solar Panel** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SmallSheetMetal.png" width="24" height="24"> Steel Sheet - Small<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | Electrical 3 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Breaker.png" width="32" height="32"> **Breaker Panel** |
| 4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Amplifier.png" width="24" height="24"> Amplifier<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SmallSheetMetal.png" width="24" height="24"> Steel Sheet - Small<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 5 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Inverter.png" width="32" height="32"> **Inverter** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SheetMetal.png" width="24" height="24"> Steel Sheet<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SheetMetalSnips.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Hammer.png" width="24" height="24"> | none | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineBlades.png" width="32" height="32"> **Wind Turbine Blade Set** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/MetalPipe.png" width="24" height="24"> Iron Pipe<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/MetalBar.png" width="24" height="24"> Steel Rod<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Hammer.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/PipeWrench.png" width="24" height="24"> | none | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineMast.png" width="32" height="32"> **Wind Turbine Mast** |
| 1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineBlades.png" width="24" height="24"> Wind Turbine Blade Set<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineMast.png" width="24" height="24"> Wind Turbine Mast<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Amplifier.png" width="24" height="24"> Amplifier<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbine.png" width="32" height="32"> **Wind Turbine** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/CarBattery1.png" width="24" height="24"> Car Battery (any)<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ScrapMetal.png" width="24" height="24"> Scrap Metal | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/DeepCycleBattery.png" width="32" height="32"> **Deep-Cycle Battery** |
| 8 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Plank.png" width="24" height="24"> Plank<br>20 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Nails.png" width="24" height="24"> Nails<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Amplifier.png" width="24" height="24"> Amplifier<br>3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/MetalBar.png" width="24" height="24"> Steel Rod | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Hammer.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | Electrical 7 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WaterWheel.png" width="32" height="32"> **Water Wheel** |
| 3 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/MetalPipe.png" width="24" height="24"> Iron Pipe<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SmallSheetMetal.png" width="24" height="24"> Steel Sheet - Small<br>4 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screws.png" width="24" height="24"> Screws | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/PipeWrench.png" width="24" height="24"> | Electrical 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WaterPump.png" width="32" height="32"> **Water Pump** |
| 2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>2 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectricWire.png" width="24" height="24"> Electrical Wire<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Amplifier.png" width="24" height="24"> Amplifier | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Screwdriver.png" width="24" height="24"> | Electrical 6 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/CouplingKit.png" width="32" height="32"> **Inverter Coupling Kit** |
| 5 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/ElectronicsScrap.png" width="24" height="24"> Scrap Electronics<br>1 × <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Aluminum.png" width="24" height="24"> Aluminum Foil | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Pliers.png" width="24" height="24"> | Electrical 8 | <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarCell.png" width="32" height="32"> **Solar Cell** |

## Loot tables

**How to read these tables.** Project Zomboid tests each item independently at each roll of a container list. A weight of W gives about W % per roll at normal loot rarity (before sandbox loot settings and zombie density). "Rolls" is the number of rolls of that vanilla list. Approximate chance per container ≈ 1 − (1 − W/100)^Rolls. For placeable furniture items like the solar panel, vanilla applies the "Other" loot modifier (0.6 at normal rarity).

**Solar cell** `LiveWire.SolarCell` (always):

Weights at ×5; estimates assume this list is selected and a vanilla loot modifier of 0.6. Actual sandbox settings, zombie density, time and container space can change the result.

| Vanilla list | Where | Weight (×5) | Rolls | ≈ chance per container |
|---|---|---|---|---|
| `GarageTools` | Garage tool storage | 10 | 4 | 21.9 % |
| `CrateTools` | Tool crates | 5 | 4 | 11.5 % |
| `GarageMetalwork` | Garage metalwork storage | 5 | 4 | 11.5 % |
| `MechanicShelfElectric` | Mechanic shop, electrical shelf | 10 | 4 | 21.9 % |
| `ElectricianTools` | Electrician's tools | 15 | 3 | 24.6 % |
| `MetalShopTools` | Metal shop tools | 5 | 4 | 11.5 % |
| `WireFactoryElectric` | Wire factory, electrical | 10 | 4 | 21.9 % |
| `ToolStoreMisc` | Hardware store, miscellaneous | 10 | 4 | 21.9 % |
| `CrateElectronics` | Electronics crates | 10 | 4 | 21.9 % |
| `ElectronicStoreMisc` | Electronics store, miscellaneous | 10 | 4 | 21.9 % |
| `ToolStoreMetalwork` | Hardware store, metalwork | 5 | 4 | 11.5 % |
| `CrateMetalwork` | Metalwork crates | 5 | 4 | 11.5 % |

**Ready-made Live Wire equipment**

Ready-made equipment, at the default EquipmentLootMultiplier = 5 (range 1–20). Estimates assume this loot list is selected, a vanilla loot modifier of 0.6, no zombie-density or time modifiers and enough container space; they are not a guaranteed discovery rate.

Look in hardware stores, garages and mechanic workshops, electronics stores, electrical factories and warehouse crates. Deep-cycle batteries also appear among camping gear. Locations and equipment vary by loot category; there is no guaranteed map location. Water wheels can now be found in farming, carpentry and technical storage; water pumps remain craft-only.

Set **Live Wire equipment and parts loot multiplier** on the **LiveWire** sandbox page: **5 by default**, from **1 to 20**. Restart the game or dedicated server after a change. Existing saves without this option use 5. Only future loot rolls are affected, including vanilla loot respawn if enabled; searched containers are not refilled. Solar cells are included. Vanilla items and their weights are unchanged; software disks keep their existing rates. At 1 the old weights are restored in existing categories, with the new locations still available.

| Equipment | Vanilla list | Where | Weight (×5) | Rolls | ≈ chance per container |
|---|---|---|---|---|---|
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/SolarPanel.png" width="24" height="24"> **Solar Panel** (furniture: × 0.6 included) | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreTools` | Hardware store, tools | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 1.5 | 4 | 3.6 % |
|  | `GarageMetalwork` | Garage metalwork storage | 1 | 4 | 2.4 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/VoltageTester.png" width="24" height="24"> **Voltage Tester** | `ElectricianTools` | Electrician's tools | 15 | 3 | 24.6 % |
|  | `ToolStoreTools` | Hardware store, tools | 5 | 4 | 11.5 % |
|  | `GarageTools` | Garage tool storage | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 5 | 4 | 11.5 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 5 | 4 | 11.5 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 5 | 4 | 11.5 % |
|  | `MechanicShelfTools` | Mechanic shop, tools | 5 | 4 | 11.5 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/DeepCycleBattery.png" width="24" height="24"> **Deep-Cycle Battery** | `CarSupplyBatteries` | Car parts store, batteries | 10 | 4 | 21.9 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 5 | 4 | 11.5 % |
|  | `CrateMechanics` | Mechanic supply crates | 3.5 | 4 | 8.1 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `GarageMechanics` | Garage, mechanic storage | 1.5 | 4 | 3.6 % |
|  | `CampingStoreGear` | Camping store, gear | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Inverter.png" width="24" height="24"> **Inverter** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 2.5 | 3 | 4.4 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreAppliances` | Electronics store, appliances | 1.5 | 1 | 0.9 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 1.5 | 4 | 3.6 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1 | 4 | 2.4 % |
|  | `CrateTools` | Tool crates | 1 | 4 | 2.4 % |
|  | `GarageTools` | Garage tool storage | 0.5 | 4 | 1.2 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/Breaker.png" width="24" height="24"> **Breaker Panel** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 5 | 3 | 8.7 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ToolStoreTools` | Hardware store, tools | 2.5 | 4 | 5.9 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/PowerBank.png" width="24" height="24"> **Power Bank** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 2.5 | 3 | 4.4 % |
|  | `MechanicShelfElectric` | Mechanic shop, electrical shelf | 2.5 | 4 | 5.9 % |
|  | `CrateElectronics` | Electronics crates | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2 | 4 | 4.7 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1.5 | 4 | 3.6 % |
|  | `CrateMechanics` | Mechanic supply crates | 1.5 | 4 | 3.6 % |
|  | `GarageTools` | Garage tool storage | 1 | 4 | 2.4 % |
|  | `GarageMechanics` | Garage, mechanic storage | 1 | 4 | 2.4 % |
|  | `CrateTools` | Tool crates | 1 | 4 | 2.4 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/BatteryAlarm.png" width="24" height="24"> **Low Battery Alarm** (furniture: × 0.6 included) | `ElectricianTools` | Electrician's tools | 5 | 3 | 8.7 % |
|  | `WireFactoryElectric` | Wire factory, electrical | 5 | 4 | 11.5 % |
|  | `CrateElectronics` | Electronics crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `ElectronicStoreMisc` | Electronics store, miscellaneous | 2.5 | 4 | 5.9 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `GarageTools` | Garage tool storage | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbine.png" width="24" height="24"> **Wind Turbine** (furniture: × 0.6 included) | `WireFactoryElectric` | Wire factory, electrical | 2.5 | 4 | 5.9 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 2.5 | 4 | 5.9 % |
|  | `WireFactoryTools` | Wire factory, tools | 2.5 | 4 | 5.9 % |
|  | `ToolStoreMisc` | Hardware store, miscellaneous | 1.5 | 4 | 3.6 % |
|  | `CrateElectronics` | Electronics crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateFarming` | Farming supply crates | 1.5 | 4 | 3.6 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 1.5 | 4 | 3.6 % |
|  | `MechanicShelfTools` | Mechanic shop, tools | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WaterWheel.png" width="24" height="24"> **Water Wheel** (furniture: × 0.6 included) | `CrateCarpentry` | Carpentry crates | 2.5 | 4 | 5.9 % |
|  | `ToolStoreCarpentry` | Hardware store, carpentry | 2.5 | 4 | 5.9 % |
|  | `CrateFarming` | Farming supply crates | 2.5 | 4 | 5.9 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 1.5 | 4 | 3.6 % |
|  | `CrateTools` | Tool crates | 1.5 | 4 | 3.6 % |
|  | `CrateMechanics` | Mechanic supply crates | 1.5 | 4 | 3.6 % |
|  | `CrateMetalwork` | Metalwork crates | 1.5 | 4 | 3.6 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineBlades.png" width="24" height="24"> **Wind Turbine Blade Set** | `CrateMetalwork` | Metalwork crates | 5 | 4 | 11.5 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 3.5 | 4 | 8.1 % |
|  | `CrateFarming` | Farming supply crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 3.5 | 4 | 8.1 % |
|  | `WireFactoryTools` | Wire factory, tools | 3.5 | 4 | 8.1 % |
| <img src="https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/WindTurbineMast.png" width="24" height="24"> **Wind Turbine Mast** | `CrateMetalwork` | Metalwork crates | 5 | 4 | 11.5 % |
|  | `ToolStoreMetalwork` | Hardware store, metalwork | 5 | 4 | 11.5 % |
|  | `CrateTools` | Tool crates | 3.5 | 4 | 8.1 % |
|  | `CrateMechanics` | Mechanic supply crates | 3.5 | 4 | 8.1 % |
|  | `CrateFarming` | Farming supply crates | 3.5 | 4 | 8.1 % |
|  | `ToolStoreFarming` | Hardware/outdoor store, farming | 3.5 | 4 | 8.1 % |

**Mod components**

Solar cells, wind turbine blade sets and masts are Live Wire components and use the same multiplier.
Only objects defined by Live Wire appear in these added loot entries and tables.
Vanilla crafting ingredients (wire, scrap, amplifiers, speakers, bulbs, batteries
and building materials) keep their existing distributions and weights. No vanilla
item is added, removed or reweighted by this option.

**Management software disk** `LiveWire.MonitorDisk` (only when the Computer Mod is active):

| Vanilla list | Where | Weight | Rolls | ≈ chance per container |
|---|---|---|---|---|
| ElectronicStoreComputers | Electronics store, computers | 2 | 1 | 2.0 % |
| CrateComputer | Computer crates | 2 | 4 | 7.8 % |
| BookstoreComputer | Bookstore, computer section | 1 | 4 | 3.9 % |
| UniversityDesk_Computer | University desk, computing | 1 | 4 | 3.9 % |
| UniversityDesk_Electrical | University desk, electrical | 2 | 4 | 7.8 % |
| OfficeDesk | Office desks | 0.3 | 4 | 1.2 % |

Also: 1 solar cell per calculator dismantled (no level); at level 8, a solar cell from 5 electronics scrap + 1 aluminum.

## Wear and maintenance

| Device | Normal wear | Accelerators |
|---|---|---|
| Solar panel | −1 per 10 days | Thunderstorm, only if sandbox `StormDamage` (off by default) |
| Wind turbine | −1 per 4 days | Wind > 85 km/h with `StormDamage` |
| Water wheel | −1 per 6 days | none |
| Inverter | −1 per 5 days while on | Load > 80 %: wear × 2; each trip without breaker: −3; soundproofed: × 1.25 |
| Breaker | −1 per 15 days | none |
| Water pump | −1 per 10 days while pumping | none |
| Power bank, alarm | −1 per 30 days | none |
| Battery | 100 / life cycles per full cycle | Discharge below 20 %: wear doubled; self-discharge 0.2 % per day |

- **Repair:** 1 electronics scrap + 1 electric wire, gain 5 + Electrical level points (up to 90). Failure chance: max(5, 40 − 5 × level) %, halved from level 8; parts are lost on failure.
- **Overhaul** (level 8, 4 scrap + 2 wires): back to 100.
- **Recondition a battery**: Electrical 4, or 6 for a dead battery; kept screwdriver, 1 electronics scrap + 1 wire + 0.5 L water. +15 condition, capped at 80, at most four repairs. Cycles and stored energy remain; a dead battery returns empty.
- **Voltage tester** (`LiveWire.VoltageTester`): right-click a tile > Live Wire > Measure. It tells power yes/no (level 0), origin (1), appliance consumption (2), network balance (4).

**Battery testing and salvage:** test a battery in inventory at Electrical 1/3/5 for increasingly detailed readings. Salvage dead, empty equipment at level 3 with a screwdriver for scrap and wire (plus a solar cell for a panel). Switch off the master inverter before live work; see the [safety rules](docs/wiki/en/10-electrical-skill-and-maintenance.md#electrical-safety-and-experience).

## Electrical skill

| Level | Unlocks | Continuous effect |
|---|---|---|
| 0 | Read a tester: powered or not | none |
| 1 | Voltage tester | Detailed reading of the tile |
| 2 | Power bank, low battery alarm, soundproofing kit | Battery wear −5 % |
| 3 | Solar panels, breaker, backup generator | Installation efficiency 0.85 |
| 4 | Recondition a battery | Autonomy reading |
| 5 | Inverter | none |
| 6 | Wind turbine assembly, deep-cycle battery, management computer | Battery wear −10 % |
| 7 | Water wheel crafting, load shedding | Installation efficiency 0.95 |
| 8 | Solar cells from scrap, overhaul | Repair failure halved |
| 9-10 | none | Installation efficiency 1.0; device wear −25 % |

**Experience** (always given by the server):

- Mod recipes: their XP is listed on the wiki page [Maintenance and skill](docs/wiki/en/10-electrical-skill-and-maintenance.md).
- Place a source: 10 (panel), 20 (wind turbine, water wheel).
- Place an inverter: 25.
- Connect a source or battery: 3.
- Inspect a device: 2 (once per device per day).
- Measure with the tester: 1 (once per tile per hour).
- Repair: 5 + 1 per point, max 15.
- Recondition a battery: 8.
- Reset after fixing an overload: 5 (once per hour).
- Soundproof the inverter: 3.

## Sandbox options

Page **LiveWire**.

| Option | Default | Range | Effect |
|---|---|---|---|
| `ConsumptionProfile` | Game values | Ultra-realistic 1993, Realistic 1993, Game values, Comfort | Power drawn by switched-on appliances (see [Appliance consumption](#appliance-consumption)) |
| `EquipmentLootMultiplier` | 5 | 1–20 | Live Wire equipment and solar-cell loot weights only; restart required, future rolls only |
| `PowerScale` | 1.0 | 0.1-10 | Multiplies the consumption given by the profile (1 = no change) |
| `SolarMultiplier` / `WindMultiplier` / `HydroMultiplier` | 1.0 | 0-10 | Production per source family |
| `BatteryCapacityMultiplier` | 1.0 | 0.1-10 | Battery capacity |
| `BatteryWearMultiplier` / `DeviceWearMultiplier` | 1.0 | 0-10 | Wear; 0 = none |
| `InverterNoiseRadius` | 2 | 0-10 | Radius of the hum heard by zombies; 0 = silent |
| `LinkRange` | 12 | 4-30 | Maximum cable distance |
| `PumpRange` | 15 | 5-30 | Radius around a water pump where its taps are supplied |
| `WirePerTiles` | 4 | 0-20 | Tiles per electric wire; 0 = free cabling |
| `SolarOrientation` | true | — | Direction affects solar yield: south 100%, east/west 85%, north 55% |
| `SolarDirt` | true | — | Dirt reduces solar production; rain and cleaning remove it |
| `BatteryCold` | false | — | Outside banks temporarily lose usable capacity in cold weather; energy is retained |
| `LiveWorkRisk` | true | — | Shock risk during live maintenance; switch off the master inverter |
| `StormDamage` | false | n/a | Storm and strong wind damage |
| `XPMultiplier` | 1.0 | 0-10 | Experience given by the mod |
| `SkillGates` | true | n/a | false = no level required |
| `SimulateUnloaded` | true | n/a | Keeps running with nobody nearby |
| `BackupStartPercent` / `BackupStopPercent` | 20 / 90 | 0-90 / 10-100 | Backup generator thresholds |

**Player option** (Options > Mods > Live Wire): inverter hum volume, 0-100 (0 = off).

## Multiplayer, status and installation

### Multiplayer

Production, stock, states, failures and experience are computed by the server; the client displays and sends requests that the server re-checks. Shared installations follow the vanilla safehouse rules. The software may lag up to 10 game minutes. If the server pauses when empty, the installation pauses too. Vanilla generators are unchanged; if a generator and an inverter cover the same appliances, both pay. Debug tools: `-debug` in single player, admins in multiplayer.

### Status

Version 1.6.0 was published on the Steam Workshop on 2026-10-25. Static checks and offline regression tests cover the new work; the supplied in-game screenshots confirm the equipment panels visually. Earlier single-player and Windows multiplayer campaigns cover the snapshots documented in the report; the latest changes still need a complete multiplayer pass. Linux is not validated. See the [validation report](docs/annexes/tests/validation.md). Balancing values remain starting values.

### Installation

- Subscribe on the Steam Workshop, or copy `Contents/mods/batman_LiveWire` into your `Zomboid/mods` folder.
- Optional mods: Computer Mod (Workshop 3725497089) or Laptop Mod (3798992436) for the management software disk and desktop app.

### Project Viewpoint

The Workshop item also contains the optional mod **Live Wire - Viewpoint models** (`batman_LiveWireViewpoint`): 3D models of every device, its lights, blade frames and soundproofing foam for [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528). Enable it only if you use Project Viewpoint; without it, the mod does nothing. The models are generated from the same Blender geometry as the tiles (`source/viewpoint/export_viewpoint.py`).

![Viewpoint](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint.png)
![Viewpoint](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint2.png)

*Live Wire devices seen with Project Viewpoint.*

### Licence and credits

MIT licence (see [LICENSE](LICENSE)). Original creation: no code or asset from other mods.

## For developers

- `docs/`: documentation (index `docs/README.md`): design documents in French, wiki sources in `docs/wiki/en` and `docs/wiki/fr`, images in `docs/images`.
- `tools/check_mod.py`: static checks of the mod.
- `tests/`: tests.
- `source/`: generators for tiles, sound and icon.

Repository: https://github.com/cyberbobjr/LiveWire
