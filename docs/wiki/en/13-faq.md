> Version française : [FAQ](../fr/13-faq.md)

# FAQ

Short answers about Live Wire (`batman_LiveWire`, Project Zomboid Build 42.21, version 1.6.0). The mod is published on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3821807453). See [Multiplayer](12-multiplayer.md#status) for the validation scope of this update. For details, follow the links to the matching pages.

## Getting started

**Do I need batteries?**
No. One source and one inverter is the minimal system. Without batteries the house only runs on current production (for example three panels on a sunny day run a fridge-freezer at noon, not at night). Add a power bank to cover the night. See [Getting started](01-getting-started.md).

**What is the minimum setup?**
One source (solar panel 100 W, wind turbine 400 W or water wheel 120 W) and one inverter, linked by electric wire. Every powered appliance within 20 tiles and 3 floors of the inverter is then powered, with no per-appliance wiring. See [Equipment](02-equipment.md).

**Which Electrical level do I need for what?**
Power bank, low battery alarm and soundproofing kit: level 2. Solar panel, breaker panel and backup generator: level 3. Inverter: level 5. Place/pick up wind turbines and water wheels: level 2. Final turbine assembly, deep-cycle battery and management computer: level 6. Water-wheel crafting and load shedding: level 7. Overhaul and solar cells from scrap: level 8. Reading a tester (powered or not) needs no level. See [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) and [Recipes](08-recipes.md).

## Wiring

**What is the cable range, and what does the wire cost?**
The range is 12 tiles horizontally (sandbox `LinkRange`, 4 to 30), at most 3 floors apart by default (sandbox `LinkVerticalRange`, 0 to 10; 0 = same floor). The cost is 1 electric wire (`Base.ElectricWire`) per 4 tiles of horizontal distance, rounded up, at least 1 (sandbox `WirePerTiles`, 0 = free). See [Wiring](03-wiring.md) and [Sandbox options](11-sandbox-options.md).

**How do I link or unlink a device?**
Right-click the device, "Live Wire", then its name, then "Connect to an inverter" and pick the inverter (the list shows distance and wires). Or right-click the inverter and use "Connect equipment" or "Disconnect equipment". The device menu also has "Disconnect from the inverter". See [Wiring](03-wiring.md).

**How many of each device per network?**
Any number of sources and power banks per inverter, with up to four coupled inverters per network. At most one breaker, one alarm, one management computer and one backup generator per network. See [Wiring](03-wiring.md).

**What happens when I pick up the inverter?**
Its whole network is disconnected. Rotating it keeps the links. A picked-up source keeps its condition, but when placed again it is "Not connected" until you link it. See [Wiring](03-wiring.md).

## Production

**How many panels does a house need?**
There is no limit; productions add up. A reference day (fridge-freezer, 10 lights for 6 h, TV for 3 h) needs about 3.8 kWh with the game values and 7.4 kWh with Realistic 1993. In winter, 6 panels plus 1 wind turbine give about 4.3 kWh (enough for the game values), and 1 water wheel plus 8 panels about 7.7 kWh (enough for Realistic 1993). See [Production and calculations](04-production-and-calculations.md#sizing-example).

**What wind speed does the turbine need?**
It produces nothing below 10 km/h, reaches 100 % (400 W) from 45 to 85 km/h, and brakes automatically above 85 km/h. In between, 25 km/h gives about 31 W and 40 km/h about 252 W. Wind counts +15 % per floor up to the 3rd. See [Production and calculations](04-production-and-calculations.md).

**Where can I place the water wheel?**
On the ground floor, on a river bank, next to river water. Lakes and ponds are refused because the engine cannot tell a lake's current. It needs Electrical level 7, and it produces day and night (about 2.9 kWh per day). See [Equipment](02-equipment.md).

**What about night, winter and snow?**
Solar panels follow a sine curve between dawn and dusk: about 0.94 kWh per summer day and 0.60 kWh in winter, and 20 % remains under full overcast. Snow stops a panel during snowfall until it melts above 0 degrees C or you use "Clear the snow". Water wheels run day and night. See [Production and calculations](04-production-and-calculations.md).

**How do I size my storage for the night?**
A 14 h winter night for a fridge-freezer and 10 lights needs about 2.4 kWh: roughly 4 car batteries or 2 deep-cycle batteries. A power bank counts 4 batteries. See [Production and calculations](04-production-and-calculations.md).

## Storage and appliances

**Do fridges keep working when I leave the area?**
Yes, as long as there is power. The server simulates every 10 game minutes even with nobody nearby (sandbox `SimulateUnloaded`). Checked in single player: a steak in a powered fridge with the player 300 tiles away for 10 game hours aged 0.083 day instead of 0.417. Catch-up replays power changes retained for 60 game days; older missing history cannot be recovered. See [Getting started](01-getting-started.md).

**What consumes power?**
It depends on the sandbox `ConsumptionProfile`. With the default game values: light 2 W, radio 10 W, television 30 W, fridge alone 80 W, stove, microwave, washer and dryer 90 W each, fridge-freezer 130 W, a stacked washer + dryer up to 1,800 W. With Realistic 1993: light 60 W, television 80 W, fridge-freezer 130 W, electric cooker 2,000 W, dryer 3,000 W. The inverter itself uses 20 W idle. See [Production and calculations](04-production-and-calculations.md#appliance-consumption).

**Why did the breaker (or the inverter) trip?**
The demand of the house appliances went above 1,500 W, for example a stacked washer + dryer. With a breaker panel, the breaker trips and the inverter takes no damage; use "Reset the breaker" once the load is lower. Without a breaker, the inverter trips and loses 3 condition points; use "Reset" on it. See [Optional equipment](06-optional-equipment.md).

**1,500 W is not enough. Can I combine several inverters?**
Yes: couple them. Place a second inverter with no equipment connected, right-click it, "Live Wire", then "Couple to an inverter", and pick the master inverter within cable range. It costs the electric wire for the distance and 1 Inverter Coupling Kit (recipe at Electrical level 6). A master takes up to 3 slaves, so 4 inverters give 6,000 W on one network, with one battery bank and the master's powered area. Each inverter switched on uses 20 W idle and wears as usual; a slave switched off or broken no longer counts. "Uncouple" on the slave gives the kit back. See [Optional equipment](06-optional-equipment.md#parallel-inverters-coupling).

**How does the low battery alarm work?**
Below 20 % stock it sends a message to players within 30 tiles and beeps every 10 game minutes until you choose "Silence the alarm". The beacon stays lit until the stock is back above 25 %. It needs Electrical level 2. See [Optional equipment](06-optional-equipment.md).

**How does the backup generator work?**
A vanilla generator linked to the inverter is started by the mod under 20 % battery and stopped at 90 % (sandbox `BackupStartPercent` and `BackupStopPercent`). It supplies 1,200 W and burns 1 L of fuel per 3 kWh on top of its vanilla consumption. It stays noisy and toxic indoors, must be plugged and fuelled the vanilla way, and never starts without batteries. See [Optional equipment](06-optional-equipment.md).

## Software and computer

**Do I need a computer or the Computer Mod?**
No, the inverter has its own LCD screen ("Open the inverter screen", 5 pages). A computer is only needed for the management software ("Live Wire Monitor"), which adds a 48 h history and the forecast "batteries will last until sunrise". See [Inverter screen and software](05-inverter-screen-and-software.md).

**How does it work with and without the Computer Mod or Laptop Mod?**
Without them, a vanilla desktop computer linked to the inverter opens the software on the mod's own computer screen. With the optional Computer Mod (Workshop 3725497089) or Laptop Mod (3798992436), the software comes on a disk and appears as a "Live Wire" app on their desktop. See [Inverter screen and software](05-inverter-screen-and-software.md).

**Where do I find the disk?**
"Disk: Live Wire Management Software" is found in computer loot, when Computer Mod or Laptop Mod is active: computer crates (about 7.8 % per container), university electrical desks (7.8 %), electronics store computers (2.0 %), among others. Right-click the computer with the disk and choose "Install the Live Wire software". See [Loot tables](09-loot-tables.md).

## Noise and zombies

**Is the inverter noisy, and can I silence it?**
It makes a hum heard only one tile around a switched-on inverter. Each player sets its volume in Options > Mods > Live Wire (0 = off). A soundproofing kit removes it entirely. See [Inverter screen and software](05-inverter-screen-and-software.md).

**How does the soundproofing kit work, and does the inverter attract zombies?**
Zombies hear a running inverter within 2 tiles (sandbox `InverterNoiseRadius`, 0 = silent). The kit (level 2, "Soundproof the inverter" with a screwdriver) removes both the hum and that noise, but the inverter runs warmer and wears 25 % faster. "Remove the soundproofing" gives the kit back. See [Optional equipment](06-optional-equipment.md).

## Maintenance

**How fast do devices wear out?**
Per game days, roughly: solar panel -1 per 10 days, wind turbine -1 per 4, water wheel -1 per 6, inverter -1 per 5 while on (twice as fast above 80 % load), breaker -1 per 15, power bank and alarm -1 per 30. Storm damage is off by default (`StormDamage`). See [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md).

**How do I repair or overhaul a device?**
Repair: 1 electronics scrap + 1 electric wire, gaining 5 + your Electrical level points (up to 90), with a failure chance of max(5, 40 - 5 x level) % that loses the parts. Overhaul (level 8, 4 scrap + 2 wires) restores 100. A battery can be reconditioned at level 4 (6 when dead): kept screwdriver, scrap, wire and 0.5 L water; +15 condition, cap 80, four repairs maximum. See [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md).

## Multiplayer and server

**Does it work on a dedicated server?**
It is designed for it: production, stock, states, failures and experience are computed by the server, which re-checks every client request. Earlier in-game campaigns covered single player and a Windows dedicated server with two clients; the validation report distinguishes those snapshots from the latest changes. See [Multiplayer](12-multiplayer.md).

**What are the Workshop ID and Mod ID?**
The Mod ID is `batman_LiveWire`. The Workshop ID is `3821807453`. You can also copy `Contents/mods/batman_LiveWire` into `Zomboid/mods`. See [Getting started](01-getting-started.md#installation).

**Which sandbox options matter for a server?**
Page "Live Wire": `ConsumptionProfile` (ultra-realistic 1993, realistic 1993, game values, comfort), `PowerScale`, source multipliers (`SolarMultiplier`, `WindMultiplier`, `HydroMultiplier`), `BatteryCapacityMultiplier`, wear multipliers, `LinkRange`, `WirePerTiles`, `SkillGates` and `SimulateUnloaded` (default on). If the server pauses when empty, the installation pauses too. See [Sandbox options](11-sandbox-options.md).

**Who can use an installation, and does it lag?**
Shared installations follow the vanilla safehouse rules. The software may lag up to 10 game minutes. Vanilla generators are unchanged: if a generator and an inverter cover the same appliances, both pay. See [Multiplayer](12-multiplayer.md).

## Compatibility

**Can I use it with other energy mods?**
Other energy mods are not supported together with Live Wire. Live Wire is an original creation: no code or asset was taken from any other mod. Optional integrations include Computer Mod, Laptop Mod, Project Viewpoint and Useful Barrels. See [Getting started](01-getting-started.md).

## Troubleshooting

**A device says "Not connected".**
It is not linked to an inverter. Right-click it, "Live Wire", then "Connect to an inverter". The inverter must be within cable range (12 tiles horizontally and 3 floors apart at most by default). A source placed again after pick-up must be linked again. See [Wiring](03-wiring.md).

**Everything is linked but nothing is powered.**
Check that the inverter is on ("Turn on") and not tripped ("Reset"), that appliances are within 20 tiles and 3 floors (use "Show the powered area"), and that a source is actually producing (night, no wind, snow). The inverter screen shows production, load and status. See [Inverter screen and software](05-inverter-screen-and-software.md).

**The tile does not appear when I place it.**
The furniture cursor refuses squares that break the placement rules and shows the reason in red in the cursor panel: outdoors with open sky for solar panel and wind turbine, river bank on the ground floor for the water wheel, a north or west wall for the breaker panel. You also need a screwdriver and the required Electrical level. See [Equipment](02-equipment.md).
