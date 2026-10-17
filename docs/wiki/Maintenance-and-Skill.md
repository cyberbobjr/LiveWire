> Version francaise : [[Entretien et competence|Entretien-et-competence]]

# Maintenance and Skill

Devices wear out over time, which lowers their output (see the condition factor in [[Production and Calculations|Production-and-Calculations]]). The Electrical skill unlocks the equipment and the repair work.

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
- **Recondition a battery** (level 4): 1 electronics scrap + 0.5 L water, +15 condition, capped at 80.

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
| 6 | Wind turbine, deep-cycle battery, management computer | Battery wear -10 % |
| 7 | Water wheel, load shedding | Installation efficiency 0.95 |
| 8 | Solar cells from scrap, overhaul | Repair failure halved |
| 9-10 | none | Installation efficiency 1.0; device wear -25 % |

## Experience

Always given by the server (sandbox `XPMultiplier`).

| Action | XP |
|---|---|
| Mod recipes | see [[Recipes|Recipes]] |
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

## See also

[[Recipes|Recipes]] - [[Equipment|Equipment]] - [[Sandbox Options|Sandbox-Options]] - [[Optional Equipment|Optional-Equipment]]
