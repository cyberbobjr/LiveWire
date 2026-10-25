> Version française : [Compétence Électricité et entretien](../fr/10-competence-electricite-et-entretien.md)

# Maintenance and Skill

Devices wear out over time, which lowers their output (see the condition factor in [Production and Calculations](04-production-and-calculations.md)). The Electrical skill unlocks the equipment and the repair work.

## Wear

| Device | Normal wear | Accelerators |
|---|---|---|
| Solar panel | -1 per 10 days | Thunderstorm, only if sandbox `StormDamage` (off by default) |
| Wind turbine | -1 per 4 days | Wind above 85 km/h with `StormDamage` |
| Water wheel | -1 per 6 days | none |
| Inverter | -1 per 5 days while on | Load above 80 %: wear x 2; each trip without breaker: -3; soundproofed: x 1.25 |
| Breaker | -1 per 15 days | none |
| Power bank, alarm | -1 per 30 days | none |
| Battery | 100 / life cycles per full cycle | Discharge below 20 %: wear doubled; self-discharge 0.2 % per day |

## Repair, overhaul, recondition

- **Repair**: 1 electronics scrap + 1 electric wire, gains 5 + Electrical level points (up to 90). Failure chance: max(5, 40 - 5 x level) %, halved from level 8. Parts are lost on failure.
- **Overhaul** (level 8): 4 electronics scrap + 2 electric wires, back to 100.
- **Recondition a battery** (level 4, or 6 when dead): kept screwdriver, 1 electronics scrap + 1 wire + 0.5 L water; +15 condition, capped at 80, four repairs maximum. See the full battery rules below.

## Voltage tester

The Voltage Tester (`LiveWire.VoltageTester`): right-click a tile, then **Live Wire**, then **Measure**.

| Level | Reading |
|---|---|
| 0 | Power yes / no |
| 1 | Origin of the power |
| 2 | Appliance consumption |
| 4 | Network balance |

## Electrical skill

| Level | Unlocks | Continuous effect |
|---|---|---|
| 0 | Read a tester: powered or not | none |
| 1 | Voltage tester | Detailed reading of the tile |
| 2 | Power bank, low battery alarm, soundproofing kit | Battery wear -5 % |
| 3 | Solar panels, breaker, backup generator | Installation efficiency 0.85 |
| 4 | Recondition a battery | Autonomy reading |
| 5 | Inverter | none |
| 6 | Wind turbine assembly, deep-cycle battery, management computer | Battery wear -10 % |
| 7 | Water wheel crafting, load shedding | Installation efficiency 0.95 |
| 8 | Solar cells from scrap, overhaul | Repair failure halved |
| 9-10 | none | Installation efficiency 1.0; device wear -25 % |

## Experience

Always given by the server (sandbox `XPMultiplier`).

| Action | XP |
|---|---|
| Mod recipes | see [Recipes](08-recipes.md) |
| Place a solar panel | 10 |
| Place a wind turbine or water wheel | 20 |
| Place an inverter | 25 |
| Connect a source or battery | 3 |
| Inspect a device | 2 (once per device per day) |
| Measure with the tester | 1 (once per tile per hour) |
| Repair | 5 + 1 per point, max 15 |
| Recondition a battery | 8 |
| Reset after fixing an overload | 5 (once per hour) |
| Soundproof the inverter | 3 |

## Battery testing and maintenance

Test an inventory battery with a voltage tester: Electrical 1 shows charge, 3 shows
stored kWh/capacity/condition, 5 adds equivalent cycles and estimated remaining life.
Recondition the same battery at level 4, or level 6 when dead: screwdriver kept,
one electronic scrap, one wire and 0.5 L of water. Gain 15 condition up to 80, at most
four repairs per battery. Cycles remain; repair never adds energy. A dead battery
returns empty. Tiny charge fractions are retained by the authoritative model even
when the native inventory gauge has coarse graduations.

BatteryCold is off by default: outside banks have 20% less accessible capacity at
0 C and 40% less at -15 C. The unavailable reserve returns on thawing; indoor banks
are unaffected. This does not erase charge or reset condition/cycles.

Dead, empty equipment can be salvaged at level 3 with a screwdriver: one scrap and
one wire, plus a solar cell for a panel. Live maintenance risk is optional; see the detailed rules below.

Wind turbines and water wheels need Electrical 2 to place/pick up; crafting stays at 6 and 7 respectively. Mechanical blade/mast recipes need no Electrical level.

## Electrical safety and experience

**Live maintenance risk** is enabled by default. When active, connecting,
disconnecting, repairing or salvaging connected equipment can cause a shock. One
roll occurs at the end of an allowed intervention, before materials are consumed.

| Actual Electrical level | Risk per intervention |
|---|---:|
| 0 | 50% |
| 1 | 42% |
| 2 | 33% |
| 3 | 25% |
| 4 | 17% |
| 5 | 8% |
| 6–10 | 0% |

**Switch off the master inverter before working.** Opening the main breaker or
both circuits does not isolate its terminals. A fault, trip or empty battery is
also not explicit isolation. A failed inverter can still be switched off; this
neither repairs it nor lets it charge batteries while its condition remains zero.

The burn and pain affect the **screwdriver hand**: right for primary, left for
secondary. An inventory tool is shown in the primary hand during the action.
Held items are dropped and the action stops before spending materials. A working
screwdriver is also required for disconnection. Gloves and weather do not change
the probability.

Opening screens, operating levers, cleaning/removing snow, moving batteries,
placing/moving equipment or coupling inverters do not invoke this shock check.
Repairing a running inverter is refused before intervention. Existing distance,
skill and safehouse rules still apply.

**Every successful Live Wire equipment repair awards Electrical XP**: 5 XP plus
one per condition point restored, capped at 15; overhauls use the same rule.
Battery reconditioning awards 8 XP. **Every Live Wire crafting recipe awards
Electrical XP**, including tester crafting/dismantling. Blades and masts each
award 2 XP without requiring an Electrical level; final turbine assembly keeps
its 30 XP. Refused or shock-interrupted work awards no repair XP.


## Testing wear in debug

In solo `-debug`, or as an MP administrator: right-click a device → Live Wire →
its name → **Debug: this device**. Remove 10 condition points, set 50% or 10%,
disable it (0%) or restore 100%. Works without a cable. This affects the selected
device, does not directly edit its stored batteries, and awards no XP. Restoring
a broken inverter leaves it switched off.

A world that already saved the electrical risk as disabled keeps that setting:
enable **Live maintenance risk** in its sandbox options if needed.

## See also

[Recipes](08-recipes.md) - [Equipment](02-equipment.md) - [Sandbox Options](11-sandbox-options.md) - [Optional Equipment](06-optional-equipment.md)
