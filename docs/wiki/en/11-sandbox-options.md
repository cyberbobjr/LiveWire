> Version française : [Options sandbox](../fr/11-options-sandbox.md)

# Sandbox Options

Server and game settings are on two pages of the sandbox options: **LiveWire** for the base mod, and **LiveWire Extended** for the optional add-on (only when the add-on is enabled).

## LiveWire page

| Name in game | Option | Default | Range | Effect |
|---|---|---|---|---|
| LiveWire equipment and parts loot multiplier | `EquipmentLootMultiplier` | 5 | 1–20 | Loot weight of LiveWire equipment and parts (devices, kits, solar cells, blades, masts) and of LiveWire Extended equipment; restart required, future rolls only. See [Loot tables](09-loot-tables.md) |
| Power scale | `PowerScale` | 1 | 0.1–10 | Multiplies the consumption given by the profile (1 = no change) |
| Consumption profile | `ConsumptionProfile` | Game values | Ultra-realistic 1993, Realistic 1993, Game values, Comfort | Power drawn by switched-on appliances; see the table in [Production and Calculations](04-production-and-calculations.md#appliance-consumption) |
| Solar production | `SolarMultiplier` | 1 | 0–10 | Solar panel production |
| Wind production | `WindMultiplier` | 1 | 0–10 | Wind turbine production |
| Hydro production | `HydroMultiplier` | 1 | 0–10 | Water wheel production |
| Battery capacity | `BatteryCapacityMultiplier` | 1 | 0.1–10 | Capacity of every battery |
| Battery wear | `BatteryWearMultiplier` | 1 | 0–10 | Battery wear; 0 = none |
| Device wear | `DeviceWearMultiplier` | 1 | 0–10 | Wear of sources, inverters and equipment; 0 = none |
| Inverter noise radius | `InverterNoiseRadius` | 2 | 0–10 | Radius in tiles of the hum heard by zombies; 0 = silent |
| Cable range | `LinkRange` | 12 | 4–30 | Maximum cable distance in tiles between a device and its inverter |
| Cable vertical range | `LinkVerticalRange` | 3 | 0–10 | Maximum floor difference for equipment connections and inverter coupling; 0 = same floor |
| Water pump range | `PumpRange` | 15 | 5–30 | Radius around a water pump where its taps are supplied |
| Tiles per electric wire | `WirePerTiles` | 4 | 0–20 | Tiles per electric wire; 0 = free cabling |
| Storm damage | `StormDamage` | off | — | Thunderstorms and very strong winds damage solar panels and wind turbines |
| Electrical experience | `XPMultiplier` | 1 | 0–10 | Experience given by LiveWire actions |
| Skill requirements | `SkillGates` | on | — | Off = no Electrical level required |
| Run without players nearby | `SimulateUnloaded` | on | — | Production, consumption and wear go on when no player is nearby |
| Charge from the public grid | `GridCharging` | on | — | While the public grid works, an inverter inside a building powers itself and charges its batteries from it, up to a fifth of its rated power |
| Backup start (percent) | `BackupStartPercent` | 20 | 0–90 | A backup generator starts when the batteries fall below this percentage |
| Backup stop (percent) | `BackupStopPercent` | 90 | 10–100 | The backup generator stops once the batteries reach this percentage; the stop threshold is always at least 5 points above the start threshold |
| Solar orientation | `SolarOrientation` | on | — | Direction affects solar yield: south 100 %, east/west 85 %, north 55 % |
| Panel dirt | `SolarDirt` | on | — | Dirt reduces solar production; rain and cleaning remove it |
| Cold batteries | `BatteryCold` | off | — | Outside banks temporarily lose usable capacity in cold weather; energy is retained |
| Live maintenance risk | `LiveWorkRisk` | on | — | Shock risk during live maintenance, from 50 % at Electrical 0 to 0 % at Electrical 6; switch off the master inverter |

## LiveWire Extended page

| Name in game | Option | Default | Range | Effect |
|---|---|---|---|---|
| Outdoor strip around a building | `LiveWireExtended.BuildingBand` | 0 | 0–8 | Width in squares of the outdoor strip around a connected building that also gets power (porch, garden path). The game powers whole 8 x 8 blocks, so the powered area rounds up to them |
| Buildings with a breaker board (%) | `LiveWireExtended.HouseBoardPercent` | 30 | 0–100 | Share of the map's buildings that already have a breaker board (their own electrical box when they have one). Once linked to an inverter, it is prewired room by room, without labels; unwired appliances of the building then have no current |

## Player option

In **Options > Mods > LiveWire**: **Inverter hum volume (0-100)**, default 100 (0 = off). It is per player and only affects what that player hears.

## Live maintenance risk

Live maintenance risk is 50% at Electrical 0 and falls to zero at Electrical 6. Switch off the master inverter; the main breaker is not enough. See [safety and XP rules](10-electrical-skill-and-maintenance.md#electrical-safety-and-experience).

## See also

[Production and Calculations](04-production-and-calculations.md) - [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) - [Wiring](03-wiring.md) - [Multiplayer](12-multiplayer.md) - [LiveWire Extended](14-livewire-extended.md)
