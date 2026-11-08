> Version française : [LiveWire Extended](../fr/14-livewire-extended.md)

# LiveWire Extended (optional add-on)

**LiveWire Extended** (`batman_LiveWireExtended`) is an optional mod shipped with Live Wire. It needs Live Wire and adds two ways to carry power beyond the inverter's circle. Without it, Live Wire works exactly as before.

## Connect a whole building

Right-click an inverter > **LiveWire Extended** > **Connect the building** (Electrical 3, no tool, no wire). The building the inverter stands in is connected; an inverter placed outside connects the nearest building its circle reaches. Every floor gets power, the basement too, plus a strip of 1 square around the ground floor (sandbox option, 0 to 8).

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

## On the inverter

**Show range** draws the circle and the outline of every block added by buildings and terminals on your floor. Page 4 of the inverter screen lists the connected buildings and terminals.

## Removing the add-on

Untick it in the mod list at any time: Live Wire goes back to its circle the next time the area loads, with no leftover power. Nothing is lost in Live Wire's own data.

Not compatible with LG Extended Electricity, which changes the generator range Live Wire relies on.
