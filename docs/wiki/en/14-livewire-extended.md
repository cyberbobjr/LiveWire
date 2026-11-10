> Version française : [LiveWire Extended](../fr/14-livewire-extended.md)

# LiveWire Extended (optional add-on)

**LiveWire Extended** (`batman_LiveWireExtended`) is an optional mod shipped with LiveWire. It needs LiveWire. **With it, an inverter has no radius anymore**: it only powers what you connect to it, a building (with **Connect the building**, or the building of a breaker board you link) and the zones of outdoor power terminals. Without it, LiveWire works exactly as before, with its radius.

## Connect a whole building

Right-click an inverter > **LiveWire Extended** > **Connect the building** (Electrical 3, no tool, no wire). The building the inverter stands in is connected; an inverter placed outside connects the nearest building within its generator range (20 squares by default). Every floor gets power, the basement too, plus the rest of the 8 x 8 blocks it covers: the game powers whole blocks. A sandbox option adds an outdoor strip around the ground floor (0 to 8 squares, 0 by default).

- The game powers whole blocks of 8 x 8 squares: neighbouring squares of the same blocks get power too (a garden path, part of the next yard).
- A building is connected to one inverter at most. **Disconnect the building** in the same menu.
- The connected appliances are billed by the inverter like the others: consumption, breaker and battery work as usual. When two inverters reach the same appliance, the nearest switched-on one pays for it.

## Outdoor power terminal

The **power terminal** (recipe at Electrical 3, also found with electricians' gear) brings power outdoors: a vegetable garden, a workshop, a player-built house.

1. Place it anywhere with the furniture cursor (no level needed); pick it up with a screwdriver.
2. Right-click it > **LiveWire Extended** > **Link to an inverter**: same cable rules as the other devices (within cable range, one electric wire per 4 squares, Electrical 3). Its own 8 x 8 block gets power at once.
3. **Set the zone**: click and drag on the ground. The zone is rounded to whole blocks (the outline shows what will really get power: green when allowed, red otherwise), at most 2 x 2 blocks (16 x 16 squares), next to the terminal, on its floor and the floors around it.
4. A linked terminal placed inside a building, or right against it, can also **Connect the building**: a distant garage gets power through it.

Unlinking or picking up the terminal removes its zone and the building it connected. Outdoors, the game's "generator outdoors" option still decides whether outdoor squares can be powered.

## Breaker boards

A **breaker board** (8, 16 or 24 modules) hangs on a wall. Craft one (Electrical 3), place it with the furniture cursor and link it to an inverter with electric wire, like a terminal. Then:

- **Install breakers** with a screwdriver: 15 A, 20 A or 30 A, one module each. Each one is an item you find (electricians, hardware stores, garages) or craft (Electrical 3, more parts for a higher rating).
- **Wire an appliance** to a breaker, from the appliance (right-click > LiveWire Extended > Wire to a breaker board) or from the board (Wire an appliance). It takes wire for the distance, a screwdriver, a voltage tester (kept) and Electrical 3, and gives 5 XP. The wiring options sit in the object's own menu when the game gives it one (Light Switch >, Dark Wall Lamp >, oven), otherwise under LiveWire Extended. A multi-tile appliance counts once; a room and its wall switches form one lighting point; a terminal wired to a breaker brings its whole zone with it.
- **Once a board serves a building, every appliance of that building that is wired to no breaker has no current.** Without a board, nothing changes.
- Each breaker **trips on its own** when its circuit draws more than its rating (W = A x V); reset it on the board. With the default consumption profile (the game's own values) a breaker almost never trips; it protects with the realistic profiles.
- **Open the board** to see each breaker: lever, label, load in W and A, energy today, yesterday and over 7 days, and **Locate** to light up its appliances. Write a label with a pen or a pencil. The inverter software lists the energy of each breaker on its House tab.
- A **twilight switch** fitted on a breaker keeps its circuit on only between dusk and dawn: garden lights, porch lamps.
- **Houses of the map**: a house with its own electrical box (often on its facade) always has it as its board; other buildings get a board on a bare wall (garage first, then a utility room, then the entrance) in 30 % of cases by default (sandbox option). It does nothing until you link it to an inverter; then it comes prewired, one breaker per room and a 30 A breaker of their own for the stove and the dryer, without labels: find out which breaker feeds what.
- My Tailor Is Rich's electric sewing machine and Functional Appliances 2's machines follow their breaker too; so do LiveWire's water pump and management computer.

## On the inverter

**Show the powered area** draws the outline of every block the inverter powers (its buildings and terminal zones) on your floor. Page 4 of the inverter screen lists the connected buildings and terminals.

## Removing the add-on

With breaker boards in use, an admin first opens a board's menu and chooses **Admin: switch every breaker back on (before removing the mod)**: no breaker cuts anymore and every appliance gets back its normal state (fridges cool again, Functional Appliances 2 machines get their setting back). Then untick the add-on in the mod list: LiveWire goes back to its circle the next time the area loads, with no leftover power. Nothing is lost in LiveWire's own data. The same menu resumes the boards if you change your mind.

Not compatible with LG Extended Electricity, which changes the generator range LiveWire relies on, nor with Knox Power, which puts its own breaker system in houses.
