# Changelog

## Unreleased

### Fixes
- Fixed fridges, freezers and other appliances losing power at random while the inverter still had plenty of power, until the inverter or the breaker panel was switched off and on again. It happened when the game loaded part of the map diagonally near the base, more often with a vanilla generator nearby (for example a backup generator).

### Improvements
- The backup generator now tells you when it switches to manual control. Switching it on or off yourself still hands it over to you, but a message now appears next to it, and the inverter screen and the management software show how to give control back: right-click the generator > Live Wire > Backup generator > Resume automatic backup. A confirmation appears when automatic control resumes.

## 1.7.2 — 2026-11-07

### Improvements
- Placing a device no longer needs any Electrical level: anyone can carry, place and rotate solar panels, inverters, wind turbines and the rest. Picking one up only needs a screwdriver.
- The Electrical level is now needed to **link** a device to an inverter: solar panel, breaker panel and water pump at 3; wind turbine, water wheel, power bank and battery alarm at 2. The first link made to an inverter puts it in service and needs level 3; after that, a level 2 electrician can add level 2 devices to it.
- Installation efficiency and battery wear now depend on whoever links the device, not on who placed it. A better electrician re-linking a device improves it; a weaker one never lowers it.
- A device's Electrical experience is now given once, at its first link, instead of each time it is placed.
- Linking a water barrel to the pump no longer needs an Electrical level: it is plumbing.
- The sandbox option that disables level requirements now also covers these links.

## 1.7.1 — 2026-11-06

### Fixes
- Fixed the wind turbine weighing only 0.5 once picked up or crafted. It now weighs 15.

### Improvements
- Reworked equipment weights for realism: nothing weighs less than the parts used to build it. Water wheel 30 (was 15), inverter cabinet 30 (was 20), deep-cycle battery 12 (was 9), soundproofing kit 13 (was 3), wind turbine mast 4.6, blades 4.1, coupling kit 0.7, voltage tester 0.6, solar cell 0.1.

## 1.7.0 — 2026-11-05

### New features
- New **inverter cabinet**: a full-height 4,500 W inverter (60 W idle) built from an ordinary inverter at Electrical level 3 (recipe "Build Inverter Cabinet"). It works like the inverter (screen, running and fault lights, soundproofing, wear) and can be coupled with inverters or other cabinets; the network capacity is the sum of the inverters in service. Model contributed by PewPewCricket.

### Fixes
- Fixed an occasional error `IndexOutOfBoundsException: Index: 0 Size: 0` in `LW_Circuits.lua` when moving away from a base, for example by car. Live Wire now drops its pending work on an area as soon as the game unloads it. When the area loads again, every appliance in it is checked again from the start, so none is missed.
- Fixed breaker switches taking effect late just after arriving at a base or loading a save. Turning a circuit off or on could wait ten seconds or more while Live Wire checked the newly loaded area, and the inverter showed the old consumption meanwhile. Breaker commands now go first and take effect within a fraction of a second.
- Fixed switching the inverter, the breaker panel or other network controls repeatedly making time run faster for the network: each action added a full game minute of production, battery charge, wear and generator fuel. Actions now only update the network state.
- Fixed resetting a tripped inverter or wall breaker while water pumps were running: the reset was accepted, then tripped again at once and cost the inverter condition. The pumps now count in the reset check, and switching a tripped inverter off then on again no longer skips it.
- Fixed a coupled inverter cabinet wearing at the rate of the main inverter's model instead of its own.
- Fixed a water pump turning all the water it moves into tainted water when its barrel held only a trace of it. The relay now gets the barrel's own proportion.
- A device destroyed outside Live Wire's own actions is now removed after two checks instead of one, so a single missed lookup can no longer delete it and its connections. One faulty device no longer stops the update of the other networks.
- Fixed water poured into a barrel linked to a water pump seeming to disappear while the pump showed 0 L/h. The pump only filled its hidden tanks for every sink, shower and toilet in range, plumbed or not, including the neighbours' houses. It now only supplies the fixtures you have plumbed with a pipe wrench, and a newly plumbed fixture gets water within a game minute.

### Improvements
- Lower Electrical requirements: everything you build, place or connect now needs at most Electrical level 3. Inverter kit, inverter cabinet, wind turbine assembly, water pump, inverter coupling kit, deep-cycle battery and solar cells from scrap are now crafted at level 3; inverters, inverter cabinets and water pumps are placed at level 3; coupling inverters and overhauling a device need level 3; connecting a backup generator needs level 2. The water wheel is crafted at level 4.
- The management computer's automatic load shedding is a software feature: it no longer requires any Electrical level, any connected computer turns the lights off when the batteries run low.
- Inverters and water pumps now use quiet native game sounds, with the game's spatial audio and sound-effects volume. Soundproofing and the Live Wire volume setting are preserved. Removed the separate per-frame hum handler; the alarm beep is only monitored while it is playing.
- Ready-made equipment is easier to find in house garages. Mechanic shelves can now hold a voltage tester, an inverter, a breaker panel, a low battery alarm or a solar panel, in addition to deep-cycle batteries and power banks. Metalwork shelves can now hold a voltage tester, a breaker panel, a wind turbine, blades and a mast, in addition to solar cells, and solar panels are more common there.
- Electrician vehicles (including the electrical company vans) can now carry Live Wire equipment: voltage testers, solar cells and panels, breaker panels, alarms, inverters and power banks in the truck bed or trunk, and a voltage tester in the glove box or on the passenger seat. Metalworker vehicles can carry blades, masts, wind turbines and solar panels. As with any loot change, only containers and vehicles not yet generated benefit: explore new areas.
- Wind turbines are now useful in ordinary Zomboid weather. They produce from 10 km/h (about 15 W) and reach full power at 30 km/h instead of 45: about 50 W at 15 km/h and 230 W at 25 km/h, where they used to show 0 to 30 W.
- Turbine blades now turn exactly when the turbine produces: they count the height bonus (+15% wind per floor, up to the 3rd) and stop above 85 km/h.
- Show the supplied taps now highlights in grey the fixtures in range that are not plumbed yet, so you can see which ones still need the pipe wrench.

## 1.6.4 — 2026-10-28

### Fixes
- Fixed refrigerated food spoiling when coming back to a base, especially by car, alongside a mod that spreads map loading over several frames, such as Let Me Drive!. The whole time away could be counted as unrefrigerated and rot everything in the fridges and freezers at once. Live Wire now restores its power coverage and updates the food as the map loads, whatever other mods are installed.

## 1.6.3 — 2026-10-27

### Fixes
- Applying or releasing a wind turbine brake no longer requires an Electrical level. The brake is a mechanical lever, like inspecting a device, clearing snow or cleaning a panel, none of which ever needed a level.
- Turbines left braked by a version older than 1.5.0, where inspecting a turbine applied its brake, can now be released by any character.

## 1.6.2 — 2026-10-27

### Wiring
- Cables now reach up to 3 floors above or below the inverter by default, allowing rooftop sources and backup generators to connect to an inverter downstairs.
- Added the Cable vertical range sandbox option (0-10 floors). It applies to equipment connections and inverter coupling; 0 restricts new connections to the same floor.

## 1.6.1 — 2026-10-25

### Fixes
- Fixed an error when switching portable radios or vehicle radios on or off.
- The electrical panel now ignores inventory items, vehicle equipment and other unrelated objects. Placed mains appliances still follow their circuit switches.
- Transferring or filling fluids from inventory items keeps its normal behaviour.

## 1.6.0 — 2026-10-25

### Electrical panels and equipment screens
- The breaker is now an electrical panel with separate lighting and equipment circuits, a main lever and an instant wattmeter for each circuit and the total. Opening the main lever stops distribution while sources can keep charging batteries.
- Circuit switches control real appliances: mains lighting, refrigerators/freezers, TVs, radios, cooking appliances, washing machines, dryers, battery chargers and fuel pumps. Water pumps stop refilling their relays. Previous on/off choices survive saves and restarts; battery-powered devices remain independent.
- Left-click nearby equipment to open its own screen. Power banks show usable charge, capacity, cold reserve and individual batteries; sources show production and condition; pumps show flow and consumption; alarms show their state. A Connections button opens the shared wiring window.
- Stack two power banks on one tile, with separate inventories, connections and condition. Empty a bank before picking it up; remove the upper one first.
- Breakers now have a green powered-distribution indicator, including a matching Viewpoint model. Pump lights remain blue whenever powered, even while idle.

### Network monitoring and production
- Show consumers as coloured silhouettes in the world and list their measured watts in the software (up to 200 entries). Show cable links, including dashed links between floors.
- The management software adds the last 30 timestamped network events and a three-day weather-based production forecast with a powered management computer. Forecasts account for source condition, solar orientation, dirt, snow and wind brakes; future maintenance and failures remain uncertain.
- Network names appear on the LCD, inspections and low-battery warnings. Strong-wind warnings and blinking turbine indicators make storm braking easier to spot.
- Solar panels now use their direction: south 100%, east/west 85% with earlier/later output, north 55%. Dirt accumulates faster in autumn; rain washes panels. Clean them with a rag and 0.5 L of water.
- Optional cold effects on outdoor battery banks reduce accessible capacity by 20% at 0°C and 40% at −15°C. Stored energy is preserved as a reserve and becomes available again as the bank warms. Indoor banks are unaffected; BatteryCold is off by default.

### Maintenance and electrical safety
- Test inventory batteries: Electrical 1 shows charge, 3 adds energy/capacity/condition and 5 adds cycles and estimated remaining life.
- Battery reconditioning requires Electrical 4 (6 for a dead battery), a kept screwdriver, one electronics scrap, one wire and 0.5 L water. It restores 15 condition up to 80, at most four times. Cycles and stored energy are preserved; a dead battery returns empty.
- Salvage dead, empty equipment at Electrical 3 with a screwdriver for one electronics scrap and one wire; a solar panel also returns one solar cell.
- Live maintenance risk is enabled by default: connecting, disconnecting, repairing or salvaging connected equipment can burn the screwdriver hand, drop held items and stop the action before materials are spent. Risk at Electrical levels 0/1/2/3/4/5/6+: 50/42/33/25/17/8/0%.
- Switch off the master inverter before working. An open main breaker, overload trip, fault or empty battery does not isolate its terminals. Existing worlds keep explicitly saved sandbox choices.
- Successful equipment repairs and overhauls consistently award Electrical XP.

### Crafting and loot
- Build wind turbines in three stages: blade set, mast, then final assembly at Electrical 6. Blades and masts need no Electrical level and each award 2 Electrical XP. Place or pick up a completed turbine or water wheel at level 2; water-wheel crafting remains level 7.
- Turbine and water-wheel recipes use two amplifiers instead of speakers; the mast uses a metal pipe. Dismantle a Live Wire voltage tester with a kept screwdriver for one electronics scrap and 2 Electrical XP. Every Live Wire recipe now awards Electrical XP.
- Updated all 17 recipe entries, English/French recipe tables and illustrated recipe boards in all ten languages. Crafted equipment shows its correct result icon.
- Broader technical, farming and carpentry loot locations include ready-made turbines, water wheels, blades and masts. EquipmentLootMultiplier defaults to 5 (range 1–20), affects only Live Wire equipment and parts, and requires a restart. Only future loot rolls change.

### Reliability and performance
- Optimisations help limit brief pauses around large electrical installations, especially when exploring or switching circuits.
- Appliances more reliably return to their previous on/off settings after changing connections, removing an inverter or returning to an area.
- In multiplayer, fixes help prevent appliances from showing the wrong power state when entering an area or reconnecting.
- The management software does less background work, especially on networks with many appliances.
- Battery charge and equipment wear keep their small gradual changes, improving accuracy over time.

### Other improvements
- New tools let mod authors add compatible batteries and power sources, and read network information.
- Updated the English/French guides, all ten Steam descriptions and screenshots. The Connections button fits inside the electrical panel.

### Updating
- Existing equipment identifiers and saved network data are retained. SolarOrientation, SolarDirt and LiveWorkRisk default to on; BatteryCold defaults to off. Explicit saved choices take precedence.
- Close the lighting and equipment circuits before disabling Live Wire, so appliances recover their original services.

## 1.5.0 — 2026-10-24

### Fixes
- Water relays survive saves and reloads, retain their water when reassigned to the nearest eligible pump, and are removed correctly when disabled, including in unloaded areas.
- Moved barrels can reconnect to pumps. Idle pumps no longer build up excess flow for the next transfer.
- Backup generators respect manual starts and stops. Automatic backup can be resumed explicitly; invalid start/stop thresholds keep a safe gap.
- Inspecting a wind turbine no longer applies its brake. Electrical level 7 can apply or release the brake explicitly; it follows the turbine when picked up. Inspection and snow clearing respect safehouse permissions.
- Batteries supply power until their energy actually runs out, with the correct cut time and discharge wear.
- Fridges replay power changes from a history retained for 60 game days. Existing saves keep the history available at upgrade; older missing history cannot be recovered.
- Missing device marks are restored from saved records, avoiding duplicate adoption or accidental deletion. Voltage-tester XP limits survive reconnects and server restarts.
- Networks can be renamed from the inverter menu or management software. Software controls consistently check distance, power and safehouse permissions.
- A maintenance error on one pump no longer prevents the others from being maintained; runtime and package versions now agree.

### Performance
- Pump discovery and the supplied-taps list are processed in bounded batches, with cached fixture positions.
- Fridge power updates and chunk loading use device indexes; client visual refreshes are spread across frames.
- Solo interface snapshots are reused until the network changes. Expired command and XP cooldown records are cleaned up regularly.

## 1.4.0 — 2026-10-22

### New features
- Consumption profile (sandbox option, Live Wire page): choose how much power switched-on appliances draw. "Game values" (default) keeps the current behaviour. "Realistic 1993" uses typical household draws of the time (light 60 W, TV 80 W, fridge-freezer 130 W, electric cooker 2,000 W, dryer 3,000 W). "Ultra-realistic 1993" uses older, hungrier appliances. "Comfort" halves the game values. The voltage tester shows the draw of the chosen profile.

## 1.3.2 — 2026-10-21

### Fixes
- Management software: the Switch on, Switch off and Reset buttons now work from the linked computer, even when the inverter is several tiles away or on another floor; in multiplayer the software no longer stays on "waiting" when the computer is on another floor than the inverter.
- "Remove every water relay" now really removes them: the pumps stop until "Enable the water pumps again", so the tanks are not placed back, and tanks in areas that are not loaded are removed when the area loads.
- Inverter screen and computer start-up text: readable in Chinese, Japanese and Korean (the LCD font has no glyphs for these languages).
- Water pump: the tanks and barrels it fills are synchronised less often, which avoids frequent lighting recalculations near a running pump in multiplayer.

## 1.3.1 — 2026-10-18

### Improvements
- Live Wire - Viewpoint models: 3D model of the water pump and of its blue light for Project Viewpoint.

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
