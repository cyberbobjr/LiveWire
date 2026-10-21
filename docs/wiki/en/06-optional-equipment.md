> Version française : [Équipements optionnels](../fr/06-equipements-optionnels.md)

# Optional Equipment

These four add-ons are not required to run a network, but they make it safer and easier to manage. Each network takes at most one of each.

| Equipment | Effect | Level |
|---|---|---|
| Breaker panel (wall) | Trips instead of the inverter when the house demand exceeds 1,500 W, so the inverter does not lose 3 condition points. Red lamp when tripped; reset on the breaker itself ("Reset the breaker"), refused while still overloaded. | 3 |
| Low battery alarm (wall) | Below 20 % stock: a message to players within 30 tiles, then a beep every 10 game minutes until "Silence the alarm". The beacon stays lit until the stock is back above 25 %. | 2 |
| Backup generator (vanilla generator) | Started by the mod under 20 % battery, stopped at 90 % (sandbox `BackupStartPercent` / `BackupStopPercent`). Supplies 1,200 W, burns 1 L of fuel per 3 kWh (on top of its vanilla consumption). Still noisy and toxic indoors; it must be plugged and fuelled the vanilla way. Never starts without batteries. | 3 |
| Management computer (vanilla desktop computer) | 48 h history, forecast until sunrise. Load shedding at level 7: switches the lights off under 15 % to keep the fridge, re-armed above 30 %. | 6 |

The management computer and the backup generator are not crafted: they are vanilla objects found in the world. Link them from their own right-click menu (see [Wiring](03-wiring.md)).

## Parallel inverters (coupling)

Real off-grid systems get more power by adding identical inverters in parallel, not by pushing one beyond its rating. Live Wire does the same:

- Right-click an inverter > **Couple to an inverter** > a master inverter within cable range. The clicked inverter becomes a **slave**. Cost: the electric wire for the distance and 1 **inverter coupling kit** (recipe at Electrical 6).
- The slave must have no equipment of its own; a master takes at most 3 slaves (4 inverters).
- One network, one battery bank, one powered area (the master's). Capacity = 1,500 W × inverters in service; each switched-on inverter uses 20 W idle and wears as usual.
- A slave switched off or broken no longer counts: if the demand then exceeds what is left, the breaker (or the master) trips. Each slave has its own On/Off switch; reset on the master or the breaker.
- **Uncouple** on the slave makes it independent again (the kit is given back). A master picked up frees its slaves.
- The LCD Status page and the software show "Coupled: n / total in service" and the total capacity.
- Two independent inverters whose areas overlap no longer count the same appliances twice: each appliance is counted by the nearest switched-on inverter.

## When does the breaker trip?

When the demand of the house appliances exceeds the inverter maximum, **1,500 W** (the 20 W idle consumption is not counted). It is checked at each simulation step: every 10 game minutes and right after an action. Example: a stacked washer + dryer running together (up to 1,800 W).

Without a breaker, the **inverter** trips and loses 3 condition points; reset it on the inverter. With a breaker, the breaker trips instead; reset it on the breaker ("Reset the breaker"), which is refused while the load is still too high. Switch off some appliances first.

## See also

[Wiring](03-wiring.md) - [Inverter Screen and Software](05-inverter-screen-and-software.md) - [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) - [Multiplayer](12-multiplayer.md)
