*[Version française](FAQ-fr)*

# FAQ

Short answers about Live Wire (`batman_LiveWire`, Project Zomboid Build 42.21, version 0.1.2). The mod is not yet published on the Steam Workshop. Multiplayer has not been tested in game yet. For details, follow the links to the matching pages.

## Getting started

**Do I need batteries?**
No. One source and one inverter is the minimal system. Without batteries the house only runs on current production (for example three panels on a sunny day run a fridge-freezer at noon, not at night). Add a power bank to cover the night. See [Overview](Overview).

**What is the minimum setup?**
One source (solar panel 100 W, wind turbine 400 W or water wheel 120 W) and one inverter, linked by electric wire. Every powered appliance within 20 tiles and 3 floors of the inverter is then powered, with no per-appliance wiring. See [Equipment](Equipment).

**Which Electrical level do I need for what?**
Power bank, low battery alarm and soundproofing kit: level 2. Solar panel, breaker panel and backup generator: level 3. Inverter: level 5. Wind turbine, deep-cycle battery and management computer: level 6. Water wheel and load shedding: level 7. Overhaul and solar cells from scrap: level 8. Reading a tester (powered or not) needs no level. See [Maintenance and skill](Maintenance-and-Skill) and [Recipes](Recipes).

## Wiring

**What is the cable range, and what does the wire cost?**
The range is 12 tiles (sandbox `LinkRange`, 4 to 30), at most 1 floor apart. The cost is 1 electric wire (`Base.ElectricWire`) per 4 tiles of distance, rounded up, at least 1 (sandbox `WirePerTiles`, 0 = free). See [Wiring](Wiring) and [Sandbox options](Sandbox-Options).

**How do I link or unlink a device?**
Right-click the device, "Live Wire", then its name, then "Connect to an inverter" and pick the inverter (the list shows distance and wires). Or right-click the inverter and use "Connect equipment" or "Disconnect equipment". The device menu also has "Disconnect from the inverter". See [Wiring](Wiring).

**How many of each device per network?**
Any number of sources and power banks per inverter, but only one inverter per network. At most one breaker, one alarm, one management computer and one backup generator per network. See [Wiring](Wiring).

**What happens when I pick up the inverter?**
Its whole network is disconnected. Rotating it keeps the links. A picked-up source keeps its condition, but when placed again it is "Not connected" until you link it. See [Wiring](Wiring).

## Production

**How many panels does a house need?**
There is no limit; productions add up. Example for a fridge-freezer and 10 lights (about 4.1 kWh per day): 4 panels give 3.8 kWh in summer and 2.4 in winter (deficit), 6 panels plus 1 wind turbine give 6.3 and 4.3, and 1 water wheel plus 2 panels give 4.8 and 4.1. See [Production and calculations](Production-and-Calculations).

**What wind speed does the turbine need?**
It produces nothing below 10 km/h, reaches 100 % (400 W) from 45 to 85 km/h, and brakes automatically above 85 km/h. In between, 25 km/h gives about 31 W and 40 km/h about 252 W. Wind counts +15 % per floor up to the 3rd. See [Production and calculations](Production-and-Calculations).

**Where can I place the water wheel?**
On the ground floor, on a river bank, next to river water. Lakes and ponds are refused because the engine cannot tell a lake's current. It needs Electrical level 7, and it produces day and night (about 2.9 kWh per day). See [Equipment](Equipment).

**What about night, winter and snow?**
Solar panels follow a sine curve between dawn and dusk: about 0.94 kWh per summer day and 0.60 kWh in winter, and 20 % remains under full overcast. Snow stops a panel during snowfall until it melts above 0 degrees C or you use "Clear the snow". Water wheels run day and night. See [Production and calculations](Production-and-Calculations).

**How do I size my storage for the night?**
A 14 h winter night for a fridge-freezer and 10 lights needs about 2.4 kWh: roughly 4 car batteries or 2 deep-cycle batteries. A power bank counts 4 batteries. See [Production and calculations](Production-and-Calculations).

## Storage and appliances

**Do fridges keep working when I leave the area?**
Yes, as long as there is power. The server simulates every 10 game minutes even with nobody nearby (sandbox `SimulateUnloaded`). Checked in single player: a steak in a powered fridge with the player 300 tiles away for 10 game hours aged 0.083 day instead of 0.417. The power state found when the area reloads counts for the whole absence. See [Overview](Overview).

**What consumes power?**
Light 2 W, radio 10 W, television 30 W, fridge alone 80 W, stove, microwave, washer and dryer 90 W each, fridge-freezer 130 W, a stacked washer + dryer up to 1,800 W. The inverter itself uses 20 W idle. See [Production and calculations](Production-and-Calculations).

**Why did the breaker (or the inverter) trip?**
The demand of the house appliances went above 1,500 W, for example a stacked washer + dryer. With a breaker panel, the breaker trips and the inverter takes no damage; use "Reset the breaker" once the load is lower. Without a breaker, the inverter trips and loses 3 condition points; use "Reset" on it. See [Optional equipment](Optional-Equipment).

**How does the low battery alarm work?**
Below 20 % stock it sends a message to players within 30 tiles and beeps every 10 game minutes until you choose "Silence the alarm". The beacon stays lit until the stock is back above 25 %. It needs Electrical level 2. See [Optional equipment](Optional-Equipment).

**How does the backup generator work?**
A vanilla generator linked to the inverter is started by the mod under 20 % battery and stopped at 90 % (sandbox `BackupStartPercent` and `BackupStopPercent`). It supplies 1,200 W and burns 1 L of fuel per 3 kWh on top of its vanilla consumption. It stays noisy and toxic indoors, must be plugged and fuelled the vanilla way, and never starts without batteries. See [Optional equipment](Optional-Equipment).

## Software and computer

**Do I need a computer or the Computer Mod?**
No, the inverter has its own LCD screen ("Open the inverter screen", 5 pages). A computer is only needed for the management software ("Live Wire Monitor"), which adds a 48 h history and the forecast "batteries will last until sunrise". See [Inverter screen and software](Inverter-Screen-and-Software).

**How does it work with and without the Computer Mod or Laptop Mod?**
Without them, a vanilla desktop computer linked to the inverter opens the software on the mod's own computer screen. With the optional Computer Mod (Workshop 3725497089) or Laptop Mod (3798992436), the software comes on a disk and appears as a "Live Wire" app on their desktop. See [Inverter screen and software](Inverter-Screen-and-Software).

**Where do I find the disk?**
"Disk: Live Wire Management Software" is found in computer loot, and only when the Computer Mod is active: computer crates (about 7.8 % per container), university electrical desks (7.8 %), electronics store computers (2.0 %), among others. Right-click the computer with the disk and choose "Install the Live Wire software". See [Loot tables](Loot-Tables).

## Noise and zombies

**Is the inverter noisy, and can I silence it?**
It makes a hum heard only one tile around a switched-on inverter. Each player sets its volume in Options > Mods > Live Wire (0 = off). A soundproofing kit removes it entirely. See [Inverter screen and software](Inverter-Screen-and-Software).

**How does the soundproofing kit work, and does the inverter attract zombies?**
Zombies hear a running inverter within 2 tiles (sandbox `InverterNoiseRadius`, 0 = silent). The kit (level 2, "Soundproof the inverter" with a screwdriver) removes both the hum and that noise, but the inverter runs warmer and wears 25 % faster. "Remove the soundproofing" gives the kit back. See [Optional equipment](Optional-Equipment).

## Maintenance

**How fast do devices wear out?**
Per game days, roughly: solar panel -1 per 10 days, wind turbine -1 per 4, water wheel -1 per 6, inverter -1 per 5 while on (twice as fast above 80 % load), breaker -1 per 15, power bank and alarm -1 per 30. Storm damage is off by default (`StormDamage`). See [Maintenance and skill](Maintenance-and-Skill).

**How do I repair or overhaul a device?**
Repair: 1 electronics scrap + 1 electric wire, gaining 5 + your Electrical level points (up to 90), with a failure chance of max(5, 40 - 5 x level) % that loses the parts. Overhaul (level 8, 4 scrap + 2 wires) restores 100. A battery can be reconditioned at level 4 (+15 condition, cap 80). See [Maintenance and skill](Maintenance-and-Skill).

## Multiplayer and server

**Does it work on a dedicated server?**
It is designed for it: production, stock, states, failures and experience are computed by the server, which re-checks every client request. **Multiplayer has not been tested in game yet**, only single player. See [Multiplayer and FAQ](Multiplayer-and-FAQ).

**What are the Workshop ID and Mod ID?**
The Mod ID is `batman_LiveWire`. The mod is not yet published on the Steam Workshop, so there is no Workshop ID yet; until then, copy `Contents/mods/batman_LiveWire` into `Zomboid/mods`. See [Multiplayer and FAQ](Multiplayer-and-FAQ).

**Which sandbox options matter for a server?**
Page "Live Wire": `PowerScale`, source multipliers (`SolarMultiplier`, `WindMultiplier`, `HydroMultiplier`), `BatteryCapacityMultiplier`, wear multipliers, `LinkRange`, `WirePerTiles`, `SkillGates` and `SimulateUnloaded` (default on). If the server pauses when empty, the installation pauses too. See [Sandbox options](Sandbox-Options).

**Who can use an installation, and does it lag?**
Shared installations follow the vanilla safehouse rules. The software may lag up to 10 game minutes. Vanilla generators are unchanged: if a generator and an inverter cover the same appliances, both pay. See [Multiplayer and FAQ](Multiplayer-and-FAQ).

## Compatibility

**Can I use it with other energy mods?**
Other energy mods are not supported together with Live Wire. Live Wire is an original creation: no code or asset was taken from any other mod, and the tiles are geometric placeholders for now. The only optional links are the Computer Mod and the Laptop Mod. See [Overview](Overview).

## Troubleshooting

**A device says "Not connected".**
It is not linked to an inverter. Right-click it, "Live Wire", then "Connect to an inverter". The inverter must be within cable range (12 tiles by default, 1 floor apart at most). A source placed again after pick-up must be linked again. See [Wiring](Wiring).

**Everything is linked but nothing is powered.**
Check that the inverter is on ("Turn on") and not tripped ("Reset"), that appliances are within 20 tiles and 3 floors (use "Show the powered area"), and that a source is actually producing (night, no wind, snow). The inverter screen shows production, load and status. See [Inverter screen and software](Inverter-Screen-and-Software).

**The tile does not appear when I place it.**
The furniture cursor refuses squares that break the placement rules and shows the reason in red in the cursor panel: outdoors with open sky for solar panel and wind turbine, river bank on the ground floor for the water wheel, a north or west wall for the breaker panel. You also need a screwdriver and the required Electrical level. See [Equipment](Equipment).
