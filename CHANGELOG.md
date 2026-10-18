# Changelog

## 1.3.0 — 2026-10-18

### Features
- Parallel inverters: couple up to 3 more inverters to a master inverter with an inverter coupling kit (new recipe, Electrical 6) and electric wire. The network's power becomes the sum of the inverters in service, up to 6,000 W, with one battery bank and one powered area. Each inverter has its own switch and wears as usual; a slave switched off or broken lowers the capacity, and the network trips if the demand is then too high. "Uncouple" makes a slave independent again and gives the kit back.
- The inverter screen and the management software show how many coupled inverters are in service and the total capacity.

### Fixes
- Two independent inverters whose powered areas overlap no longer count the same appliances twice: each appliance is counted by the nearest switched-on inverter.

## 1.2.0 — 2026-10-18

### Features
- Water pump (Electrical 6): linked to the inverter with electric wire, it moves water from water barrels into the house taps, on any floor and with no player nearby. Barrels are vanilla rain collectors or the barrels of the optional mod Useful Barrels; each one is connected with one iron pipe and must stand next to the pump (one of its 8 neighbouring squares, same floor); up to 8 barrels per pump. Only water is moved; rain keeps filling the barrels as before.
- Invisible relay tanks (25 L) are placed above the plumbed sinks, baths, showers and toilets within 15 tiles of the pump (new sandbox option `PumpRange`, 5-30) and up to 3 floors up or down. Vanilla plumbing takes its water from them, so the taps are connected with the pipe wrench as usual.
- The pump draws 250 W only while pumping (5 L per game minute at most) and stops when every tap is full. A light motor hum is heard within 4.5 tiles while it runs; zombies hear it within 2 tiles.
- "Show the supplied taps" on the pump: a blue circle for the range and a blue highlight on the supplied taps, the connected barrels and the pump. A blue light shows on the pump while it supplies at least one tap.
- The management software shows the number of pumps in service and their flow.
- Debug and administrator action "Remove every water relay", to run before removing the mod.
- Translations in English, French and the other languages of the mod.
- The poster and the Workshop preview show the water pump and a water barrel.

## 1.1.0 — 2026-10-18

### Features
- Optional mod "Live Wire - Viewpoint models" in the same item: 3D models of every Live Wire device, its lights, the wind turbine blades and the soundproofing foam for Project Viewpoint. Enable it only if you use Project Viewpoint.

## 1.0.1 — 2026-10-17

### Fixes
- Fridges and freezers now age correctly when the batteries run empty, or power comes back, while you are away.
- Clear messages when a device is too far from the inverter or too many floors apart, with the distance.
- A Live Wire device placed without being registered (conflict with another furniture mod) is now detected and registered.
- Smoother game: devices are no longer searched by a large scan every 3 seconds, and the appliance list is rebuilt in small steps.
- Backup generator: a message says why it cannot start (not connected, out of fuel, broken), and its fuel is no longer counted twice.

## 1.0.0 — 2026-10-17

### Features
- Silent power from solar panels, wind turbines and water wheels, with no fuel and no fumes.
- An inverter that you can place anywhere, indoors included, to power every appliance within 20 tiles and up to 3 floors.
- Several sources per inverter, each linked with electric wire within 12 tiles.
- Power banks that store the surplus for the night, holding up to 4 car or deep-cycle batteries.
- Optional breaker panel that trips instead of the inverter when the house draws too much power.
- Optional low battery alarm that warns nearby players when the stock runs low.
- Optional backup generator and management computer, using the vanilla objects.
- An inverter screen with five pages (production, batteries, sources, house, status) and a power and load display.
- Management software "Live Wire Monitor" with overview, batteries, sources, house, 48-hour history with forecast, and equipment tabs.
- Works on a vanilla computer, and inside the Computer Mod or Laptop Mod with a software disk.
- Fridges and freezers stay cold while you are away, as long as the house has power.
- Electrical skill from level 0 to 10, with experience, wear, repairs and an overhaul.
- A voltage tester to check whether a spot has power, where the power comes from and how much is used.

### Equipment and recipes
- Solar cells from calculators and from scrap, to build solar panels.
- Crafting for every device and battery, learnt automatically as your Electrical level rises.
- Ready-made Live Wire equipment found in electrician and hardware-store loot, garages, wire factories and car parts stores.

### Noise
- The inverter hums quietly, heard one tile around when switched on; each player sets its volume in Options > Mods > Live Wire.
- A soundproofing kit covers the inverter in acoustic foam: no hum, zombies no longer hear it, and it is shown as "Soundproofed" when inspected and on its screen.

### Multiplayer
- Production, storage, failures and experience run on the server and keep going while players are away.
- Shared installations follow the vanilla safehouse rules.

### Sandbox options
- Adjust power scale, production per source type, battery capacity and wear, zombie hearing range, cable range, cable cost, experience and the backup generator thresholds.

### Translations
- English, French, German, Spanish, Portuguese, Brazilian Portuguese, Russian, Simplified Chinese, Japanese and Korean.
