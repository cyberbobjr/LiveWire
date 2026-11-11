> Version française : [Options sandbox](../fr/11-options-sandbox.md)

# Sandbox Options

Server and game settings are on two pages of the sandbox options: **LiveWire** for the base mod, and **LiveWire Extended** for the optional add-on (only when the add-on is enabled).

## LiveWire page

| Option | Default | Range | Effect |
|---|---|---|---|
| EquipmentLootMultiplier | 5 | 1–20 | Loot weight of LiveWire equipment and parts (devices, kits, solar cells, blades, masts) and of LiveWire Extended equipment; restart required, future rolls only |
| `ConsumptionProfile` | Game values | Ultra-realistic 1993, Realistic 1993, Game values, Comfort | Power drawn by switched-on appliances; see the table in [Production and Calculations](04-production-and-calculations.md#appliance-consumption) |
| `PowerScale` | 1.0 | 0.1-10 | Multiplies the consumption given by the profile (1 = no change) |
| `SolarMultiplier` / `WindMultiplier` / `HydroMultiplier` | 1.0 | 0-10 | Production per source family |
| `BatteryCapacityMultiplier` | 1.0 | 0.1-10 | Battery capacity |
| `BatteryWearMultiplier` / `DeviceWearMultiplier` | 1.0 | 0-10 | Wear; 0 = none |
| `InverterNoiseRadius` | 2 | 0-10 | Radius of the hum heard by zombies; 0 = silent |
| `LinkRange` | 12 | 4-30 | Maximum cable distance |
| `LinkVerticalRange` | 3 | 0-10 | Maximum floor difference for equipment connections and inverter coupling; 0 = same floor |
| `PumpRange` | 15 | 5-30 | Radius around a water pump where its taps are supplied |
| `WirePerTiles` | 4 | 0-20 | Tiles per electric wire; 0 = free cabling |
| `SolarOrientation` | true | — | Direction affects solar yield: south 100%, east/west 85%, north 55% |
| `SolarDirt` | true | — | Dirt reduces solar production; rain and cleaning remove it |
| `BatteryCold` | false | — | Outside banks temporarily lose usable capacity in cold weather; energy is retained |
| `LiveWorkRisk` | true | — | Shock risk during live maintenance, from 50% at Electrical 0 to 0% at Electrical 6; switch off the master inverter |
| `StormDamage` | false | — | Thunderstorms and very strong winds damage solar panels and wind turbines |
| `XPMultiplier` | 1.0 | 0-10 | Experience given by the mod |
| `SkillGates` | true | — | false = no Electrical level required |
| `SimulateUnloaded` | true | — | Production, consumption and wear go on when no player is nearby |
| `GridCharging` | true | — | While the public grid works, an inverter inside a building powers itself and charges its batteries from it, up to a fifth of its rated power |
| `BackupStartPercent` | 20 | 0-90 | A backup generator starts when the batteries fall below this percentage |
| `BackupStopPercent` | 90 | 10-100 | The backup generator stops once the batteries reach this percentage; the stop threshold is always at least 5 points above the start threshold |

## LiveWire Extended page

| Option | Default | Range | Effect |
|---|---|---|---|
| `LiveWireExtended.BuildingBand` | 0 | 0-8 | Width in squares of the outdoor strip around a connected building that also gets power (porch, garden path). The game powers whole 8 x 8 blocks, so the powered area rounds up to them |
| `LiveWireExtended.HouseBoardPercent` | 30 | 0-100 | Share of the map's buildings that already have a breaker board (their own electrical box when they have one). Once linked to an inverter, it is prewired room by room, without labels; unwired appliances of the building then have no current |

## Player option

In **Options > Mods > LiveWire**: inverter hum volume, 0-100, default 100 (0 = off). It is per player and only affects what that player hears.

## Live maintenance risk

Live maintenance risk is 50% at Electrical 0 and falls to zero at Electrical 6. Switch off the master inverter; the main breaker is not enough. See [safety and XP rules](10-electrical-skill-and-maintenance.md#electrical-safety-and-experience).

## See also

[Production and Calculations](04-production-and-calculations.md) - [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) - [Wiring](03-wiring.md) - [Multiplayer](12-multiplayer.md) - [LiveWire Extended](14-livewire-extended.md)
