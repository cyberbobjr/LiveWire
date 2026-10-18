> Version francaise : [[Pompe a eau|Pompe-a-eau]]

# Water Pump

*New in 1.2.0. Not tested in game yet: please report any problem.*

Barrels of water standing on the ground can run the taps of a whole house. An electric pump, wired to the inverter and set next to the barrels, keeps the house sinks, showers, baths and toilets supplied while the network has power.

## What you need

| Item | Detail |
|---|---|
| Water pump | Recipe at Electrical 6 (see [[Recipes|Recipes]]). Placed like any Live Wire device, indoors or outdoors. |
| Electric wire | To connect the pump to an inverter, like any device (1 wire per 4 tiles). |
| Water barrels | Vanilla rain collectors, or the barrels of the optional mod **Useful Barrels**. Up to 8 per pump. |
| Iron pipes | 1 per barrel, given back when the barrel is disconnected. |
| Pipe wrench | To plumb the sinks, showers and toilets (vanilla action). |

## Setting it up

1. Place the pump **next to the barrels**: a barrel must stand on one of the 8 squares around the pump, on the same floor (diagonals count). A pump surrounded by barrels takes up to 8.
2. Connect the pump to an inverter: right-click the pump > **Live Wire** > **Water pump** > **Connect to an inverter**.
3. Connect each barrel: right-click the pump > **Connect a barrel**, or right-click the barrel > **Water barrel** > **Pump next to this barrel (1 pipe)**.
4. Plumb the fixtures with a pipe wrench, the vanilla way (right-click the sink > **Plumb...**). The option appears once the pump supplies the fixture.

## How it works

- **Only water.** A barrel holding anything else (petrol, alcohol...), even mixed with water, is refused. An empty barrel can be connected and is used once it fills up.
- **Rain water comes out clean.** Rain collected in a barrel is tainted, but a plumbed tap gives clean water, as in vanilla.
- **Range.** The pump supplies the plumbed fixtures inside a room within **15 tiles** of it (sandbox `PumpRange`, 5-30) and up to 3 floors up or down.
- **Invisible relay tanks.** The game only looks for a water source on the floor just above a fixture. The pump therefore places a small invisible 25-litre tank above each fixture it supplies and keeps it filled from the barrels. Nothing to place by hand.
- **Flow and power.** 5 litres per game minute per pump, 250 W while pumping. The pump **stops by itself** when every tank is full: no power used, no sound.
- **Fixtures that already have water** (a vanilla barrel upstairs, mains water still running, another mod) keep it: the pump does not compete with them.
- **Several pumps** can share one network.
- **While you are away**, rain keeps filling the barrels (the game handles it). The pump only works where the area is loaded, which is where taps are used anyway.

## Seeing what is supplied

- Right-click the pump > **Show the supplied taps**: a blue circle shows the range, and the supplied fixtures, the connected barrels and the pump are highlighted in blue. **Hide the supplied taps** turns it off.
- A **blue light** shows on the pump when it supplies at least one fixture.
- The pump menu shows its state: pumping, stopped (every tap full), no power, no water in the barrels, out of order.
- The management software (Equipment tab) shows the number of pumps in service and their flow in litres per hour. Nothing else about the pump is shown there.

## Noise

A light motor hum is heard around a running pump (same volume slider as the inverter hum, Options > Mods > Live Wire). Zombies hear it within 2 tiles.

## Wear

The pump wears only while it runs (1 condition point per 10 days of pumping) and is repaired like the other devices. Out of order, it stops filling the tanks.

## Before removing the mod

Run the debug or admin action **Remove every water relay** first (right-click > Live Wire, debug mode in single player, admin in multiplayer), then save. Tanks in areas that are not loaded are removed the next time their area loads, while the mod is still installed.

## See also

[[Equipment|Equipment]] - [[Wiring|Wiring]] - [[Recipes|Recipes]] - [[Sandbox Options|Sandbox-Options]] - [[Multiplayer and FAQ|Multiplayer-and-FAQ]]
