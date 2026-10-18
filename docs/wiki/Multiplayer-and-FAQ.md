> Version francaise : [[Multijoueur et FAQ|Multijoueur-et-FAQ]]

# Multiplayer and FAQ

## Multiplayer

Production, stock, states, failures and experience are computed by the **server**. The client displays and sends requests, which the server re-checks.

- Shared installations follow the vanilla safehouse rules.
- The software may lag up to 10 game minutes.
- If the server pauses when empty, the installation pauses too.
- Vanilla generators are unchanged. If a generator and an inverter cover the same appliances, both pay.
- Debug tools: `-debug` in single player, admins in multiplayer.

## Status

Version 1.3.0. Tested in game in single player during development: placement, container, linking, lights, breaker, alarm, LCD screen, software, powered area, rotation, pick-up, fridge while away, and the Computer Mod integration. **Multiplayer has not been tested in game yet.** Balancing values are starting values.

## FAQ

**How many solar panels can I connect?**
There is no limit. Productions add up (100 W nominal each). The 1,500 W limit applies to the house demand, not to production. See [[Production and Calculations|Production-and-Calculations]].

**Why did my breaker (or inverter) trip?**
The demand of the house appliances went above 1,500 W, for example a stacked washer + dryer (up to 1,800 W). Switch some appliances off, then reset. See [[Optional Equipment|Optional-Equipment]].

**Can I put the inverter indoors?**
Yes. It is not a game generator, so it produces no fumes and no toxicity indoors. It only makes a quiet hum, heard one tile around, which you can turn down in the options or remove with the soundproofing kit.

**Where do I find solar cells and panels?**
In garages, tool crates, hardware stores, mechanic and electrician storage. You can also dismantle calculators. See [[Loot Tables|Loot-Tables]].

**Do I need batteries?**
No. One source and one inverter is enough, but without batteries the house only runs on current production (a fridge-freezer on three panels at noon, not at night). Add a power bank to cover the night.

**Is my base powered while I am on an expedition?**
Yes. The server simulates every 10 game minutes even with nobody nearby (`SimulateUnloaded`), and fridges keep food cold while the area is unloaded. The power state found when the area reloads counts for the whole absence.

**The hum is too loud.**
Lower the volume in Options > Mods > Live Wire (0 = off), or fit a soundproofing kit. See [[Inverter Screen and Software|Inverter-Screen-and-Software]].

## Installation

Subscribe to the mod on the Steam Workshop (once published), or copy `Contents/mods/batman_LiveWire` into your `Zomboid/mods` folder, then enable `batman_LiveWire` (Project Zomboid Build 42.21). The Computer Mod (3725497089) and Laptop Mod (3798992436) are optional. The source code is at https://github.com/cyberbobjr/LiveWire.

## Licence

MIT (file `LICENSE` in the repository). No code or asset was taken from any other mod.

## See also

[[Overview|Overview]] - [[Sandbox Options|Sandbox-Options]] - [[Equipment|Equipment]] - [[Maintenance and Skill|Maintenance-and-Skill]]

See also: [FAQ](FAQ)
